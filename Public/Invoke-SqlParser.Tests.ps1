import-module PsSqlParser -Force

# $here = Split-Path -Parent $MyInvocation.MyCommand.Path
# $sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
# . "$here\$sut"

Describe "Invoke-SqlParser" {

    $query = "SELECT p.pat_mrn_id,p.pat_name,pe.pat_enc_csn_id ENC_ID FROM patient p INNER JOIN pat_enc_hsp pe ON p.pat_id=pe.pat_id"
    $syntax = "oracle"

    Context "If the -Query parameter has not been supplied" {

        It -Skip "Should throw an exception" {
            { Invoke-SqlParser -S $syntax }| Should Throw
        }

    }

    Context "If the -Syntax parameter has not been supplied" {

        It -Skip "Should throw an exception" {
            { Invoke-SqlParser $query } | Should Throw
        }

    }

    Context "If any invalid -Syntax parameter has been supplied" {

        It "Should throw an exception" {
            { Invoke-SqlParser $query -S "not valid"} | Should Throw
        }

    }

    Context "-Q and -S parameter supplied" {

        $expected = @()
        $expected += [PsCustomObject]@{Table='patient';ColumnName='pat_id';ColumnType='Linked';Location='eljoinCondition'}
        $expected += [PsCustomObject]@{Table='patient';ColumnName='pat_mrn_id';ColumnType='Linked';Location='elselectlist'}
        $expected += [PsCustomObject]@{Table='patient';ColumnName='pat_name';ColumnType='Linked';Location='elselectlist'}
        $expected += [PsCustomObject]@{Table='pat_enc_hsp';ColumnName='pat_id';ColumnType='Linked';Location='eljoinCondition'}
        $expected += [PsCustomObject]@{Table='pat_enc_hsp';ColumnName='pat_enc_csn_id';ColumnType='Linked';Location='elselectlist'}

        It "Should return an array of PsCustomObjects that contain tables and column details" {
            $actual = Invoke-SqlParser -Q $query -S $syntax -Verbose
            # $actual | Should Be $expected
            (Compare-Object $actual $expected).Count | Should Be 0
        }

    }

}
