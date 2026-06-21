---
name: windows-russia-anti-dpi
description: Harden Windows 11 network stack and prevent IP leaks when using a proxy/VPN client (HAPP, Clash, sing-box, v2ray). Disables WebRTC/STUN/TURN/mDNS/QUIC leaks, fully disables IPv6, tunes TCP stack, blocks telemetry, sets MTU 1380 for VLESS+Reality tunnels, and creates a watcher task. Includes a full leak audit. Use when a user wants to prevent IP/DNS/WebRTC leaks, harden Windows network settings, or audit a Windows machine for network leaks.
compatibility: Windows 10/11, PowerShell 5.1+ (run as Administrator). Requires a proxy/VPN client with a TUN interface (HAPP, Clash Meta, sing-box, v2ray, WireGuard). Tuned for VLESS+Reality over TCP.
metadata:
  author: derived-from-real-session
  version: "1.0"
  language: ru
---

# Windows Network Leak Hardening

Этот скилл — выжимка из реальной сессии настройки сетевого стека Windows 11 для использования с прокси/VPN клиентами (HAPP, Clash, sing-box, v2ray, WireGuard) + VPS с VLESS+Reality. Применим к любому Windows-ПК с TUN-клиентом.

## ВАЖНО — что нужно знать агенту перед началом

1. **Все действия требуют прав администратора.** Запускать elevated: `Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File <script>'`. Обычная сессия получит `Access is denied` на `Set-NetFirewallRule`, `Set-Service`, `netsh interface ... set`, записи в `HKLM:\`.

2. **Bash ломает PowerShell-переменные `$` и флаги.** Никогда не передавай PowerShell с `$_`, `$svc` и т.п. напрямую в `powershell -Command "..."` из bash. Либо экранируй `\$`, либо (надёжнее) записывай скрипт в файл через `write` и выполняй `powershell -ExecutionPolicy Bypass -File <path>`.

3. **Git Bash ломает `schtasks`/`netsh` аргументы** (`/query` превращается в путь). Всегда оборачивай такие команды в `.ps1` файл.

4. **`Get-NetIPInterface ... NlMtuBytes` возвращает пусто для TUN-адаптеров** — это баг PowerShell. MTU проверяй ТОЛЬКО через `netsh interface ipv4 show subinterface "<name>"`.

5. **HAPP (и подобные TUN-клиенты) пересоздают адаптер при каждом старте и сбрасывают MTU на 1500 + включают IPv6 binding.** Файл `config.json` параметр `mtu` HAPP ИГНОРИРУЕТ (проверено). Единственный рабочий способ — **watcher-задача**, которая каждые 3 секунды ставит MTU 1380 и отключает IPv6 binding.

6. **TCP/IP Fingerprint на browserleaks показывает MTU 1500 / OS Android — это НЕ утечка.** Browserleaks видит последний участок (VPS → сайт), а не твой ПК. Локальный MTU 1380 нужен для стабильности туннеля, он снаружи не виден. Не пытайся "исправить" fingerprint — это бессмысленно.

7. **Не задавай пользователю глупых вопросов** вроде "что такое HAPP" — это известный мультиплатформенный клиент обхода блокировок. Если не знаешь инструмент — погугли, не спрашивай.

## Порядок применения (фазы)

Выполняй фазы по порядку. После каждой перезагрузка может быть нужна (для IPv6 DisabledComponents, TCP стека, TTL).

### Фаза 1 — Блокировка утечек WebRTC/STUN/TURN/mDNS
```powershell
powershell -ExecutionPolicy Bypass -File scripts/block-webrtc.ps1
```
Создаёт 4 правила файрвола: Block STUN UDP 3478 Out, Block STUN TCP 3478 Out, Block TURN TCP 5349 Out, Block mDNS UDP 5353 Out. Включает все профили файрвола. Отключает LLMNR.

### Фаза 2 — Отключение QUIC полностью
```powershell
powershell -ExecutionPolicy Bypass -File scripts/disable-quic.ps1
```
Отключает: службу msquic + драйвер, HTTP/3 в HTTP.sys и WinHTTP, QUIC в Schannel, WinINET (system+user), политики Edge/Chrome/Firefox (QuicAllowed=0 / DisableHttp3=1), блокирует UDP 443 исходящий.

### Фаза 3 — Полное отключение IPv6
```powershell
powershell -ExecutionPolicy Bypass -File scripts/disable-ipv6-full.ps1
```
`Disable-NetAdapterBinding -ComponentID ms_tcpip6` на всех адаптерах, `netsh interface teredo/6to4/isatap/httpstunnel set state disabled`, `DisabledComponents=0xFF` в реестре. **Требует ребута.**

### Фаза 4 — Тюнинг TCP стека
```powershell
powershell -ExecutionPolicy Bypass -File scripts/tcp-stack-tuning.ps1
```
netsh: `autotuninglevel=normal`, `rss=disabled`, `chimney/dca/netdma/ecncapability/timestamps/rsc=disabled`, `fastopen=disabled`, `hystart=disabled`. Реестр Tcpip\Parameters: KeepAliveTime=60000, KeepAliveInterval=1000, DefaultTTL=128 (Windows fingerprint!), DisableTaskOffload=1, EnableECN=0, EnableHeuristics=0. Отключение Nagle (TcpAckFrequency=1, TCPNoDelay=1) на всех интерфейсах.

### Фаза 5 — Отключение телеметрии и служб
```powershell
powershell -ExecutionPolicy Bypass -File scripts/telemetry-block.ps1
powershell -ExecutionPolicy Bypass -File scripts/fix-all.ps1
```
Останавливает/отключает: DiagTrack, dmwappushservice, WMPNetworkSvc, wisvc, lfsvc (Geolocation), SharedAccess (ICS), SSDPSRV, fdPHost, upnphost, FDResPub (Network Discovery). Добавляет домены телеметрии в hosts. DisableSmartNameResolution, EnableMDNS=0.

### Фаза 6 — Watcher для MTU + IPv6 на TUN-адаптере
```powershell
# 1. Узнай имя TUN-адаптера
Get-NetAdapter | Select-Object Name, InterfaceDescription, Status

