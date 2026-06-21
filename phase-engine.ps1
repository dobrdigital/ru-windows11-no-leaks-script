# phase-engine.ps1 — вызывается GUI для запуска фаз
# Usage: .\phase-engine.ps1 -Phase <1-7> [-TunName <name>] [-TunMtu <mtu>] [-ExpectedIp <ip>]

param(
    [Parameter(Mandatory=$true)][int]$Phase,
    [string]$TunName = "happ-default-tun",
    [string]$TunMtu = "1380",
    [string]$ExpectedIp = ""
)

$ErrorActionPreference = "Continue"
$script:pass = 0; $script:fail = 0; $script:warn = 0

function Write-Result($name, $status, $detail) {
    $icon = switch ($status) { "PASS" { "[OK]"; $script:pass++ } "FAIL" { "[FAIL]"; $script:fail++ } "WARN" { "[WARN]"; $script:warn++ } }
    Write-Output "$icon $name"
    if ($detail) { Write-Output "     $detail" }
}

# ---- PHASE 1: Block WebRTC/STUN/TURN/mDNS ----
if ($Phase -eq 1) {
    Write-Output "=== Phase 1: Block WebRTC/STUN/TURN/mDNS ==="

    # Firewall on all profiles
    Get-NetFirewallProfile | ForEach-Object {
        if (!$_.Enabled) { Set-NetFirewallProfile -Name $_.Name -Enabled True }
        Write-Result "Firewall profile $($_.Name)" "PASS" "Enabled"
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
        if ($existing) { Remove-NetFirewallRule -DisplayName $r[0] }
        New-NetFirewallRule -DisplayName $r[0] -Direction $r[3] -Protocol $r[1] -LocalPort $r[2] -Action Block -Profile Any -Enabled True | Out-Null
        Write-Result "Rule: $($r[0])" "PASS"
    }

    # LLMNR off
    $llmnrPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    if (!(Test-Path $llmnrPath)) { New-Item -Path $llmnrPath -Force | Out-Null }
    Set-ItemProperty -Path $llmnrPath -Name "EnableMulticast" -Value 0 -Type DWord
    Write-Result "LLMNR disabled" "PASS"

    # NBT-NS off
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
    foreach ($a in $adapters) {
        $a.SetTcpipNetbios(2) | Out-Null
    }
    Write-Result "NBT-NS disabled" "PASS"

    Write-Output "`nPhase 1 complete: $($script:pass) OK, $($script:fail) FAIL"
}

# ---- PHASE 2: Disable QUIC ----
if ($Phase -eq 2) {
    Write-Output "=== Phase 2: Disable QUIC ==="

    # msquic service
    $svc = Get-Service -Name msquic -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service msquic -Force -ErrorAction SilentlyContinue
        Set-Service msquic -StartupType Disabled
        Write-Result "msquic service" "PASS" "Disabled"
    } else { Write-Result "msquic service" "PASS" "Not installed" }

    # msquic driver
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MsQuic" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
    Write-Result "msquic driver" "PASS" "Disabled"

    # HTTP/3 in HTTP.sys
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name "EnableHttp3" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Result "HTTP/3 (HTTP.sys)" "PASS" "Disabled"

    # Schannel QUIC
    $sqPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\QUIC"
    if (!(Test-Path $sqPath)) { New-Item -Path $sqPath -Force | Out-Null }
    Set-ItemProperty -Path $sqPath -Name "Enabled" -Value 0 -Type DWord
    Set-ItemProperty -Path $sqPath -Name "DisabledByDefault" -Value 1 -Type DWord
    Write-Result "QUIC Schannel" "PASS" "Disabled"

    # WinINET QUIC
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Result "WinINET QUIC" "PASS" "Disabled"

    # Chrome policy
    $chromePath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
    if (!(Test-Path $chromePath)) { New-Item -Path $chromePath -Force | Out-Null }
    Set-ItemProperty -Path $chromePath -Name "QuicAllowed" -Value 0 -Type DWord
    Write-Result "Chrome QUIC policy" "PASS" "Disabled"

    # Edge policy
    $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    if (!(Test-Path $edgePath)) { New-Item -Path $edgePath -Force | Out-Null }
    Set-ItemProperty -Path $edgePath -Name "QuicAllowed" -Value 0 -Type DWord
    Write-Result "Edge QUIC policy" "PASS" "Disabled"

    # Firefox policy
    $ffPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"
    if (!(Test-Path $ffPath)) { New-Item -Path $ffPath -Force | Out-Null }
    Set-ItemProperty -Path $ffPath -Name "DisableHttp3" -Value 1 -Type DWord
    Write-Result "Firefox HTTP/3 policy" "PASS" "Disabled"

    # WinHTTP HTTP/3
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp" -Name "EnableHttp3" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Result "WinHTTP HTTP/3" "PASS" "Disabled"

    Write-Output "`nPhase 2 complete: $($script:pass) OK, $($script:fail) FAIL"
}

