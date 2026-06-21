# Финальный аудит утечек: 17 категорий проверок
# Запускать можно без админа (но часть проверок будет косвенной).

$ErrorActionPreference = "SilentlyContinue"
$script:pass = 0
$script:fail = 0
$script:warn = 0

function Print-Result($name, $status, $detail) {
    $color = switch ($status) {
        "PASS" { $script:pass++; "Green" }
        "FAIL" { $script:fail++; "Red" }
        "WARN" { $script:warn++; "Yellow" }
    }
    Write-Host "[$status] $name" -ForegroundColor $color
    if ($detail) { Write-Host "       $detail" -ForegroundColor Gray }
}

# Имя TUN-адаптера — измени под себя
$tunName = "happ-default-tun"
$expectedIp = $null   # если известно — впиши IP VPS для проверки совпадения

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   FINAL LEAK AUDIT - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "   TUN adapter: $tunName" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "--- 1. FIREWALL ---" -ForegroundColor White
Get-NetFirewallProfile | ForEach-Object {
    if ($_.Enabled) { Print-Result "Profile $($_.Name) enabled" "PASS" }
    else { Print-Result "Profile $($_.Name) enabled" "FAIL" "DISABLED" }
}

Write-Host ""
Write-Host "--- 2. FIREWALL BLOCK RULES ---" -ForegroundColor White
$rules = @("Block STUN UDP 3478 Out","Block STUN TCP 3478 Out","Block TURN TCP 5349 Out","Block mDNS UDP 5353 Out","Block QUIC UDP 443 Out")
foreach ($rname in $rules) {
    $r = Get-NetFirewallRule -DisplayName $rname -ErrorAction SilentlyContinue
    if ($r -and $r.Enabled -eq 'True' -and $r.Action -eq 'Block') { Print-Result "Rule: $rname" "PASS" }
    elseif ($r) { Print-Result "Rule: $rname" "FAIL" "Disabled" }
    else { Print-Result "Rule: $rname" "FAIL" "NOT FOUND" }
}

Write-Host ""
Write-Host "--- 3. LISTENING PORTS ---" -ForegroundColor White
$tcpListen = Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in @(3478,5349,5353,1900) }
if (!$tcpListen) { Print-Result "No dangerous TCP ports" "PASS" }
else { foreach ($c in $tcpListen) { Print-Result "TCP $($c.LocalPort) listening" "WARN" "PID $($c.OwningProcess)" } }
$udpListen = Get-NetUDPEndpoint | Where-Object { $_.LocalPort -in @(3478,5349,5353,1900,5355) }
if (!$udpListen) { Print-Result "No dangerous UDP ports" "PASS" }
else { foreach ($c in $udpListen) { $p = (Get-Process -Id $c.OwningProcess).ProcessName; Print-Result "UDP $($c.LocalPort) listening" "WARN" $p } }

Write-Host ""
Write-Host "--- 4. LLMNR / IPv6 ---" -ForegroundColor White
$llmnr = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
if ($llmnr.EnableMulticast -eq 0) { Print-Result "LLMNR disabled" "PASS" } else { Print-Result "LLMNR disabled" "FAIL" "Active" }
$dc = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -ErrorAction SilentlyContinue
if ($dc.DisabledComponents -eq 255) { Print-Result "IPv6 DisabledComponents=0xFF" "PASS" } else { Print-Result "IPv6 DisabledComponents" "FAIL" "Value: $($dc.DisabledComponents)" }
$ipv6bind = Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object { $_.Enabled }
if (!$ipv6bind) { Print-Result "No adapters with IPv6 enabled" "PASS" }
else { Print-Result "IPv6 binding active" "FAIL" ($ipv6bind.Name -join ',') }

