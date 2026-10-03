<#
.SYNOPSIS
    Installiert Anwendungen auf einem frischen Windows-Client ausschliesslich ueber winget.

.DESCRIPTION
    - Bricht auf Windows Server sofort ab (Exit-Code 2).
    - Prueft, ob winget verfuegbar ist (Exit-Code 3).
    - Ermittelt die winget-IDs automatisch per 'winget search'.
    - Ueberspringt bereits installierte Anwendungen (idempotent).
    - Installiert jede Anwendung einzeln, faengt Fehler ab und gibt am Ende eine Zusammenfassung aus.

.PARAMETER DryRun
    Loest IDs auf und prueft den Installationsstatus, installiert aber nichts.

.PARAMETER LogPath
    Pfad der Logdatei (Standard: C:\Temp\win11_reinstall_<Zeitstempel>.log; das Verzeichnis wird bei Bedarf angelegt).

.NOTES
    Exit-Codes:
      0 = alle Anwendungen installiert oder bereits vorhanden
      1 = mindestens eine Anwendung fehlgeschlagen
      2 = Betriebssystem ist kein Windows-Client (z. B. Windows Server)
      3 = winget nicht verfuegbar
      4 = unerwarteter Fehler
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$LogPath = (Join-Path "C:\Temp" ("win11_reinstall_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date)))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# Logverzeichnis anlegen, falls es nicht existiert
$logDir = Split-Path -Path $LogPath -Parent
if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
    try { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    catch { Write-Warning "Logverzeichnis '$logDir' konnte nicht erstellt werden: $($_.Exception.Message)" }
}

# --- Konfiguration -----------------------------------------------------------
# SearchTerm  : Suchbegriff fuer 'winget search'
# IdPattern   : Regex, den die gefundene ID erfüllen muss (Schutz vor falschen Treffern)
# Source      : (optional) winget-Quelle, Standard 'winget'; 'msstore' fuer Microsoft-Store-Apps
# FixedId     : (optional) feste ID (z. B. Store-ID); wird nur per 'winget search --id --exact' verifiziert
# StopProcess : (optional) Prozessname, der nach der Installation beendet wird, falls der Installer die App startet
$Applications = @(
    [pscustomobject]@{ Name = 'Plex';              SearchTerm = 'Plex';              IdPattern = '^Plex\.Plex$'; StopProcess = 'Plex' }
    [pscustomobject]@{ Name = 'PowerShell';        SearchTerm = 'PowerShell';        IdPattern = '^Microsoft\.PowerShell$' }
    [pscustomobject]@{ Name = 'Windows Terminal';  SearchTerm = 'Windows Terminal';  IdPattern = '^Microsoft\.WindowsTerminal$' }
    [pscustomobject]@{ Name = 'GitHub Desktop';    SearchTerm = 'GitHub Desktop';    IdPattern = '^GitHub\.GitHubDesktop$' }
    [pscustomobject]@{ Name = 'Visual Studio Code'; SearchTerm = 'Visual Studio Code'; IdPattern = '^Microsoft\.VisualStudioCode$' }
    [pscustomobject]@{ Name = 'Claude Desktop';    SearchTerm = 'Claude';            IdPattern = '^Anthropic\.Claude$' }
    [pscustomobject]@{ Name = 'LocalSend';         SearchTerm = 'LocalSend';         IdPattern = '^LocalSend\.LocalSend$' }
    [pscustomobject]@{ Name = 'WinRAR'; SearchTerm = 'WinRAR'; IdPattern = '^RARLab\.WinRAR$' }
    [pscustomobject]@{ Name = 'Image Resizer for Windows'; SearchTerm = 'Resizer for Windows'; IdPattern = '^BriceLambson\.ImageResizerforWindows$' }
    [pscustomobject]@{ Name = 'EPOS Connect'; SearchTerm = 'EPOS Connect'; IdPattern = '^EPOS\.EPOSConnect$' }
    [pscustomobject]@{ Name = 'Stream Deck'; SearchTerm = 'Stream Deck'; IdPattern = '^Elgato\.StreamDeck$' }
    [pscustomobject]@{ Name = 'VLC'; SearchTerm = 'VLC'; IdPattern = '^VideoLAN\.VLC$' }
    [pscustomobject]@{ Name = 'File Converter'; SearchTerm = 'File Converter'; IdPattern = '^AdrienAllard\.FileConverter$' }
    [pscustomobject]@{ Name = 'WhatsApp'; SearchTerm = 'WhatsApp'; IdPattern = '^9NKSQGP7F2NH$'; Source = 'msstore'; FixedId = '9NKSQGP7F2NH' }
    [pscustomobject]@{ Name = 'Telegram'; SearchTerm = 'Telegram'; IdPattern = '^Telegram\.TelegramDesktop$' }
    [pscustomobject]@{ Name = 'Discord'; SearchTerm = 'Discord'; IdPattern = '^Discord\.Discord$'; StopProcess = 'Discord' }
    [pscustomobject]@{ Name = 'HandBrake'; SearchTerm = 'HandBrake'; IdPattern = '^HandBrake\.HandBrake$' }
    [pscustomobject]@{ Name = 'Steam'; SearchTerm = 'Steam'; IdPattern = '^Valve\.Steam$' }
)

# Optionale Eigenschaften mit Standardwerten ergaenzen (StrictMode-sicher)
foreach ($app in $Applications) {
    if (-not $app.PSObject.Properties['Source'])  { $app | Add-Member -NotePropertyName Source  -NotePropertyValue 'winget' }
    if (-not $app.PSObject.Properties['FixedId']) { $app | Add-Member -NotePropertyName FixedId -NotePropertyValue $null }
}

# winget-Exit-Codes (HRESULT als Int32)
$WingetAlreadyInstalled = @(-1978335189, -1978335135)  # 0x8A15002B (kein Update), 0x8A150061 (bereits installiert)
$WingetRebootRequired   = @(3010, -1978334970, -1978334967)  # 3010, 0x8A150086, 0x8A150089

# --- Logging -----------------------------------------------------------------
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR', 'SKIP')][string]$Level = 'INFO'
    )
    $line = '{0:yyyy-MM-dd HH:mm:ss} [{1,-5}] {2}' -f (Get-Date), $Level, $Message
    $color = switch ($Level) { 'OK' { 'Green' } 'WARN' { 'Yellow' } 'ERROR' { 'Red' } 'SKIP' { 'Cyan' } default { 'Gray' } }
    Write-Host $line -ForegroundColor $color
    try { Add-Content -Path $LogPath -Value $line -Encoding UTF8 } catch { }
}

