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
            {"Name" : "ModuleName", "Version" : "Latest"},
            {"Name" : "ModuleName", "Version" : "None"},
            {"Name" : "ModuleName", "Version" : "Latest", "AllowPrerelease" : "True"}
        ]
    }

    When version 'Latest' is specified, the script will always install the latest version available.
    When version 'AllowPrerelease' is specified, the script will always install the latest PreRelease version available.
    When version 'None' is specified, the script will ensure the module is not present on the local system.
.EXAMPLE
    .\Check-PsModules.ps1 -JSONFile .\MyModules.json

.NOTES
    Author: 	Verschaeve Dries
    Version: 1.1
    Date: 	29/09/2020
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
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName,
        [Parameter(Position=2,mandatory=$false)][bool]$AllowPrerelease = $False
    )

    Try{
        If($AllowPrerelease -eq $False){
            $Module = Find-Module -Name $ModuleName -ErrorAction Stop
        } Else {
            $Module = Find-Module -Name $ModuleName -AllowPrerelease -ErrorAction Stop
        }
        
        Return $Module.version
    } Catch {
      Return $Null
    }
}

Function Update-PsModule(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName,
        [Parameter(Position=1,mandatory=$false)][String]$RequiredVersion = "Latest",
        [Parameter(Position=2,mandatory=$false)][bool]$AllowPrerelease = $False
    )

    Uninstall-Module -Name $ModuleName -AllVersions -Force
    If($RequiredVersion -ne "Latest"){
        If($AllowPrerelease -eq $False){
            Install-Module -Name $ModuleName -RequiredVersion $Version -Force
        } Else {
            Install-Module -Name $ModuleName -RequiredVersion $Version -AllowPrerelease -Force
        }
    } Else {
        If($AllowPrerelease -eq $False){
            Install-Module -Name $ModuleName -Force
        } Else {
            Install-Module -Name $ModuleName -AllowPrerelease -Force
        }
        
    }
}

Function Test-PsModule(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$ModuleName,
        [Parameter(Position=1,mandatory=$false)][String]$Version = "Latest",
        [Parameter(Position=2,mandatory=$false)][bool]$AllowPrerelease = $False
    )

    $LocalVersion = Get-InstalledPsModule -ModuleName $ModuleName
    $GalleryVersion = Get-GalleryPSModule -ModuleName $ModuleName -AllowPrerelease $AllowPrerelease
    
    Write-Host "Module" $ModuleName": " -NoNewline

    If($Null -ne $LocalVersion){
        If($null -ne $GalleryVersion){
            If($Version -eq "Latest"){
                If($LocalVersion -ne $GalleryVersion){
                    Write-Host "version" $LocalVersion " is not up to date to the latest version" $GalleryVersion -ForegroundColor Yellow
                    Update-PsModule -ModuleName $ModuleName -AllowPrerelease $AllowPrerelease
                } Else {
                    Write-Host "running the latest version" $GalleryVersion -ForegroundColor Green
                }
            } ElseIf($Version -eq "None"){
                Write-Host "module not required anymore, removing" -ForegroundColor Yellow
                Uninstall-Module -Name $ModuleName -AllVersions -Force
            } Else {
                If($LocalVersion -ne $Version){
                    Write-Host "version" $LocalVersion "is not  the desired version" $Version -ForegroundColor Yellow
                    Update-PsModule -ModuleName $ModuleName -AllowPrerelease $AllowPrerelease -RequiredVersion $Version
                } Else {
                    Write-Host "running the desired version" $Version -ForegroundColor Green
                }
            }
        } Else {
            Write-Host "could not be found in the PowerShell gallery!" -ForegroundColor Red
        }
    } Else {
        If($Version -eq "Latest"){
            If($AllowPrerelease -eq $False){
                Write-Host "not installed, deploying Module Version:" $Version -ForegroundColor Yellow
                Install-Module -Name $ModuleName -Force
            } Else {
                Write-Host "not installed, deploying Prerelease Module Version" -ForegroundColor Yellow
                Install-Module -Name $ModuleName -AllowPrerelease -Force
            }
        } ElseIf($Version -eq "None"){
            Write-Host "Module not required" -ForegroundColor Green
        } Else {
            If($AllowPrerelease -eq $False){
                Write-Host "not installed, deploying Module Version:" $Version -ForegroundColor Yellow
                Install-Module -Name $ModuleName -RequiredVersion $Version -Force
            } Else {
                Write-Host "not installed, deploying Prerelease Module Version:" $Version -ForegroundColor Yellow
                Install-Module -Name $ModuleName -RequiredVersion $Version -AllowPrerelease -Force
            }
        }
    }
}

$JSON = Get-Content -Path $JSONFile | ConvertFrom-JSON
ForEach($Module in $JSON.PsModules){
    [bool]$AllowPrerelease = $False
    If($Module.AllowPrerelease -eq $True){
        $AllowPrerelease = $True
    }
    Test-PsModule -ModuleName $Module.Name -Version $Module.Version -AllowPrerelease $AllowPrerelease
}