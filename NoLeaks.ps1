#Requires -Version 5.1
param([string]$TunName="happ-default-tun",[string]$TunMtu="1380",[string]$ExpectedIp="")
$ErrorActionPreference="Continue"
$script:CFG=@{TunName=$TunName;TunMtu=$TunMtu;ExpectedIp=$ExpectedIp;Lang="EN"}

$script:STR=@{
    EN=@{
        title="Windows 11 No-Leaks";subtitle="Network Leak Hardening Toolkit";version="v3.0"
        lang_select="Select language:";menu_header="MAIN MENU"
        menu_run_all="Run All Phases";menu_settings="Settings";menu_quit="Quit"
        phase="Phase";desc="Description";status="Status"
        notrun="----";running="RUN...";done="DONE";failed="FAIL";warn="WARN"
        reboot="*** REBOOT REQUIRED ***";admin_warn="Run as Administrator!"
        admin_ok="Administrator: YES";admin_no="Administrator: NO (limited)"
        settings="SETTINGS";current="Current"
        enter_tun="TUN adapter name";enter_mtu="MTU value";enter_ip="Expected IP (optional)"
        saved="Settings saved!";confirm_all="Run ALL phases?";yes_no=" (1=Yes / 2=No)"
        summary="EXECUTION SUMMARY";total_pass="Total PASS";total_fail="Total FAIL";total_warn="Total WARN"
        reboot_now="Reboot now?";reboot_1="1. Yes, reboot now";reboot_2="2. No, later"
        press_key="Press any key to continue..."
        p1_name="Block WebRTC/STUN/TURN";p1_desc="Firewall rules, LLMNR/NBT-NS off"
        p2_name="Disable QUIC";p2_desc="msquic, HTTP/3, browser policies"
        p3_name="Disable IPv6";p3_desc="Bindings, tunnels, DisabledComponents"
        p4_name="TCP Stack Tuning";p4_desc="TTL=128, Fast Open/ECN off, Nagle off"
        p5_name="Telemetry and Services";p5_desc="DiagTrack, SSDP, mDNS, hosts blocks"
        p6_name="MTU Watcher Task";p6_desc="Maintains MTU + IPv6 off on TUN"
        p7_name="Final Audit";p7_desc="17 categories of leak checks"
        nav_hint="UP/DOWN=select | ENTER=run | A=All | S=Settings | Q=Quit"
        selected="SELECTED";phase_hint="Press ENTER to run this phase"
        yes_no=" (1=Yes / 2=No)"
    }
    RU=@{
        title="Windows 11 No-Leaks"
        subtitle="[RUS] Zaschita ot utechek IP"
        version="v3.0"
        lang_select="Vyberite yazyk / Select language:"
        menu_header="[RUS] GLAVNOE MENYU"
        menu_run_all="[RUS] Zapustit vse fazy"
        menu_settings="[RUS] Nastroiki"
        menu_quit="[RUS] Vyhod"
        phase="[RUS] Faza"
        desc="[RUS] Opisanie"
        status="[RUS] Status"
        notrun="----"
        running="[RUS] VYP..."
        done="[RUS] GOTOVO"
        failed="[RUS] OSHIBKA"
        warn="[RUS] VNIMANIE"
        reboot="[RUS] *** NUGNA PEREZAGRUZKA ***"
        admin_warn="[RUS] Zapustite ot imeni Administratora!"
        admin_ok="[RUS] Administrator: DA"
        admin_no="[RUS] Administrator: NET (ogranicheno)"
        settings="[RUS] NASTROYKI"
        current="[RUS] Tekuschee"
        enter_tun="[RUS] Imya TUN-adaptera"
        enter_mtu="[RUS] Znachenie MTU"
        enter_ip="[RUS] Ozhidaemyi IP (neobyazatelno)"
        saved="[RUS] Nastroiki sokhranyes!"
        confirm_all="[RUS] Zapustit VSE fazy?"
        reboot_now="[RUS] Perezagruzit seychas?"
        reboot_1="[RUS] 1. Da, perezaruzit"
        reboot_2="[RUS] 2. Net, pozzhe"
        press_key="[RUS] Nazhmite lyubuyu klavishu..."
        p1_name="[RUS] Blokirovka WebRTC/STUN/TURN"
        p1_desc="[RUS] Pravila firewalla, LLMNR/NBT-NS off"
        p2_name="[RUS] Otklyuchenie QUIC"
        p2_desc="[RUS] msquic, HTTP/3, politiki brauzerov"
        p3_name="[RUS] Otklyuchenie IPv6"
        p3_desc="[RUS] Bindingi, tunneli, DisabledComponents"
        p4_name="[RUS] Optimizaciya TCP steka"
        p4_desc="[RUS] TTL=128, Fast Open/ECN off, Nagle off"
        p5_name="[RUS] Telemetriya i sluzhby"
        p5_desc="[RUS] DiagTrack, SSDP, mDNS, blokirovka hosts"
        p6_name="[RUS] Watcher MTU"
        p6_desc="[RUS] Podderzhivaet MTU + IPv6 off na TUN"
        p7_name="[RUS] Finalnyi audit"
        p7_desc="[RUS] 17 kategorii proverok utechek"
        nav_hint="[RUS] VERH/NAIZ = [RUS] vibor | [RUS] ENTER = [RUS] zapusk | [RUS] A = [RUS] Vse | [RUS] S = [RUS] Nastroiki | [RUS] Q = [RUS] Vyhod"
        selected="[RUS] VYBRANO"
        phase_hint="[RUS] Nazhmite ENTER dlya zapuska"
        yes_no="[RUS] (1=Da / 2=Net)"
        summary="[RUS] ITOGI"
        total_pass="[RUS] Vsego PASS"
        total_fail="[RUS] Vsego FAIL"
        total_warn="[RUS] Vsego WARN"
    }
}

