# iex ((New-Object System.Net.WebClient).DownloadString('iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))'))
Write-Host "Windows 11"

$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$CurrentUserName = $CurrentUser.split("\")[1]

Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
Install-Module -Name BurntToast -Force

Write-Host "Installing Chocolatey"
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install chocolatey-core.extension
choco feature enable --name=allowGlobalConfirmation
choco feature enable -n=useRememberedArgumentsForUpgrades
Write-Host "Done"

Write-Host "Installing ChocoUpdateNotifier"
choco install choco-update-notifier
Write-Host "Done"

Write-Host "Installing WinRAR"
choco install winrar
Write-Host "Done"

Write-Host "Installing gsudo"
choco install gsudo
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

Write-Host "Installing EPOS Connect"
choco install epos-connect
Write-Host "Done"

Write-Host "Installing VLC"
choco install vlc
Remove-Item "C:\Users\Public\Desktop\VLC media player.lnk"
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

Write-Host "Install Office 365"
Start-BitsTransfer -Source "https://c2rsetup.officeapps.live.com/c2r/download.aspx?productReleaseID=O365ProPlusRetail&platform=Def&language=de-de&TaxRegion=pr&correlationId=f36678f5-ea2f-4ea4-982c-d51da53726ab&token=0c526214-e487-4a88-b804-8246c73a3a4a&version=O16GA&source=O15OLSO365&Br=2" -Destination "C:\Users\$CurrentUserName\Downloads\OfficeSetup.exe"
& "C:\Users\$CurrentUserName\Downloads\OfficeSetup.exe"
Write-Host "Done"

Write-Host "Install WhatsApp"
Start-BitsTransfer -Source "https://web.whatsapp.com/desktop/windows/release/x64/WhatsAppSetup.exe" -Destination "C:\Users\$CurrentUserName\Downloads\WhatsAppSetup.exe"
Start-Process -Wait -FilePath "C:\Users\$CurrentUserName\Downloads\WhatsAppSetup.exe" -ArgumentList "--silent"
Remove-Item "C:\Users\$CurrentUserName\Desktop\WhatsApp.lnk"
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
