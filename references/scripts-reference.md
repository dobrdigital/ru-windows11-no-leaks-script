# Scripts Reference — описание всех скриптов

Каждый скрипт запускается от администратора. Порядок важен — см. SKILL.md.

---

## block-webrtc.ps1 — Фаза 1

**Что делает:**
- Включает Windows Firewall на всех 3 профилях (Domain, Private, Public)
- Создаёт 4 правила файрвола для блокировки исходящего трафика:
  - `Block STUN UDP 3478 Out` — WebRTC STUN UDP
  - `Block STUN TCP 3478 Out` — WebRTC STUN TCP
  - `Block TURN TCP 5349 Out` — TURN relay ретрансляция
  - `Block mDNS UDP 5353 Out` — Multicast DNS обнаружение
- Отключает LLMNR через политику (`EnableMulticast = 0`)
- Отключает NBT-NS на всех адаптерах

**Требует ребута:** нет

**Проверка:**
```powershell
Get-NetFirewallProfile | Select Name, Enabled
Get-NetFirewallRule -DisplayName "Block * Out" | Select DisplayName, Enabled, Action
```

---

## disable-quic.ps1 — Фаза 2

**Что делает:**
- Останавливает и отключает службу `msquic` + драйвер (Start=4)
- Отключает HTTP/3 в `HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters` (EnableHttp3=0)
- Отключает QUIC в Schannel (Enabled=0, DisabledByDefault=1)
- Отключает QUIC в WinINET (system + user, EnableQuic=0)
- Создаёт политики Chrome и Edge (QuicAllowed=0)
- Создаёт политику Firefox (DisableHttp3=1)
- Отключает HTTP/3 в WinHTTP
- Блокирует UDP 443 исходящий через файрвол (правило `Block QUIC UDP 443 Out`)

**Требует ребута:** рекомендуется

**Проверка:**
```powershell
Get-Service msquic | Select Name, Status, StartType
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" | Select EnableHttp3
```

---

## disable-ipv6-full.ps1 — Фаза 3

**Что делает:**
- `Disable-NetAdapterBinding -ComponentID ms_tcpip6` на всех адаптерах
- `netsh interface teredo/6to4/isatap/httpstunnel set state disabled`
- `DisabledComponents = 0xFF` в `HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters`
- `DisableSmartNameResolution = 1` в политиках DNS Client
- Отключает IPv6 binding на туннельных адаптерах (TUN/TAP/VPN/SocksTunnel)

**Требует ребута:** **ОБЯЗАТЕЛЕН** для DisabledComponents

**Проверка:**
```powershell
Get-NetAdapterBinding -ComponentID ms_tcpip6 | Where-Object Enabled
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" | Select DisabledComponents
netsh interface teredo show state
```

---

## tcp-stack-tuning.ps1 — Фаза 4

**Что делает:**
- **netsh:** autotuninglevel=normal, rss/chimney/dca/netdma/ecncapability/timestamps/rsc=disabled, fastopen/fastopenfallback/hystart=disabled, pacingprofile=off
- **Реестр Tcpip\Parameters:**
  - `KeepAliveTime=60000`, `KeepAliveInterval=1000` — агрессивный keepalive для туннеля
  - `DefaultTTL=128` — Windows fingerprint
  - `DisableTaskOffload=1`, `EnableECN=0`, `EnableHeuristics=0`
  - `MaxFreeTcbs/MaxHashTableSize/NumTcbTablePartitions` — тюнинг пулов
  - И ещё ~15 параметров стабильности
- **Отключение Nagle:** `TcpAckFrequency=1`, `TCPNoDelay=1` на всех интерфейсах

**Требует ребута:** **ОБЯЗАТЕЛЕН** для DefaultTTL и Tcpip\Parameters

**Проверка:**
```powershell
netsh int tcp show global
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" | Select DefaultTTL, KeepAliveTime
```

---

## telemetry-block.ps1 — Фаза 5a

**Что делает:**
- Останавливает и отключает службы: DiagTrack, dmwappushservice, WMPNetworkSvc, wisvc
- Блокирует ~20 доменов телеметрии Microsoft в hosts-файле (0.0.0.0)
- Отключает Input TIPC
- Отключает Advertising ID
- Отключает Cortana и Cloud Search через политики

**Требует ребута:** нет

**Проверка:**
```powershell
Get-Service DiagTrack,dmwappushservice | Select Name, Status, StartType
(Select-String "$env:SystemRoot\System32\drivers\etc\hosts" -Pattern "v10.events.data").Count
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' | Select Enabled
```