Write-Host ""
Write-Host "--- 5. IPv6 TUNNELS ---" -ForegroundColor White
$teredo = netsh interface teredo show state 2>$null
if ($teredo -match "disabled|offline") { Print-Result "Teredo" "PASS" } else { Print-Result "Teredo" "WARN" "Active" }
$isatap = netsh interface isatap show state 2>$null
if ($isatap -match "disabled") { Print-Result "ISATAP" "PASS" } else { Print-Result "ISATAP" "WARN" }
$to4 = netsh interface 6to4 show state 2>$null
if ($to4 -match "disabled") { Print-Result "6to4" "PASS" } else { Print-Result "6to4" "WARN" }

Write-Host ""
Write-Host "--- 6. DNS ---" -ForegroundColor White
$dnsServers = Get-DnsClientServerAddress | Where-Object { $_.AddressFamily -eq 2 -and $_.ServerAddresses.Count -gt 0 }
foreach ($d in $dnsServers) {
    foreach ($s in $d.ServerAddresses) {
        if ($s -match '^(192\.168|10\.|127\.)') { Print-Result "DNS $($d.InterfaceAlias): $s" "PASS" "Local" }
        else { Print-Result "DNS $($d.InterfaceAlias): $s" "WARN" "Verify" }
    }
}

Write-Host ""
Write-Host "--- 7. PROXY ---" -ForegroundColor White
$proxy = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
if ($proxy.ProxyEnable -eq 1) { Print-Result "System proxy" "PASS" $proxy.ProxyServer }
else { Print-Result "System proxy" "PASS" "Direct/VPN" }

Write-Host ""
Write-Host "--- 8. ACTIVE STUN/TURN ---" -ForegroundColor White
$active = Get-NetTCPConnection -State Established | Where-Object { $_.RemotePort -in @(3478,5349,5353) }
if (!$active) { Print-Result "No active STUN/TURN connections" "PASS" }
else { foreach ($a in $active) { Print-Result "Active STUN/TURN" "FAIL" "$($a.RemoteAddress):$($a.RemotePort)" } }

Write-Host ""
Write-Host "--- 9. HOSTS FILE ---" -ForegroundColor White
$hostsContent = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" | Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' }
$blocked = ($hostsContent | Select-String '0\.0\.0\.0' | Measure-Object).Count
if ($blocked -gt 100) { Print-Result "Hosts telemetry blocks" "PASS" "$blocked entries" }
else { Print-Result "Hosts telemetry blocks" "WARN" "Only $blocked" }

Write-Host ""
Write-Host "--- 10. TUNNEL / VPN ---" -ForegroundColor White
$tun = Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'TUN|TAP|VPN|SocksTunnel' -and $_.Status -eq 'Up' }
if ($tun) { foreach ($t in $tun) { Print-Result "Tunnel: $($t.Name)" "PASS" "$($t.InterfaceDescription) UP" } }
else { Print-Result "Tunnel/VPN" "WARN" "None active" }

Write-Host ""
Write-Host "--- 11. MTU ---" -ForegroundColor White
$mtuOut = netsh interface ipv4 show subinterface $tunName 2>$null
if ($mtuOut -match "1380") { Print-Result "MTU on $tunName" "PASS" "1380" }
else { Print-Result "MTU on $tunName" "FAIL" "Not 1380 (check watcher)" }

Write-Host ""
Write-Host "--- 12. QUIC ---" -ForegroundColor White
$chromeQuic = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name QuicAllowed -ErrorAction SilentlyContinue
if ($chromeQuic.QuicAllowed -eq 0) { Print-Result "Chrome QUIC disabled" "PASS" } else { Print-Result "Chrome QUIC disabled" "FAIL" }
$edgeQuic = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name QuicAllowed -ErrorAction SilentlyContinue
if ($edgeQuic.QuicAllowed -eq 0) { Print-Result "Edge QUIC disabled" "PASS" } else { Print-Result "Edge QUIC disabled" "FAIL" }
$msquic = Get-Service -Name msquic -ErrorAction SilentlyContinue
if (!$msquic -or $msquic.StartType -eq 'Disabled') { Print-Result "msquic service" "PASS" "Disabled" } else { Print-Result "msquic service" "FAIL" "Running" }
$http3 = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name EnableHttp3 -ErrorAction SilentlyContinue
if ($http3.EnableHttp3 -eq 0) { Print-Result "HTTP/3 (HTTP.sys)" "PASS" "Disabled" } else { Print-Result "HTTP/3 (HTTP.sys)" "FAIL" }

