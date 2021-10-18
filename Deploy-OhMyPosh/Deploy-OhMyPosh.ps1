
$PackageName = "JanDeDobbeleer.OhMyPosh"
$NerdFontURI = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip"
$ScriptFolder = Split-Path $MyInvocation.MyCommand.Path
$TempFolder = Join-path $ScriptFolder "TMP"
$FontFolder = Join-Path $env:USERPROFILE "\AppData\Local\Microsoft\Windows\Fonts"


Function Main(){

    # $WingetPackage = Winget list --accept-source-agreements --id $PackageName
    # If($WingetPackage -Match "No installed package found matching input criteria."){
    #     Write-Host "Deploying $PackageName" -ForegroundColor Yellow
    #     Winget Install $PackageName --silent
    # } Else {
    #     Write-Host "Package $PackageName already installed" -ForegroundColor Green
    # }


    Write-Host "Downloading Nerdfont"
    New-Item -ItemType Directory -path $TempFolder -Force | Out-Null
    $FontFile = Join-Path $TempFolder (Split-Path $NerdFontURI -Leaf)
    Invoke-WebRequest -Uri $NerdFontURI -OutFile $FontFile
    Expand-Archive -LiteralPath $FontFile -DestinationPath $TempFolder -Force

    $FontShellFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)

    $FontFiles = Get-ChildItem -Path $TempFolder -Filter *.ttf
    ForEach($File in $FontFiles){
        If(-Not(Test-Path (Join-Path $FontFolder $File.Name))){
            Write-Host ("Install Font '{0}'" -f $File.name)
            $FontShellFolder.CopyHere($File.Fullname,0x10)
        } Else {
            Write-Host("Font '{0}' already installed" -f $File.Name)
        }
    }

    Remove-item -Path $TempFolder -Recurse -Confirm:$False -Force
} ; Main