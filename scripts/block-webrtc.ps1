# Фаза 1: Блокировка утечек WebRTC/STUN/TURN/mDNS + включение файрвола + отключение LLMNR
# Запускать от администратора

Write-Host "=== Phase 1: WebRTC/STUN/TURN/mDNS Blocking ===" -ForegroundColor Cyan

# Включаем файрвол на всех профилях
Write-Host "[1] Enabling firewall on all profiles..." -ForegroundColor Yellow
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True
Write-Host "    [OK] All profiles enabled" -ForegroundColor Green

# Правила блокировки
$rules = @(
    @{Name='Block STUN UDP 3478 Out'; Proto='UDP'; Port=3478},
    @{Name='Block STUN TCP 3478 Out'; Proto='TCP'; Port=3478},
    @{Name='Block TURN TCP 5349 Out'; Proto='TCP'; Port=5349},
    @{Name='Block mDNS UDP 5353 Out'; Proto='UDP'; Port=5353}
)

Write-Host "[2] Creating firewall block rules..." -ForegroundColor Yellow
foreach ($r in $rules) {
    $existing = Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue
    if (!$existing) {
        New-NetFirewallRule -DisplayName $r.Name -Direction Outbound -Action Block -Protocol $r.Proto -RemotePort $r.Port | Out-Null
        Write-Host "    [+] Created: $($r.Name)" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Exists: $($r.Name)" -ForegroundColor Green
    }
}

# Отключаем LLMNR
Write-Host "[3] Disabling LLMNR..." -ForegroundColor Yellow
$dnsClientPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
if (!(Test-Path $dnsClientPath)) { New-Item -Path $dnsClientPath -Force | Out-Null }
Set-ItemProperty -Path $dnsClientPath -Name "EnableMulticast" -Value 0 -Type DWord -Force
Write-Host "    [OK] LLMNR disabled" -ForegroundColor Green

# Отключаем NBT-NS на адаптерах
Write-Host "[4] Disabling NBT-NS on adapters..." -ForegroundColor Yellow
$adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
foreach ($adapter in $adapters) { $adapter.SetTcpipNetbios(2) | Out-Null }
Write-Host "    [OK] NBT-NS disabled" -ForegroundColor Green

Write-Host "`n=== Phase 1 Complete ===" -ForegroundColor Cyan
