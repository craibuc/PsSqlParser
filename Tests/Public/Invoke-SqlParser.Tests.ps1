BeforeAll {

    $ProjectDirectory = Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent
    $PublicPath = Join-Path $ProjectDirectory "/PsSqlParser/Public/"
    
    $SUT = (Split-Path -Leaf $PSCommandPath) -replace '\.Tests\.', '.'
    . (Join-Path $PublicPath $SUT)
    
}

Describe "Invoke-SqlParser" {
    
    Context 'Parameter validation' {

        BeforeAll {
            # arrange
            $Command = Get-Command 'Invoke-SqlParser'
        }

        Context 'Query' {
            BeforeAll {
                $ParameterName='Query'
            }
            It "$ParameterName is a [string[]]" {
                $Command | Should -HaveParameter $ParameterName -Type [string[]]
            }
            It "$ParameterName is mandatory" {
                $Command | Should -HaveParameter $ParameterName -Mandatory
            }
        }

        Context 'Syntax' {
            BeforeAll {
                $ParameterName='Syntax'
            }
            It "$ParameterName is a [string]" {
                $Command | Should -HaveParameter $ParameterName -Type [string]
            }
            It "$ParameterName is mandatory" {
                $Command | Should -HaveParameter $ParameterName -Mandatory
            }
        }

        Context 'Unique' {
            BeforeAll {
                $ParameterName='Unique'
            }
            It "$ParameterName is a [switch]" {
                $Command | Should -HaveParameter $ParameterName -Type [switch]
            }
            It "$ParameterName is not mandatory" {
                $Command | Should -HaveParameter $ParameterName -Not -Mandatory
            }
        }
    }

    Context 'Usage' {

        # arrange
        BeforeAll {
            $query = "SELECT p.id,p.mrn,p.name,e.id FROM patient p INNER JOIN encounter e ON p.id=e.patient_id"
            $syntax = "oracle"
        }

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
                $actual = Invoke-SqlParser -Query $query -Syntax $syntax -Verbose

                # assert
                @(Compare-Object $Expected $Actual -Property Table, ColumnName, ColumnType, Location |
                    Where-Object { $_.SideIndicator -eq '=>' }).Count | Should Be 0
            }

        }
    }

}
