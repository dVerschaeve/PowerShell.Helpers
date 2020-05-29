# Check-PSModules.ps1

## SYNOPSIS
Script validates the desired configuration for PowerShell modules.

## DESCRIPTION
The script will parse a provided JSON file containing PowerShell module names and the desired version.
The Powershell script will then install, update, uninstall or bring the module to a desired version.

The script requires a JSON input file with the following format:

```JSON
    {
        "PsModules" : [
            {"Name" : "ModuleName", "Version" : "X.X.X.X"},
            {"Name" : "ModuleName", "Version" : "Latest"},
            {"Name" : "ModuleName", "Version" : "None"}
        ]
    }
```
Instructions for Version:
- X.X.X.X: install a specific version listed on the [PowerShell Gallery](https://www.powershellgallery.com)
- Latest: the script will always install the latest version available in the PowerShell gallery.
- None: will remove a module that is no longer needed

## EXAMPLE
To execute the script, run the following command in PowerShell (Administrative priviliges might be required)
```PowerShell
    .\Check-PsModules.ps1 -JSONFile .\MyModules.json
```