# PsSqlParser
PowerShell wrapper of Gudu Software's General SQL Parser library

## Introduction

## Prerequisites

### Enable PowerShell's script execution

Ensure that PowerShell can execute scripts.

#### 64-bit Client
Start Windows Powershell (`%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe`).

At the PowerShell prompt (abbreviated to `PS >`), type:

```powershell
PS > Get-Execution Policy
```

If the result is `Restricted`, type:

```powershell
PS > Set-Execution-Policy RemoteSigned
```

NOTE: This only needs to be done once for each user.

#### 32-bit Client
Start Windows PowerShell (x86) (`%SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe`)

Follow the same process as described for the 64-bit client.

NOTE: This only needs to be done once for each user.

### Create a PowerShell Profile

A PowerShell profile (similar to the Unix's `.bashrc` and `.bash_profile` files) is used to configure the PowerShell envrionment when it starts.  The process of creating a profile will create the `Modules` directory; PowerShell modules need to be placed in the folder to be recognized by the system.

At the PowerShell prompt, type:

```powershell
PS > Test-path $profile
```

If `True` is returned, the process is done.

Otherwise, type:

```powershell
PS > New-item –type file –force $profile
```
Should you want to edit the profile (not required for this exercise), type:

```powershell
PS > Notepad $profile
```
This will open the profile file in Notepad.

NOTE: This only needs to be done once for each user.

## Install Software

### Powershell Module
Copy the contents of the ZIP file to `Modules` folder (`C:\Users\<USER_NAME>\Documents\WindowsPowerShell\Modules`)

The folder structure should resemble:

```
...
 + My Documents \
   + WindowsPowerShell \
	 + Modules \
	   + PsSqlParser \
		 - PsSqlParser.psd1
		 - PsSqlParser.psm1
		 + Public \
		 + Private \
		   - Invoke-SqlParser.ps1
 ...
```

### SQL-parsing Library
The core, SQL-parsing functionality is provided by Gudu Software’s SQL Parser assembly (a trial version (with a 1000-character limitation) is available from their website).
Steps:

1. Download the [General SQL Parser's.Net assembly](http://sqlparser.com/download.php)
2. Decompress the contents of the ZIP file
3. Location the assembly (gudusoft.gsqlparser.dll)
4. Right click the file and choose ‘Properties’ from the context menu
5. Click <kbd>Unblock</kbd>, then <kbd>OK</kbd>

	![Properties dialog](https://raw.githubusercontent.com/craibuc/PsSqlParser/master/images/properties.png)

6. Move or copy the file to the `PsSqlParser` folder.

The folder structure should resemble:

```
...
 + My Documents \
   + WindowsPowerShell \
	 + Modules \
	   + PsSqlParser \
		 - gudusoft.gsqlparser.dll
		 - PsSqlParser.psd1
		 - PsSqlParser.psm1
		 + Public \
		 + Private \
		   - Invoke-SqlParser.ps1
 ...
```

## Usage

### Parse the contents of a file

Assuming that this query:

```sql
SELECT  p.pat_mrn_id,p.pat_name,pe.pat_enc_csn_id ENC_ID 
FROM    patient p 
INNER JOIN pat_enc_hsp pe ON p.pat_id=pe.pat_id
```

is contained in `~\Desktop\query.txt` (`~` is an alias for `C:\Users\<USER_NAME>`).

Open PowerShell, type the follow commands at the prompt:

```powershell
# imports the sql-parsing library into the current powershell session
PS > Import-Module PsSqlParser

# place the contents of the file in the $query variable; without the -Raw flag,
# the contents would be converted into an array (not desirable in this situtaion)
PS > $query = Get-Content ~\Desktop\query.txt -Raw

# invoke the parser, passing the query's text, indicating that uses Oracle's syntax
PS > Invoke-SqlParser -Query $query -Syntax 'oracle'
Table                          ColumnName                    ColumnType                                         Location
-----                          ----------                    ----------                                         -------- 
patient                        pat_id                        Linked                                      eljoinCondition 
patient                        pat_mrn_id                    Linked                                         elselectlist 
patient                        pat_name                      Linked                                         elselectlist 
pat_enc_hsp                    pat_id                        Linked                                      eljoinCondition 
pat_enc_hsp                    pat_enc_csn_id                Linked                                         elselectlist
```

This can be shortened using the pipeline (`|`), aliases (`Invoke-SqlParser` => `parse`) and positional parameters (`-Query` is the first parameter; `-Syntax` is the second parameter):

```powershell
PS > gc ~\Desktop\query.txt -Raw | parse -S 'oracle'
```

```powershell
# concatenate
PS >  gc ~\Desktop\query.txt -Raw | parse -S 'oracle' | % {$_.table + "." + $_.columnname}
patient.pat_id
patient.pat_mrn_id
patient.pat_name
pat_enc_hsp.pat_id
pat_enc_hsp.pat_enc_csn_id
```

If you are using the trial edition, you can determine the length of the SQL statement is within the 1000-character limitation:

```powershell
PS > (Get-Content ~\Desktop\query.txt -Raw | Measure-Object -Character).Characters
```
