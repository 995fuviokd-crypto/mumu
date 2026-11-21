$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- devices ---'
& $adb devices 2>&1 | Out-String
'--- packages matching momo/env ---'
& $adb -s $S shell "pm list packages" 2>&1 | Select-String -Pattern 'momo|env|check|detect' | ForEach-Object { $_.Line.Trim() } | Out-String
'--- third party packages ---'
& $adb -s $S shell "pm list packages -3" 2>&1 | Out-String
