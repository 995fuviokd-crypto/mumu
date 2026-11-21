$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }

'--- install ORIGINAL apk ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S shell pm install -r /sdcard/momo.apk 2>&1 | Out-String
& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'versionName' | Select-Object -First 1 | ForEach-Object { $_.Line.Trim() } | Out-String

'--- current patch ---'
& $adb -s $S shell getprop ro.build.version.security_patch 2>&1 | Out-String

'--- resetprop patch date ---'
RunSh '/data/adb/ksud resetprop -n ro.build.version.security_patch 2026-10-05 2>&1; getprop ro.build.version.security_patch'

'--- launch original x3 ---'
for ($i = 1; $i -le 3; $i++) {
    & $adb -s $S logcat -c 2>&1 | Out-Null
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 5
    $p = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
    $crash = ((& $adb -s $S logcat -d -b crash -t 30 2>&1 | Out-String))
    $sig = if ($crash -match 'SIGSEGV') { 'SIGSEGV' } elseif ($crash -match 'FATAL') { 'FATAL' } else { 'none' }
    "attempt ${i}: pid=[$p] crash=$sig"
}
'--- ui sample ---'
& $adb -s $S shell uiautomator dump /sdcard/ui_sp.xml 2>&1 | Out-Null
& $adb -s $S pull /sdcard/ui_sp.xml 'D:\MuMuWork\momo\ui-sp.xml' 2>&1 | Out-Null
$txt = Get-Content 'D:\MuMuWork\momo\ui-sp.xml' -Raw -Encoding UTF8
[regex]::Matches($txt,'text="([^"]{2,80})"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 20 | Out-String
