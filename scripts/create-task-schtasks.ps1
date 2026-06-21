# Создаёт Scheduled Task "HappMtuWatcher" — запускает mtu-watcher.ps1 при входе от SYSTEM.
# Запускать от администратора.
#
# Перед запуском:
#   1. Отредактируй scripts/mtu-watcher.ps1 — впиши имя своего TUN-адаптера ($tunName).
#   2. Убедись что путь к mtu-watcher.ps1 ниже правильный.

$watcherPath = "C:\Users\DOBR\.pi\agent\skills\windows-russia-anti-dpi\scripts\mtu-watcher.ps1"
# ^^ ИЗМЕНИ путь если скилл установлен в другое место, или скопируй mtu-watcher.ps1 в стабильное место.

Write-Host "=== Creating HappMtuWatcher Scheduled Task ===" -ForegroundColor Cyan
Write-Host "Watcher script: $watcherPath" -ForegroundColor Gray

if (!(Test-Path $watcherPath)) {
    Write-Host "[FAIL] Watcher script not found at $watcherPath" -ForegroundColor Red
    Write-Host "       Edit this script and set the correct path." -ForegroundColor Yellow
    exit 1
}

# Удаляем старую задачу
Unregister-ScheduledTask -TaskName "HappMtuWatcher" -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "[OK] Old task removed (if existed)" -ForegroundColor Green

# Создаём через schtasks (надёжнее чем Register-ScheduledTask, который иногда невидим из обычной сессии)
$result = schtasks /create /tn "HappMtuWatcher" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watcherPath`"" /sc onlogon /rl highest /ru SYSTEM /f 2>&1
Write-Host $result -ForegroundColor Gray

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Task created" -ForegroundColor Green
    schtasks /run /tn "HappMtuWatcher" 2>&1 | Out-Null
    Write-Host "[OK] Task started" -ForegroundColor Green
    Start-Sleep -Seconds 2
    $status = schtasks /query /tn "HappMtuWatcher" /fo LIST 2>&1 | Select-String "Status"
    Write-Host "Status: $($status.ToString().Trim())" -ForegroundColor Cyan
} else {
    Write-Host "[FAIL] Task creation failed" -ForegroundColor Red
}

Write-Host "`nNOTE: To verify the task from a non-admin session, check indirectly:" -ForegroundColor Yellow
Write-Host "  netsh interface ipv4 show subinterface `"<tun-name>`"   # should show MTU 1380" -ForegroundColor Gray
Write-Host "  Get-NetAdapterBinding -Name `"<tun-name>`" -ComponentID ms_tcpip6  # Enabled: False" -ForegroundColor Gray
Write-Host "Get-ScheduledTask may return 'Access denied' for SYSTEM tasks from non-admin sessions." -ForegroundColor Yellow
