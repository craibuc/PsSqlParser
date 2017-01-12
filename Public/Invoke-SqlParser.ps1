
<#
.SYNOPSIS
    Parses a SQL statement and extracts its table/column combinations.

.DESCRIPTION
    Parses a SQL statement and extracts its table/column combinations.

.PARAMETER Query (-Q)
    The SQL statement to be processed

.PARAMETER Syntax (-S)
    The SQL statement's syntax (allowed: 'mssql','oracle')

.PARAMETER Unique (-U)
    Return a unique list of table/column combinations (NOT IMPLEMENTED)

.EXAMPLE
    PS> Invoke-SqlParser -Query "SELECT p.id,p.mrn,p.name,e.id FROM patient p INNER JOIN encounter e ON p.id=e.patient_id" -Syntax 'oracle'
    Table       ColumnName      ColumnType         Location
    -----       ----------      ----------         --------
    patient     id              Linked        joinCondition
    patient     id              Linked         resultColumn
    patient     mrn             Linked         resultColumn
    patient     name            Linked         resultColumn
    encounter   patient_id      Linked        joinCondition
    encounter   id              Linked         resultColumn

    Invokes the parsing engine, using Oracle syntax, extracting the list of tables and fields.

.EXAMPLE
    PS> Get-Content ~\Desktop\query.sql -Raw | Invoke-SqlParser -Syntax 'oracle'
    Table       ColumnName      ColumnType         Location
    -----       ----------      ----------         --------
    patient     id              Linked        joinCondition
    patient     id              Linked         resultColumn
    patient     mrn             Linked         resultColumn
    patient     name            Linked         resultColumn
    encounter   patient_id      Linked        joinCondition
    encounter   id              Linked         resultColumn

    The contents of a file are passed on the pipeline to the parsing engine.

#>
function Invoke-SqlParser {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [alias('Q')]
        [string[]]$Query,

        [Parameter(Position=1)]
        [ValidateSet('mssql','oracle')]
        [alias('S')]
        [string]$Syntax = 'oracle',

        [alias('U')]
        [switch]$Unique
    )

    # use begin/process/end to support pipeline processing
    BEGIN {
        Write-Debug "$($MyInvocation.MyCommand.Name)::Begin"

        # set SQL syntax
        switch ($Syntax)
        {
            "mssql" {
                $db = [gudusoft.gsqlparser.EDbVendor]::DbVMssql
            }
            "oracle" {
                $db = [gudusoft.gsqlparser.EDbVendor]::DbVOracle
            }
            # TODO: add others
        }

        Write-Debug "Syntax: $db"

        try {
            $sqlParser = New-Object gudusoft.gsqlparser.TGSqlParser -ArgumentList $db
        }
        catch [Exception] {
            throw $_
        }

    }
    PROCESS {
        Write-Debug "$($MyInvocation.MyCommand.Name)::Process"

        Foreach ($Q In $Query) {
            Write-Verbose $Q

            # attempt to parse the query
            $sqlParser.SqlText = $Q
            $code = $sqlParser.Parse()

            # display parsing errors
            if ( $code -ne 0 ) {
                Write-Error sqlparser.ErrorMessages
            }

            $objects=@()

            for ($i = 0; $i -lt $sqlparser.SqlStatements.Count; $i++)
            {
                $sqlStatement = $sqlParser.SqlStatements[$i]

                $objects += ( Analyze $sqlParser.SqlStatements[$i] )

            } # SqlStatements

            # return to pipeline
            Write-Output $objects

        }

    }
    END {
        Write-Debug "$($MyInvocation.MyCommand.Name)::End"
    }

}

##
# examine each statement recursively, if necessary
#

function Analyze
{

    [CmdletBinding()]
    Param(
        [gudusoft.gsqlparser.stmt.TSelectSqlStatement]$sqlStatement
    )

    $objects=@()

    for ($j=0; $j -lt $sqlStatement.Tables.Count; $j++)
    {

        $tableName = $sqlStatement.Tables[$j].Fullname
        Write-Debug "Table: $tableName"

        for ($k=0; $k-lt $sqlStatement.Tables[$j].linkedColumns.Count; $k++)
        {
            $columnName = $sqlStatement.Tables[$j].linkedColumns[$k].ColumnNameOnly
            Write-Debug "`tColumn: $columnName"

            $location = $sqlStatement.Tables[$j].linkedColumns[$k].Location
            Write-Debug "`tlocation: $location"

            $objects += [PsCustomObject]@{Table=$tableName;ColumnName=$columnName;ColumnType='Linked';Location=$location}

        } # columns

    } # tables

    # TODO: include orphans
    if ($sqlStatement.orphanColumns.Count > 0)
    {
        Write-Host "orphanColumns"
    }

    # process queries w/i queries (e.g. scalar subquery; inline views)
    for ($i=0; $i -lt $sqlStatement.ChildNodes.Count; $i++)
    {
        # recurse if child is a SQL statement
        if ($sqlStatement.ChildNodes[$i] -is [gudusoft.gsqlparser.TCustomSqlStatement])
        {
            $objects += ( Analyze $sqlStatement.ChildNodes[$i] )
        }
    }

    return $objects

}

##
# alias
#

Set-Alias parse Invoke-SqlParser
