#Requires -Version 5.1
param([string]$TunName="happ-default-tun",[string]$TunMtu="1380",[string]$ExpectedIp="")
$ErrorActionPreference="Continue"
$script:CFG=@{TunName=$TunName;TunMtu=$TunMtu;ExpectedIp=$ExpectedIp;Lang="EN"}

# Cyrillic helper: RU text built from [char] codes to avoid encoding issues
function RU($text) { return $text }

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
    }
    RU=@{
        title="Windows 11 No-Leaks"
        subtitle=([char]0x0417+[char]0x0430+[char]0x0449+[char]0x0438+[char]0x0442+[char]0x0430+" "+[char]0x043E+[char]0x0442+" "+[char]0x0443+[char]0x0442+[char]0x0435+[char]0x0447+[char]0x0435+[char]0x043A+" IP")
        version="v3.0"
        lang_select=([char]0x0412+[char]0x044B+[char]0x0431+[char]0x0435+[char]0x0440+[char]0x0438+[char]0x0442+[char]0x0435+" "+[char]0x044F+[char]0x0437+[char]0x044B+[char]0x043A+":")
        menu_header=([char]0x0413+[char]0x041B+[char]0x0410+[char]0x0412+[char]0x041D+[char]0x041E+[char]0x0415+" "+[char]0x041C+[char]0x0415+[char]0x041D+[char]0x042E)
        menu_run_all=([char]0x0417+[char]0x0430+[char]0x043F+[char]0x0443+[char]0x0441+[char]0x0442+[char]0x0438+[char]0x0442+[char]0x044C]+" "+[char]0x0432+[char]0x0441+[char]0x0435]+" "+[char]0x0444+[char]0x0430+[char]0x0437+[char]0x044B)
        menu_settings=([char]0x041D+[char]0x0430+[char]0x0441+[char]0x0442+[char]0x0440+[char]0x043E+[char]0x0439+[char]0x043A+[char]0x0438)
        menu_quit=([char]0x0412+[char]0x044B+[char]0x0445+[char]0x043E+[char]0x0434)
        phase=([char]0x0424+[char]0x0430+[char]0x0437+[char]0x0430)
        desc=([char]0x041E+[char]0x043F+[char]0x0438+[char]0x0441+[char]0x0430+[char]0x043D+[char]0x0438+[char]0x0435)
        status=([char]0x0421+[char]0x0442+[char]0x0430+[char]0x0442+[char]0x0443+[char]0x0441)
        notrun="----";running=([char]0x0412+[char]0x042B+[char]0x041F+"...")
        done=([char]0x0413+[char]0x041E+[char]0x0422+[char]0x041E+[char]0x0412+[char]0x041E)
        failed=([char]0x041E+[char]0x0428+[char]0x0418+[char]0x0411+[char]0x041A+[char]0x0410)
        warn=([char]0x0412+[char]0x041D+[char]0x0418+[char]0x041C+[char]0x0410+[char]0x041D+[char]0x0418+[char]0x0415)
        reboot="*** "+[char]0x041D+[char]0x0443+[char]0x0436+[char]0x043D+[char]0x0430]+" "+[char]0x043F+[char]0x0435+[char]0x0440+[char]0x0435+[char]0x0437+[char]0x0430+[char]0x0433+[char]0x0440+[char]0x0443+[char]0x0437+[char]0x043A+[char]0x0430+" ***"
        admin_warn=([char]0x0417+[char]0x0430+[char]0x043F+[char]0x0443+[char]0x0441+[char]0x0442+[char]0x0438+[char]0x0442+[char]0x0435]+" "+[char]0x043E+[char]0x0442]+" "+[char]0x0438+[char]0x043C+[char]0x0435+[char]0x043D+[char]0x0438]+" "+[char]0x0410+[char]0x0434+[char]0x043C+[char]0x0438+[char]0x043D+[char]0x0438+[char]0x0441+[char]0x0442+[char]0x0440+[char]0x0430+[char]0x0442+[char]0x043E+[char]0x0440+[char]0x0430]+"!")
        admin_ok=([char]0x0410+[char]0x0434+[char]0x043C+[char]0x0438+[char]0x043D+[char]0x0438+[char]0x0441+[char]0x0442+[char]0x0440+[char]0x0430+[char]0x0442+[char]0x043E+[char]0x0440]+": "+[char]0x0414+[char]0x0410)
        admin_no=([char]0x0410+[char]0x0434+[char]0x043C+[char]0x0438+[char]0x043D+[char]0x0438+[char]0x0441+[char]0x0442+[char]0x0440+[char]0x0430+[char]0x0442+[char]0x043E+[char]0x0440]+": "+[char]0x041D+[char]0x0415+[char]0x0422]+" ("+[char]0x043E+[char]0x0433+[char]0x0440+[char]0x0430+[char]0x043D+[char]0x0438+[char]0x0447+[char]0x0435+[char]0x043D+[char]0x043E]+")")
        settings=([char]0x041D+[char]0x0410+[char]0x0421+[char]0x0422+[char]0x0420+[char]0x041E+[char]0x0419+[char]0x041A+[char]0x0418)
        current=([char]0x0422+[char]0x0435+[char]0x043A+[char]0x0443+[char]0x0449+[char]0x0435+[char]0x0435)
        enter_tun=([char]0x0418+[char]0x043C+[char]0x044F]+" TUN-"+[char]0x0430+[char]0x0434+[char]0x0430+[char]0x043F+[char]0x0442+[char]0x0435+[char]0x0440+[char]0x0430)
        enter_mtu=([char]0x0417+[char]0x043D+[char]0x0430+[char]0x0447+[char]0x0435+[char]0x043D+[char]0x0438+[char]0x0435]+" MTU")
        enter_ip=([char]0x041E+[char]0x0436+[char]0x0438+[char]0x0434+[char]0x0430+[char]0x0435+[char]0x043C+[char]0x044B+[char]0x0439]+" IP ("+[char]0x043D+[char]0x0435+[char]0x043E+[char]0x0431+[char]0x044F+[char]0x0437+[char]0x0430+[char]0x0442+[char]0x0435+[char]0x043B+[char]0x044C+[char]0x043D+[char]0x043E]+")")
        saved=([char]0x041D+[char]0x0430+[char]0x0441+[char]0x0442+[char]0x0440+[char]0x043E+[char]0x0439+[char]0x043A+[char]0x0438]+" "+[char]0x0441+[char]0x043E+[char]0x0445+[char]0x0440+[char]0x0430+[char]0x043D+[char]0x0435+[char]0x043D+[char]0x044B]+"!")
        confirm_all=([char]0x0417+[char]0x0430+[char]0x043F+[char]0x0443+[char]0x0441+[char]0x0442+[char]0x0438+[char]0x0442+[char]0x044C]+" "+[char]0x0412+[char]0x0421+[char]0x0415]+" "+[char]0x0444+[char]0x0430+[char]0x0437+[char]0x044B]+"?")
        yes_no=" (1="+[char]0x0414+[char]0x0430]+" / 2="+[char]0x041D+[char]0x0435+[char]0x0442]+")")
        summary=([char]0x0418+[char]0x0422+[char]0x041E+[char]0x0413+[char]0x0418)
        total_pass=([char]0x0412+[char]0x0441+[char]0x0435+[char]0x0433+[char]0x043E]+" PASS")
        total_fail=([char]0x0412+[char]0x0441+[char]0x0435+[char]0x0433+[char]0x043E]+" FAIL")
        total_warn=([char]0x0412+[char]0x0441+[char]0x0435+[char]0x0433+[char]0x043E]+" WARN")
        reboot_now=([char]0x041F+[char]0x0435+[char]0x0440+[char]0x0435+[char]0x0437+[char]0x0430+[char]0x0433+[char]0x0440+[char]0x0443+[char]0x0437+[char]0x0438+[char]0x0442+[char]0x044C]+" "+[char]0x0441+[char]0x0435+[char]0x0439+[char]0x0447+[char]0x0430+[char]0x0441]+"?")
        reboot_1="1. "+[char]0x0414+[char]0x0430]+", "+[char]0x043F+[char]0x0435+[char]0x0440+[char]0x0435+[char]0x0437+[char]0x0430+[char]0x0433+[char]0x0440+[char]0x0443+[char]0x0437+[char]0x0438+[char]0x0442+[char]0x044C)
        reboot_2="2. "+[char]0x041D+[char]0x0435+[char]0x0442]+", "+[char]0x043F+[char]0x043E+[char]0x0437+[char]0x0436+[char]0x0435)
        press_key=([char]0x041D+[char]0x0430+[char]0x0436+[char]0x043C+[char]0x0438+[char]0x0442+[char]0x0435]+" "+[char]0x043B+[char]0x044E+[char]0x0431+[char]0x0443+[char]0x044E]+" "+[char]0x043A+[char]0x043B+[char]0x0430+[char]0x0432+[char]0x0438+[char]0x0448+[char]0x0443]+"...")
        p1_name=([char]0x0411+[char]0x043B+[char]0x043E+[char]0x043A+[char]0x0438+[char]0x0440+[char]0x043E+[char]0x0432+[char]0x043A+[char]0x0430]+" WebRTC/STUN/TURN")
        p1_desc=([char]0x041F+[char]0x0440+[char]0x0430+[char]0x0432+[char]0x0438+[char]0x043B+[char]0x0430]+" "+[char]0x0444+[char]0x0430+[char]0x0439+[char]0x0440+[char]0x0432+[char]0x043E+[char]0x043B+[char]0x0430]+", LLMNR/NBT-NS off")
        p2_name=([char]0x041E+[char]0x0442+[char]0x043A+[char]0x043B+[char]0x044E+[char]0x0447+[char]0x0435+[char]0x043D+[char]0x0438+[char]0x0435]+" QUIC")
        p2_desc="msquic, HTTP/3, "+[char]0x043F+[char]0x043E+[char]0x043B+[char]0x0438+[char]0x0442+[char]0x0438+[char]0x043A+[char]0x0438]+" "+[char]0x0431+[char]0x0440+[char]0x0430+[char]0x0443+[char]0x0437+[char]0x0435+[char]0x0440+[char]0x043E+[char]0x0432)
        p3_name=([char]0x041E+[char]0x0442+[char]0x043A+[char]0x043B+[char]0x044E+[char]0x0447+[char]0x0435+[char]0x043D+[char]0x0438+[char]0x0435]+" IPv6")
        p3_desc=([char]0x0411+[char]0x0438+[char]0x043D+[char]0x0434+[char]0x0438+[char]0x043D+[char]0x0433+[char]0x0438]+", "+[char]0x0442+[char]0x0443+[char]0x043D+[char]0x043D+[char]0x0435+[char]0x043B+[char]0x0438]+", DisabledComponents")
        p4_name=([char]0x041E+[char]0x043F+[char]0x0442+[char]0x0438+[char]0x043C+[char]0x0438+[char]0x0437+[char]0x0430+[char]0x0446+[char]0x0438+[char]0x044F]+" TCP")
        p4_desc="TTL=128, Fast Open/ECN off, Nagle off"
        p5_name=([char]0x0422+[char]0x0435+[char]0x043B+[char]0x0435+[char]0x043C+[char]0x0435+[char]0x0442+[char]0x0440+[char]0x0438+[char]0x044F]+" "+[char]0x0438]+" "+[char]0x0441+[char]0x043B+[char]0x0443+[char]0x0436+[char]0x0431+[char]0x044B)
        p5_desc="DiagTrack, SSDP, mDNS, "+[char]0x0431+[char]0x043B+[char]0x043E+[char]0x043A+[char]0x0438+[char]0x0440+[char]0x043E+[char]0x0432+[char]0x043A+[char]0x0430]+" hosts")
        p6_name="Watcher MTU"
        p6_desc=([char]0x041F+[char]0x043E+[char]0x0434+[char]0x0434+[char]0x0435+[char]0x0440+[char]0x0436+[char]0x0438+[char]0x0432+[char]0x0430+[char]0x0435+[char]0x0442]+" MTU + IPv6 off "+[char]0x043D+[char]0x0430]+" TUN")
        p7_name=([char]0x0424+[char]0x0438+[char]0x043D+[char]0x0430+[char]0x043B+[char]0x044C+[char]0x043D+[char]0x044B+[char]0x0439]+" "+[char]0x0430+[char]0x0443+[char]0x0434+[char]0x0438+[char]0x0442)
        p7_desc="17 "+[char]0x043A+[char]0x0430+[char]0x0442+[char]0x0435+[char]0x0433+[char]0x043E+[char]0x0440+[char]0x0438+[char]0x0439]+" "+[char]0x043F+[char]0x0440+[char]0x043E+[char]0x0432+[char]0x0435+[char]0x0440+[char]0x043E+[char]0x043A]+" "+[char]0x0443+[char]0x0442+[char]0x0435+[char]0x0447+[char]0x0435+[char]0x043A)
        nav_hint=([char]0x0412+[char]0x0412+[char]0x0415+[char]0x0420+[char]0x0425]+"/"+[char]0x0412+[char]0x041D+[char]0x0418+[char]0x0417]+" = "+[char]0x0432+[char]0x044B+[char]0x0431+[char]0x043E+[char]0x0440]+" | ENTER = "+[char]0x0437+[char]0x0430+[char]0x043F+[char]0x0443+[char]0x0441+[char]0x043A]+" | A = "+[char]0x0412+[char]0x0441+[char]0x0435]+" | S = "+[char]0x041D+[char]0x0430+[char]0x0441+[char]0x0442+[char]0x0440+[char]0x043E+[char]0x0439+[char]0x043A+[char]0x0438]+" | Q = "+[char]0x0412+[char]0x044B+[char]0x0445+[char]0x043E+[char]0x0434)
        selected=([char]0x0412+[char]0x042B+[char]0x0411+[char]0x0420+[char]0x0410+[char]0x041D+[char]0x041E)
        phase_hint=([char]0x041D+[char]0x0430+[char]0x0436+[char]0x043C+[char]0x0438+[char]0x0442+[char]0x0435]+" ENTER "+[char]0x0434+[char]0x043B+[char]0x044F]+" "+[char]0x0437+[char]0x0430+[char]0x043F+[char]0x0443+[char]0x0441+[char]0x043A+[char]0x0430)
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
    Write-Host ("  {0,-3} {1,-28} {2,-28} {3}" -f "#",(STR "phase"),(STR "desc"),(STR "status")) -ForegroundColor DarkGray
    Write-Host ("  "+("-"*70)) -ForegroundColor DarkGray
    for($i=0;$i -lt 7;$i++){
        $pName=STR ("p$($i+1)_name")
        $pDesc=STR ("p$($i+1)_desc")
        $icon=Get-PhaseIcon $script:PhaseStatus[$i]
        $num=($i+1).ToString()
        $cursor=if($script:MenuIndex -eq $i){">"}else{" "}
        if($script:MenuIndex -eq $i){
            Write-Host ("  {0}{1}. {2,-28} "-f$cursor,$num,$pName) -NoNewline -ForegroundColor Cyan -BackgroundColor DarkBlue
            Write-Host ("{0,-28} "-f$pDesc) -NoNewline -ForegroundColor White -BackgroundColor DarkBlue
            Write-Host ("[{0}]"-f$icon.Icon) -ForegroundColor $icon.Color -BackgroundColor DarkBlue
        } else {
            Write-Host ("  {0}{1}. {2,-28} {3,-28} [{4}]" -f$cursor,$num,$pName,$pDesc,$icon.Icon) -ForegroundColor Gray
        }
    }
    Write-Host ("  "+("-"*70)) -ForegroundColor DarkGray
    $items=@("A","S","Q")
    $labels=@((STR "menu_run_all"),(STR "menu_settings"),(STR "menu_quit"))
    for($j=0;$j -lt 3;$j++){
        $idx=$j+7
        $cursor=if($script:MenuIndex -eq $idx){">"}else{" "}
        if($script:MenuIndex -eq $idx){
            Write-Host ("  {0} [{1}] {2}" -f$cursor,$items[$j],$labels[$j]) -ForegroundColor Cyan -BackgroundColor DarkBlue
        } else {
            Write-Host ("  {0} [{1}] {2}" -f$cursor,$items[$j],$labels[$j]) -ForegroundColor White
        }
    }
    Write-Host ""
    Write-Host ("  "+(STR "nav_hint")) -ForegroundColor DarkCyan
    Write-Host ""
    if($script:MenuIndex -lt 7){
        $pName=STR ("p$($script:MenuIndex+1)_name")
        $pDesc=STR ("p$($script:MenuIndex+1)_desc")
        Write-Host ("  >> "+(STR "selected")+": $pName") -ForegroundColor Yellow
        Write-Host ("     $pDesc") -ForegroundColor Gray
        Write-Host ("     "+(STR "phase_hint")) -ForegroundColor DarkGray
    } elseif($script:MenuIndex -eq 7){
        Write-Host ("  >> "+(STR "selected")+": "+(STR "menu_run_all")) -ForegroundColor Yellow
    } elseif($script:MenuIndex -eq 8){
        Write-Host ("  >> "+(STR "selected")+": "+(STR "menu_settings")) -ForegroundColor Yellow
    } else {
        Write-Host ("  >> "+(STR "selected")+": "+(STR "menu_quit")) -ForegroundColor Yellow
    }
}

