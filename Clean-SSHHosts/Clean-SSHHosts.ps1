<#
.SYNOPSIS
    Quick and dirty cleanup of known_hosts ssh file. Will read the known_hosts input file under the userprofile directory and keep all entries defined in the JSON input file.
    All other entries will be purged from the file.
.DESCRIPTION
    JSON input file:
    {
        "known_hosts" : [
            {"friendly_name" : "github.com", "host" : "github.com"},
            {"friendly_name" : "Script Server", "host" : "192.168.0.1"},
        ]
    }
.EXAMPLE
    .\Clean-SSHHosts.ps1 -JSONFile .\hosts.json

.NOTES
    Author: 	Verschaeve Dries
    Version: 1.0
    Date: 	18/05/2021
#>
param (
    [Parameter(Position=0,mandatory=$false,HelpMessage="JSON Configuration FIle")]
    [ValidateScript({
        if( -Not ($_ | Test-Path) ){
            throw "JSON File does not exist."
        }
        return $true
    })]
    [System.IO.FileInfo]$JSONFile
)


$OutputFile = Join-Path $env:USERPROFILE "\.ssh\known_hosts_new"

Function Get-SSHKnownHostsFile(){
    $known_hosts = Join-Path $env:USERPROFILE "\.ssh\known_hosts"
    if(test-path $known_hosts)
    {
        return $known_hosts
    } else {
        throw("$known_hosts does not exist!")
    }
}

Function Add-KnownHost(){
    param(
        [Parameter(Position=0,mandatory=$true)][String]$HostLine
    )

    $HostLine | Add-Content -Path $OutputFile -Encoding UTF8
}

$JSON = Get-Content -Path $JSONFile | ConvertFrom-JSON
$known_hosts = Get-SSHKnownHostsFile
$known_hosts_content = Get-Content $known_hosts
ForEach($Line in $known_hosts_content){
    $ssh_host = $Line.split(" ")[0]
    if($ssh_host -like "*,*"){
        
        If($JSON.known_hosts.host.contains($ssh_host.split(",")[0])){
            write-host "Configured Host Name:" $ssh_host.split(",")[0]
            Add-KnownHost -HostLine $Line
        }
    } elseif($ssh_host -like "*|*") {
        write-host "Hashed host, keeping entry:" $ssh_host
        Add-KnownHost -HostLine $Line
    } else {
        if($JSON.known_hosts.host.contains($ssh_host)){
            write-host "Configured IP address:" $ssh_host
            Add-KnownHost -HostLine $Line
        }
    }
}

Remove-Item -Path $known_hosts -Confirm:$false
Rename-Item -Path $OutputFile -NewName "known_hosts"