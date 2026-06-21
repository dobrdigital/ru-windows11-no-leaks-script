# Фаза 5a: Отключение телеметрии + блокировка доменов в hosts
# Запускать от администратора

Write-Host "=== Phase 5a: Telemetry Hardening ===" -ForegroundColor Cyan

# 1. Службы телеметрии
Write-Host "[1] Disabling telemetry services..." -ForegroundColor Yellow
$services = @('DiagTrack', 'dmwappushservice', 'WMPNetworkSvc', 'wisvc')
foreach ($svc in $services) {
    $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "    [OK] Disabled: $svc" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Not found: $svc" -ForegroundColor Green
    }
}

# 2. Домены телеметрии в hosts
Write-Host "[2] Blocking telemetry domains in hosts..." -ForegroundColor Yellow
$domains = @(
    'v10.events.data.microsoft.com',
    'settings-win.data.microsoft.com',
    'diagnostics.support.microsoft.com',
    'vortex.data.microsoft.com',
    'telemetry.microsoft.com',
    'oca.telemetry.microsoft.com',
    'sqm.telemetry.microsoft.com',
    'watson.telemetry.microsoft.com',
    'redir.metaservices.microsoft.com',
    'choice.microsoft.com',
    'df.telemetry.microsoft.com',
    'reports.wes.df.telemetry.microsoft.com',
    'services.wes.df.telemetry.microsoft.com',
    'sqm.df.telemetry.microsoft.com',
    'telemetry.appex.bing.net',
    'telemetry.urs.microsoft.com',
    'settings.data.glbdns2.microsoft.com',
    'browser.events.data.microsoft.com',
    'events.data.microsoft.com'
)
$hostsPath = "$env:windir\System32\drivers\etc\hosts"
foreach ($domain in $domains) {
    if (-not (Select-String -Path $hostsPath -Pattern $domain -Quiet)) {
        Add-Content -Path $hostsPath -Value "0.0.0.0 $domain"
        Write-Host "    [+] Blocked: $domain" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Already: $domain" -ForegroundColor Green
    }
}

# 3. Input TIPC off
Write-Host "[3] Disabling Input TIPC..." -ForegroundColor Yellow
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Input\TIPC' -Name 'Enabled' -Value 0 -Type DWord -Force
Write-Host "    [OK] Input TIPC disabled" -ForegroundColor Green

# 4. Advertising ID
Write-Host "[4] Disabling Advertising ID..." -ForegroundColor Yellow
New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] Advertising ID disabled" -ForegroundColor Green

# 5. Cortana / Cloud search
Write-Host "[5] Disabling Cortana and cloud search..." -ForegroundColor Yellow
$cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (!(Test-Path $cortanaPath)) { New-Item -Path $cortanaPath -Force | Out-Null }
New-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $cortanaPath -Name "AllowCloudSearch" -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $cortanaPath -Name "AllowSearchToUseLocation" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] Cortana/cloud search disabled" -ForegroundColor Green

Write-Host "`n=== Phase 5a Complete ===" -ForegroundColor Cyan
