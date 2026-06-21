# Фаза 3: Полное отключение IPv6 (биндинги, туннели, реестр)
# Запускать от администратора. Требует ребута для DisabledComponents.

Write-Host "=== Phase 3: Disabling IPv6 Completely ===" -ForegroundColor Cyan

# 1. IPv6 биндинг на всех адаптерах
Write-Host "[1] Disabling IPv6 binding on all adapters..." -ForegroundColor Yellow
Disable-NetAdapterBinding -Name "*" -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
Write-Host "    [OK] IPv6 binding disabled" -ForegroundColor Green

# 2. Teredo
Write-Host "[2] Disabling Teredo..." -ForegroundColor Yellow
netsh interface teredo set state disabled 2>$null
Write-Host "    [OK] Teredo disabled" -ForegroundColor Green

# 3. 6to4
Write-Host "[3] Disabling 6to4..." -ForegroundColor Yellow
netsh interface 6to4 set state state=disabled undoonstop=disabled 2>$null
Write-Host "    [OK] 6to4 disabled" -ForegroundColor Green

# 4. ISATAP
Write-Host "[4] Disabling ISATAP..." -ForegroundColor Yellow
netsh interface isatap set state state=disabled 2>$null
Write-Host "    [OK] ISATAP disabled" -ForegroundColor Green

# 5. IP-HTTPS
Write-Host "[5] Disabling IP-HTTPS..." -ForegroundColor Yellow
netsh interface httpstunnel set state state=disabled 2>$null
Write-Host "    [OK] IP-HTTPS disabled" -ForegroundColor Green

# 6. DisabledComponents = 0xFF (глобально)
Write-Host "[6] Setting IPv6 DisabledComponents=0xFF..." -ForegroundColor Yellow
$tcpip6Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
if (!(Test-Path $tcpip6Path)) { New-Item -Path $tcpip6Path -Force | Out-Null }
New-ItemProperty -Path $tcpip6Path -Name "DisabledComponents" -Value 0xFF -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] DisabledComponents=0xFF" -ForegroundColor Green

# 7. DisableSmartNameResolution
Write-Host "[7] Disabling smart name resolution..." -ForegroundColor Yellow
$dnsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $dnsPolicyPath)) { New-Item -Path $dnsPolicyPath -Force | Out-Null }
New-ItemProperty -Path $dnsPolicyPath -Name "DisableSmartNameResolution" -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] DisableSmartNameResolution=1" -ForegroundColor Green

# 8. IPv6 на туннельных адаптерах
Write-Host "[8] Disabling IPv6 on tunnel adapters..." -ForegroundColor Yellow
Get-NetAdapter | Where-Object { $_.InterfaceDescription -match 'TUN|TAP|VPN|Tunnel|Socks' } | ForEach-Object {
    Disable-NetAdapterBinding -Name $_.Name -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
    Write-Host "    [OK] IPv6 disabled on: $($_.Name)" -ForegroundColor Green
}

# Проверка
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
$ipv6Adapters = Get-NetAdapterBinding -ComponentID "ms_tcpip6" | Where-Object { $_.Enabled -eq $true }
if (!$ipv6Adapters) {
    Write-Host "[PASS] No adapters with IPv6 enabled" -ForegroundColor Green
} else {
    Write-Host "[WARN] Some adapters still have IPv6:" -ForegroundColor Yellow
    $ipv6Adapters | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Yellow }
}

Write-Host "`n=== Phase 3 Complete ===" -ForegroundColor Cyan
Write-Host "REBOOT REQUIRED for DisabledComponents to take full effect." -ForegroundColor Yellow