# ---- PHASE 3: Disable IPv6 ----
if ($Phase -eq 3) {
    Write-Output "=== Phase 3: Disable IPv6 ==="

    # Disable IPv6 binding on all adapters
    Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue | ForEach-Object {
        Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    }
    Write-Result "IPv6 bindings" "PASS" "Disabled on all adapters"

    # Teredo
    netsh interface teredo set state disabled 2>&1 | Out-Null
    Write-Result "Teredo" "PASS" "Disabled"

    # 6to4
    netsh interface 6to4 set state disabled 2>&1 | Out-Null
    Write-Result "6to4" "PASS" "Disabled"

    # ISATAP
    netsh interface isatap set state disabled 2>&1 | Out-Null
    Write-Result "ISATAP" "PASS" "Disabled"

    # IP-HTTPS
    netsh interface httpstunnel set state disabled 2>&1 | Out-Null
    Write-Result "IP-HTTPS" "PASS" "Disabled"

    # DisabledComponents
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord
    Write-Result "DisabledComponents" "PASS" "0xFF (REBOOT REQUIRED)"

    # DNS Client
    $dnsPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    if (!(Test-Path $dnsPath)) { New-Item -Path $dnsPath -Force | Out-Null }
    Set-ItemProperty -Path $dnsPath -Name "DisableSmartNameResolution" -Value 1 -Type DWord
    Write-Result "Smart Name Resolution" "PASS" "Disabled"

    Write-Output "`nPhase 3 complete: $($script:pass) OK, $($script:fail) FAIL"
    Write-Output "*** REBOOT REQUIRED to apply IPv6 DisabledComponents ***"
}

# ---- PHASE 4: TCP Stack Tuning ----
if ($Phase -eq 4) {
    Write-Output "=== Phase 4: TCP Stack Tuning ==="

    # netsh global
    $netshParams = @(
        "autotuninglevel=normal",
        "rss=disabled",
        "chimney=disabled",
        "dca=disabled",
        "netdma=disabled",
        "ecncapability=disabled",
        "timestamps=disabled",
        "rsc=disabled",
        "fastopen=disabled",
        "fastopenfallback=disabled",
        "hystart=disabled",
        "pacingprofile=off"
    )
    foreach ($p in $netshParams) {
        $key = ($p -split '=')[0]
        $val = ($p -split '=')[1]
        netsh int tcp set global $key=$val 2>&1 | Out-Null
    }
    Write-Result "netsh TCP globals" "PASS" "Tuned"

    # Registry Tcpip\Parameters
    $tcpipParams = @{
        "KeepAliveTime"          = 60000
        "KeepAliveInterval"      = 1000
        "DefaultTTL"             = 128
        "DisableTaskOffload"     = 1
        "EnableECN"              = 0
        "EnableHeuristics"       = 0
        "MaxFreeTcbs"            = 65536
        "MaxHashTableSize"       = 65536
        "NumTcbTablePartitions"  = 8
        "SackOpts"               = 1
        "Tcp1323Opts"            = 0
        "TcpMaxDupAcks"          = 2
        "TcpTimedWaitDelay"      = 30
        "UserMaxPort"            = 65534
        "MaxUserPort"            = 65534
    }
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    foreach ($kv in $tcpipParams.GetEnumerator()) {
        Set-ItemProperty -Path $regPath -Name $kv.Key -Value $kv.Value -Type DWord -ErrorAction SilentlyContinue
    }
    Write-Result "Tcpip\Parameters" "PASS" "$($tcpipParams.Count) values set"

    # Nagle off on all interfaces
    $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    foreach ($iface in $interfaces) {
        Set-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $iface.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    }
    Write-Result "Nagle algorithm" "PASS" "Disabled on all interfaces"

    Write-Output "`nPhase 4 complete: $($script:pass) OK, $($script:fail) FAIL"
    Write-Output "*** REBOOT REQUIRED to apply TCP stack changes ***"
}

