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
### Windows 11 (Business)
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_business_reinstall.ps1'))
```
## Die folgenden Anwendungen werden installiert:
* Chocolatey Core
* WinRAR (nicht bei Business)
* gsudo
* ChocoUpdateNotifier
* Notepad++
* 4K Video Downloader (nicht bei Business)
* Image Resizer for Windows
* EPOS Connect
* Stream Deck (nicht bei Business)
* Plex
* Netflix
* VLC (nicht bei Business)
* AnyStream (nicht bei Business)
* File Converter
* WinSCP (nicht bei Business)
* WhatsApp (nicht bei Business)
* Telegram (nicht bei Business)
* microsip (nicht bei Business)
* Discord (nicht bei Business)
* HandBrake (nicht bei Business)
* GitHub Desktop
* Ledger Live Wallet (nicht bei Business)
* Thumbico (nicht bei Business)
* Film Info! Organiser (nicht bei Business)

## Settings
* Windows Termial

## Die folgenden Anwendungen werden deinstalliert:
* -

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/ralfes
