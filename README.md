[![LinkedIn][linkedin-shield]][linkedin-url]



# Windows (Re-)Installation Script
Dieses Script installiert die von mir gewünschten Anwendungen auf einem Windows PC. Die Installation erfolgt ausschließlich über [winget](https://learn.microsoft.com/de-de/windows/package-manager/winget/).

[![Youtube](https://img.youtube.com/vi/qpW2zixWoRk/0.jpg)](https://www.youtube.com/watch?v=qpW2zixWoRk)


## Aufruf
Mit PowerShell (und Adminrechten) den folgenden Befehl starten:
### Windows 11
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))
```

### Lokaler Aufruf
Ist die Ausführung von Skripten gesperrt, das Skript einmalig mit umgangener Execution Policy starten (gilt nur für diesen Aufruf):
```sh
powershell -ExecutionPolicy Bypass -File .\win11_reinstall.ps1
```
Mit dem Parameter `-DryRun` werden nur die winget-IDs aufgelöst und der Installationsstatus geprüft, es wird nichts installiert oder gelöscht.

## Ablauf
1. **Systemprüfung:** Das Skript läuft nur auf Windows-Clients (Windows 10/11). Auf Windows Server bricht es sofort ab.
2. **winget-Prüfung:** Ist winget nicht verfügbar, bricht das Skript ab.
3. **Installation:** Die winget-IDs werden per `winget search` ermittelt, jede Anwendung wird einzeln installiert. Bereits installierte Anwendungen werden übersprungen, das Skript kann also mehrfach ausgeführt werden.
4. **Aufräumen:** Plex und Discord werden nach der Installation wieder beendet, falls der Installer sie automatisch startet. Anschließend werden alle Verknüpfungen (`.lnk`, `.url`) vom Desktop des aktuellen Benutzers und von „Alle Benutzer“ gelöscht.
5. **Taskleiste:** Windows Terminal, GitHub Desktop und Claude werden an die Taskleiste des aktuellen Benutzers angeheftet. Dafür wird eine `LayoutModification.xml` geschrieben, der Registry-Schlüssel `Taskband` zurückgesetzt und der Explorer neu gestartet (Explorer-Fenster werden dabei kurz geschlossen).
6. **Zusammenfassung:** Am Ende wird der Status jeder Anwendung ausgegeben.

Das Log wird nach `C:\Temp\win11_reinstall_<Zeitstempel>.log` geschrieben (das Verzeichnis wird bei Bedarf angelegt).

### Exit-Codes
| Code | Bedeutung |
|------|-----------|
| 0 | Alle Anwendungen installiert oder bereits vorhanden |
| 1 | Mindestens eine Anwendung ist fehlgeschlagen |
| 2 | Betriebssystem ist kein Windows-Client (z. B. Windows Server) |
| 3 | winget ist nicht verfügbar |
| 4 | Unerwarteter Fehler |

## Die folgenden Anwendungen werden installiert:
* Plex
* PowerShell
* Windows Terminal
* GitHub Desktop
* Visual Studio Code
* Claude Desktop
* LocalSend
* WinRAR
* Image Resizer for Windows
* EPOS Connect
* Stream Deck
* VLC
* File Converter
* WhatsApp (Microsoft Store)
* Telegram
* Discord
* HandBrake
* Steam

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/ralfes
