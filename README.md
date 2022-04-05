[![LinkedIn][linkedin-shield]][linkedin-url]

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=ralfes&url=https://github.com/ralfes/Windows10Install&title=Windows10Install&language=&tags=github&category=software) 



# Windows (Re-)Installation Script
Dieses Script installiert die von mir gewünschten Anwendungen auf einem Windows PC.

[![Youtube](https://img.youtube.com/vi/qpW2zixWoRk/0.jpg)](https://www.youtube.com/watch?v=qpW2zixWoRk)


## Aufruf
Mit PowerShell (und Adminrechten) den folgenden Befehl starten:
### Windows 11
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))
```
### Windows 10
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win10_reinstall.ps1'))
```
### Windows 11 (Business)
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_business_reinstall.ps1'))
```

# Windows 11
## Die folgenden Anwendungen werden installiert:
* Chocolatey Core
* WinRAR (nicht bei Business)
* gsudo
* ChocoUpdateNotifier
* Notepad++
* 4K Video Downloader (nicht bei Business)
* Image Resizer for Windows
* EPOS Connect
* Jabra Direct
* Stream Deck
* Plex (nicht bei Business)
* VLC (nicht bei Business)
* AnyStream (nicht bei Business)
* File Converter (nicht bei Business)
* WinSCP (nicht bei Business)
* WhatsApp (nicht bei Business)
* Telegram (nicht bei Business)
* Discord (nicht bei Business)
* HandBrake (nicht bei Business)
* GitHub Desktop
* Exodus Wallet (nicht bei Business)
* Ledger Live Wallet (nicht bei Business)
* Thumbico
* Film Info! Organiser (nicht bei Business)

## Settings
* Windows Termial

## Die folgenden Anwendungen werden deinstalliert:
* -

# Windows 10
## Die folgenden Anwendungen werden installiert:
* Chocolatey Core
* Edge (Chromium)
* WinRAR
* gsudo
* ChocoUpdateNotifier
* Windows Terminal
* GeForce Experience
* WinSCP
* Notepad++
* 4K Video Downloader
* Image Resizer for Windows
* VLC
* Plex
* AnyDVD
* AnyStream
* File Converter
* HandBrake
* GitHub Desktop
* Telegram
* WhatsApp
* Discord
* Gitter
* Epic Games Launcher
* Steam
* Uplay (Ubisoft Connect)
* Amazon Games
* Streamlabs OBS
* Spotify
* Driver Booster
* Exodus Wallet
* Ledger Live Wallet
* Thumbico
* Movavi Video Editor Plus
* Film Info! Organiser

## Die folgenden Anwendungen werden deinstalliert:
* -

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/ralfes
