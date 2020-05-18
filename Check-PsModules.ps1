<#
.SYNOPSIS
    Script validates the desired configuration for PowerShell modules
.DESCRIPTION
    The script will parse a provided JSON file containing PowerShell module names and the desired version.
    The Powershell script will install, update or bring the module to a desired version.

    The script requires a JSON input file with the following format:
    {
        "PsModules" : [
            {"Name" : "ModuleName", "Version" : "X.X.X.X"},
            {"Name" : "ModuleName", "Version" : "Latest"}
        ]
    }

    When version 'Latest' is specified, the script will always install the latest version available in the PowerShell gallery.
.EXAMPLE
    .\Check-PsModules.ps1 -JSONFile .\MyModules.json

.NOTES
    Author: 	Verschaeve Dries
    Version: 1.0
    Date: 	18/05/2020
#>
param (
    [Parameter(Position=0,mandatory=$true,HelpMessage="JSON Configuration FIle")]
    [ValidateScript({
        if( -Not ($_ | Test-Path) ){
            throw "JSON File does not exist."
        }
        return $true
    })]
    [System.IO.FileInfo]$JSONFile
)

Function Get-InstalledPsModule(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName
    )

    Try{
        $Module = Get-InstalledModule -Name $ModuleName -ErrorAction Stop
        Return $Module.Version
    } Catch {
        Return $Null
    }
}

Function Get-GalleryPSModule(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName
    )

    Try{
        $Module = Find-Module -Name $ModuleName -ErrorAction Stop
        Return $Module.version
    } Catch {
      Return $Null
    }
}

Function Update-PsModule(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName,
        [Parameter(Position=1,mandatory=$false)][String]$RequiredVersion = "Latest"
    )

    Uninstall-Module -Name $ModuleName -Force
    If($RequiredVersion -ne "Latest"){
        Install-Module -Name $ModuleName -RequiredVersion $Version -Force
    } Else {
        Install-Module -Name $ModuleName -Force
    }
}

Function Test-PsModule(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName,
        [Parameter(Position=1,mandatory=$false)][String]$Version = "Latest"
    )

    $LocalVersion = Get-InstalledPsModule -ModuleName $ModuleName
    $GalleryVersion = Get-GalleryPSModule -ModuleName $ModuleName

    If($Null -ne $LocalVersion){
        If($null -ne $GalleryVersion){
            If($Version -eq "Latest"){
                If($LocalVersion -ne $GalleryVersion){
                    Write-Host "Module" $ModuleName "-" $LocalVersion " is not up to date to the latest version" $GalleryVersion -ForegroundColor Yellow
                    Update-Module -Name $ModuleName -Force
                } Else {
                    Write-Host "Module" $ModuleName "is running the latest version" $GalleryVersion -ForegroundColor Green
                }
            } Else {
                If($LocalVersion -ne $Version){
                    Write-Host "Module" $ModuleName "-" $LocalVersion "is not running the desired version" $Version -ForegroundColor Yellow
                    Update-PsModule -ModuleName $ModuleName -RequiredVersion $Version
                } Else {
                    Write-Host "Module" $ModuleName "is running the desired version" $Version -ForegroundColor Green
                }
            }
        } Else {
            Write-Host "The provide module" $ModuleName "could not be found in the PowerShell gallery!" -ForegroundColor Red
        }
    } Else {
        Write-Host "Module" $ModuleName "not installed. Deploying Module" -ForegroundColor Yellow
        If($Version -eq "Latest"){
            Install-Module -Name $ModuleName -Force
        } Else {
            Install-Module -Name $ModuleName -RequiredVersion $Version -Force
        }
    }
}

$JSON = Get-Content -Path $JSONFile | ConvertFrom-JSON
ForEach($Module in $JSON.PsModules){
    Test-PsModule -ModuleName $Module.Name -Version $Module.Version
}