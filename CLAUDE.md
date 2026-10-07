# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

Ein einzelnes PowerShell-Skript, [win11_reinstall_privat.ps1](win11_reinstall_privat.ps1), das auf einem frischen Windows-10/11-Client Anwendungen ausschliesslich ueber winget installiert. Es wird per `iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall_privat.ps1'))` direkt von GitHub (`main`) aufgerufen. Dateiname und Pfad duerfen sich deshalb nicht aendern. Es gibt keinen Build, keine Tests und keinen Linter.

Zusaetzlich gibt es [win11_reinstall_business.ps1](win11_reinstall_business.ps1) fuer den Business-PC (lokaler Admin): gleiche Struktur und Funktionen wie oben (Kopie, nicht geteilt), aber nur PowerShell, GitHub Desktop, VS Code und Copilot; kein `winget upgrade --all`, kein Desktop-Aufraeumen; Taskleiste in fester Reihenfolge ohne Explorer (Terminal, Claude, Copilot, VS Code, GitHub Desktop, Edge, OneNote, Outlook, Teams; `$wanted` mit optionalem `Fixed`-Pin fuer Edge); Log `C:\Temp\win11_reinstall_business_<Zeitstempel>.log`. Aenderungen an gemeinsamen Funktionen muessen in beiden Skripten erfolgen. Gleiche Konventionen (BOM, CRLF, `-DryRun`).

## Befehle

```powershell
# Syntaxpruefung
$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('win11_reinstall_privat.ps1',[ref]$null,[ref]$e); $e.Count

# Sicherer Testlauf: loest IDs auf und prueft den Installationsstatus, installiert/loescht/aendert nichts
powershell -NoProfile -ExecutionPolicy Bypass -File .\win11_reinstall_privat.ps1 -DryRun

# Echter Lauf (Administrator)
powershell -ExecutionPolicy Bypass -File .\win11_reinstall_privat.ps1
```

Ein echter Lauf loescht Desktop-Verknuepfungen und setzt die Taskleiste zurueck (siehe unten). Zum Testen immer `-DryRun` verwenden. Log: `C:\Temp\win11_reinstall_privat_<Zeitstempel>.log`. Exit-Codes: 0 ok, 1 App fehlgeschlagen, 2 kein Windows-Client, 3 winget fehlt, 4 unerwarteter Fehler, 5 UAC abgelehnt.

## Architektur

Ablauf in `Main`: OS-Pruefung (`Win32_OperatingSystem.ProductType -eq 1`, sonst Exit 2) -> Admin-Pruefung -> winget-Pruefung -> pro App `Install-WingetApp` -> `Update-WingetPackages` -> `New-WorkFolders` -> `Set-QuickAccess` -> `Set-ExplorerRecentSettings` -> `Remove-DesktopShortcuts` -> `Set-DesktopWallpaper` -> `Set-TaskbarPins` -> `Write-Summary`.

- **Selbst-Elevation:** Ohne Adminrechte startet `Restart-AsAdministrator` das Skript per `Start-Process -Verb RunAs` neu und gibt den Exit-Code des Kindprozesses zurueck (nicht bei `-DryRun`). Bei `iex`-Aufruf gibt es keinen `$PSCommandPath`, dann laedt das Kind das Skript ueber `$ScriptUrl` erneut von GitHub. Das Kindfenster setzt `WIN11_REINSTALL_PAUSE=1` und bleibt am Ende per `Read-Host` offen. Nicht testbar ohne echten Lauf: ein Test fuehrt die Installation wirklich aus.
- **Ordner/Schnellzugriff:** `$WorkFolders` (`C:\Temp`, `C:\GitHub`) wird von `New-WorkFolders` angelegt und von `Set-QuickAccess` per `Shell.Application` (Namespace `shell:::{679f85cb-...}`) an den Schnellzugriff geheftet (`pintohome`); Dokumente/Bilder/Musik/Videos werden ueber das lokalisierte Kontextmenue-Verb "Von Schnellzugriff loesen" entfernt. Wichtig: `Items()` unter Windows PowerShell 5.1 nur **einmal** aufzaehlen und das Ergebnis zwischenspeichern, ein zweiter Aufruf liefert eine leere Liste.
- **Explorer-Vorschläge:** `Set-ExplorerRecentSettings` setzt unter `HKCU:\...\Explorer` die DWORDs `ShowRecent`, `ShowFrequent` und `ShowCloudFilesInQuickAccess` auf 0 (wirkt für neu geöffnete Explorer-Fenster).
- **Hintergrundbild:** `Set-DesktopWallpaper` lädt `Wallpaper/wallpaper.jpg` über `$WallpaperUrl` (raw.githubusercontent.com, `main`) nach `%USERPROFILE%\Pictures\wallpaper.jpg` und setzt es per `SystemParametersInfo` (P/Invoke über `Add-Type`). Das Bild muss im Repo auf `main` liegen, sonst gibt es nur eine Warnung. Dateiname/Pfad dürfen sich nicht ändern, ohne `$WallpaperUrl` anzupassen.
- **Updates:** `Update-WingetPackages` fuehrt `winget upgrade --all` aus; Fehler sind nur Warnungen (kein Exit-Code 1).

