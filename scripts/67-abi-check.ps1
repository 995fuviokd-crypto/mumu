$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }
'--- abi props ---'
& $adb -s $S shell getprop ro.product.cpu.abilist 2>&1 | Out-String
& $adb -s $S shell getprop ro.product.cpu.abilist32 2>&1 | Out-String
& $adb -s $S shell getprop ro.product.cpu.abilist64 2>&1 | Out-String
& $adb -s $S shell getprop ro.dalvik.vm.native.bridge 2>&1 | Out-String
& $adb -s $S shell getprop ro.enable.native.bridge.exec 2>&1 | Out-String
'--- momo abi in package manager ---'
& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'primaryCpuAbi|secondaryCpuAbi|nativeLibraryDir|codePath|resourcePath|legacyNativeLibraryDir' | ForEach-Object { $_.Line.Trim() } | Out-String
'--- installed lib dirs ---'
RunSh 'ls -l /data/app/~~eCFWWTGE6A4ZYaxRyurF3Q==/io.github.vvb2060.mahoshojo-I3UN6D0-FFEZNriSKTj5oA==/lib 2>/dev/null; ls -l /data/app/~~eCFWWTGE6A4ZYaxRyurF3Q==/io.github.vvb2060.mahoshojo-I3UN6D0-FFEZNriSKTj5oA==/lib/* 2>/dev/null'
'--- app data dir ---'
RunSh 'ls -la /data/user/0/io.github.vvb2060.mahoshojo | head -20'
