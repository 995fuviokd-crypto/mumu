$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- install working build (re-signed original, no code change) ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S shell pm install -r /data/local/tmp/momo-resigned.apk 2>&1 | Out-String
'--- launch x2 ---'
for ($i = 1; $i -le 2; $i++) {
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 5
    'attempt ' + $i + ' pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
}
'--- ui evidence ---'
& $adb -s $S shell uiautomator dump /sdcard/ui_ok.xml 2>&1 | Out-Null
& $adb -s $S pull /sdcard/ui_ok.xml 'D:\MuMuWork\momo\ui-ok.xml' 2>&1 | Out-Null
$txt = Get-Content 'D:\MuMuWork\momo\ui-ok.xml' -Raw -Encoding UTF8
[regex]::Matches($txt,'text="([^"]{2,120})"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 12 | Out-String
'--- package signature note ---'
& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'versionName|firstInstallTime|lastUpdateTime' | ForEach-Object { $_.Line.Trim() } | Out-String
