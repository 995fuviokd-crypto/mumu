$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- bring to front ---'
& $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
Start-Sleep 4
'--- dump 1 ---'
& $adb -s $S shell uiautomator dump /sdcard/m1.xml 2>&1 | Out-String
& $adb -s $S pull /sdcard/m1.xml 'D:\MuMuWork\momo\m1.xml' 2>&1 | Out-Null
if (Test-Path 'D:\MuMuWork\momo\m1.xml') {
    $t = Get-Content 'D:\MuMuWork\momo\m1.xml' -Raw -Encoding UTF8
    'texts:'
    [regex]::Matches($t, 'text="([^"]{1,200})"') | ForEach-Object { '  [' + $_.Groups[1].Value + ']' } | Select-Object -First 30 | Out-String
}
'--- scroll down ---'
& $adb -s $S shell input swipe 450 1700 450 500 400 2>&1 | Out-Null
Start-Sleep 2
& $adb -s $S shell uiautomator dump /sdcard/m2.xml 2>&1 | Out-String
& $adb -s $S pull /sdcard/m2.xml 'D:\MuMuWork\momo\m2.xml' 2>&1 | Out-Null
if (Test-Path 'D:\MuMuWork\momo\m2.xml') {
    $t2 = Get-Content 'D:\MuMuWork\momo\m2.xml' -Raw -Encoding UTF8
    'texts after scroll:'
    [regex]::Matches($t2, 'text="([^"]{1,200})"') | ForEach-Object { '  [' + $_.Groups[1].Value + ']' } | Select-Object -First 40 | Out-String
}
