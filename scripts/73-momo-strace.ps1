$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }

'--- reinstall x86_64 ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S shell pm install --abi x86_64 -r /sdcard/momo.apk 2>&1 | Out-String
& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'primaryCpuAbi' | ForEach-Object { $_.Line.Trim() } | Out-String

'--- set wrap for strace ---'
RunSh 'setprop wrap.io.github.vvb2060.mahoshojo "strace -f -o /data/user/0/io.github.vvb2060.mahoshojo/cache/momo.trace -s 256"'
RunSh 'getprop wrap.io.github.vvb2060.mahoshojo'
RunSh 'rm -f /data/user/0/io.github.vvb2060.mahoshojo/cache/momo.trace'

'--- launch ---'
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-String
Start-Sleep 10

'--- trace size ---'
RunSh 'ls -l /data/user/0/io.github.vvb2060.mahoshojo/cache/momo.trace 2>/dev/null; wc -l /data/user/0/io.github.vvb2060.mahoshojo/cache/momo.trace 2>/dev/null'
'--- copy out ---'
RunSh 'cp /data/user/0/io.github.vvb2060.mahoshojo/cache/momo.trace /data/local/tmp/momo.trace; chmod 644 /data/local/tmp/momo.trace'
& $adb -s $S pull /data/local/tmp/momo.trace 'D:\MuMuWork\momo\momo.trace' 2>&1 | Out-String
'--- clear wrap ---'
RunSh 'setprop wrap.io.github.vvb2060.mahoshojo ""'