# 2. Отредактируй scripts/mtu-watcher.ps1 — впиши имя адаптера (по умолчанию happ-default-tun)
# 3. Создай scheduled task (от админа):
powershell -ExecutionPolicy Bypass -File scripts/create-task-schtasks.ps1
```
Создаёт task `HappMtuWatcher`, запускаемую при входе от SYSTEM с highest privileges. Watcher каждые 3 сек: если MTU=1500 → ставит 1380; если IPv6 binding enabled → disabled.

### Фаза 7 — Аудит (финальная проверка)
```powershell
powershell -ExecutionPolicy Bypass -File scripts/final-audit.ps1
```
17 категорий проверок: файрвол, правила блокировки, listening порты, LLMNR/IPv6, IPv6-туннели, DNS, прокси, активные STUN/TURN, hosts, туннель, MTU, QUIC, TCP стек, TTL, службы телеметрии, watcher task, внешний IP. Цель: 0 FAIL.

## Типичные значения для VLESS+Reality

| Параметр | Значение | Почему |
|---|---|---|
| MTU на TUN | 1380 | Оптимально для VLESS+Reality поверх TCP/Reality, исключает фрагментацию внутри туннеля |
| DefaultTTL | 128 | Windows fingerprint (по умолчанию Linux=64, и fingerprint путают с Android) |
| QUIC | полностью off | QUIC (UDP 443) нестабилен через прокси и создаёт утечки |
| IPv6 | полностью off | IPv6 часто обходит TUN и создаёт утечки реального IP |
| LLMNR/NBT-NS/mDNS | off | Локальное обнаружение = утечка имени хоста/сети |
| TCP Fast Open | off | Может мешать прокси-туннелированию, создаёт fingerprint |

## Проверка вручную (в браузере)

Открой и проверь:
- https://browserleaks.com/ip — IP должен быть VPS, WebRTC Local IP = n/a, IPv6 = n/a
- https://ipleak.net — DNS должен показывать только DNS туннеля
- https://quic.mitmproxy.org — должен не загрузиться (QUIC off)
- chrome://net-internals/#quic — нет активных QUIC сессий

## Если что-то не работает

См. [references/troubleshooting.md](references/troubleshooting.md) — типичные грабли этой сессии (UAC, bash-экранирование, пустой NlMtuBytes, HAPP игнорирует config.json, ложный FAIL в аудите).

## Скрипты

Все скрипты в `scripts/`. Запускать от администратора. Подробности — в [references/scripts-reference.md](references/scripts-reference.md).
