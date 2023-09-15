# iex ((New-Object System.Net.WebClient).DownloadString('iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_business_reinstall.ps1'))'))
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

Write-Host "Installing ChocoUpdateNotifier"
choco install choco-update-notifier
Write-Host "Done"

Write-Host "Installing Windows Terminal"
choco install microsoft-windows-terminal
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
Get-Process -Name 'epos-connect' -ErrorAction SilentlyContinue | Stop-Process
Write-Host "Done"

Write-Host "Installing Jabra Direct"
choco install jabra-direct
Write-Host "Done"

Write-Host "Installing Plex"
choco install plex
Write-Host "Done"

Write-Host "Installing Netflix"
Winget install Netflix --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Prime Video for Windows"
Winget install 9P6RC76MSMMJ --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Windows 365 Preview"
Winget install 9N1F85V9T8BN --accept-package-agreements
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

Write-Host "Installing File Converter"
choco install file-converter
Write-Host "Done"

Write-Host "Installing GitHub Desktop"
choco install github-desktop
Remove-Item "C:\Users\$CurrentUserName\Desktop\GitHub Desktop.lnk"
Get-Process -Name 'GitHubDesktop' -ErrorAction SilentlyContinue | Stop-Process
choco pin add -n=github-desktop
Write-Host "Done"

Write-Host "Settings Windows Termial"
New-Item -Path "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -ItemType directory -Force | Out-Null
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/Config%20Files/Windows%20Terminal/settings.json" -Destination "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Write-Host "Done"

Set-Location -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\'
Get-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' | New-Item -Name 'HideDesktopIcons\NewStartPanel' –Force
New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name  '{645FF040-5081-101B-9F08-00AA002F954E}' -Value '1' -PropertyType 'DWord' –Force

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
