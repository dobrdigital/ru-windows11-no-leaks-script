# Troubleshooting — грабли из реальной сессии

## 1. UAC не подтверждается / "Access is denied"

**Симптом:** `Set-NetFirewallRule`, `Set-Service`, `Set-NetIPInterface`, `netsh ... set`, записи в `HKLM:\` падают с `Access is denied`.

**Причина:** команда запущена в обычной сессии PowerShell, а не в elevated.

**Решение:**
```powershell
Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File C:\path\script.ps1'
```
Жми **Да** в UAC-окне. Если случайно отменил — запусти снова.

**Захват вывода из elevated-процесса:** elevated-процесс не возвращает stdout в родительский. Пиши результат в файл:
```powershell
"result" | Out-File "C:\path\to\log.log"
```
и читай его из обычной сессии через `read`.

---

## 2. Bash ломает PowerShell-переменные

**Симптом:**
```
Where-Object : The term '/usr/bin/bash.ProcessName' is not recognized...
foreach ( in ) { ~ Missing variable name after foreach.
```

**Причина:** bash разворачивает `$_`, `$svc` и т.п. до вызова PowerShell. `$_` превращается в путь к bash.

**Решение:** НЕ передавай PowerShell с `$_`/`$var` через `powershell -Command "..."` из bash. Записывай скрипт в `.ps1` файл (через `write`) и выполняй:
```bash
powershell -ExecutionPolicy Bypass -File "C:\path\script.ps1"
```

---

## 3. Git Bash ломает schtasks/netsh аргументы

**Симптом:**
```
ERROR: Invalid argument/option - 'C:/Program Files/Git/query'.
```

**Причина:** Git Bash конвертирует `/query` в Windows-путь.

**Решение:** всегда оборачивай `schtasks`, `netsh` с `/flag` в `.ps1` файл, не вызывай напрямую из bash.

---

## 4. `NlMtuBytes` пустой для TUN-адаптеров

**Симптом:**
```powershell
Get-NetIPInterface -InterfaceAlias "happ-default-tun" | Select NlMtuBytes
# NlMtuBytes пусто
```

**Причина:** баг PowerShell для туннельных/Wintun адаптеров.

**Решение:** проверяй MTU ТОЛЬКО через netsh:
```powershell
netsh interface ipv4 show subinterface "happ-default-tun"
```

---

## 5. HAPP игнорирует `mtu` в config.json

**Симптом:** в `C:\Users\<user>\AppData\Local\happ\config.json` стоит `"mtu": 1380`, но `netsh` показывает 1500.

**Проверка:** поставь `"mtu": 9000`, перезапусти HAPP — если всё равно 1500, значит HAPP игнорирует параметр.

**Причина:** HAPP (SocksTunnel драйвер) ставит MTU 1500 при создании адаптера, параметр конфига не уважает. В логе:
```
[HAPP-TUN] Set interface metric to 0 with ForwardingEnabled and MTU 1500
```

**Решение:** watcher-задача (`scripts/mtu-watcher.ps1` + `create-task-schtasks.ps1`). После старта HAPP watcher меняет MTU обратно на 1380 — и HAPP его НЕ сбрасывает повторно. Проверено: после ручной установки MTU держится 15+ секунд, HAPP не переписывает.

---

## 6. `Get-ScheduledTask` не видит SYSTEM-задачу из обычной сессии

**Симптом:**
```powershell
Get-ScheduledTask -TaskName "HappMtuWatcher"
# Access is denied (или пусто)
```
но `schtasks /query /tn "HappMtuWatcher"` от админа показывает `Status: Running`.

**Причина:** обычный пользователь не может читать SYSTEM-задачи.

**Решение:** в аудите проверяй watcher косвенно — если MTU=1380 и IPv6 disabled на туннеле, значит watcher работает:
```powershell
$mtu = netsh interface ipv4 show subinterface $tunName
$ipv6 = Get-NetAdapterBinding -Name $tunName -ComponentID "ms_tcpip6"
# $mtu -match "1380" AND -not $ipv6.Enabled => watcher работает
```

---

## 7. TCP/IP Fingerprint на browserleaks показывает Android / MTU 1500

**Симптом:** `browserleaks.com/ip` → TCP/IP Fingerprint: OS Android, MTU 1500, MSS 1460.

**Это НЕ утечка.** Browserleaks видит соединение от VPS, а не от твоего ПК:
```
ПК (MTU 1380) → HAPP туннель → VPS (MTU 1500) → browserleaks.com
```
Последний участок (VPS → сайт) определяет fingerprint. Linux-ядро VPS часто определяется как "Android".

**Не пытайся это "исправить"** на клиенте — бесполезно. Чтобы сменить fingerprint, надо тюнить TCP стэк на самом VPS.

---

## 8. IPv6 binding на туннеле включается после рестарта HAPP

**Симптом:** после `Disable-NetAdapterBinding` на `happ-default-tun` IPv6 снова Enabled.

**Причина:** HAPP пересоздаёт адаптер при старте, дефолт = IPv6 on.

**Решение:** тот же watcher (`mtu-watcher.ps1`) — он каждые 3 сек отключает IPv6 binding заново. Плюс глобально `DisabledComponents=0xFF` в `Tcpip6\Parameters` (после ребута) делает IPv6 нерабочим даже если binding формально включён.

---

## 9. IPv6 `DisabledComponents` не применяется без ребута

**Симптом:** установил `DisabledComponents=0xFF`, но `Get-ItemProperty` показывает пусто или старое значение после проверки.

**Решение:** `DisabledComponents` читается только при загрузке TCP/IP стека. **Обязателен ребут.** После ребута значение `255` (=0xFF) подтверждается.

---

## 10. `Start-Process -Verb RunAs` отменён пользователем

**Симптом:** `Start-Process : This command cannot be run due to the error: The operation was canceled by the user.`

**Решение:** просто запусти команду снова, подтверди UAC.

---

## 11. Ложный FAIL в аудите: "HappMtuWatcher task not created"

**Симптом:** аудит показывает FAIL, хотя задача реально работает (MTU 1380 держится).

**Причина:** см. пункт 6 — `Get-ScheduledTask` из обычной сессии не видит SYSTEM-задачу.

**Решение:** в `scripts/final-audit.ps1` проверка watcher сделана косвенной (MTU + IPv6). Не используй прямую проверку `Get-ScheduledTask` без прав админа.

---

## 12. Служба не останавливается: "Access is denied" на Stop-Service

**Симптом:** `Stop-Service -Name SSDPSRV -Force` → Access denied.

**Решение:** запуск от админа. Некоторые службы (SSDPSRV, lfsvc) требуют именно elevated сессии. Если упорно не стопится — попробуй `sc.exe stop <name>` и `sc.exe config <name> start= disabled`.
