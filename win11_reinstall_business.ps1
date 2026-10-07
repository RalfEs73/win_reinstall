<#
.SYNOPSIS
    Richtet einen Business-PC (Windows 10/11 Client, lokaler Administrator) nach der Installation ein.

.DESCRIPTION
    - Bricht auf Windows Server sofort ab (Exit-Code 2).
    - Prüft, ob winget verfügbar ist (Exit-Code 3).
    - Installiert PowerShell, GitHub Desktop, Visual Studio Code und Microsoft Copilot (Store) über winget.
    - Überspringt bereits installierte Anwendungen (idempotent).
    - Legt C:\Temp und C:\GitHub an und heftet sie an den Schnellzugriff (Dokumente/Bilder/Musik/Videos werden gelöst).
    - Schaltet die Explorer-Vorschläge (zuletzt verwendet, häufig, empfohlen) aus.
    - Setzt das Hintergrundbild und die Taskleiste (Terminal, Claude, Copilot, VS Code, GitHub, Edge, OneNote, Outlook, Teams).
    - Startet sich ohne Administratorrechte selbst mit UAC neu (außer bei -DryRun).
    - Schreibt ein Log nach C:\Temp und öffnet es am Ende in Notepad.

.PARAMETER DryRun
    Löst IDs auf und prüft den Installationsstatus, ändert aber nichts.

.PARAMETER LogPath
    Pfad der Logdatei (Standard: C:\Temp\win11_reinstall_business_<Zeitstempel>.log; das Verzeichnis wird bei Bedarf angelegt).

