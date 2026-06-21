#Requires -Version 5.1
# NoLeaks TUI - Text User Interface
# Run: powershell -ExecutionPolicy Bypass -File NoLeaks-TUI.ps1

param(
    [string]$TunName = "happ-default-tun",
    [string]$TunMtu = "1380",
    [string]$ExpectedIp = ""
)

$ErrorActionPreference = "Continue"
$script:Lang = "EN"

# ============================================================
# STRINGS (ASCII-safe)
# ============================================================
$S = @{
    EN = @{
        title = "Windows 11 No-Leaks TUI"
        subtitle = "Network leak hardening toolkit"
        selectLang = "Select language:"
        phase = "Phase"
        status = "Status"
        pressKey = "Press 1-7 = run phase, a = All, s = Settings, q = Quit"
        running = "Running..."
        done = "DONE"
        failed = "FAIL"
        warn = "WARN"
        notRun = "----"
        rebootNeeded = "*** REBOOT REQUIRED ***"
        adminWarning = "WARNING: Run as Administrator!"
        summary = "SUMMARY"
        pressAnyKey = "Press any key to continue..."
        selectPhase = "Select phase (1-7), a=All, q=Quit:"
        phaseDesc1 = "Block WebRTC/STUN/TURN/mDNS + Firewall + LLMNR"
        phaseDesc2 = "Disable QUIC (msquic, HTTP/3, browser policies)"
        phaseDesc3 = "Disable IPv6 (bindings, tunnels, DisabledComponents)"
        phaseDesc4 = "TCP Stack Tuning (TTL=128, Fast Open/ECN off)"
        phaseDesc5 = "Telemetry and Services (DiagTrack, SSDP, mDNS)"
        phaseDesc6 = "MTU Watcher Task (maintains MTU + IPv6 off)"
        phaseDesc7 = "Final Audit (17 leak check categories)"
        phaseName1 = "Block WebRTC/STUN/TURN"
        phaseName2 = "Disable QUIC"
        phaseName3 = "Disable IPv6"
        phaseName4 = "TCP Stack Tuning"
        phaseName5 = "Telemetry and Services"
        phaseName6 = "MTU Watcher Task"
        phaseName7 = "Final Audit"
        askTunName = "Enter TUN adapter name:"
        askMtu = "Enter MTU (default 1380):"
        askExpIp = "Enter expected IP (optional, Enter to skip):"
        settings = "Settings"
        current = "Current"
        confirmAll = "Run ALL phases? This will modify system settings."
        rebootNow = "Reboot now"
        later = "Later"
        selectOption = "Select option:"
        logSaved = "Log saved to"
        copied = "Log copied to clipboard"
    }
    RU = @{
        title = "Windows 11 No-Leaks TUI"
        subtitle = "Zashchita ot utechek IP i nastroika seti"
        selectLang = "Vyberite yazyk:"
        phase = "Faza"
        status = "Status"
        pressKey = "Nazhmite 1-7 = zapus fazy, a = Vse, s = Nastroyki, q = Vyhod"
        running = "Vypolnyaetsya..."
        done = "GOTOVO"
        failed = "OSHIBKA"
        warn = "VNIMANIE"
        notRun = "----"
        rebootNeeded = "*** NUGNA PEREZAGRUZKA ***"
        adminWarning = "VNIMANIE: Zapustite ot imeni Administratora!"
        summary = "ITOGI"
        pressAnyKey = "Nazhmite lyubuyu klavishu..."
        selectPhase = "Vyberite fazu (1-7), a=Vse, q=Vyhod:"
        phaseDesc1 = "Blokirovka WebRTC/STUN/TURN/mDNS + Firewall + LLMNR"
        phaseDesc2 = "Otklyuchenie QUIC (msquic, HTTP/3, politiki brauzerov)"
        phaseDesc3 = "Otklyuchenie IPv6 (bindingi, tunneli, DisabledComponents)"
        phaseDesc4 = "Optimizaciya TCP steka (TTL=128, Fast Open/ECN off)"
        phaseDesc5 = "Telemetriya i sluzhby (DiagTrack, SSDP, mDNS)"
        phaseDesc6 = "Watcher MTU (podderzhivaet MTU + IPv6 off)"
        phaseDesc7 = "Finalnyj audit (17 kategorij proverok)"
        phaseName1 = "Blokirovka WebRTC/STUN/TURN"
        phaseName2 = "Otklyuchenie QUIC"
        phaseName3 = "Otklyuchenie IPv6"
        phaseName4 = "Optimizaciya TCP steka"
        phaseName5 = "Telemetriya i sluzhby"
        phaseName6 = "Watcher MTU"
        phaseName7 = "Finalnyj audit"
        askTunName = "Vvedite imya TUN-adaptera:"
        askMtu = "Vvedite MTU (po umolchaniyu 1380):"
        askExpIp = "Vvedite ozhidaemyj IP (neobyazatelno, Enter = propustit):"
        settings = "Nastroyki"
        current = "Tekushchee"
        confirmAll = "Zapustit VSE fazy? Izmenit sistemnye nastrojki."
        rebootNow = "Perezagruzit seychas"
        later = "Pozzhe"
        selectOption = "Vyberite opciyu:"
        logSaved = "Log sohranen v"
        copied = "Log skopirovan v bufer"
    }
}