---

## fix-all.ps1 — Фаза 5b

**Что делает:**
- Останавливает и отключает службы: lfsvc, SharedAccess, SSDPSRV, fdPHost, upnphost, FDResPub, WMPNetworkSvc
- `EnableMDNS = 0` в Dnscache Parameters
- `EnableMulticast = 0` для LLMNR (повторно)
- Создаёт правило файрвола `Block SSDP UDP 1900 Out`
- Создаёт правило файрвола `Block LLMNR UDP 5355 Out`

**Требует ребута:** нет

**Проверка:**
```powershell
Get-Service lfsvc,SharedAccess,SSDPSRV | Select Name, Status, StartType
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" | Select EnableMDNS
Get-NetFirewallRule -DisplayName "Block SSDP*","Block LLMNR*" | Select DisplayName, Enabled
```

---

## mtu-watcher.ps1 — Фаза 6 (watcher)

**Что делает (бесконечный цикл каждые 3 секунды):**
- Если TUN-адаптер UP и MTU ≠ 1380 → ставит MTU 1380
- Если IPv6 binding enabled → отключает

**Запускается как Scheduled Task при входе в систему.** Не запускать вручную — для этого есть `create-task-schtasks.ps1`.

**Перед первым использованием:** отредактируй переменные внутри скрипта:
```powershell
$tunName = "happ-default-tun"   # имя твоего TUN-адаптера
$targetMtu = 1380               # 1380 для VLESS+Reality
```

**Проверка работы:**
```powershell
netsh interface ipv4 show subinterface "happ-default-tun"
Get-NetAdapterBinding -Name "happ-default-tun" -ComponentID ms_tcpip6 | Select Enabled
```

---

## create-task-schtasks.ps1 — Фаза 6 (создание задачи)

**Что делает:**
- Удаляет старую задачу `HappMtuWatcher` (если есть)
- Создаёт Scheduled Task через `schtasks.exe` с:
  - Trigger: at logon
  - User: SYSTEM, RunLevel: Highest
  - Action: запуск `mtu-watcher.ps1`
- Сразу запускает задачу
- Выводит статус через `schtasks /query`

**ВАЖНО:** отредактируй переменную `$watcherPath` под свой путь к `mtu-watcher.ps1`.

**Требует ребута:** нет

**Проверка:**
```powershell
schtasks /query /tn "HappMtuWatcher" /fo LIST
# Должно показать Status: Ready или Running
```

---

## final-audit.ps1 — Фаза 7 (аудит)

**Что делает:** 17 категорий проверок:

1. Файвall (3 профиля) — должны быть Enabled
2. Правила блокировки (5 правил) — должны быть Enabled + Block
3. Listening порты (STUN/TURN/mDNS/SSDP/LLMNR) — не должны слушать
4. LLMNR + IPv6 DisabledComponents — LLMNR off, 0xFF
5. IPv6 tunnels (Teredo/ISATAP/6to4) — все disabled
6. DNS серверы — только локальные
7. Прокси — проверка настроек WinINET
8. Активные STUN/TURN соединения — не должно быть
9. Hosts — более 100 заблокированных доменов
10. Туннель — UP
11. MTU — 1380 на TUN
12. QUIC — Chrome/Edge/msquic/HTTP3 отключены
13. TCP стек — Fast Open/ECN/Timestamps disabled, Auto-Tuning normal
14. TTL — 128
15. Службы телеметрии — stopped/disabled
16. Watcher task — проверяется косвенно (MTU + IPv6 on tunnel)
17. Внешний IP — через api.ipify.org

**Цель:** 0 FAIL (WARN допустимы для UDP 5353 браузера и подобных)

**Перед первым использованием:** отредактируй переменные:
```powershell
$tunName = "happ-default-tun"
$expectedIp = $null   # впиши IP VPS для проверки совпадения, или оставь $null
```

**Запуск:** можно без прав админа, но часть проверок будет косвенной.

---

## Краткая сводка по порядку запуска

```
block-webrtc.ps1 → disable-quic.ps1 → disable-ipv6-full.ps1 → РЕБУТ
→ tcp-stack-tuning.ps1 → telemetry-block.ps1 → fix-all.ps1 → РЕБУТ
→ create-task-schtasks.ps1 → final-audit.ps1
```

Мимум 2 ребута: после фазы 3 и фазы 5.