# --- Systempruefung ----------------------------------------------------------
function Test-WindowsClient {
    # ProductType: 1 = Workstation (Client), 2 = Domain Controller, 3 = Server
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $build = [int]$os.BuildNumber
    Write-Log "Betriebssystem: $($os.Caption) (Build $build, ProductType $($os.ProductType))"
    return ($os.ProductType -eq 1 -and $build -ge 10240)
}

function Test-IsAdministrator {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-WingetAvailable {
    $cmd = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    try {
        $version = (& winget --version 2>&1 | Out-String).Trim()
        Write-Log "winget gefunden: $version ($($cmd.Source))"
        return ($LASTEXITCODE -eq 0)
    }
    catch { return $false }
}

# --- winget-Hilfsfunktionen --------------------------------------------------
function Invoke-Winget {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = & winget @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = @($output) }
}

function Resolve-WingetId {
    <# Ermittelt die winget-ID per 'winget search' und filtert mit dem erwarteten ID-Muster. #>
    param([Parameter(Mandatory)]$App)

    if ($App.FixedId) {
        $check = Invoke-Winget -Arguments @('search', '--id', $App.FixedId, '--exact', '--source', $App.Source,
            '--accept-source-agreements', '--disable-interactivity')
        if ($check.ExitCode -ne 0) { throw "ID '$($App.FixedId)' wurde in Quelle '$($App.Source)' nicht gefunden." }
        return $App.FixedId
    }

    $result = Invoke-Winget -Arguments @('search', '--query', $App.SearchTerm, '--source', $App.Source,
        '--accept-source-agreements', '--disable-interactivity')
    if ($result.ExitCode -ne 0) {
        throw "winget search fuer '$($App.SearchTerm)' fehlgeschlagen (Exit-Code $($result.ExitCode))."
    }

    # Tabellenzeilen nach der Trennzeile ('-----') auswerten. Spaltenbreiten sind variabel (bei engen Tabellen nur
    # ein Leerzeichen zwischen den Spalten), daher wird jedes Wort der Zeile gegen das erwartete ID-Muster geprueft.
    $separatorIndex = -1
    for ($i = 0; $i -lt $result.Output.Count; $i++) {
        if ($result.Output[$i] -match '^-{5,}\s*$') { $separatorIndex = $i; break }
    }
    if ($separatorIndex -lt 0 -or $separatorIndex -ge ($result.Output.Count - 1)) {
        throw "Keine Suchergebnisse fuer '$($App.SearchTerm)'."
    }

    $rows = $result.Output[($separatorIndex + 1)..($result.Output.Count - 1)]
    $match = $rows | ForEach-Object { $_.Trim() -split '\s+' } | Where-Object { $_ -match $App.IdPattern } | Select-Object -First 1
    if (-not $match) { throw "Keine passende winget-ID fuer '$($App.Name)' gefunden (Muster $($App.IdPattern))." }
    return $match
}