function Get-S($key) { $S[$script:Lang][$key] }

# ============================================================
# STATE
# ============================================================
$script:PhaseStatus = @("notrun","notrun","notrun","notrun","notrun","notrun","notrun")
$script:PhaseReboot = @($false,$false,$true,$true,$false,$false,$false)
$script:Log = [System.Collections.ArrayList]::new()
$script:PassCount = 0; $script:FailCount = 0; $script:WarnCount = 0

# ============================================================
# FUNCTIONS
# ============================================================
function Write-Log {
    param([string]$msg, [string]$lvl = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts][$lvl] $msg"
    [void]$script:Log.Add($line)
}

function Show-Header {
    Clear-Host
    $w = $Host.UI.RawUI.WindowSize.Width
    $line = "=" * [Math]::Min($w - 1, 70)

    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host ("  " + (Get-S "title")) -ForegroundColor White
    Write-Host ("  " + (Get-S "subtitle")) -ForegroundColor Gray
    Write-Host $line -ForegroundColor Cyan
    Write-Host ""

    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    $isAdmin = $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-Host "  [!] $(Get-S "adminWarning")" -ForegroundColor Yellow
        Write-Host ""
    }

    Write-Host ("  $(Get-S "settings"): TUN=$TunName | MTU=$TunMtu | IP=" + $(if($ExpectedIp){$ExpectedIp}else{"-"})) -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Phases {
    Write-Host ("  {0,-35} {1}" -f (Get-S "phase"), (Get-S "status")) -ForegroundColor DarkGray
    Write-Host "  " + ("-" * 55) -ForegroundColor DarkGray

    for ($i = 0; $i -lt 7; $i++) {
        $num = ($i + 1).ToString()
        $name = (Get-S ("phaseName" + ($i+1)))
        $st = $script:PhaseStatus[$i]

        $stIcon = switch ($st) {
            "done"    { "[$(Get-S "done")]" }
            "failed"  { "[$(Get-S "failed")]" }
            "warn"    { "[$(Get-S "warn")]" }
            "running" { "[$(Get-S "running")]" }
            default   { "[$(Get-S "notRun")]" }
        }

        $stColor = switch ($st) {
            "done"    { "Green" }
            "failed"  { "Red" }
            "warn"    { "Yellow" }
            "running" { "Cyan" }
            default   { "DarkGray" }
        }

        Write-Host ("  {0}. {1,-30} " -f $num, $name) -NoNewline -ForegroundColor Gray
        Write-Host $stIcon -ForegroundColor $stColor
    }
    Write-Host ""
    Write-Host "  " + ("-" * 55) -ForegroundColor DarkGray
    Write-Host ("  $(Get-S "pressKey")") -ForegroundColor DarkCyan
    Write-Host ""
}

