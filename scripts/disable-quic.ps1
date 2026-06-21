# Фаза 2: Полное отключение QUIC на всех уровнях
# Запускать от администратора

Write-Host "=== Phase 2: Disabling QUIC Completely ===" -ForegroundColor Cyan

# 1. Служба msquic
Write-Host "[1] Stopping msquic service..." -ForegroundColor Yellow
Stop-Service -Name "msquic" -Force -ErrorAction SilentlyContinue
Set-Service -Name "msquic" -StartupType Disabled -ErrorAction SilentlyContinue
Write-Host "    [OK] msquic service disabled" -ForegroundColor Green

# 2. HTTP/3 в HTTP.sys
Write-Host "[2] Disabling HTTP/3 in HTTP.sys..." -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name "EnableHttp3" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] HTTP/3 disabled" -ForegroundColor Green

# 3. QUIC в Schannel
Write-Host "[3] Disabling QUIC in Schannel..." -ForegroundColor Yellow
$schannelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\QUIC"
if (!(Test-Path $schannelPath)) { New-Item -Path $schannelPath -Force | Out-Null }
New-ItemProperty -Path $schannelPath -Name "Enabled" -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $schannelPath -Name "DisabledByDefault" -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] QUIC disabled in Schannel" -ForegroundColor Green

# 4. WinINET (system + user)
Write-Host "[4] Disabling QUIC in WinINET..." -ForegroundColor Yellow
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] WinINET QUIC disabled" -ForegroundColor Green

# 5. Edge policy
Write-Host "[5] Disabling QUIC in Edge..." -ForegroundColor Yellow
$edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (!(Test-Path $edgePath)) { New-Item -Path $edgePath -Force | Out-Null }
New-ItemProperty -Path $edgePath -Name "QuicAllowed" -Value 0 -PropertyType DWORD -Force | Out-Null
$edgePathUser = "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
if (!(Test-Path $edgePathUser)) { New-Item -Path $edgePathUser -Force | Out-Null }
New-ItemProperty -Path $edgePathUser -Name "QuicAllowed" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] Edge QUIC disabled" -ForegroundColor Green

# 6. Chrome policy
Write-Host "[6] Disabling QUIC in Chrome..." -ForegroundColor Yellow
$chromePath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
if (!(Test-Path $chromePath)) { New-Item -Path $chromePath -Force | Out-Null }
New-ItemProperty -Path $chromePath -Name "QuicAllowed" -Value 0 -PropertyType DWORD -Force | Out-Null
$chromePathUser = "HKCU:\SOFTWARE\Policies\Google\Chrome"
if (!(Test-Path $chromePathUser)) { New-Item -Path $chromePathUser -Force | Out-Null }
New-ItemProperty -Path $chromePathUser -Name "QuicAllowed" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] Chrome QUIC disabled" -ForegroundColor Green

# 7. Firefox policy
Write-Host "[7] Disabling QUIC in Firefox..." -ForegroundColor Yellow
$ffPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"
if (!(Test-Path $ffPath)) { New-Item -Path $ffPath -Force | Out-Null }
New-ItemProperty -Path $ffPath -Name "DisableHttp3" -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] Firefox HTTP/3 disabled" -ForegroundColor Green

# 8. Блокировка UDP 443 (QUIC порт)
Write-Host "[8] Blocking UDP 443 outbound..." -ForegroundColor Yellow
$existing = Get-NetFirewallRule -DisplayName "Block QUIC UDP 443 Out" -ErrorAction SilentlyContinue
if (!$existing) {
    New-NetFirewallRule -DisplayName "Block QUIC UDP 443 Out" -Direction Outbound -Action Block -Protocol UDP -RemotePort 443 | Out-Null
    Write-Host "    [+] UDP 443 blocked" -ForegroundColor Green
} else {
    Write-Host "    [OK] UDP 443 block exists" -ForegroundColor Green
}

# 9. WinHTTP
Write-Host "[9] Disabling HTTP/3 in WinHTTP..." -ForegroundColor Yellow
$winhttpPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHttp"
if (!(Test-Path $winhttpPath)) { New-Item -Path $winhttpPath -Force | Out-Null }
New-ItemProperty -Path $winhttpPath -Name "EnableHttp3" -Value 0 -PropertyType DWORD -Force | Out-Null
Write-Host "    [OK] WinHTTP HTTP/3 disabled" -ForegroundColor Green

# 10. msquic драйвер
Write-Host "[10] Disabling msquic driver..." -ForegroundColor Yellow
$msquicDriver = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\msquic" -ErrorAction SilentlyContinue
if ($msquicDriver) {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\msquic" -Name "Start" -Value 4 -PropertyType DWORD -Force | Out-Null
    Write-Host "    [OK] msquic driver Start=4" -ForegroundColor Green
} else {
    Write-Host "    [OK] msquic driver not found" -ForegroundColor Green
}

Write-Host "`n=== Phase 2 Complete ===" -ForegroundColor Cyan
Write-Host "Reboot recommended for full effect." -ForegroundColor Yellow
