$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- uninstall ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-String
'--- install arm64-v8a ---'
& $adb -s $S shell pm install --abi arm64-v8a -r /sdcard/momo.apk 2>&1 | Out-String
'--- abi after ---'
& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'primaryCpuAbi|secondaryCpuAbi|nativeLibraryDir' | ForEach-Object { $_.Line.Trim() } | Out-String
'--- launch ---'
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-String
Start-Sleep 6
'--- alive ---'
(& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim()
'--- crash ---'
& $adb -s $S logcat -d -b crash -t 60 2>&1 | Select-Object -First 30 | Out-String
