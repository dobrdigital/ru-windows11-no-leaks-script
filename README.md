# Windows 11 Russia Anti-DPI & Leak Hardening

Набор скриптов и скилл для [pi coding agent](https://github.com/earendil-works/pi-coding-agent), который настраивает Windows 11 для обхода ТСПУ (DPI) в России через прокси/VPN клиенты (HAPP, Clash Meta, sing-box, v2ray, WireGuard) с протоколами VLESS+Reality, Trojan и т.п.

Полностью закрывает утечки реального IP: WebRTC/STUN/TURN/mDNS/QUIC, отключает IPv6, тюнит TCP-стек, блокирует телеметрию, выставляет MTU 1380 для стабильности туннеля и создаёт watcher-задачу для автоматического поддержания настроек.

> ⚠️ **ВНИМАНИЕ.** Скрипты меняют системные настройки Windows. Выполняй на свой страх и риск. Обязательно создай точку восстановления Windows перед запуском. Скрипты полностью отключают IPv6 — это может сломать некоторые локальные сервисы. Все скрипты требуют прав администратора. Перед запуском проверь содержимое скриптов — не запускай вслепую. Автор не несёт ответственности за любой ущерб.

## Кому подойдёт

- Пользователи в России с VPN/прокси через HAPP / Clash Meta / sing-box / v2ray
- Протоколы VLESS+Reality, Trojan, Hysteria2, Shadowsocks2022 поверх TCP
- Windows 10/11 (PowerShell 5.1+)
- Те, кто хочет исключить утечки реального IP через WebRTC/DNS/IPv6/QUIC

## Что делает

| Фаза | Что | Скрипт |
|---|---|---|
| 1 | Блокировка STUN/TURN/mDNS + включение файрвола + отключение LLMNR | `scripts/block-webrtc.ps1` |
| 2 | Полное отключение QUIC (msquic, HTTP/3, политики Chrome/Edge/Firefox, UDP 443) | `scripts/disable-quic.ps1` |
| 3 | Полное отключение IPv6 (биндинги, Teredo/6to4/ISATAP/IP-HTTPS, DisabledComponents) | `scripts/disable-ipv6-full.ps1` |
| 4 | Тюнинг TCP стека (DefaultTTL=128, отключение Fast Open/ECN/Timestamps/Heuristics, Nagle off) | `scripts/tcp-stack-tuning.ps1` |
| 5a | Отключение телеметрии + блокировка доменов в hosts + Cortana/Cloud search off | `scripts/telemetry-block.ps1` |
| 5b | Остановка лишних служб + блокировка SSDP/LLMNR + mDNS off | `scripts/fix-all.ps1` |
| 6 | Watcher-задача: держит MTU 1380 + IPv6 off на TUN-адаптере | `scripts/mtu-watcher.ps1` + `scripts/create-task-schtasks.ps1` |
| 7 | Финальный аудит (17 категорий проверок, цель — 0 FAIL) | `scripts/final-audit.ps1` |

## Установка

### Способ A — как скилл для pi coding agent

В `~/.pi/settings.json` (или `.pi/settings.json` в проекте):
```json
{
  "skills": [
    "https://github.com/<username>/windows-russia-anti-dpi"
  ]
}
```
Или вручную:
```bash
git clone https://github.com/<username>/windows-russia-anti-dpi.git ~/.pi/agent/skills/windows-russia-anti-dpi
```
После загрузки скажи pi: «настрой Windows для обхода ТСПУ и защиты от утечек» — скилл применится.

### Способ B — как набор скриптов (без pi)

```bash
git clone https://github.com/<username>/windows-russia-anti-dpi.git
cd windows-russia-anti-dpi/scripts
```

## Использование (без pi)

1. **Узнай имя своего TUN-адаптера:**
   ```powershell
   Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
   ```
   Типичные имена: `happ-default-tun`, `Mihomo`, `Clash`, `sing-box`, `wgtunnel`.

2. **Отредактируй переменные под себя:**
   - `scripts/mtu-watcher.ps1` → `$tunName = "happ-default-tun"`
   - `scripts/final-audit.ps1` → `$tunName = "happ-default-tun"`
   - `scripts/create-task-schtasks.ps1` → путь к `mtu-watcher.ps1`
   - `scripts/final-audit.ps1` → `$expectedIp = "IP_ТВОЕГО_VPS"` (опционально)

3. **Запускай фазы по порядку от администратора:**
   ```powershell
   # Открой PowerShell от имени администратора
   cd C:\path\to\windows-russia-anti-dpi\scripts

   .\block-webrtc.ps1
   .\disable-quic.ps1
   .\disable-ipv6-full.ps1
   # → ПЕРЕЗАГРУЗИ ПК
   .\tcp-stack-tuning.ps1
   .\telemetry-block.ps1
   .\fix-all.ps1
   # → ПЕРЕЗАГРУЗИ ПК
   .\create-task-schtasks.ps1
   .\final-audit.ps1
   ```

4. **Проверь результат вручную** в браузере:
   - https://browserleaks.com/ip — IP должен быть VPS, WebRTC Local IP = n/a, IPv6 = n/a
   - https://ipleak.net — DNS должен показывать только DNS туннеля
   - https://quic.mitmproxy.org — должен не загрузиться (QUIC off)
   - chrome://net-internals/#quic — нет активных QUIC сессий

## Ключевые параметры для России / VLESS+Reality

| Параметр | Значение | Почему |
|---|---|---|
| MTU на TUN | 1380 | Оптимально для VLESS+Reality поверх TCP, исключает фрагментацию |
| DefaultTTL | 128 | Windows fingerprint (Linux=64 часто путают с Android) |
| QUIC | полностью off | QUIC (UDP 443) нестабилен через прокси, создаёт утечки |
| IPv6 | полностью off | IPv6 часто обходит TUN, утечки реального IP |
| LLMNR/NBT-NS/mDNS | off | Локальное обнаружение = утечка имени хоста/сети |
| TCP Fast Open | off | Мешает DPI-обходу, создаёт fingerprint |

## Частые грабли

- **TCP/IP Fingerprint на browserleaks показывает Android / MTU 1500** — это НЕ утечка. Browserleaks видит последний участок (VPS → сайт), а не твой ПК. Не пытайся "исправить" — бесполезно. Подробнее в [references/troubleshooting.md](references/troubleshooting.md).
- **`Get-NetIPInterface NlMtuBytes` пустой для TUN-адаптеров** — баг PowerShell. MTU проверяй через `netsh interface ipv4 show subinterface`.
- **HAPP игнорирует `mtu` в config.json** — особенность драйвера. Решение: watcher-задача.
- **`Get-ScheduledTask` не видит SYSTEM-задачу из обычной сессии** — проверяй косвенно (MTU + IPv6).

Полный список граблей и решений — в [references/troubleshooting.md](references/troubleshooting.md).

## Документация

- [SKILL.md](SKILL.md) — главный файл скилла
- [references/troubleshooting.md](references/troubleshooting.md) — типичные проблемы
- [references/scripts-reference.md](references/scripts-reference.md) — описание скриптов
- [references/github-publish-guide.md](references/github-publish-guide.md) — как публиковать на GitHub

## Лицензия

MIT — см. [LICENSE](LICENSE). Можно свободно использовать, модифицировать, распространять.

## Contributing

Нашёл баг или хочешь улучшить — открывай [Issue](../../issues) или PR. Перед PR прочитай [references/github-publish-guide.md](references/github-publish-guide.md) (секция про CONTRIBUTING).

## Отказ от ответственности

Скрипты предоставляются "как есть" без каких-либо гарантий. Автор не несёт ответственности за любой ущерб, потерю данных или проблемы, возникшие в результате использования. Всегда создавай точку восстановления Windows перед запуском.
