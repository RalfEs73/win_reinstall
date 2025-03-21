# iex ((New-Object System.Net.WebClient).DownloadString('iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))'))
Write-Host "Windows 11"

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$CurrentUserName = $CurrentUser.split("\")[1]

Install-Module -Name BurntToast -Force
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force


Write-Host "Installing PowerShell"
winget install 9MZ1SNWT0N5D --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Windows Terminal"
winget install Microsoft.WindowsTerminal --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Notepad++"
winget install Notepad++.Notepad++ --accept-package-agreements
Write-Host "Done"

Write-Host "Nearby Share"
winget install Google.QuickShare --accept-package-agreements
Write-Host "Done"

Write-Host "Plex"
winget install Plex.Plex  --accept-package-agreements
Write-Host "Done"

Write-Host "Installing Translatium"
Winget install 9MWPG56JKS38 --accept-package-agreements
Write-Host "Done"

Write-Host "Installing GitHub Desktop"
winget install GitHub.GitHubDesktop --accept-package-agreements
Remove-Item "C:\Users\$CurrentUserName\Desktop\GitHub Desktop.lnk"
Get-Process -Name 'GitHubDesktop' -ErrorAction SilentlyContinue | Stop-Process
Write-Host "Done"

Write-Host "Settings Windows Termial"
New-Item -Path "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -ItemType directory -Force | Out-Null
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/Config%20Files/Windows%20Terminal/settings.json" -Destination "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Write-Host "Done"

Set-Location -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\'
Get-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\' | New-Item -Name 'HideDesktopIcons\NewStartPanel' –Force
New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel' -Name  '{645FF040-5081-101B-9F08-00AA002F954E}' -Value '1' -PropertyType 'DWord' –Force



