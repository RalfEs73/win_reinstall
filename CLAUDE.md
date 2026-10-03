# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

Ein einzelnes PowerShell-Skript, [win11_reinstall.ps1](win11_reinstall.ps1), das auf einem frischen Windows-10/11-Client Anwendungen ausschliesslich ueber winget installiert. Es wird per `iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall.ps1'))` direkt von GitHub (`main`) aufgerufen. Dateiname und Pfad duerfen sich deshalb nicht aendern. Es gibt keinen Build, keine Tests und keinen Linter.

## Befehle

```powershell
# Syntaxpruefung
$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile('win11_reinstall.ps1',[ref]$null,[ref]$e); $e.Count

# Sicherer Testlauf: loest IDs auf und prueft den Installationsstatus, installiert/loescht/aendert nichts
powershell -NoProfile -ExecutionPolicy Bypass -File .\win11_reinstall.ps1 -DryRun

# Echter Lauf (Administrator)
powershell -ExecutionPolicy Bypass -File .\win11_reinstall.ps1
```

Ein echter Lauf loescht Desktop-Verknuepfungen und setzt die Taskleiste zurueck (siehe unten). Zum Testen immer `-DryRun` verwenden. Log: `C:\Temp\win11_reinstall_<Zeitstempel>.log`. Exit-Codes: 0 ok, 1 App fehlgeschlagen, 2 kein Windows-Client, 3 winget fehlt, 4 unerwarteter Fehler.

## Architektur

Ablauf in `Main`: OS-Pruefung (`Win32_OperatingSystem.ProductType -eq 1`, sonst Exit 2) -> winget-Pruefung -> pro App `Install-WingetApp` -> `Remove-DesktopShortcuts` -> `Set-TaskbarPins` -> `Write-Summary`.

- **App-Liste:** Das Array `$Applications` (oben im Skript) ist die einzige Stelle, an der Apps hinzugefuegt oder entfernt werden. Pflichtfelder: `Name`, `SearchTerm`, `IdPattern`. Optional: `Source` (Standard `winget`, `msstore` fuer Store-Apps), `FixedId` (feste ID, wird nur per `winget search --id --exact` geprueft), `StopProcess` (Prozess, der nach der Installation beendet wird, wenn der Installer die App selbst startet, z. B. Plex, Discord). Optionale Felder werden danach per `Add-Member` mit Standardwerten ergaenzt, weil `Set-StrictMode -Version Latest` aktiv ist.
- **ID-Aufloesung:** `Resolve-WingetId` fuehrt `winget search` aus und prueft **jedes Wort** der Ergebniszeilen gegen `IdPattern`. Spaltentrennung per Leerzeichen funktioniert nicht, weil winget bei einem einzelnen Treffer nur ein Leerzeichen zwischen den Spalten ausgibt. `IdPattern` verhindert falsche Treffer (z. B. `LocalSend.LocalSend.CLI`).
- **Idempotenz:** `Test-AppInstalled` nutzt `winget list --id --exact`. Winget-Exit-Codes fuer "bereits installiert" und "Neustart erforderlich" stehen in `$WingetAlreadyInstalled` / `$WingetRebootRequired`.
- **Taskleiste:** `Set-TaskbarPins` schreibt `%LOCALAPPDATA%\Microsoft\Windows\Shell\LayoutModification.xml` mit `PinListPlacement="Replace"` (Explorer, Edge, Terminal, GitHub Desktop, Claude), loescht danach `HKCU:\...\Explorer\Taskband` und startet den Explorer neu. Die Terminal-/GitHub-/Claude-IDs werden zur Laufzeit per `Get-StartApps` ermittelt (Store-Apps haben ein `!` in der AppUserModelID -> `taskbar:UWA`, sonst `taskbar:DesktopApp`). Fuer andere Apps in der Taskleiste das Array `$wanted` bzw. die festen Pins anpassen.
- **Desktop:** `Remove-DesktopShortcuts` loescht nur `.lnk`/`.url` auf dem Benutzer- und dem Public-Desktop, keine anderen Dateien.
- `-DryRun` wird in `Install-WingetApp`, `Remove-DesktopShortcuts` und `Set-TaskbarPins` beachtet. Neue Funktionen mit Seiteneffekten muessen das ebenfalls tun.

## Konventionen

- Das Skript soll unter Windows PowerShell 5.1 laufen. Log- und Konsolenmeldungen bewusst ASCII (ae/oe/ue statt Umlaute), weil die Datei BOM-los UTF-8 ist.
- Die Datei hat CRLF-Zeilenenden. Beim Bearbeiten ueber Skripte `newline=''` verwenden, um sie nicht zu veraendern.
- Die Eintraege in `$Applications` sind mit **Tabulatoren** (Tabbreite 4) in Spalten ausgerichtet. Beim Hinzufuegen einer App die Spalten wieder ausrichten.
- `README.md`: Der direkte Aufruf-Link und das YouTube-Video muessen unveraendert bleiben. Die Anwendungsliste dort muss mit `$Applications` uebereinstimmen, ebenso die Beschreibung des Ablaufs.
- **Niemals `git commit` oder `git push` ausfuehren und nicht danach fragen.** Der Nutzer committet selbst.
