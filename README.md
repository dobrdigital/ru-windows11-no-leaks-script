# Windows 11 No-Leaks Script

**Русская документация ниже**

PowerShell scripts for hardening Windows 11 network stack and preventing IP leaks.

> WARNING: Run as Administrator. Use at your own risk.

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

> **ВНИМАНИЕ! Скрипты меняют системные настройки.**

## Быстрый запуск

1. Скачайте NoLeaksWin11.zip из Релизов
2. Распакуйте в любую папку
3. Нажмите ПКМ на Run-Admin.bat > Запуск от имени Администратора
4. Выберите язык (1=Английский, 2=Русский)
5. Нажмите A для выполнения всех фаз, или 1-7 для отдельных
6. Перезагрузите компьютер когда программа попросит (после фаз 3 и 4)

## Требования

- Windows 10 или Windows 11
- PowerShell 5.1+
- Права Администратора
- Прокси/ВПН-клиент с ТУН интерфейсом (HAPP, Clash, sing-box, v2ray, т.д.)

## Лицензия: MIT

