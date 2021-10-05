[![LinkedIn][linkedin-shield]][linkedin-url]

[![Flattr this git repo](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=ralfes&url=https://github.com/ralfes/Windows10Install&title=Windows10Install&language=&tags=github&category=software) 



# Windows 10 (Re-)Installation Script
Dieses Script installiert die von mir gewünschten Anwendungen auf einem Windows 10 PC.

[![Youtube](https://img.youtube.com/vi/qpW2zixWoRk/0.jpg)](https://www.youtube.com/watch?v=qpW2zixWoRk)


## Aufruf
Mit PowerShell (und Adminrechten) den folgenden Befehl starten:
Windows 11
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))
```
Windows 10
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win10_reinstall.ps1'))
```


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
* CandyCrush App

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/ralfes
