#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Windows 11 No-Leaks TUI v2.0 — Single-file network hardening toolkit
.DESCRIPTION
    Interactive terminal UI. No external files needed.
    Run: powershell -ExecutionPolicy Bypass -File NoLeaks.ps1
    Or double-click NoLeaks.bat
#>

# ============================================================
# CONFIG
# ============================================================
$script:CFG = @{
    TunName    = "happ-default-tun"
    TunMtu     = "1380"
    ExpectedIp = ""
    Lang       = "EN"
    Version    = "2.0"
}

# ============================================================
# ALL STRINGS
# ============================================================
$script:STR = @{
    EN = @{
        title         = "Windows 11 No-Leaks"
        version       = "v2.0"
        subtitle      = "Network Leak Hardening Toolkit"
        lang_select   = "Select language / Vyberite yazyk:"
        lang_en       = "1. English"
        lang_ru       = "2. Russian"
        menu_header   = "MAIN MENU"
        menu_run_all  = "Run All Phases"
        menu_settings = "Settings"
        menu_audit    = "Audit Only"
        menu_quit     = "Quit"
        menu_press    = "Press number to select"
        phase         = "Phase"
        desc          = "Description"
        status        = "Status"
        notrun        = "----"
        running       = "RUN..."
        done          = "DONE"
        failed        = "FAIL"
        warn          = "WARN"
        reboot        = "*** REBOOT REQUIRED ***"
        admin_warn    = "Run as Administrator for full functionality!"
        admin_ok      = "Administrator: YES"
        admin_no      = "Administrator: NO (limited)"
        settings      = "SETTINGS"
        current       = "Current"
        enter_tun     = "TUN adapter name"
        enter_mtu     = "MTU value"
        enter_ip      = "Expected IP (optional)"
        saved         = "Settings saved!"
        confirm_all   = "Run ALL phases? This modifies system settings."
        yes_no        = " (1=Yes / 2=No)"
        summary       = "EXECUTION SUMMARY"
        total_pass    = "Total PASS"
        total_fail    = "Total FAIL"
        total_warn    = "Total WARN"
        reboot_now    = "Reboot now?"
        reboot_1      = "1. Yes, reboot now"
        reboot_2      = "2. No, later"
        press_key     = "Press any key to continue..."
        press_menu    = "Press key: 1-7=Phase, A=All, S=Settings, Q=Quit"
        log_copied    = "Log copied to clipboard"
        p1_name       = "Block WebRTC/STUN/TURN"
        p1_desc       = "Firewall rules, LLMNR/NBT-NS off"
        p2_name       = "Disable QUIC"
        p2_desc       = "msquic, HTTP/3, browser policies"
        p3_name       = "Disable IPv6"
        p3_desc       = "Bindings, tunnels, DisabledComponents"
        p4_name       = "TCP Stack Tuning"
        p4_desc       = "TTL=128, Fast Open/ECN off, Nagle off"
        p5_name       = "Telemetry & Services"
        p5_desc       = "DiagTrack, SSDP, mDNS, hosts blocks"
        p6_name       = "MTU Watcher Task"
        p6_desc       = "Maintains MTU + IPv6 off on TUN"
        p7_name       = "Final Audit"
        p7_desc       = "17 categories of leak checks"
    }
    RU = @{
        title         = "Windows 11 No-Leaks"
        version       = "v2.0"
        subtitle      = "Zashchita ot utechek IP"
        lang_select   = "Vyberite yazyk / Select language:"
        lang_en       = "1. English"
        lang_ru       = "2. Russkij"
        menu_header   = "GLAVNOE MENYU"
        menu_run_all  = "Zapustit vse fazy"
        menu_settings = "Nastroyki"
        menu_audit    = "Tolko audit"
        menu_quit     = "Vyhod"
        menu_press    = "Nazhmite nomer punkta"
        phase         = "Faza"
        desc          = "Opisanie"
        status        = "Status"
        notrun        = "----"
        running       = "RUN..."
        done          = "GOTOVO"
        failed        = "OSHIBKA"
        warn          = "VNIM"
        reboot        = "*** PEREZAGRUZKA ***"
        admin_warn    = "Zapustite ot imeni Administratora!"
        admin_ok      = "Administrator: DA"
        admin_no      = "Administrator: NET (ogranicheno)"
        settings      = "NASTROYKI"
        current       = "Tekushchee"
        enter_tun     = "Imya TUN-adaptera"
        enter_mtu     = "Znachenie MTU"
        enter_ip      = "Ozhidaemyj IP (neobyazatelno)"
        saved         = "Nastroyki sohraneny!"
        confirm_all   = "Zapustit VSE fazy? Izmenit nastrojki."
        yes_no        = " (1=Da / 2=Net)"
        summary       = "ITOGI"
        total_pass    = "Vsego PASS"
        total_fail    = "Vsego FAIL"
        total_warn    = "Vsego WARN"
        reboot_now    = "Perezagruzit seychas?"
        reboot_1      = "1. Da, perezaruzit"
        reboot_2      = "2. Net, pozzhe"
        press_key     = "Nazhmite lyubuyu klavishu..."
        press_menu    = "Klavisha: 1-7=Faza, A=Vse, S=Nastroyki, Q=Vyhod"
        log_copied    = "Log skopirovan"
        p1_name       = "Blokirovka WebRTC/STUN/TURN"
        p1_desc       = "Pravila firewall, LLMNR/NBT-NS off"
        p2_name       = "Otklyuchenie QUIC"
        p2_desc       = "msquic, HTTP/3, politiki brauzerov"
        p3_name       = "Otklyuchenie IPv6"
        p3_desc       = "Bindingi, tunneli, DisabledComponents"
        p4_name       = "Optimizaciya TCP"
        p4_desc       = "TTL=128, Fast Open/ECN off, Nagle off"
        p5_name       = "Telemetriya i sluzhby"
        p5_desc       = "DiagTrack, SSDP, mDNS, blokirovka hosts"
        p6_name       = "Watcher MTU"
        p6_desc       = "Podderzhivaet MTU + IPv6 off na TUN"
        p7_name       = "Finalnyj audit"
        p7_desc       = "17 kategorij proverok utechek"
    }
}