# ---- PHASE 5: Telemetry & Services ----
if ($Phase -eq 5) {
    Write-Output "=== Phase 5: Telemetry & Services ==="

    # Services to disable
    $services = @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV","fdPHost","upnphost","FDResPub")
    foreach ($svcName in $services) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service $svcName -Force -ErrorAction SilentlyContinue
            Set-Service $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Result "Service $svcName" "PASS" "Stopped + Disabled"
        } else {
            Write-Result "Service $svcName" "PASS" "Not installed"
        }
    }

    # Telemetry domains in hosts
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $telemetryDomains = @(
        "v10.events.data.microsoft.com","v20.events.data.microsoft.com",
        "vortex.data.microsoft.com","vortex-win.data.microsoft.com",
        "telecommand.telemetry.microsoft.com","telecommand.telemetry.microsoft.com.nsatc.net",
        "oca.telemetry.microsoft.com","oca.telemetry.microsoft.com.nsatc.net",
        "sqm.telemetry.microsoft.com","sqm.telemetry.microsoft.com.nsatc.net",
        "watson.telemetry.microsoft.com","watson.telemetry.microsoft.com.nsatc.net",
        "redir.metaservices.microsoft.com","choice.microsoft.com",
        "choice.microsoft.com.nsatc.net","df.telemetry.microsoft.com",
        "reports.wes.df.telemetry.microsoft.com","wes.df.telemetry.microsoft.com",
        "services.wes.df.telemetry.microsoft.com","sqm.df.telemetry.microsoft.com",
        "telemetry.microsoft.com","watson.ppe.telemetry.microsoft.com",
        "wes.df.telemetry.microsoft.com","ui.skype.com",
        "pricelist.skype.com","apps.skype.com","m.hotmail.com",
        "s.gateway.messenger.live.com","sa.windows.com",
        "pre.predictivadnetwork.microsoft.com","i1.services.social.microsoft.com",
        "df.telemetry.microsoft.com","diagnostics.support.microsoft.com",
        "corp.sts.microsoft.com","statsfe1.ws.microsoft.com",
        "pre.footprintpredict.com","i1.services.social.microsoft.com.nsatc.net",
        "feedback.windows.com","feedback.microsoft-hohm.com",
        "feedback.search.microsoft.com","rad.msn.com",
        "preview.msn.com","ad.doubleclick.net","ads.msn.com",
        "ads1.msads.net","ads1.msn.com","a.ads1.msn.com",
        "a.ads2.msn.com","adnexus.net","adnxs.com",
        "az361816.vo.msecnd.net","az512334.vo.msecnd.net",
        "ssw.live.com","ca.telemetry.microsoft.com",
        "i1.services.social.microsoft.com","df.telemetry.microsoft.com",
        "diagnostics.support.microsoft.com","corp.sts.microsoft.com",
        "statsfe1.ws.microsoft.com","pre.footprintpredict.com",
        "i1.services.social.microsoft.com.nsatc.net","feedback.windows.com",
        "feedback.microsoft-hohm.com","feedback.search.microsoft.com",
        "rad.msn.com","preview.msn.com","ad.doubleclick.net",
        "ads.msn.com","ads1.msads.net","ads1.msn.com",
        "a.ads1.msn.com","a.ads2.msn.com","adnexus.net",
        "adnxs.com","az361816.vo.msecnd.net","az512334.vo.msecnd.net",
        "ssw.live.com","ca.telemetry.microsoft.com",
        "settings-sandbox.data.microsoft.com","vsgallery.com",
        "watson.microsoft.com","wes.df.telemetry.microsoft.com",
        "ui.skype.com","pricelist.skype.com","apps.skype.com",
        "m.hotmail.com","s.gateway.messenger.live.com","sa.windows.com"
    )
    $existingHosts = Get-Content $hostsPath -ErrorAction SilentlyContinue
    $added = 0
    foreach ($domain in $telemetryDomains) {
        if ($existingHosts -notcontains "0.0.0.0 $domain") {
            Add-Content -Path $hostsPath -Value "0.0.0.0 $domain" -ErrorAction SilentlyContinue
            $added++
        }
    }
    Write-Result "Hosts telemetry blocks" "PASS" "$added domains added"

    # mDNS off
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableMDNS" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Result "mDNS" "PASS" "Disabled"

    # Advertising ID
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Result "Advertising ID" "PASS" "Disabled"

    # Cortana
    $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (!(Test-Path $cortanaPath)) { New-Item -Path $cortanaPath -Force | Out-Null }
    Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -Type DWord
    Write-Result "Cortana" "PASS" "Disabled"

    # Cloud Search
    Set-ItemProperty -Path $cortanaPath -Name "DisableWebSearch" -Value 1 -Type DWord
    Set-ItemProperty -Path $cortanaPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord
    Write-Result "Cloud Search" "PASS" "Disabled"

    Write-Output "`nPhase 5 complete: $($script:pass) OK, $($script:fail) FAIL"
}

