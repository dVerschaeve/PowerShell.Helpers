$DownloadFolder = "$HOME\Downloads"

Function Enter-Process(){
	[CmdletBinding()]
    param(
        [Parameter(Position=0,mandatory=$true)]$Path,
        [Parameter(Position=1,mandatory=$true)][String]$Parameters
    )

	If(Test-Path $Path){
		#Execute process with param
		Write-Host ("Starting {0} {1}" -f $Path, $Paramters )
		$psi = new-object diagnostics.processstartinfo
		$psi.filename = $Path
		$psi.RedirectStandardInput = $false
		$psi.RedirectStandardOutput = $false
		$psi.UseShellExecute = $false
		$psi.Arguments = $Parameters
		$Process = [System.Diagnostics.Process]::Start($psi)
		$Process.WaitForExit()
		
	} Else {
		Throw("File not found! {0}" -f $Path)
	}
}

Function Get-GitLatest {
    [CmdletBinding()]
    [OutputType([string])]
    param ()
  
    $url = "https://git-scm.com/download/win"
    try {
        # Downloading the Terraform downloads page for analisys
        $response = Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction SilentlyContinue
        #$response.links
    }
    catch {
        Throw "Failed to connect to ODT: $url with error $_."
        Break
    }
    finally {
        # Check if the Windows X64 executable is listed on the Links section of the page
        $ODTUri = $response.links | Where-Object {$_.outerHTML -like "*64-bit Git for Windows Setup*"}
        Write-Output $ODTUri.href
    }
  }

Function Test-IsGitInstalled() {
    $32BitPrograms = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
    $64BitPrograms = Get-ItemProperty     HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    $programsWithGitInName = ($32BitPrograms + $64BitPrograms) | Where-Object { $null -ne $_.DisplayName -and $_.Displayname.Contains('Git') }
    $isGitInstalled = $null -ne $programsWithGitInName
    return $isGitInstalled
}

  Function Install-Git(){
    $GitURL = Get-GitLatest
    $FileName = $GitURL.split("/")[$GitURL.SPlit("/").count - 1]
    $GitEXE = Join-Path $DownloadFolder $FileName
    
    Write-Host "Downloading" $FileName "from" $GitURL -ForegroundColor Yellow
    # Download the Git Executable
    Invoke-WebRequest -Uri $GitURL -OutFile $GitEXE

    #Installing GIT
    Enter-Process -Path $GitEXE -Parameters "/SILENT"
}

Function Get-GitVersion(){
  $GitVersion = $Null
    $GitInstalled = Test-IsGitInstalled
    If($GitInstalled){
        Write-Host "GIT installed, checking version: " -NoNewline
        $GitOutput = Git --version
        $GitVersion = $GitOutput.replace("git version ", "")
        Write-host $GitVersion -ForegroundColor Yellow
    }  

    Return $GitVersion
}


Function Main(){
    $GitLocalVersion = Get-GitVersion
    $GitLatestVersionURL = Get-GitLatest
    $GitLatestVersion = $GitLatestVersionURL.split("/")[$GitLatestVersionURL.SPlit("/").count - 2]
    Write-Host "Latest GIT Version:" -NoNewLine
    Write-Host $GitLatestVersion -ForegroundColor Yellow
    
    If($GitLocalVersion -ne $GitLatestVersion.replace("v","")){
        Write-Host "A newer verion is available, updating GIT towards latest version" -ForegroundColor Red
        Install-Git
    } Else {
        Write-Host "GIT up to date" -ForegroundColor Green
    }
    
}; Main