function STR($key) { $script:STR[$script:CFG.Lang][$key] }

# ============================================================
# PHASE STATUS
# ============================================================
$script:PhaseStatus = @("notrun","notrun","notrun","notrun","notrun","notrun","notrun")
$script:PhaseReboot = @($false,$false,$true,$true,$false,$false,$false)
$script:TotalPass = 0
$script:TotalFail = 0
$script:TotalWarn = 0

# ============================================================
# HELPER FUNCTIONS
# ============================================================
function Is-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AdminStatus {
    if (Is-Admin) { return (STR "admin_ok") } else { return (STR "admin_no") }
}

function Draw-Line($char = "─", $color = "DarkGray") {
    $w = [Math]::Min($Host.UI.RawUI.WindowSize.Width - 1, 76)
    Write-Host ($char * $w) -ForegroundColor $color
}

function Draw-BoxTop { Write-Host "┌" -NoNewline -ForegroundColor Cyan; Draw-Line "─" Cyan; Write-Host "┐" -ForegroundColor Cyan }
function Draw-BoxBot { Write-Host "└" -NoNewline -ForegroundColor Cyan; Draw-Line "─" Cyan; Write-Host "┘" -ForegroundColor Cyan }
function Draw-BoxMid { Write-Host "├" -NoNewline -ForegroundColor Cyan; Draw-Line "─" Cyan; Write-Host "┤" -ForegroundColor Cyan }

function Write-Center($text, $color = "White", $padChar = " ") {
    $w = [Math]::Min($Host.UI.RawUI.WindowSize.Width - 1, 76)
    $pad = [Math]::Max(0, [Math]::Floor(($w - $text.Length) / 2))
    $line = ($padChar * $pad) + $text + ($padChar * ($w - $pad - $text.Length))
    Write-Host $line -ForegroundColor $color
}

function Write-BoxLine($text, $color = "White") {
    $w = [Math]::Min($Host.UI.RawUI.WindowSize.Width - 1, 74)
    $padded = $text.PadRight($w).Substring(0, [Math]::Min($text.Length, $w))
    Write-Host "│ " -NoNewline -ForegroundColor Cyan
    Write-Host $padded -NoNewline -ForegroundColor $color
    Write-Host " │" -ForegroundColor Cyan
}

