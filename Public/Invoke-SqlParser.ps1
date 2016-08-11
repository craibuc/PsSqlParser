
<#
.SYNOPSIS
Parses a SQL statement and extracts its table/column combinations.

.DESCRIPTION
Parses a SQL statement and extracts its table/column combinations.

.PARAMETER Query (-Q)
The SQL statement to be processed

.PARAMETER Syntax (-S)
The SQL statement's syntax (allowed: 'mssql','oracle')

.PARAMETER Syntax (-U)
Return a unique list of table/column combinations (NOT IMPLEMENTED)

.EXAMPLE
PS> Invoke-SqlParser -Q "SELECT p.pat_mrn_id,p.pat_name,pe.pat_enc_csn_id ENC_ID FROM patient p INNER JOIN pat_enc_hsp pe ON p.pat_id=pe.pat_id" -S "oracle"
Table        ColumnName      ColumnType         Location
 -----       ----------      ----------         --------
 patient     pat_id          Linked      eljoinCondition
 patient     pat_mrn_id      Linked         elselectlist
 patient     pat_name        Linked         elselectlist
pat_enc_hsp  pat_id          Linked      eljoinCondition
pat_enc_hsp  pat_enc_csn_id  Linked         elselectlist

Invokes the parsing engine, using Oracle syntax, extracting the list of tables and fields.

.EXAMPLE
PS> Get-Content ~\Desktop\query.sql -Raw | Invoke-SqlParser -S "oracle"
Table        ColumnName      ColumnType         Location
 -----       ----------      ----------         --------
 patient     pat_id          Linked      eljoinCondition
 patient     pat_mrn_id      Linked         elselectlist
 patient     pat_name        Linked         elselectlist
pat_enc_hsp  pat_id          Linked      eljoinCondition
pat_enc_hsp  pat_enc_csn_id  Linked         elselectlist

The contents of a file are passed on the pipeline to the parsing engine.

#>
function Invoke-SqlParser {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [alias('Q')]
        [string[]]$Query,

        [Parameter(Position=1, Mandatory=$true)]
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
                $db = [gudusoft.gsqlparser.TDbVendor]::DbVMssql
            }
            "oracle" {
                $db = [gudusoft.gsqlparser.TDbVendor]::DbVOracle
            }
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
            $sqlParser.SqlText.Text = $Q
            $code = $sqlParser.Parse()

            # display parsing errors
            if ( $code -ne 0 ) {
                Write-Error sqlparser.ErrorMessages
            }

            $objects=@()

            for ($i = 0; $i -lt $sqlparser.SqlStatements.Count(); $i++)
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
# 
#

function Analyze
{

    [CmdletBinding()]
    Param(
        [gudusoft.gsqlparser.TSelectSqlStatement]$sqlStatement
    )

    $objects=@()

    for ($j=0; $j -lt $sqlStatement.Tables.Count(); $j++)
    {

        $tableName = $sqlStatement.Tables[$j].TableFullname
        Write-Debug "Table: $tableName"

        # $tbl = [PsCustomObject]@{Table=$tableName; Columns=@()}
        # $objects += $tbl

        for ($k=0; $k-lt $sqlStatement.Tables[$j].linkedColumns.Count(); $k++)
        {
            $columnName = $sqlStatement.Tables[$j].linkedColumns[$k].fieldAttrName
            Write-Debug "`tColumn: $columnName"

            $location = $sqlStatement.Tables[$j].linkedColumns[$k].Location
            Write-Debug "`tlocation: $location"

            $object = [PsCustomObject]@{Table=$tableName;ColumnName=$columnName;ColumnType='Linked';Location=$location}
            $objects += $object

            # $col = [PsCustomObject]@{ColumnName=$columnName;ColumnType='Linked';Location=$location}
            # $tbl.Columns += $col

        } # columns

    } # tables

    if ($sqlStatement.orphanColumns.Count() > 0)
    {
        Write-Host "orphanColumns"
    }

    # process queries w/i queries (e.g. scalar subquery; inline views)
    for ($i=0; $i -lt $sqlStatement.ChildNodes.Count(); $i++)
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