function Run-Phase {
    param([int]$Index)

    $script:PhaseStatus[$Index] = "running"
    Show-Header
    Show-Phases

    $phaseNum = $Index + 1
    Write-Host ""
    $pName = Get-S ("phaseName" + $phaseNum); Write-Host (">>> Phase ${phaseNum}: " + $pName) -ForegroundColor Cyan
    Write-Host ""

    $scriptPath = Join-Path $PSScriptRoot "phase-engine.ps1"
    if (!(Test-Path $scriptPath)) {
        $scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "phase-engine.ps1"
    }
    if (!(Test-Path $scriptPath)) {
        Write-Host "  ERROR: phase-engine.ps1 not found!" -ForegroundColor Red
        Write-Log "ERROR: phase-engine.ps1 not found" "ERR"
        $script:PhaseStatus[$Index] = "failed"
        return
    }

    try {
        $output = & powershell -ExecutionPolicy Bypass -NoProfile -File $scriptPath -Phase $phaseNum -TunName $TunName -TunMtu $TunMtu -ExpectedIp $ExpectedIp 2>&1

        $phaseFail = $false
        foreach ($line in $output) {
            if ($line -match "^\[FAIL\]") {
                Write-Host ("  $line") -ForegroundColor Red
                Write-Log $line "ERR"
                $phaseFail = $true; $script:FailCount++
            }
            elseif ($line -match "^\[OK\]") {
                Write-Host ("  $line") -ForegroundColor Green
                Write-Log $line "OK"
                $script:PassCount++
            }
            elseif ($line -match "^\[WARN\]") {
                Write-Host ("  $line") -ForegroundColor Yellow
                Write-Log $line "WARN"
                $script:WarnCount++
            }
            elseif ($line -match "REBOOT REQUIRED") {
                Write-Host ("  >>> $line") -ForegroundColor Yellow
                Write-Log $line "WARN"
            }
            elseif ($line -match "SUMMARY|complete:|PASS:|FAIL:|WARN:|ACTION|ALL CRITICAL") {
                Write-Host ("  $line") -ForegroundColor Cyan
                Write-Log $line "INFO"
            }
            elseif ($line.Trim() -ne "") {
                Write-Host ("  $line") -ForegroundColor Gray
                Write-Log $line "INFO"
            }
        }

        if ($phaseFail) { $script:PhaseStatus[$Index] = "failed" } else { $script:PhaseStatus[$Index] = "done" }

        if ($script:PhaseReboot[$Index]) {
            Write-Host ""
            Write-Host ("  $(Get-S "rebootNeeded")") -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host ("  ERROR: $_") -ForegroundColor Red
        Write-Log ("ERROR: $_") "ERR"
        $script:PhaseStatus[$Index] = "failed"
        $script:FailCount++
    }

    Write-Host ""
    Write-Host ("  $(Get-S "pressAnyKey")") -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-AllPhases {
    $needReboot = $false
    for ($i = 0; $i -lt 7; $i++) {
        Run-Phase -Index $i
        if ($script:PhaseReboot[$i]) { $needReboot = $true }
    }

    Show-Header
    Show-Phases
    Write-Host ""
    Write-Host ("  === $(Get-S "summary") ===") -ForegroundColor Cyan
    Write-Host ("  PASS: $($script:PassCount)") -ForegroundColor Green
    Write-Host ("  FAIL: $($script:FailCount)") -ForegroundColor Red
    Write-Host ("  WARN: $($script:WarnCount)") -ForegroundColor Yellow
    Write-Host ""

    if ($needReboot) {
        Write-Host ("  $(Get-S "rebootNeeded")") -ForegroundColor Yellow
        Write-Host ("  1. $(Get-S "rebootNow")") -ForegroundColor White
        Write-Host ("  2. $(Get-S "later")") -ForegroundColor Gray
        Write-Host ""
        $rb = Read-Host ("  $(Get-S "selectOption")")
        if ($rb -eq "1") { Restart-Computer -Force }
    }
}

function Select-Language {
    Clear-Host
    Write-Host ""
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host "       Windows 11 No-Leaks TUI" -ForegroundColor White
    Write-Host "       Network leak hardening" -ForegroundColor Gray
    Write-Host "  ======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. English" -ForegroundColor White
    Write-Host "  2. Russian (Russkij)" -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "  Select (1-2)"
    switch ($choice) {
        "2" { $script:Lang = "RU" }
        default { $script:Lang = "EN" }
    }
}

function Configure-Settings {
    Show-Header
    Write-Host ""
    Write-Host ("  === $(Get-S "settings") ===") -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  $(Get-S "current"): TUN=$TunName, MTU=$TunMtu") -ForegroundColor Gray
    Write-Host ""
    $newTun = Read-Host ("  $(Get-S "askTunName") [$TunName]")
    if ($newTun.Trim() -ne "") { $script:TunName = $newTun.Trim() }
    $newMtu = Read-Host ("  $(Get-S "askMtu") [$TunMtu]")
    if ($newMtu.Trim() -ne "") { $script:TunMtu = $newMtu.Trim() }
    $newIp = Read-Host ("  $(Get-S "askExpIp")")
    if ($newIp.Trim() -ne "") { $script:ExpectedIp = $newIp.Trim() }
}

# ============================================================
# MAIN
# ============================================================
Select-Language

$enginePath = Join-Path $PSScriptRoot "phase-engine.ps1"
if (!(Test-Path $enginePath)) {
    $enginePath = Join-Path (Split-Path $PSScriptRoot -Parent) "phase-engine.ps1"
}
if (!(Test-Path $enginePath)) {
    Write-Host ""
    Write-Host "  ERROR: phase-engine.ps1 not found!" -ForegroundColor Red
    Write-Host "  Place phase-engine.ps1 in the same folder as this script." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter to exit"
    exit 1
}

while ($true) {
    Show-Header
    Show-Phases

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.Character) {
        "1" { Run-Phase -Index 0 }
        "2" { Run-Phase -Index 1 }
        "3" { Run-Phase -Index 2 }
        "4" { Run-Phase -Index 3 }
        "5" { Run-Phase -Index 4 }
        "6" { Run-Phase -Index 5 }
        "7" { Run-Phase -Index 6 }
        "a" { Run-AllPhases }
        "A" { Run-AllPhases }
        "s" { Configure-Settings }
        "S" { Configure-Settings }
        "q" { exit 0 }
        "Q" { exit 0 }
    }
}
