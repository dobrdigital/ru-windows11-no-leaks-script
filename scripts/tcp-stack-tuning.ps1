# Фаза 4: Тюнинг TCP стека для стабильности туннеля и Windows fingerprint
# Запускать от администратора. Требует ребута.

Write-Host "=== Phase 4: TCP Stack Tuning ===" -ForegroundColor Cyan

# 1. netsh TCP global
Write-Host "[1] Setting TCP global parameters..." -ForegroundColor Yellow
$tcpSettings = @(
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
foreach ($setting in $tcpSettings) {
    $result = netsh int tcp set global $setting 2>&1
    if ($result -match "OK") {
        Write-Host "    [OK] $setting" -ForegroundColor Green
    } else {
        Write-Host "    [WARN] $setting : $result" -ForegroundColor Yellow
    }
}

# 2. Реестр Tcpip\Parameters
Write-Host "[2] Setting TCP/IP registry parameters..." -ForegroundColor Yellow
$tcpipParams = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"

$regSettings = @{
    "KeepAliveTime"             = 60000
    "KeepAliveInterval"         = 1000
    "TcpMaxDataRetransmissions" = 5
    "SackOpts"                  = 1
    "Tcp1323Opts"               = 1
    "DefaultTTL"                = 128      # Windows fingerprint! (Linux=64)
    "TcpTimedWaitDelay"         = 30
    "MaxUserPort"               = 65534
    "TcpNumConnections"         = 16777214
    "SynAttackProtect"          = 1
    "TcpMaxPortsExhausted"      = 5
    "DisableIPSourceRouting"    = 2
    "EnableDeadGWDetect"        = 0
    "EnablePMTUDiscovery"       = 1
    "EnablePMTUBHDetect"        = 0
    "ForwardBufferMemory"       = 65536
    "MaxForwardBufferMemory"    = 131072
    "MaxFreeTcbs"               = 65536
    "MaxHashTableSize"          = 65536
    "NumTcbTablePartitions"     = 8
    "MaxDupAcks"                = 2
    "DisableTaskOffload"        = 1
    "EnableECN"                 = 0
    "EnableHeuristics"          = 0
}

foreach ($name in $regSettings.Keys) {
    New-ItemProperty -Path $tcpipParams -Name $name -Value $regSettings[$name] -PropertyType DWORD -Force | Out-Null
    Write-Host "    [OK] $name = $($regSettings[$name])" -ForegroundColor Green
}

# 3. Отключение Nagle на всех интерфейсах (низкая задержка)
Write-Host "[3] Disabling Nagle algorithm..." -ForegroundColor Yellow
$adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
foreach ($adapter in $adapters) {
    New-ItemProperty -Path $adapter.PSPath -Name "TcpAckFrequency" -Value 1 -PropertyType DWORD -Force | Out-Null
    New-ItemProperty -Path $adapter.PSPath -Name "TCPNoDelay" -Value 1 -PropertyType DWORD -Force | Out-Null
}
Write-Host "    [OK] Nagle disabled on all interfaces" -ForegroundColor Green

Write-Host "`n=== Phase 4 Complete ===" -ForegroundColor Cyan
Write-Host "REBOOT REQUIRED for full effect." -ForegroundColor Yellow
