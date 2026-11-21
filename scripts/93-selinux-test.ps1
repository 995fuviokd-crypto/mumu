$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
'--- current enforce ---'
RunSh 'getenforce; cat /sys/fs/selinux/enforce'
'--- set enforcing ---'
RunSh 'setenforce 1; getenforce; cat /sys/fs/selinux/enforce'
'--- launch original x3 ---'
for ($i = 1; $i -le 3; $i++) {
    & $adb -s $S logcat -c 2>&1 | Out-Null
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 5
    $p = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
    $crash = ((& $adb -s $S logcat -d -b crash -t 20 2>&1 | Out-String))
    $sig = if ($crash -match 'SIGSEGV') { 'SIGSEGV' } elseif ($crash -match 'FATAL') { 'FATAL' } else { 'none' }
    "attempt ${i}: pid=[$p] crash=$sig"
}
'--- ui sample ---'
& $adb -s $S shell uiautomator dump /sdcard/ui_se.xml 2>&1 | Out-Null
& $adb -s $S pull /sdcard/ui_se.xml 'D:\MuMuWork\momo\ui-se.xml' 2>&1 | Out-Null
if (Test-Path 'D:\MuMuWork\momo\ui-se.xml') {
    $txt = Get-Content 'D:\MuMuWork\momo\ui-se.xml' -Raw -Encoding UTF8
    [regex]::Matches($txt,'text="([^"]{2,80})"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 20 | Out-String
}
'--- restore permissive ---'
RunSh 'setenforce 0; getenforce'
