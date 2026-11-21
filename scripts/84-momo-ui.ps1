$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- alive / focus ---'
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
& $adb -s $S shell dumpsys activity activities 2>&1 | Select-String -Pattern 'mahoshojo.*HomeActivity|Display: mDisplayId' | Select-Object -First 8 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- uiautomator dump ---'
& $adb -s $S shell uiautomator dump /sdcard/momo-ui.xml 2>&1 | Out-String
& $adb -s $S pull /sdcard/momo-ui.xml 'D:\MuMuWork\momo\momo-ui.xml' 2>&1 | Out-Null
if (Test-Path 'D:\MuMuWork\momo\momo-ui.xml') {
    $x = [xml](Get-Content 'D:\MuMuWork\momo\momo-ui.xml' -Raw)
    'texts:'
    $x.SelectNodes('//node[@text!=""]') | ForEach-Object { '  [' + $_.text + ']' + ' class=' + $_.class } | Out-String
    $x.SelectNodes('//node[@content-desc!=""]') | ForEach-Object { '  desc: [' + $_.'content-desc' + ']' } | Out-String
}
'--- momo own logs ---'
& $adb -s $S logcat -d 2>&1 | Select-String -Pattern 'mahoshojo' | Select-Object -Last 20 | ForEach-Object { $_.Line.Trim() } | Out-String
