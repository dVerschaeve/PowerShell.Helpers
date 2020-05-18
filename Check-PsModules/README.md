# Check-PSModules.ps1

## SYNOPSIS
Script validates the desired configuration for PowerShell modules

## DESCRIPTION
The script will parse a provided JSON file containing PowerShell module names and the desired version.
The Powershell script will install, update or bring the module to a desired version.
The script requires a JSON input file with the following format:

```JSON
    {
        "PsModules" : [
            {"Name" : "ModuleName", "Version" : "X.X.X.X"},
            {"Name" : "ModuleName", "Version" : "Latest"}
        ]
    }
```
When version 'Latest' is specified, the script will always install the latest version available in the PowerShell gallery.

## EXAMPLE
To execute the script, run the following command in PowerShell (Administrative priviliges might be required)
```PowerShell
    .\Check-PsModules.ps1 -JSONFile .\MyModules.json
```