- **App-Liste:** Das Array `$Applications` (oben im Skript) ist die einzige Stelle, an der Apps hinzugefuegt oder entfernt werden. Pflichtfelder: `Name`, `SearchTerm`, `IdPattern`. Optional: `Source` (Standard `winget`, `msstore` fuer Store-Apps), `FixedId` (feste ID, wird nur per `winget search --id --exact` geprueft), `StopProcess` (ein Prozessname oder ein Array davon, wird nach der Installation beendet, wenn der Installer die App selbst startet, z. B. Plex, Discord, Copilot mit `mscopilot_proxy` + `mscopilot`; `Stop-AutoLaunchedProcess` beobachtet bis zu 40 s und beendet alles Gefundene, bis 8 s Ruhe herrscht), `RemoveAutostart` (Wildcard-Muster fuer Wertnamen unter `...\CurrentVersion\Run` in HKCU/HKLM; `Remove-AppAutostart` loescht sie nach den Updates, z. B. `MicrosoftCopilotAutoLaunch*`, das Copilot mit `--no-startup-window --win-session-start` bei jeder Anmeldung startet). Optionale Felder werden danach per `Add-Member` mit Standardwerten ergaenzt, weil `Set-StrictMode -Version Latest` aktiv ist.
- **ID-Aufloesung:** `Resolve-WingetId` fuehrt `winget search` aus und prueft **jedes Wort** der Ergebniszeilen gegen `IdPattern`. Spaltentrennung per Leerzeichen funktioniert nicht, weil winget bei einem einzelnen Treffer nur ein Leerzeichen zwischen den Spalten ausgibt. `IdPattern` verhindert falsche Treffer (z. B. `LocalSend.LocalSend.CLI`).
- **Idempotenz:** `Test-AppInstalled` nutzt `winget list --id --exact`. Winget-Exit-Codes fuer "bereits installiert" und "Neustart erforderlich" stehen in `$WingetAlreadyInstalled` / `$WingetRebootRequired`.
- **Taskleiste:** `Set-TaskbarPins` schreibt `%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.xml` mit `PinListPlacement="Replace"` (Explorer, Edge, Terminal, Claude, Copilot, GitHub Desktop, WhatsApp, Telegram; Reihenfolge = Reihenfolge in `$wanted`), loescht danach `HKCU:\...\Explorer\Taskband` und beendet den Explorer. Windows startet die Shell selbst neu; das Skript wartet darauf und startet `explorer.exe` **nie** aus dem erhoehten Prozess (sonst liefe die Shell als Administrator und alle daraus gestarteten Apps auch), im Notfall nur ueber `runas /trustlevel:0x20000`. Danach prueft `Test-ExplorerElevated` (P/Invoke `GetTokenInformation`/TokenElevation), ob der neue Explorer erhoeht laeuft, startet ihn ggf. bis zu zweimal neu und loggt das Ergebnis. Die Terminal-/GitHub-/Claude-IDs werden zur Laufzeit per `Get-StartApps` ermittelt (Store-Apps haben ein `!` in der AppUserModelID -> `taskbar:UWA`, sonst `taskbar:DesktopApp`). Fuer andere Apps in der Taskleiste das Array `$wanted` bzw. die festen Pins anpassen.
- **Desktop:** `Remove-DesktopShortcuts` loescht nur `.lnk`/`.url` auf dem Benutzer- und dem Public-Desktop, keine anderen Dateien.
- `-DryRun` wird in `Install-WingetApp`, `Remove-DesktopShortcuts` und `Set-TaskbarPins` beachtet. Neue Funktionen mit Seiteneffekten muessen das ebenfalls tun.

## Konventionen

- Das Skript soll unter Windows PowerShell 5.1 laufen. Meldungen, Kommentare und Hilfetexte verwenden **echte deutsche Umlaute** (ä, ö, ü, ß), keine Umschreibungen.
- Die Skriptdatei muss **UTF-8 mit BOM** bleiben, sonst liest Windows PowerShell 5.1 sie bei `-File` als ANSI und die Umlaute sind kaputt. Der `iex`-Aufruf ist davon nicht betroffen, weil `WebClient.DownloadString` das BOM entfernt. Beim Bearbeiten per Skript `utf-8-sig` verwenden.
- Die Datei hat CRLF-Zeilenenden. Beim Bearbeiten ueber Skripte `newline=''` verwenden, um sie nicht zu veraendern.
- Die Eintraege in `$Applications` sind mit **Tabulatoren** (Tabbreite 4) in Spalten ausgerichtet. Beim Hinzufuegen einer App die Spalten wieder ausrichten.
- `README.md`: Der direkte Aufruf-Link und das YouTube-Video muessen unveraendert bleiben. Die Anwendungsliste dort muss mit `$Applications` uebereinstimmen, ebenso die Beschreibung des Ablaufs.
- **Niemals `git commit` oder `git push` ausfuehren und nicht danach fragen.** Der Nutzer committet selbst.