Write-Host ""
Write-Host "--- 13. TCP STACK ---" -ForegroundColor White
$tcp = netsh int tcp show global
if ($tcp -match "Fast Open\s*:\s*disabled") { Print-Result "TCP Fast Open" "PASS" "Disabled" } else { Print-Result "TCP Fast Open" "WARN" }
if ($tcp -match "Auto-Tuning Level\s*:\s*normal") { Print-Result "TCP Auto-Tuning" "PASS" "Normal" } else { Print-Result "TCP Auto-Tuning" "WARN" }
if ($tcp -match "ECN Capability\s*:\s*disabled") { Print-Result "ECN" "PASS" "Disabled" } else { Print-Result "ECN" "WARN" }
if ($tcp -match "RFC 1323 Timestamps\s*:\s*disabled") { Print-Result "RFC 1323 Timestamps" "PASS" "Disabled" } else { Print-Result "RFC 1323 Timestamps" "WARN" }

Write-Host ""
Write-Host "--- 14. TTL ---" -ForegroundColor White
$ttl = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DefaultTTL -ErrorAction SilentlyContinue
if ($ttl.DefaultTTL -eq 128) { Print-Result "DefaultTTL" "PASS" "128 (Windows)" } else { Print-Result "DefaultTTL" "FAIL" "Value: $($ttl.DefaultTTL)" }

Write-Host ""
Write-Host "--- 15. TELEMETRY SERVICES ---" -ForegroundColor White
$services = @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV")
foreach ($svcName in $services) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if (!$svc) { Print-Result "Service $svcName" "PASS" "Not installed" }
    elseif ($svc.Status -eq 'Running') { Print-Result "Service $svcName" "WARN" "Running" }
    else { Print-Result "Service $svcName" "PASS" "Stopped" }
}

Write-Host ""
Write-Host "--- 16. WATCHER TASK ---" -ForegroundColor White
# Косвенная проверка: обычный пользователь не может запросить SYSTEM task (Access denied).
# Если MTU=1380 и IPv6 disabled на туннеле — watcher работает.
$mtuCheck = netsh interface ipv4 show subinterface $tunName 2>$null
$ipv6bind = Get-NetAdapterBinding -Name $tunName -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
if ($mtuCheck -match "1380" -and $ipv6bind -and -not $ipv6bind.Enabled) {
    Print-Result "HappMtuWatcher task" "PASS" "Working (MTU=1380 + IPv6 disabled on tunnel)"
} else {
    Print-Result "HappMtuWatcher task" "FAIL" "MTU or IPv6 not maintained"
}

Write-Host ""
Write-Host "--- 17. IP LEAK CHECK (external) ---" -ForegroundColor White
try {
    $extIp = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content
    Print-Result "External IP" "PASS" $extIp
    if ($expectedIp -and $extIp -eq $expectedIp) { Print-Result "IP matches expected tunnel IP" "PASS" "No leak" }
    elseif ($expectedIp) { Print-Result "IP check" "FAIL" "Expected $expectedIp, got $extIp" }
    else { Print-Result "IP check" "PASS" "Verify manually on browserleaks.com/ip" }
} catch {
    Print-Result "External IP fetch" "WARN" "Could not fetch"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   SUMMARY" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   PASS: $script:pass" -ForegroundColor Green
Write-Host "   FAIL: $script:fail" -ForegroundColor Red
Write-Host "   WARN: $script:warn" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
if ($script:fail -gt 0) { Write-Host "`n   ACTION REQUIRED: $($script:fail) FAIL(s)" -ForegroundColor Red }
elseif ($script:warn -gt 0) { Write-Host "`n   $($script:warn) warning(s) to review" -ForegroundColor Yellow }
else { Write-Host "`n   ALL CHECKS PASSED!" -ForegroundColor Green }
Write-Host ""