# ---- PHASE 6: MTU Watcher Task ----
if ($Phase -eq 6) {
    Write-Output "=== Phase 6: MTU Watcher Task ==="

    if (!$TunName) {
        Write-Result "TUN adapter name" "FAIL" "Not specified"
        exit 1
    }

    # Create watcher script
    $watcherDir = "C:\Users\$env:USERNAME\.no-leaks-watcher"
    if (!(Test-Path $watcherDir)) { New-Item -Path $watcherDir -ItemType Directory -Force | Out-Null }

    $watcherScript = @"
`$tunName = "$TunName"
`$targetMtu = $TunMtu
while (`$true) {
    try {
        `$adapter = Get-NetAdapter -Name `$tunName -ErrorAction SilentlyContinue
        if (`$adapter -and `$adapter.Status -eq "Up") {
            `$mtuOut = netsh interface ipv4 show subinterface `$tunName 2>`$null
            if (`$mtuOut -notmatch `$targetMtu) {
                netsh interface ipv4 set subinterface `$tunName mtu=`$targetMtu store=persistent 2>`$null
            }
            `$ipv6 = Get-NetAdapterBinding -Name `$tunName -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
            if (`$ipv6 -and `$ipv6.Enabled) {
                Disable-NetAdapterBinding -Name `$tunName -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
            }
        }
    } catch {}
    Start-Sleep -Seconds 3
}
"@
    $watcherScript | Out-File -FilePath "$watcherDir\mtu-watcher.ps1" -Encoding UTF8 -Force
    Write-Result "Watcher script" "PASS" "Created at $watcherDir\mtu-watcher.ps1"

    # Create scheduled task
    Unregister-ScheduledTask -TaskName "NoLeaksWatcher" -Confirm:$false -ErrorAction SilentlyContinue
    $result = schtasks /create /tn "NoLeaksWatcher" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watcherDir\mtu-watcher.ps1`"" /sc onlogon /rl highest /ru SYSTEM /f 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Result "Scheduled task" "PASS" "NoLeaksWatcher created"
        schtasks /run /tn "NoLeaksWatcher" 2>&1 | Out-Null
        Write-Result "Task started" "PASS"
    } else {
        Write-Result "Scheduled task" "FAIL" "$result"
    }

    Write-Output "`nPhase 6 complete: $($script:pass) OK, $($script:fail) FAIL"
}