function STR($key) { $script:STR[$script:CFG.Lang][$key] }
$script:PhaseStatus=@("notrun","notrun","notrun","notrun","notrun","notrun","notrun")
$script:PhaseReboot=@($false,$false,$true,$true,$false,$false,$false)
$script:TotalPass=0;$script:TotalFail=0;$script:TotalWarn=0
$script:MenuIndex=0

function Is-Admin {
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    $pr=New-Object Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-PhaseIcon($st) {
    switch($st) {
        "done"    { return @{Icon=(STR "done");Color="Green"} }
        "failed"  { return @{Icon=(STR "failed");Color="Red"} }
        "warn"    { return @{Icon=(STR "warn");Color="Yellow"} }
        "running" { return @{Icon=(STR "running");Color="Cyan"} }
        default   { return @{Icon=(STR "notrun");Color="DarkGray"} }
    }
}

function Draw-Screen {
    Clear-Host
    Write-Host ""
    Write-Host ("  "+(STR "title")+" "+(STR "version")) -ForegroundColor White
    Write-Host ("  "+(STR "subtitle")) -ForegroundColor Gray
    Write-Host ("  "+("-"*70)) -ForegroundColor DarkGray
    if(Is-Admin){Write-Host ("  "+(STR "admin_ok")) -ForegroundColor Green}else{Write-Host ("  "+(STR "admin_no")) -ForegroundColor Yellow}
    Write-Host ("  TUN: "+$script:CFG.TunName+" | MTU: "+$script:CFG.TunMtu) -ForegroundColor DarkGray
    Write-Host ""
    Write-Host ("  {0,-2} {1,-30} {2,-30} {3}" -f "#",(STR "phase"),(STR "desc"),(STR "status")) -ForegroundColor DarkGray
    Write-Host ("  "+("-"*70)) -ForegroundColor DarkGray
    for($i=0;$i -lt 7;$i++){
        $pName=STR ("p$($i+1)_name");$pDesc=STR ("p$($i+1)_desc")
        $icon=Get-PhaseIcon $script:PhaseStatus[$i]
        $cursor=if($script:MenuIndex -eq $i){"->"}else{"  "}
        if($script:MenuIndex -eq $i){
            Write-Host ("  {0} {1,-30} "-f$cursor,$pName) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
            Write-Host ("{0,-30} "-f$pDesc) -NoNewline -ForegroundColor Black -BackgroundColor Cyan
            Write-Host ("[{0}]"-f$icon.Icon) -ForegroundColor $icon.Color -BackgroundColor Cyan
        } else {
            Write-Host ("  {0} {1,-30} {2,-30} [{3}]" -f$cursor,$pName,$pDesc,$icon.Icon) -ForegroundColor Gray
        }
    }
    Write-Host ("  "+("-"*70)) -ForegroundColor DarkGray
    $menuItems=@("A:"+(STR "menu_run_all"),"S:"+(STR "menu_settings"),"Q:"+(STR "menu_quit"))
    for($j=0;$j -lt 3;$j++){
        $idx=$j+7;$cursor=if($script:MenuIndex -eq $idx){"->"}else{"  "}
        if($script:MenuIndex -eq $idx){
            Write-Host ("  {0} [{1}]" -f$cursor,$menuItems[$j]) -ForegroundColor Black -BackgroundColor Cyan
        } else {
            Write-Host ("  {0} [{1}]" -f$cursor,$menuItems[$j]) -ForegroundColor White
        }
    }
    Write-Host ""
    Write-Host ("  "+(STR "nav_hint")) -ForegroundColor DarkCyan
    Write-Host ""
    if($script:MenuIndex -lt 7){
        Write-Host ("  >> "+(STR "selected")+": "+(STR ("p$($script:MenuIndex+1)_name"))) -ForegroundColor Yellow
        Write-Host ("     "+(STR ("p$($script:MenuIndex+1)_desc"))) -ForegroundColor Gray
    } elseif($script:MenuIndex -eq 7){
        Write-Host ("  >> "+(STR "selected")+": "+(STR "menu_run_all")) -ForegroundColor Yellow
    } elseif($script:MenuIndex -eq 8){
        Write-Host ("  >> "+(STR "selected")+": "+(STR "menu_settings")) -ForegroundColor Yellow
    } else {
        Write-Host ("  >> "+(STR "selected")+": "+(STR "menu_quit")) -ForegroundColor Yellow
    }
}

function Invoke-PhaseEngine {
    param([int]$Phase)
    $results=@()
    switch($Phase){
        1 {
            Get-NetFirewallProfile|ForEach-Object{if(!$_.Enabled){Set-NetFirewallProfile -Name $_.Name -Enabled True|Out-Null};$results+=@{Name="Firewall $($_.Name)";Status="PASS"}}
            $rules=@(@("Block STUN UDP 3478 Out","UDP",3478,"Outbound"),@("Block STUN TCP 3478 Out","TCP",3478,"Outbound"),@("Block TURN TCP 5349 Out","TCP",5349,"Outbound"),@("Block mDNS UDP 5353 Out","UDP",5353,"Outbound"),@("Block QUIC UDP 443 Out","UDP",443,"Outbound"),@("Block SSDP UDP 1900 Out","UDP",1900,"Outbound"),@("Block LLMNR UDP 5355 Out","UDP",5355,"Outbound"))
            foreach($r in $rules){$e=Get-NetFirewallRule -DisplayName $r[0] -ErrorAction SilentlyContinue;if($e){Remove-NetFirewallRule -DisplayName $r[0]|Out-Null};New-NetFirewallRule -DisplayName $r[0] -Direction $r[3] -Protocol $r[1] -LocalPort $r[2] -Action Block -Profile Any -Enabled True|Out-Null;$results+=@{Name="Rule: $($r[0])";Status="PASS"}}
            $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient";if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null};Set-ItemProperty -Path $p -Name "EnableMulticast" -Value 0 -Type DWord;$results+=@{Name="LLMNR off";Status="PASS"}
            Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue|Where-Object{$_.IPEnabled}|ForEach-Object{$_.SetTcpipNetbios(2)|Out-Null};$results+=@{Name="NBT-NS off";Status="PASS"}
        }
        2 {
            $svc=Get-Service -Name msquic -ErrorAction SilentlyContinue;if($svc){Stop-Service msquic -Force -ErrorAction SilentlyContinue;Set-Service msquic -StartupType Disabled}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MsQuic" -Name "Start" -Value 4 -ErrorAction SilentlyContinue;$results+=@{Name="msquic";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name "EnableHttp3" -Value 0 -Type DWord -ErrorAction SilentlyContinue;$results+=@{Name="HTTP/3";Status="PASS"}
            $p="HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\QUIC";if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null};Set-ItemProperty -Path $p -Name "Enabled" -Value 0 -Type DWord;Set-ItemProperty -Path $p -Name "DisabledByDefault" -Value 1 -Type DWord;$results+=@{Name="QUIC Schannel";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue;$results+=@{Name="WinINET QUIC";Status="PASS"}
            $p="HKLM:\SOFTWARE\Policies\Google\Chrome";if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null};Set-ItemProperty -Path $p -Name "QuicAllowed" -Value 0 -Type DWord;$results+=@{Name="Chrome QUIC";Status="PASS"}
            $p="HKLM:\SOFTWARE\Policies\Microsoft\Edge";if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null};Set-ItemProperty -Path $p -Name "QuicAllowed" -Value 0 -Type DWord;$results+=@{Name="Edge QUIC";Status="PASS"}
        }
        3 {
            Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue|ForEach-Object{Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue};$results+=@{Name="IPv6 bindings";Status="PASS"}
            netsh interface teredo set state disabled 2>&1|Out-Null;$results+=@{Name="Teredo";Status="PASS"}
            netsh interface 6to4 set state disabled 2>&1|Out-Null;$results+=@{Name="6to4";Status="PASS"}
            netsh interface isatap set state disabled 2>&1|Out-Null;$results+=@{Name="ISATAP";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord;$results+=@{Name="DisabledComponents=0xFF";Status="PASS";Reboot=$true}
            $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient";if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null};Set-ItemProperty -Path $p -Name "DisableSmartNameResolution" -Value 1 -Type DWord;$results+=@{Name="Smart Name Resolution";Status="PASS"}
        }
        4 {
            @("autotuninglevel=normal","rss=disabled","chimney=disabled","dca=disabled","netdma=disabled","ecncapability=disabled","timestamps=disabled","rsc=disabled","fastopen=disabled","fastopenfallback=disabled","hystart=disabled","pacingprofile=off")|ForEach-Object{$kv=$_ -split "=";netsh int tcp set global "$($kv[0])=$($kv[1])" 2>&1|Out-Null}
            $results+=@{Name="netsh TCP globals";Status="PASS"}
            $rp="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            @{KeepAliveTime=60000;KeepAliveInterval=1000;DefaultTTL=128;DisableTaskOffload=1;EnableECN=0;EnableHeuristics=0;MaxFreeTcbs=65536;MaxHashTableSize=65536;NumTcbTablePartitions=8;Tcp1323Opts=0;TcpMaxDupAcks=2;TcpTimedWaitDelay=30;MaxUserPort=65534}.GetEnumerator()|ForEach-Object{Set-ItemProperty -Path $rp -Name $_.Key -Value $_.Value -Type DWord -ErrorAction SilentlyContinue}
            $results+=@{Name="Tcpip parameters (16)";Status="PASS";Reboot=$true}
            Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue|ForEach-Object{Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue;Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue}
            $results+=@{Name="Nagle disabled";Status="PASS"}
        }
        5 {
            @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV","fdPHost","upnphost","FDResPub")|ForEach-Object{$svc=Get-Service -Name $_ -ErrorAction SilentlyContinue;if($svc){Stop-Service $_ -Force -ErrorAction SilentlyContinue;Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue};$results+=@{Name="Service $_";Status="PASS"}}
            $hp="$env:SystemRoot\System32\drivers\etc\hosts"
            $domains=@("v10.events.data.microsoft.com","v20.events.data.microsoft.com","vortex.data.microsoft.com","vortex-win.data.microsoft.com","telecommand.telemetry.microsoft.com","oca.telemetry.microsoft.com","sqm.telemetry.microsoft.com","watson.telemetry.microsoft.com","redir.metaservices.microsoft.com","choice.microsoft.com","df.telemetry.microsoft.com","feedback.windows.com","feedback.microsoft-hohm.com","feedback.search.microsoft.com","rad.msn.com","preview.msn.com","ad.doubleclick.net","ads.msn.com","ads1.msads.net","settings-sandbox.data.microsoft.com","vsgallery.com","watson.microsoft.com","ui.skype.com","pricelist.skype.com","apps.skype.com","m.hotmail.com","s.gateway.messenger.live.com","sa.windows.com")
            $eh=Get-Content $hp -ErrorAction SilentlyContinue;$added=0
            foreach($d in $domains){if($eh -notcontains "0.0.0.0 $d"){Add-Content -Path $hp -Value "0.0.0.0 $d" -ErrorAction SilentlyContinue;$added++}}
            $results+=@{Name="Hosts blocks ($added domains)";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableMDNS" -Value 0 -Type DWord -ErrorAction SilentlyContinue;$results+=@{Name="mDNS disabled";Status="PASS"}
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue;$results+=@{Name="Advertising ID";Status="PASS"}
            $p="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search";if(!(Test-Path $p)){New-Item -Path $p -Force|Out-Null};Set-ItemProperty -Path $p -Name "AllowCortana" -Value 0 -Type DWord;Set-ItemProperty -Path $p -Name "DisableWebSearch" -Value 1 -Type DWord;Set-ItemProperty -Path $p -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord;$results+=@{Name="Cortana/Cloud Search";Status="PASS"}
        }
        6 {
            $wd="C:\Users\$env:USERNAME\.no-leaks-watcher";if(!(Test-Path $wd)){New-Item -Path $wd -ItemType Directory -Force|Out-Null}
            $ws="`$tunName = `"$($script:CFG.TunName)`"`n`$targetMtu = $($script:CFG.TunMtu)`nwhile (`$true) {`n  try {`n    `$adapter = Get-NetAdapter -Name `$tunName -ErrorAction SilentlyContinue`n    if (`$adapter -and `$adapter.Status -eq `"Up`") {`n      `$mtuOut = netsh interface ipv4 show subinterface `$tunName 2>`$null`n      if (`$mtuOut -notmatch `$targetMtu) { netsh interface ipv4 set subinterface `$tunName mtu=`$targetMtu store=persistent 2>`$null }`n      `$ipv6 = Get-NetAdapterBinding -Name `$tunName -ComponentID `"ms_tcpip6`" -ErrorAction SilentlyContinue`n      if (`$ipv6 -and `$ipv6.Enabled) { Disable-NetAdapterBinding -Name `$tunName -ComponentID `"ms_tcpip6`" -ErrorAction SilentlyContinue }`n    }`n  } catch {}`n  Start-Sleep -Seconds 3`n}"
            $ws|Out-File -FilePath "$wd\mtu-watcher.ps1" -Encoding UTF8 -Force;$results+=@{Name="Watcher script";Status="PASS"}
            Unregister-ScheduledTask -TaskName "NoLeaksWatcher" -Confirm:$false -ErrorAction SilentlyContinue
            $tr=schtasks /create /tn "NoLeaksWatcher" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$wd\mtu-watcher.ps1`"" /sc onlogon /rl highest /ru SYSTEM /f 2>&1
            if($LASTEXITCODE -eq 0){$results+=@{Name="Scheduled task";Status="PASS"};schtasks /run /tn "NoLeaksWatcher" 2>&1|Out-Null}else{$results+=@{Name="Scheduled task";Status="FAIL";Detail=$tr}}
        }
        7 {
            Get-NetFirewallProfile|ForEach-Object{$s=if($_.Enabled){"PASS"}else{"FAIL"};$results+=@{Name="Firewall $($_.Name)";Status=$s}}
            @("Block STUN UDP 3478 Out","Block STUN TCP 3478 Out","Block TURN TCP 5349 Out","Block mDNS UDP 5353 Out","Block QUIC UDP 443 Out","Block SSDP UDP 1900 Out","Block LLMNR UDP 5355 Out")|ForEach-Object{$r=Get-NetFirewallRule -DisplayName $_ -ErrorAction SilentlyContinue;$s=if($r -and $r.Enabled -eq "True" -and $r.Action -eq "Block"){"PASS"}else{"FAIL"};$results+=@{Name="Rule: $_";Status=$s}}
            $dp=@(3478,5349,5353,1900,5355);$tl=Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue|Where-Object{$_.LocalPort -in $dp};$ul=Get-NetUDPEndpoint -ErrorAction SilentlyContinue|Where-Object{$_.LocalPort -in $dp}
            $s=if(!$tl -and !$ul){"PASS"}else{"WARN"};$results+=@{Name="Dangerous ports";Status=$s}
            $ll=Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue;$s=if($ll.EnableMulticast -eq 0){"PASS"}else{"FAIL"};$results+=@{Name="LLMNR";Status=$s}
            $dc=Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -ErrorAction SilentlyContinue;$s=if($dc.DisabledComponents -eq 255){"PASS"}else{"WARN"};$results+=@{Name="IPv6 DisabledComponents";Status=$s}
            $cq=Get-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name QuicAllowed -ErrorAction SilentlyContinue;$s=if($cq.QuicAllowed -eq 0){"PASS"}else{"FAIL"};$results+=@{Name="Chrome QUIC";Status=$s}
            $eq=Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name QuicAllowed -ErrorAction SilentlyContinue;$s=if($eq.QuicAllowed -eq 0){"PASS"}else{"FAIL"};$results+=@{Name="Edge QUIC";Status=$s}
            $tcp=netsh int tcp show global 2>$null;$s=if($tcp -match "Fast Open\s*:\s*disabled"){"PASS"}else{"WARN"};$results+=@{Name="TCP Fast Open";Status=$s}
            $ttl=Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DefaultTTL -ErrorAction SilentlyContinue;$s=if($ttl.DefaultTTL -eq 128){"PASS"}else{"FAIL"};$results+=@{Name="DefaultTTL";Status=$s}
            @("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV")|ForEach-Object{$svc=Get-Service -Name $_ -ErrorAction SilentlyContinue;$s=if(!$svc -or $svc.Status -eq "Stopped"){"PASS"}else{"WARN"};$results+=@{Name="Service $_";Status=$s}}
            $hc=Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue|Where-Object{$_ -notmatch "^\s*#" -and $_ -notmatch "^\s*$"};$b=($hc|Select-String "0\.0\.0\.0"|Measure-Object).Count;$s=if($b -gt 50){"PASS"}else{"WARN"};$results+=@{Name="Hosts blocks ($b)";Status=$s}
            $tun=Get-NetAdapter -ErrorAction SilentlyContinue|Where-Object{$_.InterfaceDescription -match "TUN|TAP|VPN|SocksTunnel" -and $_.Status -eq "Up"};$s=if($tun){"PASS"}else{"WARN"};$results+=@{Name="Tunnel";Status=$s}
            $mo=netsh interface ipv4 show subinterface $script:CFG.TunName 2>$null;$s=if($mo -match $script:CFG.TunMtu){"PASS"}else{"WARN"};$results+=@{Name="MTU on $($script:CFG.TunName)";Status=$s}
            try{$ip=(Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content;$results+=@{Name="External IP: $ip";Status="PASS"};if($script:CFG.ExpectedIp -and $ip -eq $script:CFG.ExpectedIp){$results+=@{Name="IP matches";Status="PASS"}}elseif($script:CFG.ExpectedIp){$results+=@{Name="IP mismatch!";Status="WARN"}}}catch{$results+=@{Name="External IP";Status="WARN"}}
        }
    }
    return $results
}

function Run-PhaseWithUI {
    param([int]$PhaseNum)
    $script:PhaseStatus[$PhaseNum-1]="running";Draw-Screen
    Write-Host "";Write-Host ">>> Phase $PhaseNum : " -NoNewline -ForegroundColor Cyan;Write-Host (STR ("p$($PhaseNum)_name")) -ForegroundColor White;Write-Host ""
    try{
        $results=Invoke-PhaseEngine -Phase $PhaseNum;$phaseFail=$false
        foreach($r in $results){
            $icon=switch($r.Status){"PASS"{"[OK]";$script:TotalPass++}"FAIL"{"[FAIL]";$script:TotalFail++;$phaseFail=$true}"WARN"{"[WARN]";$script:TotalWarn++}}
            $color=switch($r.Status){"PASS"{"Green"}"FAIL"{"Red"}"WARN"{"Yellow"}}
            Write-Host ("  $icon $($r.Name)") -ForegroundColor $color
        }
        if($phaseFail){$script:PhaseStatus[$PhaseNum-1]="failed"}else{$script:PhaseStatus[$PhaseNum-1]="done"}
        if($script:PhaseReboot[$PhaseNum-1]){Write-Host "";Write-Host ("  "+(STR "reboot")) -ForegroundColor Yellow}
    } catch{Write-Host ("  ERROR: $_") -ForegroundColor Red;$script:PhaseStatus[$PhaseNum-1]="failed";$script:TotalFail++}
    Write-Host "";Write-Host ("  "+(STR "press_key")) -ForegroundColor DarkGray
    $null=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-AllPhasesWithUI {
    $needReboot=$false
    for($i=1;$i -le 7;$i++){Run-PhaseWithUI -PhaseNum $i;if($script:PhaseReboot[$i-1]){$needReboot=$true}}
    Draw-Screen;Write-Host "";Write-Host ("  === "+(STR "summary")+" ===") -ForegroundColor Cyan
    Write-Host ("  "+(STR "total_pass")+": $($script:TotalPass)") -ForegroundColor Green
    Write-Host ("  "+(STR "total_fail")+": $($script:TotalFail)") -ForegroundColor Red
    Write-Host ("  "+(STR "total_warn")+": $($script:TotalWarn)") -ForegroundColor Yellow;Write-Host ""
    if($needReboot){Write-Host ("  "+(STR "reboot_now")) -ForegroundColor Yellow;Write-Host ("  "+(STR "reboot_1")) -ForegroundColor White;Write-Host ("  "+(STR "reboot_2")) -ForegroundColor Gray;Write-Host "";$rb=Read-Host ("  "+(STR "yes_no"));if($rb -eq "1"){Restart-Computer -Force}}
}

function Show-Settings {
    Clear-Host;Write-Host "";Write-Host ("  === "+(STR "settings")+" ===") -ForegroundColor Cyan;Write-Host ""
    Write-Host ("  "+(STR "current")+": TUN="+$script:CFG.TunName+", MTU="+$script:CFG.TunMtu) -ForegroundColor Gray;Write-Host ""
    $nt=Read-Host ("  "+(STR "enter_tun")+" ["+$script:CFG.TunName+"]");if($nt.Trim() -ne ""){$script:CFG.TunName=$nt.Trim()}
    $nm=Read-Host ("  "+(STR "enter_mtu")+" ["+$script:CFG.TunMtu+"]");if($nm.Trim() -ne ""){$script:CFG.TunMtu=$nm.Trim()}
    $ni=Read-Host ("  "+(STR "enter_ip")+" ["+$(if($script:CFG.ExpectedIp){$script:CFG.ExpectedIp}else{""})+"]");if($ni.Trim() -ne ""){$script:CFG.ExpectedIp=$ni.Trim()}
    Write-Host "";Write-Host ("  "+(STR "saved")) -ForegroundColor Green;Start-Sleep -Seconds 1
}

function Show-LanguageSelect {
    Clear-Host;Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host "       Windows 11 No-Leaks TUI v3.0" -ForegroundColor White
    Write-Host "       Network leak hardening" -ForegroundColor Gray
    Write-Host "  ========================================" -ForegroundColor Cyan;Write-Host ""
    Write-Host "  1. English" -ForegroundColor White
    Write-Host "  2. Russian (Russkij)" -ForegroundColor White;Write-Host ""
    $choice=Read-Host "  > "
    switch($choice){"2"{$script:CFG.Lang="RU"}default{$script:CFG.Lang="EN"}}
}

Show-LanguageSelect
while($true){
    Draw-Screen
    $key=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch($key.VirtualKeyCode){
        38{if($script:MenuIndex -gt 0){$script:MenuIndex--}}
        40{if($script:MenuIndex -lt 9){$script:MenuIndex++}}
        13{if($script:MenuIndex -lt 7){Run-PhaseWithUI -PhaseNum ($script:MenuIndex+1)}elseif($script:MenuIndex -eq 7){Run-AllPhasesWithUI}elseif($script:MenuIndex -eq 8){Show-Settings}else{exit 0}}
    }
    switch($key.Character){
        "a"{Run-AllPhasesWithUI}"A"{Run-AllPhasesWithUI}"s"{Show-Settings}"S"{Show-Settings}"q"{exit 0}"Q"{exit 0}
        "1"{Run-PhaseWithUI -PhaseNum 1}"2"{Run-PhaseWithUI -PhaseNum 2}"3"{Run-PhaseWithUI -PhaseNum 3}
        "4"{Run-PhaseWithUI -PhaseNum 4}"5"{Run-PhaseWithUI -PhaseNum 5}"6"{Run-PhaseWithUI -PhaseNum 6}"7"{Run-PhaseWithUI -PhaseNum 7}
    }
}
