# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win10_reinstall/master/win10_reinstall.ps1'))

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$CurrentUserName = $CurrentUser.split("\")[1]

Install-PackageProvider -Name NuGet -Force
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

Write-Host "Installing Edge (Chromium)"
choco install microsoft-edge
choco pin add -n=microsoft-edge
Remove-Item "C:\Users\Public\Desktop\Microsoft Edge.lnk"
Write-Host "Done"

Write-Host "Installing WinRAR"
choco install winrar
Write-Host "Done"

Write-Host "Installing gsudo"
choco install gsudo
Write-Host "Done"

Write-Host "Installing Windows Termial"
choco install microsoft-windows-terminal
New-Item -Path "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState" -ItemType directory -Force | Out-Null
Start-BitsTransfer -Source "https://github.com/RalfEs73/win10_reinstall/raw/master/Config%20Files/Windows%20Terminal/settings.json" -Destination "C:\Users\$CurrentUserName\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
Write-Host "Done"

Write-Host "Installing GeForce Experience"
choco install geforce-experience
Write-Host "Done"

Write-Host "Installing WinSCP"
choco install winscp.install
Remove-Item "C:\Users\Public\Desktop\WinSCP.lnk"
Write-Host "Done"

Write-Host "Installing Notepad++"
choco install notepadplusplus.install
Write-Host "Done"

Write-Host "Installing 4K Video Downloader"
choco install 4k-video-downloader
Remove-Item "C:\Users\Public\Desktop\4K Video Downloader.lnk"
Write-Host "Done"

Write-Host "Installing Image Resizer for Windows"
choco install imageresizerapp
Write-Host "Done"

Write-Host "Installing VLC"
choco install vlc
Remove-Item "C:\Users\Public\Desktop\VLC media player.lnk"
Write-Host "Done"

Write-Host "Installing Plex"
choco install plex
Write-Host "Done"

Write-Host "Installing AnyDVD"
choco install anydvd
Remove-Item "C:\Users\Public\Desktop\AnyDVD.lnk"
Write-Host "Done"

Write-Host "Installing AnyStream"
choco install anystream
Remove-Item "C:\Users\Public\Desktop\AnyStream.lnk"
Write-Host "Done"

Write-Host "Installing File Converter"
choco install file-converter
Write-Host "Done"

Write-Host "Installing HandBrake"
choco install handbrake.install
Remove-Item "C:\Users\Public\Desktop\Handbrake.lnk"
Write-Host "Done"

Write-Host "Installing GitHub Desktop"
choco install github-desktop
choco pin add -n=github-desktop
Remove-Item "C:\Users\$CurrentUserName\Desktop\GitHub Desktop.lnk"
Stop-Process -Name GitHubDesktop
Write-Host "Done"

Write-Host "Installing Telegram"
choco install telegram.install
Remove-Item "C:\Users\$CurrentUserName\Desktop\Telegram.lnk"
Write-Host "Done"

Write-Host "Installing WhatsApp"
choco install WhatsApp
choco pin add -n=WhatsApp
Remove-Item "C:\Users\$CurrentUserName\Desktop\WhatsApp.lnk"
Write-Host "Done"

Write-Host "Installing Discord"
choco install discord.install
Remove-Item "C:\Users\$CurrentUserName\Desktop\Discord.lnk"
Write-Host "Done"

Write-Host "Installing Gitter"
choco install gitter
Write-Host "Done"

Write-Host "Installing Epic Games Launcher"
choco install epicgameslauncher
Remove-Item "C:\Users\Public\Desktop\Epic Games Launcher.lnk"
Write-Host "Done"

Write-Host "Installing Steam"
choco install steam
choco pin add -n=steam
Remove-Item "C:\Users\Public\Desktop\Steam.lnk"
Write-Host "Done"

Write-Host "Installing Uplay"
choco install uplay --ignore-checksums
Remove-Item "C:\Users\$CurrentUserName\Desktop\Ubisoft Connect.lnk"
Write-Host "Done"

Write-Host "Installing Amazon Games"
choco install amazongames
Remove-Item "C:\Users\$CurrentUserName\Desktop\Amazon Games.lnk"
Stop-Process -Name Amazon*
Write-Host "Done"

Write-Host "Installing Streamlabs OBS"
choco install streamlabs-obs
Remove-Item "C:\Users\Public\Desktop\Streamlabs OBS.lnk"
Write-Host "Done"

Write-Host "Installing Spotify"
choco install spotify --ignore-checksums
Remove-Item "C:\Users\$CurrentUserName\Desktop\Spotify.lnk"
Write-Host "Done"

Write-Host "Installing Driver Booster"
choco install driverbooster --ignore-checksums
Remove-Item "C:\Users\Public\Desktop\Driver Booster*.lnk"
Stop-Process -Name Driver*
Write-Host "Done"

Write-Host "Installing Exodus Wallet"
choco install exoduswallet
choco pin add -n=exoduswallet
Remove-Item "C:\Users\$CurrentUserName\Desktop\Exodus.lnk"
Write-Host "Done"

Write-Host "Installing Ledger Live Wallet"
choco install ledger-live
Remove-Item "C:\Users\Public\Desktop\Ledger Live.lnk"
Write-Host "Done"

Write-Host "Installing Thumbico"
choco install thumbico
Write-Host "Done"

Write-Host "Installing Movavi Video Editor Plus"
choco install movavivideoeditorplus
Remove-Item "C:\Users\$CurrentUserName\Desktop\Movavi Video Editor Plus 2021.lnk"
Write-Host "Done"

Write-Host "Installing Film Info! Organiser"
choco install film-info-organizer
Remove-Item "C:\Users\Public\Desktop\Film Info! Organizer.lnk"
New-Item -Path "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer" -ItemType directory -Force | Out-Null
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/Columns.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\Columns.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/Config.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\Config.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/Favoriten.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\Favoriten.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/Filter.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\Filter.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/Genre.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\Genre.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/Interface.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\Interface.xml"
Start-BitsTransfer -Source "https://raw.githubusercontent.com/RalfEs73/chocolatey-packages/master/film-info-organizer/settings/tmdb_config.xml" -Destination "C:\Users\$CurrentUserName\AppData\Roaming\film info! organizer\tmdb_config.xml"
Write-Host "Done"

$Logfiles = @(
    "C:\ProgramData\chocolatey\logs\chocolatey.log"
    "C:\ProgramData\chocolatey\logs\choco.summary.log"
    )

# Write-Host "Del Logfiles Test"
foreach ($Log in $Logfiles) {
    If (Test-Path $Log) {
        Write-Host $Log
        Remove-Item $Log
        }
    }

New-BurntToastNotification -Text "Installation abgeschlossen", 'Die Installationen der Anwendungen wurden erfolgreich abgeschlossen'
