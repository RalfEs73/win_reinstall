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

Write-Host "Installing ChocoUpdateNotifier"
choco install choco-update-notifier
Write-Host "Done"

Write-Host "Installing PowerShell"
choco install powershell-core
Write-Host "Done"

Write-Host "Installing Windows Terminal"
choco install microsoft-windows-terminal
Write-Host "Done"

Write-Host "Installing WinRAR"
choco install winrar
Write-Host "Done"

Write-Host "Installing Notepad++"
choco install notepadplusplus.install
Write-Host "Done"

Write-Host "Nearby Share"
choco install nearby-share
Write-Host "Done"

Write-Host "Installing Image Resizer for Windows"
choco install imageresizerapp
Write-Host "Done"

Write-Host "Installing EPOS Connect"
choco install epos-connect
Remove-Item "C:\Users\Public\Desktop\EPOS Connect.lnk"
Get-Process -Name 'epos-connect' -ErrorAction SilentlyContinue | Stop-Process
Write-Host "Done"

Write-Host "Installing Stream Deck"
choco install streamdeck
Remove-Item "C:\Users\Public\Desktop\Stream Deck.lnk"
Get-Process -Name 'StreamDeck' -ErrorAction SilentlyContinue | Stop-Process
Write-Host "Done"

Write-Host "Installing VLC"
choco install vlc
Remove-Item "C:\Users\Public\Desktop\VLC media player.lnk"
Write-Host "Done"

Write-Host "Installing File Converter"
choco install file-converter
Write-Host "Done"

Write-Host "Installing WinSCP"
choco install winscp
Remove-Item "C:\Users\Public\Desktop\WinSCP.lnk"
Write-Host "Done"

Write-Host "Install Telegram"
choco install telegram
Remove-Item "C:\Users\$CurrentUserName\Desktop\Telegram.lnk"
choco pin add -n telegram
Write-Host "Done"

Write-Host "Install Discord"
choco install discord.install
Remove-Item "C:\Users\$CurrentUserName\Desktop\Discord.lnk"
choco pin add -n discord.install
Write-Host "Done"

Write-Host "Installing HandBrake"
choco install handbrake.install
Remove-Item "C:\Users\Public\Desktop\Handbrake.lnk"
Write-Host "Done"

Write-Host "Installing GitHub Desktop"
choco install github-desktop
Remove-Item "C:\Users\$CurrentUserName\Desktop\GitHub Desktop.lnk"
Get-Process -Name 'GitHubDesktop' -ErrorAction SilentlyContinue | Stop-Process
choco pin add -n=github-desktop
Write-Host "Done"

Write-Host "Installing Ledger Live Wallet"
choco install ledger-live
Remove-Item "C:\Users\Public\Desktop\Ledger Live.lnk"
Write-Host "Done"

Write-Host "Installing Thumbico"
choco install thumbico
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
