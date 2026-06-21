# Windows 11 No-Leaks Script

**Russian documentation is below**

A collection of PowerShell scripts for hardening Windows 11 network stack.

> **WARNING.** Run at your own risk. Create a restore point first.

## What it does

| Phase | What | Script |
|---|---|---|
| 1 | Block STUN/TURN/mDNS + Firewall | scripts/block-webrtc.ps1 |
| 2 | Disable QUIC | scripts/disable-quic.ps1 |
| 3 | Disable IPv6 | scripts/disable-ipv6-full.ps1 |
| 4 | TCP Stack Tuning | scripts/tcp-stack-tuning.ps1 |
| 5a | Telemetry off | scripts/telemetry-block.ps1 |
| 5b | Services off | scripts/fix-all.ps1 |
| 6 | MTU Watcher | scripts/mtu-watcher.ps1 |
| 7 | Final Audit | scripts/final-audit.ps1 |

## Installation

git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git

## License: MIT

---

# Windows 11 No-Leaks Script (Russian)

Набор Повершенных текстов для настройки сетевого стека Виндовс для обхода утечек ЙП

## !!! ЗАПУСКАТЬ ТОЛЬКО ОТ ИМЕНИ АДМИНИСТРАТОРА !!!

ВНИМАНИЕ. Скрипты меняют системные настройки Виндовс. Выполняй на свой страх и риск.

## Chto delayet

| Faza | Chto | Skript |
|---|---|---|
| 1 | Blokirovka STUN/TURN/mDNS | scripts/block-webrtc.ps1 |
| 2 | Otklyuchenie QUIC | scripts/disable-quic.ps1 |
| 3 | Otklyuchenie IPv6 | scripts/disable-ipv6-full.ps1 |
| 4 | Optimizaciya TCP | scripts/tcp-stack-tuning.ps1 |
| 5a | Telemetriya | scripts/telemetry-block.ps1 |
| 5b | Sluzhby | scripts/fix-all.ps1 |
| 6 | Watcher MTU | scripts/mtu-watcher.ps1 |
| 7 | Audit | scripts/final-audit.ps1 |

## Ustanovka

git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git

## Litsenziya: MIT