function Test-AppInstalled {
    param([Parameter(Mandatory)][string]$Id)
    $result = Invoke-Winget -Arguments @('list', '--id', $Id, '--exact', '--accept-source-agreements', '--disable-interactivity')
    # Exit-Code 0 und ID in der Ausgabe => installiert
    return ($result.ExitCode -eq 0 -and ($result.Output | Where-Object { $_ -match [regex]::Escape($Id) }))
}

function Stop-AutoLaunchedProcess {
    <# Beendet eine vom Installer automatisch gestartete App (wartet kurz, da der Start verzoegert erfolgen kann). #>
    param([Parameter(Mandatory)][string]$ProcessName, [int]$TimeoutSeconds = 20)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $stopped = $false
    do {
        $procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) {
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
            $stopped = $true
            Start-Sleep -Seconds 2   # Nachzuegler abwarten
        }
        else { Start-Sleep -Seconds 1 }
    } while ((Get-Date) -lt $deadline -and -not $stopped)
    if ($stopped) { Write-Log "Automatisch gestarteter Prozess '$ProcessName' wurde beendet." }
}

function Install-WingetApp {
    <# Verarbeitet eine Anwendung und liefert ein Ergebnisobjekt (Status: Installed/Skipped/Failed/DryRun). #>
    param([Parameter(Mandatory)]$App)

    $entry = [pscustomobject]@{ Name = $App.Name; Id = ''; Status = 'Failed'; Detail = '' }
    try {
        Write-Log "--- $($App.Name) ---"
        $entry.Id = Resolve-WingetId -App $App
        Write-Log "Aufgeloeste winget-ID: $($entry.Id)"

        if (Test-AppInstalled -Id $entry.Id) {
            $entry.Status = 'Skipped'; $entry.Detail = 'bereits installiert'
            Write-Log "$($App.Name): bereits installiert - uebersprungen." -Level SKIP
            return $entry
        }

        if ($DryRun) {
            $entry.Status = 'DryRun'; $entry.Detail = 'nicht installiert (DryRun)'
            Write-Log "$($App.Name): wuerde installiert (DryRun)." -Level WARN
            return $entry
        }

        Write-Log "Installiere $($App.Name) ($($entry.Id)) ..."
        $result = Invoke-Winget -Arguments @('install', '--id', $entry.Id, '--exact', '--source', $App.Source,
            '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
        $result.Output | Where-Object { $_.Trim() -and $_ -notmatch '^\s*[-\\|/]\s*$' } |
            ForEach-Object { try { Add-Content -Path $LogPath -Value "    $_" -Encoding UTF8 } catch { } }

        if ($result.ExitCode -eq 0) {
            $entry.Status = 'Installed'; $entry.Detail = 'erfolgreich installiert'
            Write-Log "$($App.Name): erfolgreich installiert." -Level OK
            if ($App.PSObject.Properties['StopProcess']) { Stop-AutoLaunchedProcess -ProcessName $App.StopProcess }
        }
        elseif ($WingetAlreadyInstalled -contains $result.ExitCode) {
            $entry.Status = 'Skipped'; $entry.Detail = 'bereits installiert (winget)'
            Write-Log "$($App.Name): bereits installiert - uebersprungen." -Level SKIP
        }
        elseif ($WingetRebootRequired -contains $result.ExitCode) {
            $entry.Status = 'Installed'; $entry.Detail = 'installiert, Neustart erforderlich'
            Write-Log "$($App.Name): installiert, Neustart erforderlich." -Level WARN
        }
        else {
            $entry.Detail = "winget Exit-Code $($result.ExitCode)"
            Write-Log "$($App.Name): Installation fehlgeschlagen ($($entry.Detail))." -Level ERROR
        }
    }
    catch {
        $entry.Status = 'Failed'; $entry.Detail = $_.Exception.Message
        Write-Log "$($App.Name): $($_.Exception.Message)" -Level ERROR
    }
    return $entry
}

function Remove-DesktopShortcuts {
    <# Loescht alle Verknuepfungen (.lnk/.url) vom Desktop des aktuellen Benutzers und vom Desktop 'Alle Benutzer'. #>
    $folders = @(
        [Environment]::GetFolderPath('Desktop'),              # aktueller Benutzer (beruecksichtigt OneDrive-Umleitung)
        [Environment]::GetFolderPath('CommonDesktopDirectory') # Alle Benutzer
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    foreach ($folder in $folders) {
        $items = @(Get-ChildItem -LiteralPath $folder -Force -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.lnk', '.url' })
        Write-Log "Desktop-Bereinigung: $folder ($($items.Count) Verknuepfung(en))"
        foreach ($item in $items) {
            if ($DryRun) { Write-Log "Wuerde loeschen: $($item.Name) (DryRun)" -Level WARN; continue }
            try {
                Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
                Write-Log "Geloescht: $($item.Name)" -Level OK
            }
            catch { Write-Log "Konnte '$($item.FullName)' nicht loeschen: $($_.Exception.Message)" -Level WARN }
        }
    }
}

function Set-TaskbarPins {
    <# Heftet Windows Terminal, GitHub Desktop und Claude per LayoutModification.xml an die Taskleiste (aktueller Benutzer).
       Windows 11 bietet keine offizielle Pin-API; die Datei wird durch Zuruecksetzen von 'Taskband' und Explorer-Neustart angewendet. #>
    $wanted = @(
        [pscustomobject]@{ Name = 'Windows Terminal'; Pattern = '^(Windows )?Terminal$' }
        [pscustomobject]@{ Name = 'GitHub Desktop';   Pattern = '^GitHub Desktop$' }
        [pscustomobject]@{ Name = 'Claude';           Pattern = '^Claude$' }
    )
    try {
        $startApps = @(Get-StartApps)
        $pins = foreach ($w in $wanted) {
            $hit = $startApps | Where-Object { $_.Name -match $w.Pattern } | Select-Object -First 1
            if ($hit) {
                Write-Log "Taskleiste: $($w.Name) -> $($hit.AppID)"
                # Store-Apps haben ein '!' in der AppUserModelID, klassische Desktop-Apps nicht
                if ($hit.AppID -match '!') { '        <taskbar:UWA AppUserModelID="{0}" />' -f $hit.AppID }
                else { '        <taskbar:DesktopApp DesktopApplicationID="{0}" />' -f $hit.AppID }
            }
            else { Write-Log "Taskleiste: $($w.Name) nicht gefunden - uebersprungen." -Level WARN }
        }
        if (-not $pins) { Write-Log 'Taskleiste: keine Anwendung gefunden, nichts zu tun.' -Level WARN; return }

        if ($DryRun) { Write-Log 'Taskleiste: Anheften uebersprungen (DryRun).' -Level WARN; return }

        $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Add">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
$($pins -join "`r`n")
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
        $shellDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Shell'
        if (-not (Test-Path -LiteralPath $shellDir)) { New-Item -Path $shellDir -ItemType Directory -Force | Out-Null }
        Set-Content -Path (Join-Path $shellDir 'LayoutModification.xml') -Value $xml -Encoding UTF8

        # Layout fuer das bestehende Profil neu einlesen lassen
        $taskband = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
        if (Test-Path $taskband) { Remove-Item -Path $taskband -Recurse -Force }
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        Write-Log 'Taskleiste: Terminal, GitHub Desktop und Claude angeheftet.' -Level OK
    }
    catch { Write-Log "Taskleiste: Anheften fehlgeschlagen: $($_.Exception.Message)" -Level WARN }
}

function Write-Summary {
    param([Parameter(Mandatory)][object[]]$Results)
    Write-Log '=================== Zusammenfassung ==================='
    $Results | Format-Table Name, Id, Status, Detail -AutoSize | Out-String -Width 200 |
        ForEach-Object { Write-Host $_; try { Add-Content -Path $LogPath -Value $_ -Encoding UTF8 } catch { } }
    $count = { param($s) @($Results | Where-Object Status -eq $s).Count }
    Write-Log ("Installiert: {0} | Uebersprungen: {1} | Fehlgeschlagen: {2}{3}" -f (& $count 'Installed'), (& $count 'Skipped'),
        (& $count 'Failed'), $(if ($DryRun) { " | DryRun: $(& $count 'DryRun')" } else { '' }))
    Write-Log "Logdatei: $LogPath"
}

# --- Hauptprogramm -----------------------------------------------------------
function Main {
    Write-Log "Start (Host: $env:COMPUTERNAME, DryRun: $([bool]$DryRun))"

    if (-not (Test-WindowsClient)) {
        Write-Log 'Abbruch: Dieses Skript laeuft nur auf Windows-Clients (Windows 10/11), nicht auf Windows Server.' -Level ERROR
        return 2
    }
    if (-not (Test-IsAdministrator)) {
        Write-Log 'Hinweis: Skript laeuft nicht als Administrator - einzelne Installer koennen UAC-Abfragen zeigen oder fehlschlagen.' -Level WARN
    }
    if (-not (Test-WingetAvailable)) {
        Write-Log 'Abbruch: winget ist nicht verfuegbar. Bitte den "App Installer" aus dem Microsoft Store installieren/aktualisieren.' -Level ERROR
        return 3
    }

    $results = foreach ($app in $Applications) { Install-WingetApp -App $app }
    Remove-DesktopShortcuts
    Set-TaskbarPins
    Write-Summary -Results @($results)

    if (@($results | Where-Object Status -eq 'Failed').Count -gt 0) { return 1 }
    return 0
}

try { $code = Main }
catch {
    Write-Log "Unerwarteter Fehler: $($_.Exception.Message)" -Level ERROR
    $code = 4
}
exit $code
