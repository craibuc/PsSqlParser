import-module PsSqlParser -Force

# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
# $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
# . "$here\$sut"

Describe "Invoke-SqlParser" {

    # arrange
    $query = "SELECT p.id,p.mrn,p.name,e.id FROM patient p INNER JOIN encounter e ON p.id=e.patient_id"
    $syntax = "oracle"

    Context "Well-formatted, two-table query" {

        $expected = @()
        $expected += [PsCustomObject]@{Table='patient';ColumnName='id';ColumnType='Linked';Location='joinCondition'}
        $expected += [PsCustomObject]@{Table='patient';ColumnName='id';ColumnType='Linked';Location='resultColumn'}
        $expected += [PsCustomObject]@{Table='patient';ColumnName='mrn';ColumnType='Linked';Location='resultColumn'}
        $expected += [PsCustomObject]@{Table='patient';ColumnName='name';ColumnType='Linked';Location='resultColumn'}
        $expected += [PsCustomObject]@{Table='encounter';ColumnName='id';ColumnType='Linked';Location='resultColumn'}
        $expected += [PsCustomObject]@{Table='encounter';ColumnName='patient_id';ColumnType='Linked';Location='joinCondition'}

        It "Should return an array of PsCustomObjects that contain tables and column details" {
            # act
            $actual = Invoke-SqlParser -Q $query -S $syntax -Verbose

            # assert            
            @(Compare-Object $Expected $Actual -Property Table, ColumnName, ColumnType, Location |
                Where-Object { $_.SideIndicator -eq '=>' }).Count | Should Be 0
        }

    }

}