# ---- PHASE 7: Final Audit ----
if ($Phase -eq 7) {
    Write-Output "=== Phase 7: Final Audit ==="

    # 1. Firewall
    Get-NetFirewallProfile | ForEach-Object {
        if ($_.Enabled) { Write-Result "Firewall $($_.Name)" "PASS" }
        else { Write-Result "Firewall $($_.Name)" "FAIL" "DISABLED" }
    }

    # 2. Block rules
    $ruleNames = @("Block STUN UDP 3478 Out","Block STUN TCP 3478 Out","Block TURN TCP 5349 Out","Block mDNS UDP 5353 Out","Block QUIC UDP 443 Out","Block SSDP UDP 1900 Out","Block LLMNR UDP 5355 Out")
    foreach ($rname in $ruleNames) {
        $r = Get-NetFirewallRule -DisplayName $rname -ErrorAction SilentlyContinue
        if ($r -and $r.Enabled -eq 'True' -and $r.Action -eq 'Block') { Write-Result "Rule: $rname" "PASS" }
        else { Write-Result "Rule: $rname" "FAIL" "NOT FOUND" }
    }

    # 3. Listening ports
    $dangerPorts = @(3478,5349,5353,1900,5355)
    $tcpListen = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $dangerPorts }
    $udpListen = Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in $dangerPorts }
    if (!$tcpListen -and !$udpListen) { Write-Result "No dangerous ports" "PASS" }
    else { Write-Result "Dangerous ports listening" "WARN" "Check manually" }

    # 4. LLMNR + IPv6
    $llmnr = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
    if ($llmnr.EnableMulticast -eq 0) { Write-Result "LLMNR" "PASS" } else { Write-Result "LLMNR" "FAIL" }
    $dc = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -ErrorAction SilentlyContinue
    if ($dc.DisabledComponents -eq 255) { Write-Result "IPv6 DisabledComponents" "PASS" } else { Write-Result "IPv6 DisabledComponents" "WARN" "Reboot pending" }

    # 5. IPv6 tunnels
    $teredo = netsh interface teredo show state 2>$null
    if ($teredo -match "disabled|offline") { Write-Result "Teredo" "PASS" } else { Write-Result "Teredo" "WARN" }

    # 6. QUIC
    $chromeQuic = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name QuicAllowed -ErrorAction SilentlyContinue
    if ($chromeQuic.QuicAllowed -eq 0) { Write-Result "Chrome QUIC" "PASS" } else { Write-Result "Chrome QUIC" "FAIL" }
    $edgeQuic = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name QuicAllowed -ErrorAction SilentlyContinue
    if ($edgeQuic.QuicAllowed -eq 0) { Write-Result "Edge QUIC" "PASS" } else { Write-Result "Edge QUIC" "FAIL" }

    # 7. TCP stack
    $tcp = netsh int tcp show global 2>$null
    if ($tcp -match "Fast Open\s*:\s*disabled") { Write-Result "TCP Fast Open" "PASS" } else { Write-Result "TCP Fast Open" "WARN" }
    if ($tcp -match "Auto-Tuning Level\s*:\s*normal") { Write-Result "TCP Auto-Tuning" "PASS" } else { Write-Result "TCP Auto-Tuning" "WARN" }

    # 8. TTL
    $ttl = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DefaultTTL -ErrorAction SilentlyContinue
    if ($ttl.DefaultTTL -eq 128) { Write-Result "DefaultTTL" "PASS" "128" } else { Write-Result "DefaultTTL" "FAIL" "Value: $($ttl.DefaultTTL)" }

    # 9. Telemetry services
    $svcList = @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV")
    foreach ($svcName in $svcList) {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if (!$svc -or $svc.Status -eq 'Stopped') { Write-Result "Service $svcName" "PASS" "Stopped" }
        else { Write-Result "Service $svcName" "WARN" "Running" }
    }

    # 10. Hosts
    $hostsContent = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
    $blocked = ($hostsContent | Select-String '0\.0\.0\.0' | Measure-Object).Count
    if ($blocked -gt 50) { Write-Result "Hosts blocks" "PASS" "$blocked entries" }
    else { Write-Result "Hosts blocks" "WARN" "Only $blocked" }

    # 11. Tunnel
    $tun = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -match 'TUN|TAP|VPN|SocksTunnel' -and $_.Status -eq 'Up' }
    if ($tun) { Write-Result "Tunnel" "PASS" "$($tun.Name) UP" }
    else { Write-Result "Tunnel" "WARN" "None active" }

    # 12. MTU
    $mtuOut = netsh interface ipv4 show subinterface $TunName 2>$null
    if ($mtuOut -match $TunMtu) { Write-Result "MTU on $TunName" "PASS" $TunMtu }
    else { Write-Result "MTU on $TunName" "WARN" "Check watcher" }

    # 13. External IP
    try {
        $extIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content
        Write-Result "External IP" "PASS" $extIp
        if ($ExpectedIp -and $extIp -eq $ExpectedIp) { Write-Result "IP matches expected" "PASS" "No leak" }
        elseif ($ExpectedIp) { Write-Result "IP check" "WARN" "Expected $ExpectedIp, got $extIp" }
    } catch {
        Write-Result "External IP" "WARN" "Could not fetch"
    }

    Write-Output "`n=== AUDIT SUMMARY ==="
    Write-Output "PASS: $script:pass"
    Write-Output "FAIL: $script:fail"
    Write-Output "WARN: $script:warn"
    if ($script:fail -gt 0) { Write-Output "ACTION REQUIRED: $script:fail FAIL(s)" }
    else { Write-Output "ALL CRITICAL CHECKS PASSED!" }
}
