$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
$res = & $adb -s $S shell cmd package resolve-activity --brief io.github.vvb2060.mahoshojo 2>&1
'--- launcher activity ---'
$res | Out-String
$act = (($res | Select-String -Pattern '^[a-zA-Z0-9_.]+/[a-zA-Z0-9_.$]+$' | Select-Object -Last 1).Line)
'act=' + $act
'--- version ---'
& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'versionName|versionCode|minSdk|targetSdk|primaryCpuAbi|codePath|flags=' | Select-Object -First 12 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- clear log & launch ---'
& $adb -s $S logcat -c 2>&1 | Out-Null
if ($act) { & $adb -s $S shell am start -W -n $act 2>&1 | Out-String }
Start-Sleep 6
'--- still running? ---'
$pidOut = & $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1
'pid=' + (($pidOut | Out-String).Trim())
'--- crash buffer ---'
& $adb -s $S logcat -d -b crash -t 400 2>&1 | Out-String