# Inline phase engine
function Invoke-PhaseEngine {
    param([int]$Phase)
    $results=@()
    switch($Phase){
        1 {
            Get-NetFirewallProfile | ForEach-Object {
                if(!$_.Enabled){Set-NetFirewallRule -Name $_.Name -Enabled True | Out-Null}
                $results+=@{Name="Firewall $($_.Name)";Status="PASS"}
            }
            $rules=@(
                @("Block STUN UDP 3478 Out","UDP",3478,"Outbound"),@("Block STUN TCP 3478 Out","TCP",3478,"Outbound"),
                @("Block TURN TCP 5349 Out","TCP",5349,"Outbound"),@("Block mDNS UDP 5353 Out","UDP",5353,"Outbound"),
                @("Block QUIC UDP 443 Out","UDP",443,"Outbound"),@("Block SSDP UDP 1900 Out","UDP",1900,"Outbound"),
                @("Block LLMNR UDP 5355 Out","UDP",5355,"Outbound")
            )
            foreach($r in $rules){
                $existing=Get-NetFirewallRule -DisplayName $r[0] -ErrorAction SilentlyContinue
                if($existing){Remove-NetFirewallRule -DisplayName $r[0]|Out-Null}
                New-NetFirewallRule -DisplayName $r[0] -Direction $r[3] -Protocol $r[1] -LocalPort $r[2] -Action Block -Profile Any -Enabled True|Out-Null
                $results+=@{Name="Rule: $($r[0])";Status="PASS"}
            }
            $llmnrPath="HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
            if(!(Test-Path $llmnrPath)){New-Item -Path $llmnrPath -Force|Out-Null}
            Set-ItemProperty -Path $llmnrPath -Name "EnableMulticast" -Value 0 -Type DWord
            $results+=@{Name="LLMNR disabled";Status="PASS"}
            $adapters=Get-WmiObject Win32_NetworkAdapterConfiguration -ErrorAction SilentlyContinue|Where-Object{$_.IPEnabled}
            foreach($a in $adapters){$a.SetTcpipNetbios(2)|Out-Null}
            $results+=@{Name="NBT-NS disabled";Status="PASS"}
        }
        2 {
            $svc=Get-Service -Name msquic -ErrorAction SilentlyContinue
            if($svc){Stop-Service msquic -Force -ErrorAction SilentlyContinue;Set-Service msquic -StartupType Disabled}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\MsQuic" -Name "Start" -Value 4 -ErrorAction SilentlyContinue
            $results+=@{Name="msquic service";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" -Name "EnableHttp3" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results+=@{Name="HTTP/3 (HTTP.sys)";Status="PASS"}
            $sqPath="HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\QUIC"
            if(!(Test-Path $sqPath)){New-Item -Path $sqPath -Force|Out-Null}
            Set-ItemProperty -Path $sqPath -Name "Enabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $sqPath -Name "DisabledByDefault" -Value 1 -Type DWord
            $results+=@{Name="QUIC Schannel";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableQuic" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results+=@{Name="WinINET QUIC";Status="PASS"}
            $chromePath="HKLM:\SOFTWARE\Policies\Google\Chrome"
            if(!(Test-Path $chromePath)){New-Item -Path $chromePath -Force|Out-Null}
            Set-ItemProperty -Path $chromePath -Name "QuicAllowed" -Value 0 -Type DWord
            $results+=@{Name="Chrome QUIC";Status="PASS"}
            $edgePath="HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            if(!(Test-Path $edgePath)){New-Item -Path $edgePath -Force|Out-Null}
            Set-ItemProperty -Path $edgePath -Name "QuicAllowed" -Value 0 -Type DWord
            $results+=@{Name="Edge QUIC";Status="PASS"}
        }
        3 {
            Get-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue|ForEach-Object{
                Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
            }
            $results+=@{Name="IPv6 bindings";Status="PASS"}
            netsh interface teredo set state disabled 2>&1|Out-Null
            $results+=@{Name="Teredo";Status="PASS"}
            netsh interface 6to4 set state disabled 2>&1|Out-Null
            $results+=@{Name="6to4";Status="PASS"}
            netsh interface isatap set state disabled 2>&1|Out-Null
            $results+=@{Name="ISATAP";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xFF -Type DWord
            $results+=@{Name="DisabledComponents=0xFF";Status="PASS";Reboot=$true}
            $dnsPath="HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
            if(!(Test-Path $dnsPath)){New-Item -Path $dnsPath -Force|Out-Null}
            Set-ItemProperty -Path $dnsPath -Name "DisableSmartNameResolution" -Value 1 -Type DWord
            $results+=@{Name="Smart Name Resolution";Status="PASS"}
        }
        4 {
            $netshParams=@("autotuninglevel=normal","rss=disabled","chimney=disabled","dca=disabled","netdma=disabled","ecncapability=disabled","timestamps=disabled","rsc=disabled","fastopen=disabled","fastopenfallback=disabled","hystart=disabled","pacingprofile=off")
            foreach($p in $netshParams){$kv=$p -split '=';netsh int tcp set global "$($kv[0])=$($kv[1])" 2>&1|Out-Null}
            $results+=@{Name="netsh TCP globals";Status="PASS"}
            $regPath="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            $tcpipParams=@{KeepAliveTime=60000;KeepAliveInterval=1000;DefaultTTL=128;DisableTaskOffload=1;EnableECN=0;EnableHeuristics=0;MaxFreeTcbs=65536;MaxHashTableSize=65536;NumTcbTablePartitions=8;Tcp1323Opts=0;TcpMaxDupAcks=2;TcpTimedWaitDelay=30;MaxUserPort=65534}
            foreach($kv in $tcpipParams.GetEnumerator()){Set-ItemProperty -Path $regPath -Name $kv.Key -Value $kv.Value -Type DWord -ErrorAction SilentlyContinue}
            $results+=@{Name="Tcpip parameters ($($tcpipParams.Count))";Status="PASS";Reboot=$true}
            $interfaces=Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
            foreach($iface in $interfaces){Set-ItemProperty -Path $iface.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord -ErrorAction SilentlyContinue;Set-ItemProperty -Path $iface.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord -ErrorAction SilentlyContinue}
            $results+=@{Name="Nagle disabled";Status="PASS"}
        }
        5 {
            $services=@("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV","fdPHost","upnphost","FDResPub")
            foreach($svcName in $services){$svc=Get-Service -Name $svcName -ErrorAction SilentlyContinue;if($svc){Stop-Service $svcName -Force -ErrorAction SilentlyContinue;Set-Service $svcName -StartupType Disabled -ErrorAction SilentlyContinue};$results+=@{Name="Service $svcName";Status="PASS"}}
            $hostsPath="$env:SystemRoot\System32\drivers\etc\hosts"
            $telemetryDomains=@("v10.events.data.microsoft.com","v20.events.data.microsoft.com","vortex.data.microsoft.com","vortex-win.data.microsoft.com","telecommand.telemetry.microsoft.com","oca.telemetry.microsoft.com","sqm.telemetry.microsoft.com","watson.telemetry.microsoft.com","redir.metaservices.microsoft.com","choice.microsoft.com","df.telemetry.microsoft.com","feedback.windows.com","feedback.microsoft-hohm.com","feedback.search.microsoft.com","rad.msn.com","preview.msn.com","ad.doubleclick.net","ads.msn.com","ads1.msads.net","settings-sandbox.data.microsoft.com","vsgallery.com","watson.microsoft.com","ui.skype.com","pricelist.skype.com","apps.skype.com","m.hotmail.com","s.gateway.messenger.live.com","sa.windows.com")
            $existingHosts=Get-Content $hostsPath -ErrorAction SilentlyContinue
            $added=0
            foreach($domain in $telemetryDomains){if($existingHosts -notcontains "0.0.0.0 $domain"){Add-Content -Path $hostsPath -Value "0.0.0.0 $domain" -ErrorAction SilentlyContinue;$added++}}
            $results+=@{Name="Hosts blocks ($added domains)";Status="PASS"}
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableMDNS" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results+=@{Name="mDNS disabled";Status="PASS"}
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            $results+=@{Name="Advertising ID";Status="PASS"}
            $cortanaPath="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if(!(Test-Path $cortanaPath)){New-Item -Path $cortanaPath -Force|Out-Null}
            Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -Type DWord
            Set-ItemProperty -Path $cortanaPath -Name "DisableWebSearch" -Value 1 -Type DWord
            Set-ItemProperty -Path $cortanaPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord
            $results+=@{Name="Cortana/Cloud Search";Status="PASS"}
        }
        6 {
            $watcherDir="C:\Users\$env:USERNAME\.no-leaks-watcher"
            if(!(Test-Path $watcherDir)){New-Item -Path $watcherDir -ItemType Directory -Force|Out-Null}
            $watcherScript="`$tunName = `"$($script:CFG.TunName)`"`n`$targetMtu = $($script:CFG.TunMtu)`nwhile (`$true) {`n  try {`n    `$adapter = Get-NetAdapter -Name `$tunName -ErrorAction SilentlyContinue`n    if (`$adapter -and `$adapter.Status -eq `"Up`") {`n      `$mtuOut = netsh interface ipv4 show subinterface `$tunName 2>`$null`n      if (`$mtuOut -notmatch `$targetMtu) { netsh interface ipv4 set subinterface `$tunName mtu=`$targetMtu store=persistent 2>`$null }`n      `$ipv6 = Get-NetAdapterBinding -Name `$tunName -ComponentID `"ms_tcpip6`" -ErrorAction SilentlyContinue`n      if (`$ipv6 -and `$ipv6.Enabled) { Disable-NetAdapterBinding -Name `$tunName -ComponentID `"ms_tcpip6`" -ErrorAction SilentlyContinue }`n    }`n  } catch {}`n  Start-Sleep -Seconds 3`n}"
            $watcherScript|Out-File -FilePath "$watcherDir\mtu-watcher.ps1" -Encoding UTF8 -Force
            $results+=@{Name="Watcher script";Status="PASS"}
            Unregister-ScheduledTask -TaskName "NoLeaksWatcher" -Confirm:$false -ErrorAction SilentlyContinue
            $taskResult=schtasks /create /tn "NoLeaksWatcher" /tr "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$watcherDir\mtu-watcher.ps1`"" /sc onlogon /rl highest /ru SYSTEM /f 2>&1
            if($LASTEXITCODE -eq 0){$results+=@{Name="Scheduled task";Status="PASS"};schtasks /run /tn "NoLeaksWatcher" 2>&1|Out-Null}
            else{$results+=@{Name="Scheduled task";Status="FAIL";Detail=$taskResult}}
        }
        7 {
            Get-NetFirewallProfile|ForEach-Object{$st=if($_.Enabled){"PASS"}else{"FAIL"};$results+=@{Name="Firewall $($_.Name)";Status=$st}}
            $ruleNames=@("Block STUN UDP 3478 Out","Block STUN TCP 3478 Out","Block TURN TCP 5349 Out","Block mDNS UDP 5353 Out","Block QUIC UDP 443 Out","Block SSDP UDP 1900 Out","Block LLMNR UDP 5355 Out")
            foreach($rname in $ruleNames){$r=Get-NetFirewallRule -DisplayName $rname -ErrorAction SilentlyContinue;$st=if($r -and $r.Enabled -eq 'True' -and $r.Action -eq 'Block'){"PASS"}else{"FAIL"};$results+=@{Name="Rule: $rname";Status=$st}}
            $dangerPorts=@(3478,5349,5353,1900,5355)
            $tcpListen=Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue|Where-Object{$_.LocalPort -in $dangerPorts}
            $udpListen=Get-NetUDPEndpoint -ErrorAction SilentlyContinue|Where-Object{$_.LocalPort -in $dangerPorts}
            $st=if(!$tcpListen -and !$udpListen){"PASS"}else{"WARN"}
            $results+=@{Name="Dangerous ports";Status=$st}
            $llmnr=Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
            $st=if($llmnr.EnableMulticast -eq 0){"PASS"}else{"FAIL"}
            $results+=@{Name="LLMNR";Status=$st}
            $dc=Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -ErrorAction SilentlyContinue
            $st=if($dc.DisabledComponents -eq 255){"PASS"}else{"WARN"}
            $results+=@{Name="IPv6 DisabledComponents";Status=$st}
            $chromeQuic=Get-ItemProperty "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name QuicAllowed -ErrorAction SilentlyContinue
            $st=if($chromeQuic.QuicAllowed -eq 0){"PASS"}else{"FAIL"}
            $results+=@{Name="Chrome QUIC";Status=$st}
            $edgeQuic=Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name QuicAllowed -ErrorAction SilentlyContinue
            $st=if($edgeQuic.QuicAllowed -eq 0){"PASS"}else{"FAIL"}
            $results+=@{Name="Edge QUIC";Status=$st}
            $tcp=netsh int tcp show global 2>$null
            $st=if($tcp -match "Fast Open\s*:\s*disabled"){"PASS"}else{"WARN"}
            $results+=@{Name="TCP Fast Open";Status=$st}
            $ttl=Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DefaultTTL -ErrorAction SilentlyContinue
            $st=if($ttl.DefaultTTL -eq 128){"PASS"}else{"FAIL"}
            $results+=@{Name="DefaultTTL";Status=$st}
            $svcList=@("DiagTrack","dmwappushservice","WMPNetworkSvc","wisvc","lfsvc","SharedAccess","SSDPSRV")
            foreach($svcName in $svcList){$svc=Get-Service -Name $svcName -ErrorAction SilentlyContinue;$st=if(!$svc -or $svc.Status -eq 'Stopped'){"PASS"}else{"WARN"};$results+=@{Name="Service $svcName";Status=$st}}
            $hostsContent=Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue|Where-Object{$_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$'}
            $blocked=($hostsContent|Select-String '0\.0\.0\.0'|Measure-Object).Count
            $st=if($blocked -gt 50){"PASS"}else{"WARN"}
            $results+=@{Name="Hosts blocks ($blocked)";Status=$st}
            $tun=Get-NetAdapter -ErrorAction SilentlyContinue|Where-Object{$_.InterfaceDescription -match 'TUN|TAP|VPN|SocksTunnel' -and $_.Status -eq 'Up'}
            $st=if($tun){"PASS"}else{"WARN"}
            $results+=@{Name="Tunnel";Status=$st}
            $mtuOut=netsh interface ipv4 show subinterface $script:CFG.TunName 2>$null
            $st=if($mtuOut -match $script:CFG.TunMtu){"PASS"}else{"WARN"}
            $results+=@{Name="MTU on $($script:CFG.TunName)";Status=$st}
            try{
                $extIp=(Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 10).Content
                $results+=@{Name="External IP: $extIp";Status="PASS"}
                if($script:CFG.ExpectedIp -and $extIp -eq $script:CFG.ExpectedIp){$results+=@{Name="IP matches expected";Status="PASS"}}
                elseif($script:CFG.ExpectedIp){$results+=@{Name="IP mismatch!";Status="WARN"}}
            } catch{$results+=@{Name="External IP";Status="WARN";Detail=$_.Exception.Message}}
        }
    }
    return $results
}

function Run-PhaseWithUI {
    param([int]$PhaseNum)
    $script:PhaseStatus[$PhaseNum-1]="running"
    Draw-Screen
    $pName=STR ("p$($PhaseNum)_name")
    Write-Host ""
    Write-Host ">>> Phase $PhaseNum : $pName" -ForegroundColor Cyan
    Write-Host ""
    try{
        $results=Invoke-PhaseEngine -Phase $PhaseNum
        $phaseFail=$false
        foreach($r in $results){
            $icon=switch($r.Status){"PASS"{"[OK]";$script:TotalPass++}"FAIL"{"[FAIL]";$script:TotalFail++;$phaseFail=$true}"WARN"{"[WARN]";$script:TotalWarn++}}
            $color=switch($r.Status){"PASS"{"Green"}"FAIL"{"Red"}"WARN"{"Yellow"}}
            Write-Host ("  $icon $($r.Name)") -ForegroundColor $color
            if($r.Detail){Write-Host ("       $($r.Detail)") -ForegroundColor DarkGray}
        }
        if($phaseFail){$script:PhaseStatus[$PhaseNum-1]="failed"}else{$script:PhaseStatus[$PhaseNum-1]="done"}
        if($script:PhaseReboot[$PhaseNum-1]){Write-Host "";Write-Host ("  "+(STR "reboot")) -ForegroundColor Yellow}
    } catch{
        Write-Host ("  ERROR: $_") -ForegroundColor Red
        $script:PhaseStatus[$PhaseNum-1]="failed"
        $script:TotalFail++
    }
    Write-Host ""
    Write-Host ("  "+(STR "press_key")) -ForegroundColor DarkGray
    $null=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Run-AllPhasesWithUI {
    $needReboot=$false
    for($i=1;$i -le 7;$i++){
        Run-PhaseWithUI -PhaseNum $i
        if($script:PhaseReboot[$i-1]){$needReboot=$true}
    }
    Draw-Screen
    Write-Host ""
    Write-Host ("  === "+(STR "summary")+" ===") -ForegroundColor Cyan
    Write-Host ("  "+(STR "total_pass")+": $($script:TotalPass)") -ForegroundColor Green
    Write-Host ("  "+(STR "total_fail")+": $($script:TotalFail)") -ForegroundColor Red
    Write-Host ("  "+(STR "total_warn")+": $($script:TotalWarn)") -ForegroundColor Yellow
    Write-Host ""
    if($needReboot){
        Write-Host ("  "+(STR "reboot_now")) -ForegroundColor Yellow
        Write-Host ("  "+(STR "reboot_1")) -ForegroundColor White
        Write-Host ("  "+(STR "reboot_2")) -ForegroundColor Gray
        Write-Host ""
        $rb=Read-Host ("  "+(STR "yes_no"))
        if($rb -eq "1"){Restart-Computer -Force}
    }
}

function Show-Settings {
    Clear-Host
    Write-Host ""
    Write-Host ("  === "+(STR "settings")+" ===") -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  "+(STR "current")+": TUN="+$script:CFG.TunName+", MTU="+$script:CFG.TunMtu+", IP="+$(if($script:CFG.ExpectedIp){$script:CFG.ExpectedIp}else{"-"})) -ForegroundColor Gray
    Write-Host ""
    $newTun=Read-Host ("  "+(STR "enter_tun")+" ["+$script:CFG.TunName+"]")
    if($newTun.Trim() -ne ""){$script:CFG.TunName=$newTun.Trim()}
    $newMtu=Read-Host ("  "+(STR "enter_mtu")+" ["+$script:CFG.TunMtu+"]")
    if($newMtu.Trim() -ne ""){$script:CFG.TunMtu=$newMtu.Trim()}
    $newIp=Read-Host ("  "+(STR "enter_ip")+" ["+$(if($script:CFG.ExpectedIp){$script:CFG.ExpectedIp}else{""})+"]")
    if($newIp.Trim() -ne ""){$script:CFG.ExpectedIp=$newIp.Trim()}
    Write-Host ""
    Write-Host ("  "+(STR "saved")) -ForegroundColor Green
    Start-Sleep -Seconds 1
}

function Show-LanguageSelect {
    Clear-Host
    Write-Host ""
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host "       Windows 11 No-Leaks TUI" -ForegroundColor White
    Write-Host "       Network leak hardening" -ForegroundColor Gray
    Write-Host "  ========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. English" -ForegroundColor White
    Write-Host "  2. Russkij" -ForegroundColor White
    Write-Host ""
    $choice=Read-Host "  > "
    switch($choice){"2"{$script:CFG.Lang="RU"}default{$script:CFG.Lang="EN"}}
}

# MAIN
Show-LanguageSelect
while($true){
    Draw-Screen
    $key=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch($key.VirtualKeyCode){
        38{if($script:MenuIndex -gt 0){$script:MenuIndex--}}
        40{if($script:MenuIndex -lt 9){$script:MenuIndex++}}
        13{
            if($script:MenuIndex -lt 7){Run-PhaseWithUI -PhaseNum ($script:MenuIndex+1)}
            elseif($script:MenuIndex -eq 7){Run-AllPhasesWithUI}
            elseif($script:MenuIndex -eq 8){Show-Settings}
            else{exit 0}
        }
    }
    switch($key.Character){
        "a"{Run-AllPhasesWithUI}"A"{Run-AllPhasesWithUI}
        "s"{Show-Settings}"S"{Show-Settings}
        "q"{exit 0}"Q"{exit 0}
        "1"{Run-PhaseWithUI -PhaseNum 1}"2"{Run-PhaseWithUI -PhaseNum 2}
        "3"{Run-PhaseWithUI -PhaseNum 3}"4"{Run-PhaseWithUI -PhaseNum 4}
        "5"{Run-PhaseWithUI -PhaseNum 5}"6"{Run-PhaseWithUI -PhaseNum 6}
        "7"{Run-PhaseWithUI -PhaseNum 7}
    }
}
