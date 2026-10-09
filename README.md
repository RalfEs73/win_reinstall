[![LinkedIn][linkedin-shield]][linkedin-url]



# Windows (Re-)Installation Script
Dieses Script installiert die von mir gewünschten Anwendungen auf einem Windows PC. Die Installation erfolgt ausschließlich über [winget](https://learn.microsoft.com/de-de/windows/package-manager/winget/).

[![Youtube](https://img.youtube.com/vi/qpW2zixWoRk/0.jpg)](https://www.youtube.com/watch?v=qpW2zixWoRk)


## Aufruf
Mit PowerShell den folgenden Befehl starten (Adminrechte werden bei Bedarf automatisch per UAC angefordert):
### Windows 11 – Privat-PC
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall_privat.ps1'))
```

### Windows 11 – Business-PC
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall_business.ps1'))
```
Details siehe Abschnitt „Business-PC“ unten.

### Lokaler Aufruf
Ist die Ausführung von Skripten gesperrt, das Skript einmalig mit umgangener Execution Policy starten (gilt nur für diesen Aufruf):
```sh
powershell -ExecutionPolicy Bypass -File .\win11_reinstall_privat.ps1
```
Mit dem Parameter `-DryRun` werden nur die winget-IDs aufgelöst und der Installationsstatus geprüft, es wird nichts installiert oder gelöscht.

## Ablauf
1. **Systemprüfung:** Das Skript läuft nur auf Windows-Clients (Windows 10/11). Auf Windows Server bricht es sofort ab.
2. **Administratorrechte:** Läuft das Skript ohne Adminrechte, startet es sich selbst neu und fragt per UAC nach (nicht bei `-DryRun`). Wird die Abfrage abgelehnt, bricht es ab. Das erhöhte Fenster bleibt am Ende offen, bis Enter gedrückt wird.
3. **winget-Prüfung:** Ist winget nicht verfügbar, bricht das Skript ab.
4. **Installation:** Die winget-IDs werden per `winget search` ermittelt, jede Anwendung wird einzeln installiert. Bereits installierte Anwendungen werden übersprungen, das Skript kann also mehrfach ausgeführt werden.
5. **Updates:** Danach werden alle weiteren winget-Pakete mit `winget upgrade --all` aktualisiert. Fehler dabei erzeugen nur eine Warnung.
6. **Ordner und Schnellzugriff:** Die Ordner `C:\Temp` und `C:\GitHub` werden angelegt, falls sie fehlen. Im Datei-Explorer werden Dokumente, Bilder, Musik und Videos aus dem Schnellzugriff entfernt und die beiden Ordner angeheftet. Zusätzlich werden die Vorschläge zu zuletzt verwendeten Dateien, häufig verwendeten Ordnern und empfohlenen Cloud-Dateien im Datei-Explorer ausgeschaltet.
7. **Aufräumen:** Plex und Discord werden nach der Installation wieder beendet, falls der Installer sie automatisch startet. Der Autostart-Eintrag von Copilot (`MicrosoftCopilotAutoLaunch…`) wird entfernt, damit Copilot sich nicht bei jeder Anmeldung öffnet. Anschließend werden alle Verknüpfungen (`.lnk`, `.url`) vom Desktop des aktuellen Benutzers und von „Alle Benutzer“ gelöscht. Zusätzlich werden die Desktopsymbole Dieser PC, Benutzerdateien, Netzwerk, Papierkorb und Systemsteuerung ausgeblendet. Im Startmenü wird neben dem Netzschalter der Ordner „Einstellungen“ eingeblendet.
8. **Hintergrundbild:** Das Bild `Wallpaper/wallpaper.jpg` wird aus diesem Repository nach `Bilder\wallpaper.jpg` heruntergeladen und als Desktop-Hintergrund des aktuellen Benutzers gesetzt (Anpassung „Ausfüllen“).
9. **Taskleiste:** Die Taskleiste des aktuellen Benutzers enthält danach nur Explorer, Edge, Windows Terminal, Claude, Copilot, GitHub Desktop, WhatsApp und Telegram (in dieser Reihenfolge). Alle anderen Pins, z. B. der Microsoft Store, werden entfernt. Dafür wird eine `LayoutModification.xml` geschrieben, der Registry-Schlüssel `Taskband` zurückgesetzt und der Explorer beendet. Windows startet ihn anschließend im normalen Benutzerkontext neu (Explorer-Fenster werden dabei kurz geschlossen).
10. **Zusammenfassung:** Am Ende wird der Status jeder Anwendung ausgegeben und die Logdatei in Notepad geöffnet.

Das Log wird nach `C:\Temp\win11_reinstall_privat_<Zeitstempel>.log` geschrieben (das Verzeichnis wird bei Bedarf angelegt).

### Exit-Codes
| Code | Bedeutung |
|------|-----------|
| 0 | Alle Anwendungen installiert oder bereits vorhanden |
| 1 | Mindestens eine Anwendung ist fehlgeschlagen |
| 2 | Betriebssystem ist kein Windows-Client (z. B. Windows Server) |
| 3 | winget ist nicht verfügbar |
| 4 | Unerwarteter Fehler |
| 5 | Administratorrechte nicht erteilt (UAC abgelehnt) |

## Die folgenden Anwendungen werden installiert:
* PowerShell
* GitHub Desktop
* Visual Studio Code
* Claude Desktop
* Microsoft Copilot (Microsoft Store)
* Plex
* LocalSend
* WinRAR
* Image Resizer for Windows
* EPOS Connect
* Jabra Direct
* Stream Deck
* VLC
* FileBot
* File Converter
* WhatsApp (Microsoft Store)
* Telegram
* Discord
* HandBrake
* Steam
* NVIDIA App (Microsoft Store)

## Business-PC
Für einen Business-PC (lokaler Administrator) gibt es das schlankere Skript `win11_reinstall_business.ps1` mit demselben Prinzip (Selbst-Elevation, winget, Log, `-DryRun`):
```sh
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall_business.ps1'))
```
Es installiert PowerShell, GitHub Desktop, Visual Studio Code, Microsoft Copilot (Microsoft Store) und Poly Studio, legt `C:\Temp` und `C:\GitHub` an, passt Schnellzugriff und Explorer-Vorschläge wie oben an, setzt das Hintergrundbild und pinnt in der Taskleiste Terminal, Claude, Copilot, Visual Studio Code, GitHub Desktop, Edge, OneNote, Outlook und Teams (in dieser Reihenfolge; nicht gefundene Apps werden übersprungen). Es führt kein `winget upgrade --all` aus, löscht aber wie das private Skript alle Verknüpfungen (`.lnk`, `.url`) vom Desktop des aktuellen Benutzers und von „Alle Benutzer“ und blendet die Desktopsymbole (Dieser PC, Papierkorb usw.) aus und zeigt im Startmenü den Ordner „Einstellungen“ an. Das Log liegt unter `C:\Temp\win11_reinstall_business_<Zeitstempel>.log`.

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/ralfes
