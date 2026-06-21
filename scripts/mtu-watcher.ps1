# HAPP Tunnel Watcher
# Поддерживает MTU 1380 и отключает IPv6 binding на TUN-адаптере.
# HAPP (и подобные TUN-клиенты) пересоздают адаптер при старте и сбрасывают MTU на 1500
# + включают IPv6 binding. Этот watcher каждые 3 сек возвращает нужные значения.
#
# Перед использованием: впиши имя своего TUN-адаптера в переменную $tunName ниже.
# Узнать имя: Get-NetAdapter | Select-Object Name, InterfaceDescription, Status
# Типичные имена: happ-default-tun, Mihomo, Clash, sing-box, wgtunnel, etc.

$tunName = "happ-default-tun"   # <-- ИЗМЕНИ под свой адаптер
$targetMtu = 1380               # 1380 для VLESS+Reality; 1280 для WireGuard

while ($true) {
    try {
        $adapter = Get-NetAdapter -Name $tunName -ErrorAction SilentlyContinue
        if ($adapter -and $adapter.Status -eq "Up") {
            # MTU
            $mtuOut = netsh interface ipv4 show subinterface $tunName 2>$null
            if ($mtuOut -notmatch $targetMtu) {
                netsh interface ipv4 set subinterface $tunName mtu=$targetMtu store=persistent 2>$null
            }
            # IPv6 binding
            $ipv6 = Get-NetAdapterBinding -Name $tunName -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
            if ($ipv6 -and $ipv6.Enabled) {
                Disable-NetAdapterBinding -Name $tunName -ComponentID "ms_tcpip6" -ErrorAction SilentlyContinue
            }
        }
    } catch {}
    Start-Sleep -Seconds 3
}