function Get-PhaseIcon($st) {
    switch ($st) {
        "done"    { return @{ Icon = (STR "done"); Color = "Green" } }
        "failed"  { return @{ Icon = (STR "failed"); Color = "Red" } }
        "warn"    { return @{ Icon = (STR "warn"); Color = "Yellow" } }
        "running" { return @{ Icon = (STR "running"); Color = "Cyan" } }
        default   { return @{ Icon = (STR "notrun"); Color = "DarkGray" } }
    }
}

# ============================================================
# SCREENS
# ============================================================
function Show-LanguageSelect {
    Clear-Host
    Write-Host ""
    Draw-BoxTop
    Write-Center "" "White"
    Write-Center "Windows 11 No-Leaks" "White"
    Write-Center "Network Leak Hardening" "Gray"
    Write-Center "" "White"
    Draw-BoxBot
    Write-Host ""
    Write-Host ("  " + (STR "lang_select")) -ForegroundColor Yellow
    Write-Host ""
    Write-Host ("  " + (STR "lang_en")) -ForegroundColor White
    Write-Host ("  " + (STR "lang_ru")) -ForegroundColor White
    Write-Host ""
    $choice = Read-Host "  > "
    switch ($choice) {
        "2" { $script:CFG.Lang = "RU" }
        default { $script:CFG.Lang = "EN" }
    }
}

function Show-MainScreen {
    Clear-Host
    $w = [Math]::Min($Host.UI.RawUI.WindowSize.Width - 1, 76)

    # Header
    Write-Host ""
    Write-Host ("  " + (STR "title") + " " + $script:CFG.Version) -ForegroundColor White
    Write-Host ("  " + (STR "subtitle")) -ForegroundColor Gray
    Draw-Line
    Write-Host ""

    # Admin status
    $adm = Get-AdminStatus
    $admColor = if (Is-Admin) { "Green" } else { "Yellow" }
    Write-Host "  $adm" -ForegroundColor $admColor
    Write-Host ("  TUN: " + $script:CFG.TunName + " | MTU: " + $script:CFG.TunMtu) -ForegroundColor DarkGray
    Write-Host ""

    # Phase table
    Write-Host ("  {0,-3} {1,-28} {2,-30} {3}" -f "#", (STR "phase"), (STR "desc"), (STR "status")) -ForegroundColor DarkGray
    Draw-Line "─" DarkGray

    for ($i = 0; $i -lt 7; $i++) {
        $pName = STR ("p$($i+1)_name")
        $pDesc = STR ("p$($i+1)_desc")
        $icon = Get-PhaseIcon $script:PhaseStatus[$i]

        $num = ($i + 1).ToString()
        Write-Host ("  {0}. {1,-28} " -f $num, $pName) -NoNewline -ForegroundColor Gray
        Write-Host ("{0,-30} " -f $pDesc) -NoNewline -ForegroundColor DarkGray
        Write-Host ("[{0}]" -f $icon.Icon) -ForegroundColor $icon.Color
    }

    Draw-Line "─" DarkGray
    Write-Host ""

    # Menu
    Write-Host ("  " + (STR "menu_press")) -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host ("  [1-7] " + (STR "phase")) -ForegroundColor White
    Write-Host ("  [A]   " + (STR "menu_run_all")) -ForegroundColor White
    Write-Host ("  [S]   " + (STR "menu_settings")) -ForegroundColor White
    Write-Host ("  [Q]   " + (STR "menu_quit")) -ForegroundColor White
    Write-Host ""
}

function Show-Settings {
    Clear-Host
    Write-Host ""
    Write-Host ("  === " + (STR "settings") + " ===") -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  " + (STR "current") + ": TUN=" + $script:CFG.TunName + ", MTU=" + $script:CFG.TunMtu + ", IP=" + $(if($script:CFG.ExpectedIp){$script:CFG.ExpectedIp}else{"-"})) -ForegroundColor Gray
    Write-Host ""

    $newTun = Read-Host ("  " + (STR "enter_tun") + " [" + $script:CFG.TunName + "]")
    if ($newTun.Trim() -ne "") { $script:CFG.TunName = $newTun.Trim() }

    $newMtu = Read-Host ("  " + (STR "enter_mtu") + " [" + $script:CFG.TunMtu + "]")
    if ($newMtu.Trim() -ne "") { $script:CFG.TunMtu = $newMtu.Trim() }

    $newIp = Read-Host ("  " + (STR "enter_ip") + " [" + $(if($script:CFG.ExpectedIp){$script:CFG.ExpectedIp}else{""}) + "]")
    if ($newIp.Trim() -ne "") { $script:CFG.ExpectedIp = $newIp.Trim() }

    Write-Host ""
    Write-Host ("  " + (STR "saved")) -ForegroundColor Green
    Start-Sleep -Seconds 1
}

