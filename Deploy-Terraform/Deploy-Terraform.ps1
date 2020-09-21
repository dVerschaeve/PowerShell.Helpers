
[cmdletbinding(
    DefaultParameterSetName='Manual'
)]
param (
    [Parameter(Position=0,ParameterSetName='Manual',HelpMessage="Installation forlder for Terraform")][String]$InstallFolder = "C:\Terraform"
)

function Get-TerraformLatest {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
  
    $url = "https://www.terraform.io/downloads.html"
    try {
        # Downloading the Terraform downloads page for analisys
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
    }
    catch {
        Throw "Failed to connect to ODT: $url with error $_."
        Break
    }
    finally {
        # Check if the Windows X64 executable is listed on the Links section of the page
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*windows_amd64*"}
        Write-Output $ODTUri.href
    }
  }

Function Install-Terraform(){
    $TerraformURL = Get-TerraformLatest
    $TerraformZIP = Join-Path $InstallFolder "Terraform.zip"
    Write-Host "Downloading Terraform.zip from " $TerraformURL -ForegroundColor Yellow
    # Download the Terraform ZIP file
    Invoke-WebRequest -Uri $TerraformURL -OutFile $TerraformZIP
    
    # Extract the Terraform ZIP file
    Write-host "Extracting terraform.zip towards " $InstallFolder -ForegroundColor Yellow
    Expand-Archive -LiteralPath $TerraformZIP -DestinationPath $InstallFolder -Force

    # Removing the downloaded ZIP file
    Write-Host "Cleaning up" -ForegroundColor Yellow
    Remove-Item -path $TerraformZIP -Force -Confirm:$False
}

Function Update-Terraform(){
    $Version = . $TerraformFileName `-version
    write-host $Version
    If($version -like "*Your version of terraform is out of date!*"){
        # Update is required as Terraform reports it's out of date
        write-host "Update Required" -ForegroundColor Yellow
        Install-Terraform
    } Else {
        # Nothing to do
        Write-Host "Up to date" -ForegroundColor Green
    }
}
  
Function Main(){
    Write-Host "Installation directory" $InstallFolder": " -NoNewline 
    If((Test-Path $InstallFolder) -eq $False){
        Try{
            # Create the Terraform directory as it does not exist
            New-Item -ItemType Directory -Path $InstallFolder -Force | Out-Null
            Write-Host -ForegroundColor Green "OK"
        } Catch{
            # Error occured creating the directory, unable to continue
            Write-host "Unable to create installation directory!" -ForegroundColor Red
            Break
        }
    } Else {
        Write-Host -ForegroundColor Green "OK"
    }

    $TerraformFileName = Join-Path $InstallFolder "Terraform.exe"

    Write-Host "Terraform Executable: " -NoNewline
    If((Test-Path $TerraformFileName) -eq $False){
        # Terraform is not installed
        Write-Host "Not installed" -ForegroundColor Red
        Install-Terraform
    } Else {
        # Terraform executable was found, check if update is required
        Update-Terraform
    }

    # To have access to Terraform.exe, the installation folder is added into the user environmental variables
    Write-Host "Terraform directory located in environmental variables: " -NoNewline
    $SearchFilter = "*{0}*" -f $InstallFolder
    If($Env:Path -Like $SearchFilter){
        Write-Host "OK" -ForegroundColor Green
    } Else {
        Write-Host "NOK" -ForegroundColor Red
        Write-Host "Adding" $InstallFolder "to environmental variables" -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("Path", $env:Path + (";{0}" -f $InstallFolder), "User")
    }
}; Main