.NOTES
    Exit-Codes:
      0 = alle Anwendungen installiert oder bereits vorhanden
      1 = mindestens eine Anwendung fehlgeschlagen
      2 = Betriebssystem ist kein Windows-Client (z. B. Windows Server)
      3 = winget nicht verfügbar
      4 = unerwarteter Fehler
      5 = Administratorrechte nicht erteilt (UAC abgelehnt)
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$LogPath = (Join-Path "C:\Temp" ("win11_reinstall_business_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date)))
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

# Quelle für den erhöhten Neustart, wenn das Skript per iex (ohne Datei) gestartet wurde
$ScriptUrl = 'https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/win11_reinstall_business.ps1'
$script:Relaunched = $false

# Hintergrundbild (liegt im Repo unter Wallpaper/)
$WallpaperUrl = 'https://raw.githubusercontent.com/RalfEs73/win_reinstall/main/Wallpaper/wallpaper.jpg'

# Arbeitsordner: werden angelegt und an den Schnellzugriff des Datei-Explorers geheftet
$WorkFolders = @('C:\Temp', 'C:\GitHub')

# --- Konfiguration -----------------------------------------------------------
# SearchTerm  : Suchbegriff für 'winget search'
# IdPattern   : Regex, den die gefundene ID erfüllen muss (Schutz vor falschen Treffern)
# Source      : (optional) winget-Quelle, Standard 'winget'; 'msstore' für Microsoft-Store-Apps
# FixedId     : (optional) feste ID (z. B. Store-ID); wird nur per 'winget search --id --exact' verifiziert
# RemoveAutostart : (optional) Namensmuster (Wildcard) von Autostart-Einträgen unter ...\CurrentVersion\Run, die entfernt werden
# StopProcess : (optional) Prozessname, der nach der Installation beendet wird, falls der Installer die App startet
$Applications = @(
    [pscustomobject]@{ Name = 'PowerShell';					SearchTerm = 'PowerShell';			IdPattern = '^Microsoft\.PowerShell$' }
    [pscustomobject]@{ Name = 'GitHub Desktop';				SearchTerm = 'GitHub Desktop';		IdPattern = '^GitHub\.GitHubDesktop$' }
    [pscustomobject]@{ Name = 'Visual Studio Code';			SearchTerm = 'Visual Studio Code';	IdPattern = '^Microsoft\.VisualStudioCode$' }
    [pscustomobject]@{ Name = 'Microsoft Copilot';			SearchTerm = 'Microsoft Copilot';	IdPattern = '^XP9CXNGPPJ97XX$'; Source = 'msstore'; FixedId = 'XP9CXNGPPJ97XX'; StopProcess = @('mscopilot_proxy', 'mscopilot'); RemoveAutostart = 'MicrosoftCopilotAutoLaunch*' }
)

# Optionale Eigenschaften mit Standardwerten ergänzen (StrictMode-sicher)
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

# --- Systemprüfung ----------------------------------------------------------
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

function Restart-AsAdministrator {
    <# Startet das Skript in einem neuen, erhöhten PowerShell-Prozess (UAC) und liefert dessen Exit-Code.
       Funktioniert als Datei (-File-Aufruf) und beim Aufruf per iex (Skript wird dann erneut von GitHub geladen). #>
    $paused = '$env:WIN11_REINSTALL_PAUSE = ''1''; '
    if ($PSCommandPath) {
        $command = $paused + "& '$PSCommandPath' -LogPath '$LogPath'"
    }
    else {
        $command = $paused + "iex ((New-Object System.Net.WebClient).DownloadString('$ScriptUrl'))"
    }
    try {
        $process = Start-Process -FilePath (Get-Process -Id $PID).Path -Verb RunAs -Wait -PassThru `
            -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', "`"$command`""
        return $process.ExitCode
    }
    catch {
        Write-Log "Abbruch: Start mit Administratorrechten fehlgeschlagen oder abgelehnt: $($_.Exception.Message)" -Level ERROR
        return 5
    }
}

function Test-WingetAvailable {
    $cmd = Get-Command -Name winget.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { return $false }
    try {
        $version = (& winget --version 2>&1 | Out-String).Trim()
        Write-Log "winget gefunden: $version"
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
        throw "winget search für '$($App.SearchTerm)' fehlgeschlagen (Exit-Code $($result.ExitCode))."
    }

    # Tabellenzeilen nach der Trennzeile ('-----') auswerten. Spaltenbreiten sind variabel (bei engen Tabellen nur
    # ein Leerzeichen zwischen den Spalten), daher wird jedes Wort der Zeile gegen das erwartete ID-Muster geprüft.
    $separatorIndex = -1
    for ($i = 0; $i -lt $result.Output.Count; $i++) {
        if ($result.Output[$i] -match '^-{5,}\s*$') { $separatorIndex = $i; break }
    }
    if ($separatorIndex -lt 0 -or $separatorIndex -ge ($result.Output.Count - 1)) {
        throw "Keine Suchergebnisse für '$($App.SearchTerm)'."
    }

    $rows = $result.Output[($separatorIndex + 1)..($result.Output.Count - 1)]
    $match = $rows | ForEach-Object { $_.Trim() -split '\s+' } | Where-Object { $_ -match $App.IdPattern } | Select-Object -First 1
    if (-not $match) { throw "Keine passende winget-ID für '$($App.Name)' gefunden (Muster $($App.IdPattern))." }
    return $match
}

function Test-AppInstalled {
    param([Parameter(Mandatory)][string]$Id)
    $result = Invoke-Winget -Arguments @('list', '--id', $Id, '--exact', '--accept-source-agreements', '--disable-interactivity')
    # Exit-Code 0 und ID in der Ausgabe => installiert
    return ($result.ExitCode -eq 0 -and ($result.Output | Where-Object { $_ -match [regex]::Escape($Id) }))
}

function Stop-AutoLaunchedProcess {
    <# Beendet eine vom Installer automatisch gestartete App. Der Start kann verzögert erfolgen und die App kann sich
       über einen Proxy-Prozess neu starten. Daher wird bis zu $TimeoutSeconds lang beobachtet und alles Gefundene
       beendet, bis $QuietSeconds Sekunden lang nichts mehr auftaucht. #>
    param([Parameter(Mandatory)][string[]]$ProcessName, [int]$TimeoutSeconds = 40, [int]$QuietSeconds = 8)
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastKill = $null
    $killedNames = @()
    while ((Get-Date) -lt $deadline) {
        $procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
        if ($procs.Count -gt 0) {
            $killedNames += $procs | ForEach-Object { $_.Name }
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
            $lastKill = Get-Date
        }
        elseif ($lastKill -and ((Get-Date) - $lastKill).TotalSeconds -ge $QuietSeconds) { break }
        Start-Sleep -Seconds 1
    }
    if ($lastKill) { Write-Log "Automatisch gestartete Prozesse wurden beendet: $((@($killedNames | Select-Object -Unique)) -join ', ')." }
    else { Write-Log "Kein automatisch gestarteter Prozess ($($ProcessName -join ', ')) gefunden." }
}

function Remove-AppAutostart {
    <# Entfernt Autostart-Einträge (HKCU/HKLM ...\Run), deren Name zu 'RemoveAutostart' einer App passt. Manche Apps
       (z. B. Copilot) legen sich beim ersten Start einen Eintrag an und öffnen sich dann bei jeder Anmeldung. #>
    $runKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run'
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    )
    foreach ($app in $Applications) {
        if (-not $app.PSObject.Properties['RemoveAutostart']) { continue }
        foreach ($key in $runKeys) {
            $item = Get-Item -Path $key -ErrorAction SilentlyContinue
            if (-not $item) { continue }
            foreach ($name in @($item.GetValueNames() | Where-Object { $_ -like $app.RemoveAutostart })) {
                if ($DryRun) { Write-Log "Autostart: würde '$name' ($($app.Name)) entfernen (DryRun)." -Level WARN; continue }
                try {
                    Remove-ItemProperty -Path $key -Name $name -ErrorAction Stop
                    Write-Log "Autostart: '$name' ($($app.Name)) entfernt." -Level OK
                }
                catch { Write-Log "Autostart: '$name' konnte nicht entfernt werden: $($_.Exception.Message)" -Level WARN }
            }
        }
    }
}

function Install-WingetApp {
    <# Verarbeitet eine Anwendung und liefert ein Ergebnisobjekt (Status: Installed/Skipped/Failed/DryRun). #>
    param([Parameter(Mandatory)]$App)

    $entry = [pscustomobject]@{ Name = $App.Name; Id = ''; Status = 'Failed'; Detail = '' }
    try {
        Write-Log "--- $($App.Name) ---"
        $entry.Id = Resolve-WingetId -App $App
        Write-Log "Aufgelöste winget-ID: $($entry.Id)"

        if (Test-AppInstalled -Id $entry.Id) {
            $entry.Status = 'Skipped'; $entry.Detail = 'bereits installiert'
            Write-Log "$($App.Name): bereits installiert - übersprungen." -Level SKIP
            return $entry
        }

        if ($DryRun) {
            $entry.Status = 'DryRun'; $entry.Detail = 'nicht installiert (DryRun)'
            Write-Log "$($App.Name): würde installiert (DryRun)." -Level WARN
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
            Write-Log "$($App.Name): bereits installiert - übersprungen." -Level SKIP
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

function New-WorkFolders {
    <# Legt die Arbeitsordner an, falls sie fehlen. #>
    foreach ($folder in $WorkFolders) {
        if (Test-Path -LiteralPath $folder) { Write-Log "Ordner vorhanden: $folder"; continue }
        if ($DryRun) { Write-Log "Würde Ordner anlegen: $folder (DryRun)" -Level WARN; continue }
        try {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Write-Log "Ordner angelegt: $folder" -Level OK
        }
        catch { Write-Log "Ordner '$folder' konnte nicht angelegt werden: $($_.Exception.Message)" -Level WARN }
    }
}

function Set-QuickAccess {
    <# Entfernt Dokumente, Bilder, Musik und Videos aus dem Schnellzugriff des Datei-Explorers und heftet $WorkFolders an. #>
    try {
        $shell = New-Object -ComObject Shell.Application
        $quickAccess = $shell.Namespace('shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}')
        if (-not $quickAccess) { throw 'Schnellzugriff konnte nicht geöffnet werden.' }

        $unpin = @('MyDocuments', 'MyPictures', 'MyMusic', 'MyVideos') |
            ForEach-Object { [Environment]::GetFolderPath($_).TrimEnd('\') } | Where-Object { $_ }

        # Items() nur einmal aufzählen: ein zweiter Aufruf liefert unter Windows PowerShell 5.1 eine leere Liste
        $items = @($quickAccess.Items())
        foreach ($item in $items) {
            $path ="$($item.Path)".TrimEnd('\')
            if ($unpin -notcontains $path) { continue }
            $verb = $item.Verbs() | Where-Object { $_.Name.Replace('&', '') -match 'Schnellzugriff.*(l.sen|entfernen)|Unpin from Quick access' } | Select-Object -First 1
            if (-not $verb) { Write-Log "Schnellzugriff: '$($item.Name)' ist nicht angeheftet - übersprungen."; continue }
            if ($DryRun) { Write-Log "Würde aus Schnellzugriff entfernen: $($item.Name) (DryRun)" -Level WARN; continue }
            $verb.DoIt()
            Write-Log "Schnellzugriff: '$($item.Name)' entfernt." -Level OK
        }

        $pinned = @()
        foreach ($item in $items) { $pinned += "$($item.Path)".TrimEnd('\') }
        foreach ($folder in $WorkFolders) {
            if ($pinned -contains $folder) { Write-Log "Schnellzugriff: $folder bereits angeheftet."; continue }
            if ($DryRun) { Write-Log "Würde an Schnellzugriff anheften: $folder (DryRun)" -Level WARN; continue }
            if (-not (Test-Path -LiteralPath $folder)) { Write-Log "Schnellzugriff: $folder existiert nicht - übersprungen." -Level WARN; continue }
            $shell.Namespace($folder).Self.InvokeVerb('pintohome')
            Write-Log "Schnellzugriff: $folder angeheftet." -Level OK
        }
    }
    catch { Write-Log "Schnellzugriff: $($_.Exception.Message)" -Level WARN }
}

function Set-ExplorerRecentSettings {
    <# Schaltet im Datei-Explorer alle Vorschläge zu zuletzt verwendeten Dateien und häufigen Ordnern aus. #>
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    $settings = [ordered]@{
        ShowRecent                  = 'Zuletzt verwendete Dateien im Schnellzugriff/Start anzeigen'
        ShowFrequent                = 'Häufig verwendete Ordner im Schnellzugriff anzeigen'
        ShowCloudFilesInQuickAccess = 'Empfohlene/Cloud-Dateien (Office.com) anzeigen'
    }
    foreach ($name in $settings.Keys) {
        if ($DryRun) { Write-Log "Explorer: würde '$($settings[$name])' ausschalten (DryRun)." -Level WARN; continue }
        try {
            if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
            Set-ItemProperty -Path $key -Name $name -Value 0 -Type DWord
            Write-Log "Explorer: '$($settings[$name])' ausgeschaltet." -Level OK
        }
        catch { Write-Log "Explorer: '$name' konnte nicht gesetzt werden: $($_.Exception.Message)" -Level WARN }
    }
}

function Set-DesktopWallpaper {
    <# Lädt das Hintergrundbild aus dem GitHub-Repo herunter und setzt es als Desktop-Hintergrund des aktuellen Benutzers. #>
    $target = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'wallpaper.jpg'
    if ($DryRun) { Write-Log "Hintergrundbild: würde $WallpaperUrl nach $target laden und setzen (DryRun)." -Level WARN; return }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $targetDir = Split-Path -Path $target -Parent
        if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
        Invoke-WebRequest -Uri $WallpaperUrl -OutFile $target -UseBasicParsing
        Write-Log "Hintergrundbild heruntergeladen: $target"

        # Anpassung 'Ausfüllen', nicht gekachelt
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10'
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'

        if (-not ('Win32Wallpaper' -as [type])) {
            Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class Win32Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
        }
        # SPI_SETDESKWALLPAPER = 20; SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 3
        if ([Win32Wallpaper]::SystemParametersInfo(20, 0, $target, 3)) { Write-Log 'Hintergrundbild gesetzt.' -Level OK }
        else { Write-Log 'Hintergrundbild konnte nicht gesetzt werden (SystemParametersInfo fehlgeschlagen).' -Level WARN }
    }
    catch { Write-Log "Hintergrundbild: $($_.Exception.Message)" -Level WARN }
}

function Test-ExplorerElevated {
    <# Prüft, ob ein laufender explorer.exe mit erhöhten (Administrator-)Rechten läuft. #>
    if (-not ('Win32TokenInfo' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class Win32TokenInfo {
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool OpenProcessToken(IntPtr h, uint access, out IntPtr token);
    [DllImport("advapi32.dll", SetLastError = true)] static extern bool GetTokenInformation(IntPtr token, int cls, out int info, int len, out int ret);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr h);
    public static bool IsElevated(IntPtr process) {
        IntPtr token;
        if (!OpenProcessToken(process, 8, out token)) return false;   // TOKEN_QUERY
        try { int v; int r; return GetTokenInformation(token, 20, out v, 4, out r) && v != 0; }   // TokenElevation
        finally { CloseHandle(token); }
    }
}
'@
    }
    foreach ($proc in @(Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
        try { if ([Win32TokenInfo]::IsElevated($proc.Handle)) { return $true } } catch { }
    }
    return $false
}

function Set-TaskbarPins {
    <# Setzt die Taskleiste (aktueller Benutzer) per LayoutModification.xml auf: Terminal, Claude, Copilot, VS Code, GitHub Desktop,
       Edge, OneNote, Outlook, Teams (in genau dieser Reihenfolge). Windows 11 bietet keine offizielle Pin-API; die Datei wird
       durch Zurücksetzen von 'Taskband' und Explorer-Neustart angewendet. #>
    # Reihenfolge = Reihenfolge in der Taskleiste. 'Fixed' = feste Pin-Zeile (ohne Get-StartApps-Suche).
    $wanted = @(
        [pscustomobject]@{ Name = 'Windows Terminal';  Pattern = '^(Windows )?Terminal$';                  Fixed = $null }
        [pscustomobject]@{ Name = 'Claude';            Pattern = '^Claude$';                               Fixed = $null }
        [pscustomobject]@{ Name = 'Copilot';           Pattern = '^(Microsoft )?Copilot$';                 Fixed = $null }
        [pscustomobject]@{ Name = 'Visual Studio Code'; Pattern = '^Visual Studio Code$';                  Fixed = $null }
        [pscustomobject]@{ Name = 'GitHub Desktop';    Pattern = '^GitHub Desktop$';                       Fixed = $null }
        [pscustomobject]@{ Name = 'Edge';              Pattern = $null; Fixed = '        <taskbar:DesktopApp DesktopApplicationID="MSEdge" />' }
        [pscustomobject]@{ Name = 'OneNote';           Pattern = '^OneNote( \(.*\))?( für Windows 10)?$';  Fixed = $null }
        [pscustomobject]@{ Name = 'Outlook';           Pattern = '^Outlook( \(.*\))?$';                    Fixed = $null }
        [pscustomobject]@{ Name = 'Teams';             Pattern = '^(Microsoft )?Teams( \(.*\))?$';         Fixed = $null }
    )
    try {
        $startApps = @(Get-StartApps)
        $pinned = @()
        $pins = foreach ($w in $wanted) {
            if ($w.Fixed) { $pinned += $w.Name; $w.Fixed; continue }
            $hit = $startApps | Where-Object { $_.Name -match $w.Pattern } | Select-Object -First 1
            if ($hit) {
                Write-Log "Taskleiste: $($w.Name) -> $($hit.AppID)"
                $pinned += $w.Name
                # Store-Apps haben ein '!' in der AppUserModelID, klassische Desktop-Apps nicht
                if ($hit.AppID -match '!') { '        <taskbar:UWA AppUserModelID="{0}" />' -f $hit.AppID }
                else { '        <taskbar:DesktopApp DesktopApplicationID="{0}" />' -f $hit.AppID }
            }
            else { Write-Log "Taskleiste: $($w.Name) nicht gefunden - übersprungen." -Level WARN }
        }
        if (-not $pins) { Write-Log 'Taskleiste: keine Anwendung gefunden, nichts zu tun.' -Level WARN; return }

        if ($DryRun) { Write-Log 'Taskleiste: Anheften übersprungen (DryRun).' -Level WARN; return }

        # Die Pin-Liste wird ersetzt (Replace): alle anderen Standard-Pins, z. B. Explorer und Microsoft Store, entfallen.
        $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
$(@($pins) -join "`r`n")
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
        $shellDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Shell'
        if (-not (Test-Path -LiteralPath $shellDir)) { New-Item -Path $shellDir -ItemType Directory -Force | Out-Null }
        Set-Content -Path (Join-Path $shellDir 'LayoutModification.xml') -Value $xml -Encoding UTF8

        # Layout für das bestehende Profil neu einlesen lassen
        $taskband = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
        if (Test-Path $taskband) { Remove-Item -Path $taskband -Recurse -Force }
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        # Windows startet die Shell selbst im normalen Benutzerkontext neu. Darauf warten, statt explorer.exe aus
        # diesem erhöhten Prozess zu starten: sonst läuft die Shell als Administrator und alle daraus gestarteten
        # Apps (z. B. Terminal aus der Taskleiste) ebenfalls.
        $waitForExplorer = {
            $deadline = (Get-Date).AddSeconds(15)
            while (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 1 }
            if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) {
                # Notfall: Explorer mit eingeschränktem Token (nicht erhöht) starten
                Start-Process -FilePath "$env:SystemRoot\System32\runas.exe" -ArgumentList '/trustlevel:0x20000', "$env:SystemRoot\explorer.exe" -WindowStyle Hidden
                Start-Sleep -Seconds 3
            }
        }
        & $waitForExplorer

        # Kontrolle: Die Shell darf nicht erhöht laufen, sonst startet Terminal & Co. aus der Taskleiste als Administrator
        for ($try = 1; $try -le 2 -and (Test-ExplorerElevated); $try++) {
            Write-Log 'Taskleiste: Explorer läuft erhöht - wird im normalen Benutzerkontext neu gestartet.' -Level WARN
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            & $waitForExplorer
        }
        if (Test-ExplorerElevated) { Write-Log 'Taskleiste: Explorer läuft weiterhin erhöht - bitte einmal ab- und wieder anmelden.' -Level WARN }
        else { Write-Log 'Taskleiste: Explorer läuft im normalen Benutzerkontext (nicht als Administrator).' }
        Write-Log "Taskleiste: Pins gesetzt ($($pinned -join ', '))." -Level OK
    }
    catch { Write-Log "Taskleiste: Anheften fehlgeschlagen: $($_.Exception.Message)" -Level WARN }
}

function Write-Summary {
    param([Parameter(Mandatory)][object[]]$Results)
    Write-Log '=================== Zusammenfassung ==================='
    $Results | Format-Table Name, Id, Status, Detail -AutoSize | Out-String -Width 200 |
        ForEach-Object { Write-Host $_; try { Add-Content -Path $LogPath -Value $_ -Encoding UTF8 } catch { } }
    $count = { param($s) @($Results | Where-Object Status -eq $s).Count }
    Write-Log ("Installiert: {0} | Übersprungen: {1} | Fehlgeschlagen: {2}{3}" -f (& $count 'Installed'), (& $count 'Skipped'),
        (& $count 'Failed'), $(if ($DryRun) { " | DryRun: $(& $count 'DryRun')" } else { '' }))
    Write-Log "Logdatei: $LogPath"
}

# --- Hauptprogramm -----------------------------------------------------------
function Main {
    Write-Log "Start (Host: $env:COMPUTERNAME, DryRun: $([bool]$DryRun))"

    if (-not (Test-WindowsClient)) {
        Write-Log 'Abbruch: Dieses Skript läuft nur auf Windows-Clients (Windows 10/11), nicht auf Windows Server.' -Level ERROR
        return 2
    }
    if (-not (Test-IsAdministrator)) {
        if ($DryRun) {
            Write-Log 'Hinweis: Skript läuft nicht als Administrator (für DryRun nicht erforderlich).' -Level WARN
        }
        else {
            Write-Log 'Administratorrechte erforderlich - Skript wird mit erhöhten Rechten neu gestartet (UAC).'
            $script:Relaunched = $true   # der erhöhte Prozess öffnet das Log, nicht dieser
            return (Restart-AsAdministrator)
        }
    }
    if (-not (Test-WingetAvailable)) {
        Write-Log 'Abbruch: winget ist nicht verfügbar. Bitte den "App Installer" aus dem Microsoft Store installieren/aktualisieren.' -Level ERROR
        return 3
    }

    $results = foreach ($app in $Applications) { Install-WingetApp -App $app }
    Remove-AppAutostart
    New-WorkFolders
    Set-QuickAccess
    Set-ExplorerRecentSettings
    Set-DesktopWallpaper
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
# Logdatei in Notepad öffnen (nicht im Elternprozess, der nur den erhöhten Neustart auslöst)
if (-not $script:Relaunched -and (Test-Path -LiteralPath $LogPath)) {
    try { Start-Process -FilePath notepad.exe -ArgumentList "`"$LogPath`"" }
    catch { Write-Log "Logdatei konnte nicht in Notepad geöffnet werden: $($_.Exception.Message)" -Level WARN }
}
# Im automatisch erhöhten Fenster offen halten, damit die Ausgabe lesbar bleibt
if ($env:WIN11_REINSTALL_PAUSE -eq '1') { Write-Host ''; Read-Host 'Zum Schließen Enter drücken' | Out-Null }
exit $code
