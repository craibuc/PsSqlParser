##
# import SQL-parsing assembly (located in same folder as PsSql.psm1)
#

# Add-Type -Path  "$PSScriptRoot\gudusoft.gsqlparser.dll"

##
# load (dot-source) *.PS1 files, excluding unit-test scripts (*.Tests.*), and disabled scripts (__*)
#

@("$PSScriptRoot\Public\*.ps1","$PSScriptRoot\Private\*.ps1") | Get-ChildItem | 
    Where-Object { $_.Name -like '*.ps1' -and $_.Name -notlike '__*' -and $_.Name -notlike '*.Tests*' } | 
    % {

        # dot-source script
        # Write-Host "Loading $($_.BaseName)"
        . $_

        # export functions in the `Public` folder
        if ( (Split-Path( $_.Directory) -Leaf) -Eq 'Public' ) {
            # Write-Host "Exporting $($_.BaseName)"
            Export-ModuleMember $_.BaseName
        }

    }

##
#  export aliases specified in a PS1 file
#

Export-ModuleMember -Alias parse