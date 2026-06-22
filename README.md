# Windows 11 No-Leaks Script

PowerShell scripts for hardening Windows 11 network stack and preventing IP leaks.

> **WARNING.** Run at your own risk. Create a restore point first. **Run as Administrator!**

## What it does

| Phase | What | Script |
|---|---|---|
| 1 | Block STUN/TURN/mDNS + Firewall + LLMNR off | scripts/block-webrtc.ps1 |
| 2 | Full QUIC disable (msquic, HTTP/3, browser policies) | scripts/disable-quic.ps1 |
| 3 | Full IPv6 disable (bindings, tunnels, DisabledComponents) | scripts/disable-ipv6-full.ps1 |
| 4 | TCP Stack Tuning (TTL=128, Fast Open/ECN off, Nagle off) | scripts/tcp-stack-tuning.ps1 |
| 5a | Telemetry off (DiagTrack, hosts blocks) | scripts/telemetry-block.ps1 |
| 5b | Services off (SSDP, mDNS) | scripts/fix-all.ps1 |
| 6 | MTU Watcher Task (maintains MTU 1380 + IPv6 off) | scripts/mtu-watcher.ps1 |
| 7 | Final Audit (17 leak check categories) | scripts/final-audit.ps1 |

## Quick Start

1. Download NoLeaksWin11.zip from Releases
2. Extract to any folder
3. Right-click Run-Admin.bat -> Run as Administrator
4. Select language (1=English, 2=Russian)
5. Press A to run all phases, or 1-7 for individual phases
6. Reboot when prompted (after phases 3 and 4)

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1+
- Administrator privileges
- Proxy/VPN client with TUN interface (HAPP, Clash, sing-box, v2ray, etc.)

## License: MIT

---

**Русская документация ниже**

Набор PowerShell скриптов для настройки сетевого стека Windows 11 для обхода утечек IP

## Что делает

| Фаза | Что | Скрипт |
|---|---|---|
| 1 | Блокировка STUN/TURN/mDNS | scripts/block-webrtc.ps1 |
| 2 | Отключение QUIC | scripts/disable-quic.ps1 |
| 3 | Отключение IPv6 | scripts/disable-ipv6-full.ps1 |
| 4 | Оптимизация TCP | scripts/tcp-stack-tuning.ps1 |
| 5a | Телеметрия | scripts/telemetry-block.ps1 |
| 5b | Службы | scripts/fix-all.ps1 |
| 6 | Вотчер MTU | scripts/mtu-watcher.ps1 |
| 7 | Аудит | scripts/final-audit.ps1 |

> **ВНИМАНИЕ! Скрипты меняют системные настройки. Запускайте от  Администратора!**

## Быстрый запуск

1. Скачайте NoLeaksWin11.zip из Релизов
2. Распакуйте в любую папку
3. Нажмите ПКМ на Run-Admin.bat > Запуск от имени Администратора
4. Выберите язык (1=Английский, 2=Русский)
5. Нажмите A для выполнения всех фаз, или 1-7 для отдельных
6. Перезагрузите когда программа попросит (после фаз 3 и 4)

## Требования

- Windows 10 или Windows 11
- PowerShell 5.1+
- Права Администратора
- Прокси/ВПН-клиент с ТУН интерфейсом (HAPP, Clash, sing-box, v2ray, т.д.)

## Лицензия: MIT

