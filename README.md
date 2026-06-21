# Windows 11 No-Leaks Script

**Russian documentation is below / Ð ÑƒÑÑÐºÐ°Ñ Ð´Ð¾ÐºÑƒÐ¼ÐµÐ½Ñ‚Ð°Ñ†Ð¸Ñ Ð½Ð¸Ð¶Ðµ**

A collection of PowerShell scripts and a [pi coding agent](https://github.com/earendil-works/pi-coding-agent) skill that hardens Windows 11 network stack for use with proxy/VPN clients (HAPP, Clash Meta, sing-box, v2ray, WireGuard) using VLESS+Reality, Trojan, and similar protocols.

Completely blocks real IP leaks: WebRTC/STUN/TURN/mDNS/QUIC, disables IPv6, tunes TCP stack, blocks telemetry, sets MTU 1380 for tunnel stability, and creates a watcher task to maintain settings automatically.

> **WARNING.** These scripts modify system Windows settings. Run at your own risk. Always create a Windows restore point before running. Scripts completely disable IPv6 -- this may break some local services. All scripts require administrator privileges. Review script contents before running -- don't run blindly. The author is not responsible for any damage.

---

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
| 7 | Final audit (17 categories of checks, goal -- 0 FAIL) | `scripts/final-audit.ps1` |

## Installation

### Method A -- as a pi coding agent skill

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
After loading, tell pi: "harden Windows network stack and prevent IP leaks" -- the skill will apply.

### Method B -- as standalone scripts (without pi)

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
   - `scripts/mtu-watcher.ps1` -> `$tunName = "happ-default-tun"`
   - `scripts/final-audit.ps1` -> `$tunName = "happ-default-tun"`
   - `scripts/create-task-schtasks.ps1` -> path to `mtu-watcher.ps1`
   - `scripts/final-audit.ps1` -> `$expectedIp = "YOUR_VPS_IP"` (optional)

3. **Run phases in order as administrator:**
   ```powershell
   cd C:\path\to\ru-windows11-no-leaks-script\scripts
   .\block-webrtc.ps1
   .\disable-quic.ps1
   .\disable-ipv6-full.ps1
   # -> REBOOT
   .\tcp-stack-tuning.ps1
   .\telemetry-block.ps1
   .\fix-all.ps1
   # -> REBOOT
   .\create-task-schtasks.ps1
   .\final-audit.ps1
   ```

4. **Verify results manually** in browser:
   - https://browserleaks.com/ip -- IP should be your proxy server, WebRTC Local IP = n/a, IPv6 = n/a
   - https://ipleak.net -- DNS should show only your tunnel DNS
   - https://quic.mitmproxy.org -- should fail to load (QUIC off)
   - chrome://net-internals/#quic -- no active QUIC sessions

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

- **TCP/IP Fingerprint on browserleaks shows Android / MTU 1500** -- this is NOT a leak. Browserleaks sees the last segment (your server -> site), not your PC. Don't try to "fix" it -- it's useless. See [references/troubleshooting.md](references/troubleshooting.md).
- **`Get-NetIPInterface NlMtuBytes` empty for TUN adapters** -- PowerShell bug. Check MTU via `netsh interface ipv4 show subinterface`.
- **HAPP ignores `mtu` in config.json** -- driver limitation. Solution: watcher task.
- **`Get-ScheduledTask` can't see SYSTEM task from non-admin session** -- check indirectly (MTU + IPv6).

Full list of issues and solutions in [references/troubleshooting.md](references/troubleshooting.md).

## Documentation

- [SKILL.md](SKILL.md) -- main skill file
- [references/troubleshooting.md](references/troubleshooting.md) -- common issues
- [references/scripts-reference.md](references/scripts-reference.md) -- script descriptions

## License

MIT -- see [LICENSE](LICENSE). Free to use, modify, distribute.

## Contributing

Found a bug or want to improve? Open an [Issue](../../issues) or PR.

## Disclaimer

Scripts are provided "as is" without any warranty. The author is not responsible for any damage, data loss, or issues arising from use. Always create a Windows restore point before running.

---

---

---

# Windows 11 No-Leaks Script (Russian / Ð ÑƒÑÑÐºÐ¸Ð¹)

ÐÐ°Ð±Ð¾Ñ€ PowerShell-ÑÐºÑ€Ð¸Ð¿Ñ‚Ð¾Ð² Ð¸ ÑÐºÐ¸Ð»Ð» Ð´Ð»Ñ [pi coding agent](https://github.com/earendil-works/pi-coding-agent) Ð´Ð»Ñ Ð½Ð°ÑÑ‚Ñ€Ð¾Ð¹ÐºÐ¸ ÑÐµÑ‚ÐµÐ²Ð¾Ð³Ð¾ ÑÑ‚ÐµÐºÐ° Windows 11 Ð¿Ñ€Ð¸ Ð¸ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¸Ð¸ Ð¿Ñ€Ð¾ÐºÑÐ¸/VPN ÐºÐ»Ð¸ÐµÐ½Ñ‚Ð¾Ð² (HAPP, Clash Meta, sing-box, v2ray, WireGuard) Ñ Ð¿Ñ€Ð¾Ñ‚Ð¾ÐºÐ¾Ð»Ð°Ð¼Ð¸ VLESS+Reality, Trojan Ð¸ Ñ‚.Ð¿.

ÐŸÐ¾Ð»Ð½Ð¾ÑÑ‚ÑŒÑŽ Ð·Ð°ÐºÑ€Ñ‹Ð²Ð°ÐµÑ‚ ÑƒÑ‚ÐµÑ‡ÐºÐ¸ Ñ€ÐµÐ°Ð»ÑŒÐ½Ð¾Ð³Ð¾ IP: WebRTC/STUN/TURN/mDNS/QUIC, Ð¾Ñ‚ÐºÐ»ÑŽÑ‡Ð°ÐµÑ‚ IPv6, Ð¾Ð¿Ñ‚Ð¸Ð¼Ð¸Ð·Ð¸Ñ€ÑƒÐµÑ‚ TCP-ÑÑ‚ÐµÐº, Ð±Ð»Ð¾ÐºÐ¸Ñ€ÑƒÐµÑ‚ Ñ‚ÐµÐ»ÐµÐ¼ÐµÑ‚Ñ€Ð¸ÑŽ, Ð²Ñ‹ÑÑ‚Ð°Ð²Ð»ÑÐµÑ‚ MTU 1380 Ð´Ð»Ñ ÑÑ‚Ð°Ð±Ð¸Ð»ÑŒÐ½Ð¾ÑÑ‚Ð¸ Ñ‚ÑƒÐ½Ð½ÐµÐ»Ñ Ð¸ ÑÐ¾Ð·Ð´Ð°Ñ‘Ñ‚ watcher-Ð·Ð°Ð´Ð°Ñ‡Ñƒ Ð´Ð»Ñ Ð°Ð²Ñ‚Ð¾Ð¼Ð°Ñ‚Ð¸Ñ‡ÐµÑÐºÐ¾Ð³Ð¾ Ð¿Ð¾Ð´Ð´ÐµÑ€Ð¶Ð°Ð½Ð¸Ñ Ð½Ð°ÑÑ‚Ñ€Ð¾ÐµÐº.

> **Ð’ÐÐ˜ÐœÐÐÐ˜Ð•.** Ð¡ÐºÑ€Ð¸Ð¿Ñ‚Ñ‹ Ð¼ÐµÐ½ÑÑŽÑ‚ ÑÐ¸ÑÑ‚ÐµÐ¼Ð½Ñ‹Ðµ Ð½Ð°ÑÑ‚Ñ€Ð¾Ð¹ÐºÐ¸ Windows. Ð’Ñ‹Ð¿Ð¾Ð»Ð½ÑÐ¹ Ð½Ð° ÑÐ²Ð¾Ð¹ ÑÑ‚Ñ€Ð°Ñ… Ð¸ Ñ€Ð¸ÑÐº. ÐžÐ±ÑÐ·Ð°Ñ‚ÐµÐ»ÑŒÐ½Ð¾ ÑÐ¾Ð·Ð´Ð°Ð¹ Ñ‚Ð¾Ñ‡ÐºÑƒ Ð²Ð¾ÑÑÑ‚Ð°Ð½Ð¾Ð²Ð»ÐµÐ½Ð¸Ñ Windows Ð¿ÐµÑ€ÐµÐ´ Ð·Ð°Ð¿ÑƒÑÐºÐ¾Ð¼. Ð¡ÐºÑ€Ð¸Ð¿Ñ‚Ñ‹ Ð¿Ð¾Ð»Ð½Ð¾ÑÑ‚ÑŒÑŽ Ð¾Ñ‚ÐºÐ»ÑŽÑ‡Ð°ÑŽÑ‚ IPv6 â€” ÑÑ‚Ð¾ Ð¼Ð¾Ð¶ÐµÑ‚ ÑÐ»Ð¾Ð¼Ð°Ñ‚ÑŒ Ð½ÐµÐºÐ¾Ñ‚Ð¾Ñ€Ñ‹Ðµ Ð»Ð¾ÐºÐ°Ð»ÑŒÐ½Ñ‹Ðµ ÑÐµÑ€Ð²Ð¸ÑÑ‹. Ð’ÑÐµ ÑÐºÑ€Ð¸Ð¿Ñ‚Ñ‹ Ñ‚Ñ€ÐµÐ±ÑƒÑŽÑ‚ Ð¿Ñ€Ð°Ð² Ð°Ð´Ð¼Ð¸Ð½Ð¸ÑÑ‚Ñ€Ð°Ñ‚Ð¾Ñ€Ð°. ÐŸÐµÑ€ÐµÐ´ Ð·Ð°Ð¿ÑƒÑÐºÐ¾Ð¼ Ð¿Ñ€Ð¾Ð²ÐµÑ€ÑŒ ÑÐ¾Ð´ÐµÑ€Ð¶Ð¸Ð¼Ð¾Ðµ ÑÐºÑ€Ð¸Ð¿Ñ‚Ð¾Ð² â€” Ð½Ðµ Ð·Ð°Ð¿ÑƒÑÐºÐ°Ð¹ Ð²ÑÐ»ÐµÐ¿ÑƒÑŽ. ÐÐ²Ñ‚Ð¾Ñ€ Ð½Ðµ Ð½ÐµÑÑ‘Ñ‚ Ð¾Ñ‚Ð²ÐµÑ‚ÑÑ‚Ð²ÐµÐ½Ð½Ð¾ÑÑ‚Ð¸ Ð·Ð° Ð»ÑŽÐ±Ð¾Ð¹ ÑƒÑ‰ÐµÑ€Ð±.

## ÐšÐ¾Ð¼Ñƒ Ð¿Ð¾Ð´Ð¾Ð¹Ð´Ñ‘Ñ‚

- ÐŸÐ¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ñ‚ÐµÐ»Ð¸, Ð½Ð°Ð¿Ñ€Ð°Ð²Ð»ÑÑŽÑ‰Ð¸Ðµ Ñ‚Ñ€Ð°Ñ„Ð¸Ðº Ñ‡ÐµÑ€ÐµÐ· Ð»Ð¸Ñ‡Ð½Ñ‹Ð¹ Ð¿Ñ€Ð¾ÐºÑÐ¸/VPN-ÑÐµÑ€Ð²ÐµÑ€ Ð·Ð° Ñ€ÑƒÐ±ÐµÐ¶Ð¾Ð¼
- ÐŸÑ€Ð¾Ñ‚Ð¾ÐºÐ¾Ð»Ñ‹ VLESS+Reality, Trojan, Hysteria2, Shadowsocks2022 Ð¿Ð¾Ð²ÐµÑ€Ñ… TCP
- Windows 10/11 (PowerShell 5.1+)
- Ð¢Ðµ, ÐºÑ‚Ð¾ Ñ…Ð¾Ñ‡ÐµÑ‚ Ð¸ÑÐºÐ»ÑŽÑ‡Ð¸Ñ‚ÑŒ ÑƒÑ‚ÐµÑ‡ÐºÐ¸ Ñ€ÐµÐ°Ð»ÑŒÐ½Ð¾Ð³Ð¾ IP Ñ‡ÐµÑ€ÐµÐ· WebRTC/DNS/IPv6/QUIC

## Ð§Ñ‚Ð¾ Ð´ÐµÐ»Ð°ÐµÑ‚

| Ð¤Ð°Ð·Ð° | Ð§Ñ‚Ð¾ | Ð¡ÐºÑ€Ð¸Ð¿Ñ‚ |
|---|---|---|
| 1 | Ð‘Ð»Ð¾ÐºÐ¸Ñ€Ð¾Ð²ÐºÐ° STUN/TURN/mDNS + Ð²ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Ñ„Ð°Ð¹Ñ€Ð²Ð¾Ð»Ð° + Ð¾Ñ‚ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ LLMNR | `scripts/block-webrtc.ps1` |
| 2 | ÐŸÐ¾Ð»Ð½Ð¾Ðµ Ð¾Ñ‚ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ QUIC (msquic, HTTP/3, Ð¿Ð¾Ð»Ð¸Ñ‚Ð¸ÐºÐ¸ Chrome/Edge/Firefox, UDP 443) | `scripts/disable-quic.ps1` |
| 3 | ÐŸÐ¾Ð»Ð½Ð¾Ðµ Ð¾Ñ‚ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ IPv6 (Ð±Ð¸Ð½Ð´Ð¸Ð½Ð³Ð¸, Teredo/6to4/ISATAP/IP-HTTPS, DisabledComponents) | `scripts/disable-ipv6-full.ps1` |
| 4 | ÐžÐ¿Ñ‚Ð¸Ð¼Ð¸Ð·Ð°Ñ†Ð¸Ñ TCP ÑÑ‚ÐµÐºÐ° (DefaultTTL=128, Ð¾Ñ‚ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Fast Open/ECN/Timestamps/Heuristics, Nagle off) | `scripts/tcp-stack-tuning.ps1` |
| 5a | ÐžÑ‚ÐºÐ»ÑŽÑ‡ÐµÐ½Ð¸Ðµ Ñ‚ÐµÐ»ÐµÐ¼ÐµÑ‚Ñ€Ð¸Ð¸ + Ð±Ð»Ð¾ÐºÐ¸Ñ€Ð¾Ð²ÐºÐ° Ð´Ð¾Ð¼ÐµÐ½Ð¾Ð² Ð² hosts + Cortana/Cloud search off | `scripts/telemetry-block.ps1` |
| 5b | ÐžÑÑ‚Ð°Ð½Ð¾Ð²ÐºÐ° Ð»Ð¸ÑˆÐ½Ð¸Ñ… ÑÐ»ÑƒÐ¶Ð± + Ð±Ð»Ð¾ÐºÐ¸Ñ€Ð¾Ð²ÐºÐ° SSDP/LLMNR + mDNS off | `scripts/fix-all.ps1` |
| 6 | Watcher-Ð·Ð°Ð´Ð°Ñ‡Ð°: Ð´ÐµÑ€Ð¶Ð¸Ñ‚ MTU 1380 + IPv6 off Ð½Ð° TUN-Ð°Ð´Ð°Ð¿Ñ‚ÐµÑ€Ðµ | `scripts/mtu-watcher.ps1` + `scripts/create-task-schtasks.ps1` |
| 7 | Ð¤Ð¸Ð½Ð°Ð»ÑŒÐ½Ñ‹Ð¹ Ð°ÑƒÐ´Ð¸Ñ‚ (17 ÐºÐ°Ñ‚ÐµÐ³Ð¾Ñ€Ð¸Ð¹ Ð¿Ñ€Ð¾Ð²ÐµÑ€Ð¾Ðº, Ñ†ÐµÐ»ÑŒ â€” 0 FAIL) | `scripts/final-audit.ps1` |

## Ð£ÑÑ‚Ð°Ð½Ð¾Ð²ÐºÐ°

### Ð¡Ð¿Ð¾ÑÐ¾Ð± A â€” ÐºÐ°Ðº ÑÐºÐ¸Ð»Ð» Ð´Ð»Ñ pi coding agent

Ð’ `~/.pi/settings.json`:
```json
{
  "skills": [
    "https://github.com/dobrdigital/ru-windows11-no-leaks-script"
  ]
}
```
Ð˜Ð»Ð¸ Ð²Ñ€ÑƒÑ‡Ð½ÑƒÑŽ:
```bash
git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git ~/.pi/agent/skills/ru-windows11-no-leaks-script
```

### Ð¡Ð¿Ð¾ÑÐ¾Ð± B â€” ÐºÐ°Ðº Ð½Ð°Ð±Ð¾Ñ€ ÑÐºÑ€Ð¸Ð¿Ñ‚Ð¾Ð² (Ð±ÐµÐ· pi)

```bash
git clone https://github.com/dobrdigital/ru-windows11-no-leaks-script.git
cd ru-windows11-no-leaks-script/scripts
```

## Ð˜ÑÐ¿Ð¾Ð»ÑŒÐ·Ð¾Ð²Ð°Ð½Ð¸Ðµ (Ð±ÐµÐ· pi)

1. **Ð£Ð·Ð½Ð°Ð¹ Ð¸Ð¼Ñ ÑÐ²Ð¾ÐµÐ³Ð¾ TUN-Ð°Ð´Ð°Ð¿Ñ‚ÐµÑ€Ð°:**
   ```powershell
   Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
   ```
   Ð¢Ð¸Ð¿Ð¸Ñ‡Ð½Ñ‹Ðµ Ð¸Ð¼ÐµÐ½Ð°: `happ-default-tun`, `Mihomo`, `Clash`, `sing-box`, `wgtunnel`.

2. **ÐžÑ‚Ñ€ÐµÐ´Ð°ÐºÑ‚Ð¸Ñ€ÑƒÐ¹ Ð¿ÐµÑ€ÐµÐ¼ÐµÐ½Ð½Ñ‹Ðµ Ð¿Ð¾Ð´ ÑÐµÐ±Ñ:**
   - `scripts/mtu-watcher.ps1` -> `$tunName = "happ-default-tun"`
   - `scripts/final-audit.ps1` -> `$tunName = "happ-default-tun"`
   - `scripts/create-task-schtasks.ps1` -> Ð¿ÑƒÑ‚ÑŒ Ðº `mtu-watcher.ps1`

3. **Ð—Ð°Ð¿ÑƒÑÐºÐ°Ð¹ Ñ„Ð°Ð·Ñ‹ Ð¿Ð¾ Ð¿Ð¾Ñ€ÑÐ´ÐºÑƒ Ð¾Ñ‚ Ð°Ð´Ð¼Ð¸Ð½Ð¸ÑÑ‚Ñ€Ð°Ñ‚Ð¾Ñ€Ð°:**
   ```powershell
   cd C:\path\to\ru-windows11-no-leaks-script\scripts
   .\block-webrtc.ps1
   .\disable-quic.ps1
   .\disable-ipv6-full.ps1
   # -> ÐŸÐ•Ð Ð•Ð—ÐÐ“Ð Ð£Ð—Ð˜ ÐŸÐš
   .\tcp-stack-tuning.ps1
   .\telemetry-block.ps1
   .\fix-all.ps1
   # -> ÐŸÐ•Ð Ð•Ð—ÐÐ“Ð Ð£Ð—Ð˜ ÐŸÐš
   .\create-task-schtasks.ps1
   .\final-audit.ps1
   ```

4. **ÐŸÑ€Ð¾Ð²ÐµÑ€ÑŒ Ñ€ÐµÐ·ÑƒÐ»ÑŒÑ‚Ð°Ñ‚ Ð²Ñ€ÑƒÑ‡Ð½ÑƒÑŽ** Ð² Ð±Ñ€Ð°ÑƒÐ·ÐµÑ€Ðµ:
   - https://browserleaks.com/ip â€” IP Ð´Ð¾Ð»Ð¶ÐµÐ½ Ð±Ñ‹Ñ‚ÑŒ Ñ‚Ð²Ð¾ÐµÐ³Ð¾ ÑÐµÑ€Ð²ÐµÑ€Ð°, WebRTC Local IP = n/a, IPv6 = n/a
   - https://ipleak.net â€” DNS Ð´Ð¾Ð»Ð¶ÐµÐ½ Ð¿Ð¾ÐºÐ°Ð·Ñ‹Ð²Ð°Ñ‚ÑŒ Ñ‚Ð¾Ð»ÑŒÐºÐ¾ DNS Ñ‚ÑƒÐ½Ð½ÐµÐ»Ñ
   - https://quic.mitmproxy.org â€” Ð´Ð¾Ð»Ð¶ÐµÐ½ Ð½Ðµ Ð·Ð°Ð³Ñ€ÑƒÐ·Ð¸Ñ‚ÑŒÑÑ (QUIC off)

## ÐšÐ»ÑŽÑ‡ÐµÐ²Ñ‹Ðµ Ð¿Ð°Ñ€Ð°Ð¼ÐµÑ‚Ñ€Ñ‹

| ÐŸÐ°Ñ€Ð°Ð¼ÐµÑ‚Ñ€ | Ð—Ð½Ð°Ñ‡ÐµÐ½Ð¸Ðµ | ÐŸÐ¾Ñ‡ÐµÐ¼Ñƒ |
|---|---|---|
| MTU Ð½Ð° TUN | 1380 | ÐžÐ¿Ñ‚Ð¸Ð¼Ð°Ð»ÑŒÐ½Ð¾ Ð´Ð»Ñ VLESS+Reality Ð¿Ð¾Ð²ÐµÑ€Ñ… TCP, Ð¸ÑÐºÐ»ÑŽÑ‡Ð°ÐµÑ‚ Ñ„Ñ€Ð°Ð³Ð¼ÐµÐ½Ñ‚Ð°Ñ†Ð¸ÑŽ |
| DefaultTTL | 128 | Windows fingerprint (Linux=64 Ñ‡Ð°ÑÑ‚Ð¾ Ð¿ÑƒÑ‚Ð°ÑŽÑ‚ Ñ Android) |
| QUIC | Ð¿Ð¾Ð»Ð½Ð¾ÑÑ‚ÑŒÑŽ off | QUIC (UDP 443) Ð½ÐµÑÑ‚Ð°Ð±Ð¸Ð»ÐµÐ½ Ñ‡ÐµÑ€ÐµÐ· Ð¿Ñ€Ð¾ÐºÑÐ¸, ÑÐ¾Ð·Ð´Ð°Ñ‘Ñ‚ ÑƒÑ‚ÐµÑ‡ÐºÐ¸ |
| IPv6 | Ð¿Ð¾Ð»Ð½Ð¾ÑÑ‚ÑŒÑŽ off | IPv6 Ñ‡Ð°ÑÑ‚Ð¾ Ð¾Ð±Ñ…Ð¾Ð´Ð¸Ñ‚ TUN, ÑƒÑ‚ÐµÑ‡ÐºÐ¸ Ñ€ÐµÐ°Ð»ÑŒÐ½Ð¾Ð³Ð¾ IP |
| LLMNR/NBT-NS/mDNS | off | Ð›Ð¾ÐºÐ°Ð»ÑŒÐ½Ð¾Ðµ Ð¾Ð±Ð½Ð°Ñ€ÑƒÐ¶ÐµÐ½Ð¸Ðµ = ÑƒÑ‚ÐµÑ‡ÐºÐ° Ð¸Ð¼ÐµÐ½Ð¸ Ñ…Ð¾ÑÑ‚Ð°/ÑÐµÑ‚Ð¸ |
| TCP Fast Open | off | ÐœÐ¾Ð¶ÐµÑ‚ Ð¼ÐµÑˆÐ°Ñ‚ÑŒ Ð¿Ñ€Ð¾ÐºÑÐ¸-Ñ‚ÑƒÐ½Ð½ÐµÐ»Ð¸Ñ€Ð¾Ð²Ð°Ð½Ð¸ÑŽ, ÑÐ¾Ð·Ð´Ð°Ñ‘Ñ‚ fingerprint |

## Ð§Ð°ÑÑ‚Ñ‹Ðµ Ð³Ñ€Ð°Ð±Ð»Ð¸

- **TCP/IP Fingerprint Ð½Ð° browserleaks Ð¿Ð¾ÐºÐ°Ð·Ñ‹Ð²Ð°ÐµÑ‚ Android / MTU 1500** â€” ÑÑ‚Ð¾ ÐÐ• ÑƒÑ‚ÐµÑ‡ÐºÐ°. Browserleaks Ð²Ð¸Ð´Ð¸Ñ‚ Ð¿Ð¾ÑÐ»ÐµÐ´Ð½Ð¸Ð¹ ÑƒÑ‡Ð°ÑÑ‚Ð¾Ðº (Ñ‚Ð²Ð¾Ð¹ ÑÐµÑ€Ð²ÐµÑ€ â†’ ÑÐ°Ð¹Ñ‚), Ð° Ð½Ðµ Ñ‚Ð²Ð¾Ð¹ ÐŸÐš.
- **`Get-NetIPInterface NlMtuBytes` Ð¿ÑƒÑÑ‚Ð¾Ð¹ Ð´Ð»Ñ TUN-Ð°Ð´Ð°Ð¿Ñ‚ÐµÑ€Ð¾Ð²** â€” Ð±Ð°Ð³ PowerShell. MTU Ð¿Ñ€Ð¾Ð²ÐµÑ€ÑÐ¹ Ñ‡ÐµÑ€ÐµÐ· `netsh interface ipv4 show subinterface`.
- **HAPP Ð¸Ð³Ð½Ð¾Ñ€Ð¸Ñ€ÑƒÐµÑ‚ `mtu` Ð² config.json** â€” Ð¾ÑÐ¾Ð±ÐµÐ½Ð½Ð¾ÑÑ‚ÑŒ Ð´Ñ€Ð°Ð¹Ð²ÐµÑ€Ð°. Ð ÐµÑˆÐµÐ½Ð¸Ðµ: watcher-Ð·Ð°Ð´Ð°Ñ‡Ð°.

## Ð”Ð¾ÐºÑƒÐ¼ÐµÐ½Ñ‚Ð°Ñ†Ð¸Ñ

- [SKILL.md](SKILL.md) â€” Ð³Ð»Ð°Ð²Ð½Ñ‹Ð¹ Ñ„Ð°Ð¹Ð» ÑÐºÐ¸Ð»Ð»Ð°
- [references/troubleshooting.md](references/troubleshooting.md) â€” Ñ‚Ð¸Ð¿Ð¸Ñ‡Ð½Ñ‹Ðµ Ð¿Ñ€Ð¾Ð±Ð»ÐµÐ¼Ñ‹
- [references/scripts-reference.md](references/scripts-reference.md) â€” Ð¾Ð¿Ð¸ÑÐ°Ð½Ð¸Ðµ ÑÐºÑ€Ð¸Ð¿Ñ‚Ð¾Ð²

## Ð›Ð¸Ñ†ÐµÐ½Ð·Ð¸Ñ

MIT â€” ÑÐ¼. [LICENSE](LICENSE).

## ÐžÑ‚ÐºÐ°Ð· Ð¾Ñ‚ Ð¾Ñ‚Ð²ÐµÑ‚ÑÑ‚Ð²ÐµÐ½Ð½Ð¾ÑÑ‚Ð¸

Ð¡ÐºÑ€Ð¸Ð¿Ñ‚Ñ‹ Ð¿Ñ€ÐµÐ´Ð¾ÑÑ‚Ð°Ð²Ð»ÑÑŽÑ‚ÑÑ "ÐºÐ°Ðº ÐµÑÑ‚ÑŒ" Ð±ÐµÐ· ÐºÐ°ÐºÐ¸Ñ…-Ð»Ð¸Ð±Ð¾ Ð³Ð°Ñ€Ð°Ð½Ñ‚Ð¸Ð¹. ÐÐ²Ñ‚Ð¾Ñ€ Ð½Ðµ Ð½ÐµÑÑ‘Ñ‚ Ð¾Ñ‚Ð²ÐµÑ‚ÑÑ‚Ð²ÐµÐ½Ð½Ð¾ÑÑ‚Ð¸ Ð·Ð° Ð»ÑŽÐ±Ð¾Ð¹ ÑƒÑ‰ÐµÑ€Ð±.