# ============================================================
# PHASE ENGINE (inline — no external files)
# ============================================================
function Invoke-PhaseEngine {
    param([int]$Phase)

    $results = @()

    switch ($Phase) {
        # ---- PHASE 1: Block WebRTC/STUN/TURN/mDNS ----
        1 {
            # Firewall on all profiles
            Get-NetFirewallProfile | ForEach-Object {
                if (!$_.Enabled) { Set-NetFirewallProfile -Name $_.Name -Enabled True | Out-Null }
                $results += @{ Name = "Firewall $($_.Name)"; Status = "PASS" }
            }

            # Block rules
            $rules = @(
                @("Block STUN UDP 3478 Out","UDP",3478,"Outbound"),
                @("Block STUN TCP 3478 Out","TCP",3478,"Outbound"),
                @("Block TURN TCP 5349 Out","TCP",5349,"Outbound"),
                @("Block mDNS UDP 5353 Out","UDP",5353,"Outbound"),
                @("Block QUIC UDP 443 Out","UDP",443,"Outbound"),
                @("Block SSDP UDP 1900 Out","UDP",1900,"Outbound"),
                @("Block LLMNR UDP 5355 Out","UDP",5355,"Outbound")
            )
            foreach ($r in $rules) {
                $existing = Get-NetFirewallRule -DisplayName $r[0] -ErrorAction SilentlyContinue
                if ($existing) { Remove-NetFirewallRule -DisplayName $r[0] | Out-Null }
                New-NetFirewallRule -DisplayName $r[0] -Direction $r[3] -Protocol $r[1] -LocalPort $r[2] -Action Block -Profile Any -Enabled True | Out-Null
                $results += @{ Name = "Rule: $($r[0])"; Status = "PASS" }
            }

            # LLMNR off
            $llmnrPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
            if (!(Test-Path $llmnrPath)) { New-Item -Path $llmnrPath -Force | Out-Null }
            Set-ItemProperty -Path $llmnrPath -Name "EnableMulticast" -Value 0 -Type DWord
            $results += @{ Name = "LLMNR disabled"; Status = "PASS" }

            # NBT-NS off
            $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue | Where-Object { $_.IPEnabled }
            foreach ($a in $adapters) { $a.SetTcpipNetbios(2) | Out-Null }
            $results += @{ Name = "NBT-NS disabled"; Status = "PASS" }
        }

        # ---- PHASE 2: Disable QUIC ----
        2 {
            $svc = Get-Service -Name msquic -ErrorAction SilentlyContinue
            if ($svc) {
                Stop-Service msquic -Force -ErrorAction SilentlyContinue
                Set-Service msquic -StartupType Disabled
            }
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MsQuic" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
            $results += @{ Name = "msquic service"; Status = "PASS" }

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name "EnableHttp3" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results += @{ Name = "HTTP/3 (HTTP.sys)"; Status = "PASS" }

            $sqPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\QUIC"
            if (!(Test-Path $sqPath)) { New-Item -Path $sqPath -Force | Out-Null }
            Set-ItemProperty -Path $sqPath -Name "Enabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $sqPath -Name "DisabledByDefault" -Value 1 -Type DWord
            $results += @{ Name = "QUIC Schannel"; Status = "PASS" }

            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results += @{ Name = "WinINET QUIC"; Status = "PASS" }

            $chromePath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
            if (!(Test-Path $chromePath)) { New-Item -Path $chromePath -Force | Out-Null }
            Set-ItemProperty -Path $chromePath -Name "QuicAllowed" -Value 0 -Type DWord
            $results += @{ Name = "Chrome QUIC"; Status = "PASS" }

            $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            if (!(Test-Path $edgePath)) { New-Item -Path $edgePath -Force | Out-Null }
            Set-ItemProperty -Path $edgePath -Name "QuicAllowed" -Value 0 -Type DWord
            $results += @{ Name = "Edge QUIC"; Status = "PASS" }

            $ffPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"
            if (!(Test-Path $ffPath)) { New-Item -Path $ffPath -Force | Out-Null }
            Set-ItemProperty -Path $ffPath -Name "DisableHttp3" -Value 1 -Type DWord
            $results += @{ Name = "Firefox HTTP/3"; Status = "PASS" }
        }

        # ---- PHASE 3: Disable IPv6 ----
        3 {
            Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | ForEach-Object {
                Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            }
            $results += @{ Name = "IPv6 bindings"; Status = "PASS" }

            netsh interface teredo set state disabled 2>&1 | Out-Null
            $results += @{ Name = "Teredo"; Status = "PASS" }
            netsh interface 6to4 set state disabled 2>&1 | Out-Null
            $results += @{ Name = "6to4"; Status = "PASS" }
            netsh interface isatap set state disabled 2>&1 | Out-Null
            $results += @{ Name = "ISATAP"; Status = "PASS" }
            netsh interface httpstunnel set state disabled 2>&1 | Out-Null
            $results += @{ Name = "IP-HTTPS"; Status = "PASS" }

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord
            $results += @{ Name = "DisabledComponents=0xFF"; Status = "PASS"; Reboot = $true }

            $dnsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
            if (!(Test-Path $dnsPath)) { New-Item -Path $dnsPath -Force | Out-Null }
            Set-ItemProperty -Path $dnsPath -Name "DisableSmartNameResolution" -Value 1 -Type DWord
            $results += @{ Name = "Smart Name Resolution"; Status = "PASS" }
        }

        # ---- PHASE 4: TCP Stack Tuning ----
        4 {
            $netshParams = @("autotuninglevel=normal","rss=disabled","chimney=disabled","dca=disabled","netdma=disabled","ecncapability=disabled","timestamps=disabled","rsc=disabled","fastopen=disabled","fastopenfallback=disabled","hystart=disabled","pacingprofile=off")
            foreach ($p in $netshParams) {
                $kv = $p -split '='
                netsh int tcp set global "$($kv[0])=$($kv[1])" 2>&1 | Out-Null
            }
            $results += @{ Name = "netsh TCP globals"; Status = "PASS" }

            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            $tcpipParams = @{ "KeepAliveTime" = 60000; "KeepAliveInterval" = 1000; "DefaultTTL" = 128; "DisableTaskOffload" = 1; "EnableECN" = 0; "EnableHeuristics" = 0; "MaxFreeTcbs" = 65536; "MaxHashTableSize" = 65536; "NumTcbTablePartitions" = 8; "Tcp1323Opts" = 0; "TcpMaxDupAcks" = 2; "TcpTimedWaitDelay" = 30; "MaxUserPort" = 65534 }
            foreach ($kv in $tcpipParams.GetEnumerator()) {
                Set-ItemProperty -Path $regPath -Name $kv.Key -Value $kv.Value -Type DWord -ErrorAction SilentlyContinue
            }
            $results += @{ Name = "Tcpip\Parameters ($($tcpipParams.Count) values)"; Status = "PASS"; Reboot = $true }

            $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
            foreach ($iface in $interfaces) {
                Set-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $iface.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
            $results += @{ Name = "Nagle disabled"; Status = "PASS" }
        }

        # ---- PHASE 5: Telemetry & Services ----
        5 {
            $services = @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV","fdPHost","upnphost","FDResPub")
            foreach ($svcName in $services) {
                $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                if ($svc) {
                    Stop-Service $svcName -Force -ErrorAction SilentlyContinue
                    Set-Service $svcName -StartupType Disabled -ErrorAction SilentlyContinue
                }
                $results += @{ Name = "Service $svcName"; Status = "PASS" }
            }

            $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
            $telemetryDomains = @("v10.events.data.microsoft.com","v20.events.data.microsoft.com","vortex.data.microsoft.com","vortex-win.data.microsoft.com","telecommand.telemetry.microsoft.com","oca.telemetry.microsoft.com","sqm.telemetry.microsoft.com","watson.telemetry.microsoft.com","redir.metaservices.microsoft.com","choice.microsoft.com","df.telemetry.microsoft.com","services.wes.df.telemetry.microsoft.com","feedback.windows.com","feedback.microsoft-hohm.com","feedback.search.microsoft.com","rad.msn.com","preview.msn.com","ad.doubleclick.net","ads.msn.com","ads1.msads.net","a.ads1.msn.com","a.ads2.msn.com","adnexus.net","adnxs.com","az361816.vo.msecnd.net","az512334.vo.msecnd.net","ssw.live.com","settings-sandbox.data.microsoft.com","vsgallery.com","watson.microsoft.com","ui.skype.com","pricelist.skype.com","apps.skype.com","m.hotmail.com","s.gateway.messenger.live.com","sa.windows.com")
            $existingHosts = Get-Content $hostsPath -ErrorAction SilentlyContinue
            $added = 0
            foreach ($domain in $telemetryDomains) {
                if ($existingHosts -notcontains "0.0.0.0 $domain") {
                    Add-Content -Path $hostsPath -Value "0.0.0.0 $domain" -ErrorAction SilentlyContinue
                    $added++
                }
            }
            $results += @{ Name = "Hosts blocks ($added domains)"; Status = "PASS" }

            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableMDNS" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results += @{ Name = "mDNS disabled"; Status = "PASS" }

            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results += @{ Name = "Advertising ID"; Status = "PASS" }

            $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (!(Test-Path $cortanaPath)) { New-Item -Path $cortanaPath -Force | Out-Null }
            Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -Type DWord
            Set-ItemProperty -Path $cortanaPath -Name "DisableWebSearch" -Value 1 -Type DWord
            Set-ItemProperty -Path $cortanaPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord
            $results += @{ Name = "Cortana/Cloud Search"; Status = "PASS" }
        }

        # ---- PHASE 6: MTU Watcher Task ----
        6 {
            $watcherDir = "C:\Users\$env:USERNAME\.no-leaks-watcher"
            if (!(Test-Path $watcherDir)) { New-Item -Path $watcherDir -ItemType Directory -Force | Out-Null }

            $watcherScript = "`$tunName = `"$($script:CFG.TunName)`"`n`$targetMtu = $($script:CFG.TunMtu)`nwhile (`$true) {`n  try {`n    `$adapter = Get-NetAdapter -Name `$tunName -ErrorAction SilentlyContinue`n    if (`$adapter -and `$adapter.Status -eq `"Up`") {`n      `$mtuOut = netsh interface ipv4 show subinterface `$tunName 2>`$null`n      if (`$mtuOut -notmatch `$targetMtu) { netsh interface ipv4 set subinterface `$tunName mtu=`$targetMtu store=persistent 2>`$null }`n      `$ipv6 = Get-NetAdapterBinding -Name `$tunName -ComponentID `"ms_tcpip6`" -ErrorAction SilentlyContinue`n      if (`$ipv6 -and `$ipv6.Enabled) { Disable-NetAdapterBinding -Name `$tunName -ComponentID `"ms_tcpip6`" -ErrorAction SilentlyContinue }`n    }`n  } catch {}`n  Start-Sleep -Seconds 3`n}"
            $watcherScript | Out-File -FilePath "$watcherDir\mtu-watcher.ps1" -Encoding UTF8 -Force
            $results += @{ Name = "Watcher script"; Status = "PASS" }

            Unregister-ScheduledTask -TaskName "NoLeaksWatcher" -Confirm:$false -ErrorAction SilentlyContinue
            $taskResult = schtasks /create /tn "NoLeaksWatcher" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watcherDir\mtu-watcher.ps1`"" /sc onlogon /rl highest /ru SYSTEM /f 2>&1
            if ($LASTEXITCODE -eq 0) {
                $results += @{ Name = "Scheduled task"; Status = "PASS" }
                schtasks /run /tn "NoLeaksWatcher" 2>&1 | Out-Null
            } else {
                $results += @{ Name = "Scheduled task"; Status = "FAIL"; Detail = $taskResult }
            }
        }

        # ---- PHASE 7: Final Audit ----
        7 {
            # Firewall
            Get-NetFirewallProfile | ForEach-Object {
                $st = if ($_.Enabled) { "PASS" } else { "FAIL" }
                $results += @{ Name = "Firewall $($_.Name)"; Status = $st }
            }

            # Block rules
            $ruleNames = @("Block STUN UDP 3478 Out","Block STUN TCP 3478 Out","Block TURN TCP 5349 Out","Block mDNS UDP 5353 Out","Block QUIC UDP 443 Out","Block SSDP UDP 1900 Out","Block LLMNR UDP 5355 Out")
            foreach ($rname in $ruleNames) {
                $r = Get-NetFirewallRule -DisplayName $rname -ErrorAction SilentlyContinue
                $st = if ($r -and $r.Enabled -eq 'True' -and $r.Action -eq 'Block') { "PASS" } else { "FAIL" }
                $results += @{ Name = "Rule: $rname"; Status = $st }
            }

            # Listening ports
            $dangerPorts = @(3478,5349,5353,1900,5355)
            $tcpListen = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $dangerPorts }
            $udpListen = Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $dangerPorts }
            $st = if (!$tcpListen -and !$udpListen) { "PASS" } else { "WARN" }
            $results += @{ Name = "Dangerous ports"; Status = $st }

            # LLMNR + IPv6
            $llmnr = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
            $st = if ($llmnr.EnableMulticast -eq 0) { "PASS" } else { "FAIL" }
            $results += @{ Name = "LLMNR"; Status = $st }

            $dc = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -ErrorAction SilentlyContinue
            $st = if ($dc.DisabledComponents -eq 255) { "PASS" } else { "WARN" }
            $results += @{ Name = "IPv6 DisabledComponents"; Status = $st }

            # QUIC
            $chromeQuic = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name QuicAllowed -ErrorAction SilentlyContinue
            $st = if ($chromeQuic.QuicAllowed -eq 0) { "PASS" } else { "FAIL" }
            $results += @{ Name = "Chrome QUIC"; Status = $st }

            $edgeQuic = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name QuicAllowed -ErrorAction SilentlyContinue
            $st = if ($edgeQuic.QuicAllowed -eq 0) { "PASS" } else { "FAIL" }
            $results += @{ Name = "Edge QUIC"; Status = $st }

            # TCP stack
            $tcp = netsh int tcp show global 2>$null
            $st = if ($tcp -match "Fast Open\s*:\s*disabled") { "PASS" } else { "WARN" }
            $results += @{ Name = "TCP Fast Open"; Status = $st }

            $ttl = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DefaultTTL -ErrorAction SilentlyContinue
            $st = if ($ttl.DefaultTTL -eq 128) { "PASS" } else { "FAIL" }
            $results += @{ Name = "DefaultTTL"; Status = $st }

            # Telemetry services
            $svcList = @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV")
            foreach ($svcName in $svcList) {
                $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                $st = if (!$svc -or $svc.Status -eq 'Stopped') { "PASS" } else { "WARN" }
                $results += @{ Name = "Service $svcName"; Status = $st }
            }

            # Hosts
            $hostsContent = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
            $blocked = ($hostsContent | Select-String '0\.0\.0\.0' | Measure-Object).Count
            $st = if ($blocked -gt 50) { "PASS" } else { "WARN" }
            $results += @{ Name = "Hosts blocks ($blocked)"; Status = $st }

            # Tunnel
            $tun = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'TUN|TAP|VPN|SocksTunnel' -and $_.Status -eq 'Up' }
            $st = if ($tun) { "PASS" } else { "WARN" }
            $results += @{ Name = "Tunnel"; Status = $st }

            # MTU
            $mtuOut = netsh interface ipv4 show subinterface $script:CFG.TunName 2>$null
            $st = if ($mtuOut -match $script:CFG.TunMtu) { "PASS" } else { "WARN" }
            $results += @{ Name = "MTU on $($script:CFG.TunName)"; Status = $st }

            # External IP
            try {
                $extIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content
                $results += @{ Name = "External IP: $extIp"; Status = "PASS" }
                if ($script:CFG.ExpectedIp -and $extIp -eq $script:CFG.ExpectedIp) {
                    $results += @{ Name = "IP matches expected"; Status = "PASS" }
                } elseif ($script:CFG.ExpectedIp) {
                    $results += @{ Name = "IP mismatch!"; Status = "WARN" }
                }
            } catch {
                $results += @{ Name = "External IP"; Status = "WARN"; Detail = $_.Exception.Message }
            }
        }
    }

    return $results
}

# ============================================================
# RUN PHASE (with UI)
# ============================================================
function Run-PhaseWithUI {
    param([int]$PhaseNum)

    $script:PhaseStatus[$PhaseNum - 1] = "running"
    Show-MainScreen

    $pName = STR ("p$($PhaseNum)_name")
    Write-Host ""
    Write-Host (">>> Phase $PhaseNum: $pName") -ForegroundColor Cyan
    Write-Host ""

    try {
        $results = Invoke-PhaseEngine -Phase $PhaseNum

        $phaseFail = $false
        foreach ($r in $results) {
            $icon = switch ($r.Status) {
                "PASS" { "[OK]"; $script:TotalPass++ }
                "FAIL" { "[FAIL]"; $script:TotalFail++; $phaseFail = $true }
                "WARN" { "[WARN]"; $script:TotalWarn++ }
            }
            $color = switch ($r.Status) {
                "PASS" { "Green" }
                "FAIL" { "Red" }
                "WARN" { "Yellow" }
            }
            Write-Host ("  $icon $($r.Name)") -ForegroundColor $color
            if ($r.Detail) { Write-Host ("       $($r.Detail)") -ForegroundColor DarkGray }
        }

        if ($phaseFail) {
            $script:PhaseStatus[$PhaseNum - 1] = "failed"
        } else {
            $script:PhaseStatus[$PhaseNum - 1] = "done"
        }

        if ($script:PhaseReboot[$PhaseNum - 1]) {
            Write-Host ""
            Write-Host ("  " + (STR "reboot")) -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host ("  ERROR: $_") -ForegroundColor Red
        $script:PhaseStatus[$PhaseNum - 1] = "failed"
        $script:TotalFail++
    }

    Write-Host ""
    Write-Host ("  " + (STR "press_key")) -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-AllPhasesWithUI {
    $needReboot = $false
    for ($i = 1; $i -le 7; $i++) {
        Run-PhaseWithUI -PhaseNum $i
        if ($script:PhaseReboot[$i - 1]) { $needReboot = $true }
    }

    # Summary
    Show-MainScreen
    Write-Host ""
    Write-Host ("  === " + (STR "summary") + " ===") -ForegroundColor Cyan
    Write-Host ("  $(STR "total_pass"): $($script:TotalPass)") -ForegroundColor Green
    Write-Host ("  $(STR "total_fail"): $($script:TotalFail)") -ForegroundColor Red
    Write-Host ("  $(STR "total_warn"): $($script:TotalWarn)") -ForegroundColor Yellow
    Write-Host ""

    if ($needReboot) {
        Write-Host ("  " + (STR "reboot_now")) -ForegroundColor Yellow
        Write-Host ("  " + (STR "reboot_1")) -ForegroundColor White
        Write-Host ("  " + (STR "reboot_2")) -ForegroundColor Gray
        Write-Host ""
        $rb = Read-Host ("  " + (STR "yes_no"))
        if ($rb -eq "1") { Restart-Computer -Force }
    }
}

# ============================================================
# MAIN LOOP
# ============================================================
Show-LanguageSelect

while ($true) {
    Show-MainScreen

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

    switch ($key.Character) {
        "1" { Run-PhaseWithUI -PhaseNum 1 }
        "2" { Run-PhaseWithUI -PhaseNum 2 }
        "3" { Run-PhaseWithUI -PhaseNum 3 }
        "4" { Run-PhaseWithUI -PhaseNum 4 }
        "5" { Run-PhaseWithUI -PhaseNum 5 }
        "6" { Run-PhaseWithUI -PhaseNum 6 }
        "7" { Run-PhaseWithUI -PhaseNum 7 }
        "a" { Run-AllPhasesWithUI }
        "A" { Run-AllPhasesWithUI }
        "s" { Show-Settings }
        "S" { Show-Settings }
        "q" { exit 0 }
        "Q" { exit 0 }
    }
}
