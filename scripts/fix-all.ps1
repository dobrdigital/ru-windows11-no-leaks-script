# Фаза 5b: Остановка лишних служб + блокировка SSDP/LLMNR + mDNS off
# Запускать от администратора

Write-Host "=== Phase 5b: Services & Network Discovery ===" -ForegroundColor Cyan

# 1. Службы для остановки и отключения
Write-Host "[1] Disabling risky services..." -ForegroundColor Yellow
$services = @("lfsvc","SharedAccess","SSDPSRV","fdPHost","upnphost","FDResPub","WMPNetworkSvc")
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction Stop
            Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
            Write-Host "    [OK] $svc stopped + disabled" -ForegroundColor Green
        } catch {
            Write-Host "    [WARN] $svc : $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [OK] $svc not installed" -ForegroundColor Green
    }
}

# 2. mDNS off через DNS Client
Write-Host "[2] Disabling mDNS via DNS Client..." -ForegroundColor Yellow
$dnsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"
if (!(Test-Path $dnsPath)) { New-Item -Path $dnsPath -Force | Out-Null }
New-ItemProperty -Path $dnsPath -Name "EnableMDNS" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] EnableMDNS=0" -ForegroundColor Green

# 3. LLMNR повторно
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name "EnableMulticast" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] LLMNR EnableMulticast=0" -ForegroundColor Green

# 4. Блокировка SSDP UDP 1900 исходящий
Write-Host "[4] Blocking SSDP UDP 1900 outbound..." -ForegroundColor Yellow
if (!(Get-NetFirewallRule -DisplayName "Block SSDP UDP 1900 Out" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Block SSDP UDP 1900 Out" -Direction Outbound -Action Block -Protocol UDP -RemotePort 1900 | Out-Null
    Write-Host "    [+] SSDP UDP 1900 blocked" -ForegroundColor Green
} else {
    Write-Host "    [OK] SSDP block exists" -ForegroundColor Green
}

# 5. Блокировка LLMNR UDP 5355 исходящий
Write-Host "[5] Blocking LLMNR UDP 5355 outbound..." -ForegroundColor Yellow
if (!(Get-NetFirewallRule -DisplayName "Block LLMNR UDP 5355 Out" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "Block LLMNR UDP 5355 Out" -Direction Outbound -Action Block -Protocol UDP -RemotePort 5355 | Out-Null
    Write-Host "    [+] LLMNR UDP 5355 blocked" -ForegroundColor Green
} else {
    Write-Host "    [OK] LLMNR block exists" -ForegroundColor Green
}

Write-Host "`n=== Phase 5b Complete ===" -ForegroundColor Cyan
