# Windows 11 No-Leaks Script

A collection of PowerShell scripts and a [pi coding agent](https://github.com/earendil-works/pi-coding-agent) skill that hardens Windows 11 network stack for use with proxy/VPN clients (HAPP, Clash Meta, sing-box, v2ray, WireGuard) using VLESS+Reality, Trojan, and similar protocols.

Completely blocks real IP leaks: WebRTC/STUN/TURN/mDNS/QUIC, disables IPv6, tunes TCP stack, blocks telemetry, sets MTU 1380 for tunnel stability, and creates a watcher task to maintain settings automatically.

> ⚠️ **WARNING.** These scripts modify system Windows settings. Run at your own risk. Always create a Windows restore point before running. Scripts completely disable IPv6 — this may break some local services. All scripts require administrator privileges. Review script contents before running — don't run blindly. The author is not responsible for any damage.

## Who is this for

- Users who route traffic through a personal proxy/VPN server abroad
- Protocols: VLESS+Reality, Trojan, Hysteria2, Shadowsocks2022 over TCP
- Windows 10/11 (PowerShell 5.1+)
- Anyone who wants to eliminate real IP leaks via WebRTC/DNS/IPv6/QUIC

## What it does

| Phase | What | Script |
|---|---|---|
| 1 | Block STUN/TURN/mDNS + enable firewall + disable LLMNR | `scripts/block-webrtc.ps1` |
| 2 | Full QUIC disable (msquic, HTTP/3, Chrome/Edge/Firefox policies, UDP 443) | `scripts/disable-quic.ps1` |
| 3 | Full IPv6 disable (bindings, Teredo/6to4/ISATAP/IP-HTTPS, DisabledComponents) | `scripts/disable-ipv6-full.ps1` |
| 4 | TCP stack tuning (DefaultTTL=128, disable Fast Open/ECN/Timestamps/Heuristics, Nagle off) | `scripts/tcp-stack-tuning.ps1` |
| 5a | Disable telemetry + block domains in hosts + Cortana/Cloud search off | `scripts/telemetry-block.ps1` |
| 5b | Stop unnecessary services + block SSDP/LLMNR + mDNS off | `scripts/fix-all.ps1` |
| 6 | Watcher task: maintains MTU 1380 + IPv6 off on TUN adapter | `scripts/mtu-watcher.ps1` + `scripts/create-task-schtasks.ps1` |
| 7 | Final audit (17 categories of checks, goal — 0 FAIL) | `scripts/final-audit.ps1` |

## Installation

### Method A — as a pi coding agent skill

In `~/.pi/settings.json` (or `.pi/settings.json` in your project):
```json
{
  "skills": [
    "https://github.com/dobrdigital/ru-windows11-no-leaks-script"
  ]
}
```
Or manually:
```bash
git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git ~/.pi/agent/skills/ru-windows11-no-leaks-script
```
After loading, tell pi: "harden Windows network stack and prevent IP leaks" — the skill will apply.

### Method B — as standalone scripts (without pi)

```bash
git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git
cd ru-windows11-no-leaks-script/scripts
```

## Usage (without pi)

1. **Find your TUN adapter name:**
   ```powershell
   Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
   ```
   Typical names: `happ-default-tun`, `Mihomo`, `Clash`, `sing-box`, `wgtunnel`.

2. **Edit variables for your setup:**
   - `scripts/mtu-watcher.ps1` → `$tunName = "happ-default-tun"`
   - `scripts/final-audit.ps1` → `$tunName = "happ-default-tun"`
   - `scripts/create-task-schtasks.ps1` → path to `mtu-watcher.ps1`
   - `scripts/final-audit.ps1` → `$expectedIp = "YOUR_VPS_IP"` (optional)

3. **Run phases in order as administrator:**
   ```powershell
   # Open PowerShell as Administrator
   cd C:\path\to\ru-windows11-no-leaks-script\scripts

   .\block-webrtc.ps1
   .\disable-quic.ps1
   .\disable-ipv6-full.ps1
   # → REBOOT
   .\tcp-stack-tuning.ps1
   .\telemetry-block.ps1
   .\fix-all.ps1
   # → REBOOT
   .\create-task-schtasks.ps1
   .\final-audit.ps1
   ```

4. **Verify results manually** in browser:
   - https://browserleaks.com/ip — IP should be your proxy server, WebRTC Local IP = n/a, IPv6 = n/a
   - https://ipleak.net — DNS should show only your tunnel DNS
   - https://quic.mitmproxy.org — should fail to load (QUIC off)
   - chrome://net-internals/#quic — no active QUIC sessions

## Key Parameters

| Parameter | Value | Why |
|---|---|---|
| MTU on TUN | 1380 | Optimal for VLESS+Reality over TCP, prevents fragmentation |
| DefaultTTL | 128 | Windows fingerprint (Linux=64 often detected as Android) |
| QUIC | fully off | QUIC (UDP 443) is unstable through proxy, causes leaks |
| IPv6 | fully off | IPv6 often bypasses TUN, real IP leaks |
| LLMNR/NBT-NS/mDNS | off | Local discovery = hostname/network name leak |
| TCP Fast Open | off | Can interfere with proxy tunneling, creates fingerprint |

## Common Issues

- **TCP/IP Fingerprint on browserleaks shows Android / MTU 1500** — this is NOT a leak. Browserleaks sees the last segment (your server → site), not your PC. Don't try to "fix" it — it's useless. See [references/troubleshooting.md](references/troubleshooting.md).
- **`Get-NetIPInterface NlMtuBytes` empty for TUN adapters** — PowerShell bug. Check MTU via `netsh interface ipv4 show subinterface`.
- **HAPP ignores `mtu` in config.json** — driver limitation. Solution: watcher task.
- **`Get-ScheduledTask` can't see SYSTEM task from non-admin session** — check indirectly (MTU + IPv6).

Full list of issues and solutions in [references/troubleshooting.md](references/troubleshooting.md).

## Documentation

- [SKILL.md](SKILL.md) — main skill file
- [references/troubleshooting.md](references/troubleshooting.md) — common issues
- [references/scripts-reference.md](references/scripts-reference.md) — script descriptions
- [references/github-publish-guide.md](references/github-publish-guide.md) — how to publish on GitHub

## License

MIT — see [LICENSE](LICENSE). Free to use, modify, distribute.

## Contributing

Found a bug or want to improve? Open an [Issue](../../issues) or PR.

## Disclaimer

Scripts are provided "as is" without any warranty. The author is not responsible for any damage, data loss, or issues arising from use. Always create a Windows restore point before running.

---

---

---

# Windows 11 No-Leaks Script (Русский)

Набор PowerShell-скриптов и скилл для [pi coding agent](https://github.com/earendil-works/pi-coding-agent) для настройки сетевого стека Windows 11 при использовании прокси/VPN клиентов (HAPP, Clash Meta, sing-box, v2ray, WireGuard) с протоколами VLESS+Reality, Trojan и т.п.

Полностью закрывает утечки реального IP: WebRTC/STUN/TURN/mDNS/QUIC, отключает IPv6, оптимизирует TCP-стек, блокирует телеметрию, выставляет MTU 1380 для стабильности туннеля и создаёт watcher-задачу для автоматического поддержания настроек.

> ⚠️ **ВНИМАНИЕ.** Скрипты меняют системные настройки Windows. Выполняй на свой страх и риск. Обязательно создай точку восстановления Windows перед запуском. Скрипты полностью отключают IPv6 — это может сломать некоторые локальные сервисы. Все скрипты требуют прав администратора. Перед запуском проверь содержимое скриптов — не запускай вслепую. Автор не несёт ответственности за любой ущерб.

## Кому подойдёт

- Пользователи, направляющие трафик через личный прокси/VPN-сервер за рубежом
- Протоколы VLESS+Reality, Trojan, Hysteria2, Shadowsocks2022 поверх TCP
- Windows 10/11 (PowerShell 5.1+)
- Те, кто хочет исключить утечки реального IP через WebRTC/DNS/IPv6/QUIC

## Что делает

| Фаза | Что | Скрипт |
|---|---|---|
| 1 | Блокировка STUN/TURN/mDNS + включение файрвола + отключение LLMNR | `scripts/block-webrtc.ps1` |
| 2 | Полное отключение QUIC (msquic, HTTP/3, политики Chrome/Edge/Firefox, UDP 443) | `scripts/disable-quic.ps1` |
| 3 | Полное отключение IPv6 (биндинги, Teredo/6to4/ISATAP/IP-HTTPS, DisabledComponents) | `scripts/disable-ipv6-full.ps1` |
| 4 | Оптимизация TCP стека (DefaultTTL=128, отключение Fast Open/ECN/Timestamps/Heuristics, Nagle off) | `scripts/tcp-stack-tuning.ps1` |
| 5a | Отключение телеметрии + блокировка доменов в hosts + Cortana/Cloud search off | `scripts/telemetry-block.ps1` |
| 5b | Остановка лишних служб + блокировка SSDP/LLMNR + mDNS off | `scripts/fix-all.ps1` |
| 6 | Watcher-задача: держит MTU 1380 + IPv6 off на TUN-адаптере | `scripts/mtu-watcher.ps1` + `scripts/create-task-schtasks.ps1` |
| 7 | Финальный аудит (17 категорий проверок, цель — 0 FAIL) | `scripts/final-audit.ps1` |

## Установка

### Способ A — как скилл для pi coding agent

В `~/.pi/settings.json`:
```json
{
  "skills": [
    "https://github.com/dobrdigital/ru-windows11-no-leaks-script"
  ]
}
```
Или вручную:
```bash
git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git ~/.pi/agent/skills/ru-windows11-no-leaks-script
```
После загрузки скажи pi: «настрой сетевой стек Windows и предотврати утечки IP» — скилл применится.

### Способ B — как набор скриптов (без pi)

```bash
git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git
cd ru-windows11-no-leaks-script/scripts
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
   - `scripts/final-audit.ps1` → `$expectedIp = "IP_ТВОЕГО_СЕРВЕРА"` (опционально)

3. **Запускай фазы по порядку от администратора:**
   ```powershell
   # Открой PowerShell от имени администратора
   cd C:\path\to\ru-windows11-no-leaks-script\scripts

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
   - https://browserleaks.com/ip — IP должен быть твоего сервера, WebRTC Local IP = n/a, IPv6 = n/a
   - https://ipleak.net — DNS должен показывать только DNS туннеля
   - https://quic.mitmproxy.org — должен не загрузиться (QUIC off)
   - chrome://net-internals/#quic — нет активных QUIC сессий

## Ключевые параметры

| Параметр | Значение | Почему |
|---|---|---|
| MTU на TUN | 1380 | Оптимально для VLESS+Reality поверх TCP, исключает фрагментацию |
| DefaultTTL | 128 | Windows fingerprint (Linux=64 часто путают с Android) |
| QUIC | полностью off | QUIC (UDP 443) нестабилен через прокси, создаёт утечки |
| IPv6 | полностью off | IPv6 часто обходит TUN, утечки реального IP |
| LLMNR/NBT-NS/mDNS | off | Локальное обнаружение = утечка имени хоста/сети |
| TCP Fast Open | off | Может мешать прокси-туннелированию, создаёт fingerprint |

## Частые грабли

- **TCP/IP Fingerprint на browserleaks показывает Android / MTU 1500** — это НЕ утечка. Browserleaks видит последний участок (твой сервер → сайт), а не твой ПК. Не пытайся "исправить" — бесполезно. Подробнее в [references/troubleshooting.md](references/troubleshooting.md).
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

Нашёл баг или хочешь улучшить — открывай [Issue](../../issues) или PR.

## Отказ от ответственности

Скрипты предоставляются "как есть" без каких-либо гарантий. Автор не несёт ответственности за любой ущерб, потерю данных или проблемы, возникшие в результате использования. Всегда создавай точку восстановления Windows перед запуском.
