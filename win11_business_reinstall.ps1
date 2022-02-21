# iex ((New-Object System.Net.WebClient).DownloadString('iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))'))
Write-Host "Windows 11"

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$CurrentUserName = $CurrentUser.split("\")[1]

Install-Module -Name BurntToast -Force
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

Write-Host "Installing Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install chocolatey-core.extension
choco feature enable --name=allowGlobalConfirmation
choco feature enable -n=useRememberedArgumentsForUpgrades
Write-Host "Done"

Write-Host "Installing gsudo"
choco install gsudo
Write-Host "Done"

Write-Host "Installing Notepad++"
choco install notepadplusplus.install
Write-Host "Done"

Write-Host "Installing Image Resizer for Windows"
choco install imageresizerapp
Write-Host "Done"

Write-Host "Installing EPOS Connect"
choco install epos-connect
Remove-Item "C:\Users\Public\Desktop\EPOS Connect.lnk"
Stop-Process -Name epos-connect
Write-Host "Done"

Write-Host "Installing File Converter"
choco install file-converter
Write-Host "Done"

Write-Host "Installing GitHub Desktop"
choco install github-desktop
Remove-Item "C:\Users\$CurrentUserName\Desktop\GitHub Desktop.lnk"
Stop-Process -Name GitHubDesktop
choco pin add -n=github-desktop
Write-Host "Done"

Write-Host "Settings Windows Termial"
New-Item -Path "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -ItemType directory -Force | Out-Null
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/Config%20Files/Windows%20Terminal/settings.json" -Destination "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
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

New-BurntToastNotification -Text "Installation abgeschlossen", 'Die Installationen der Anwendungen wurden erfolgreich abgeschlossen'
