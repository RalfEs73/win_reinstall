# iex ((New-Object System.Net.WebClient).DownloadString('iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))'))
Write-Host "Windows 11"

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$CurrentUserName = $CurrentUser.split("\")[1]

Install-Module -Name BurntToast -Force
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force


Write-Host "Installing 2fast - Two Factor Authenticator"
Winget install 9P9D81GLH89Q --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Translatium"
Winget install 9MWPG56JKS38 --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Screenbits"
Winget install 9P65DCKJFTJ3 --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Microsoft Whiteboard"
Winget install 9MSPC6MP8FM4 --accept-package-agreements
Write-Host "Done"

Write-Host "Installing FileBot"
Winget install 9NBLGGH52T9X --accept-package-agreements
Write-Host "Done"

Write-Host "Installing File Converter"
choco install file-converter
Write-Host "Done"

Write-Host "Install WhatsApp"
winget install 9NKSQGP7F2NH --accept-package-agreements
Write-Host "Done"

$Logfiles = @(
    "C:\ProgramData\chocolatey\logs\chocolatey.log"
    "C:\ProgramData\chocolatey\logs\choco.summary.log"
    )

Write-Host "Del Logfiles"
foreach ($Log in $Logfiles) {
    If (Test-Path $Log) {
        Write-Host $Log
        Remove-Item $Log
        }
    }

Start-Sleep -Seconds 5
New-BurntToastNotification -Text "Installation abgeschlossen", 'Die Installationen der Anwendungen wurden erfolgreich abgeschlossen'
