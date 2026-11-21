$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
for ($i = 1; $i -le 3; $i++) {
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 8
    $p = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
    $u = (& $adb -s $S shell uiautomator dump /sdcard/ui$i.xml 2>&1 | Out-String).Trim()
    "run ${i}: pid=[$p] uiautomator=[$u]"
}
'--- wait 30s, check ANR ---'
Start-Sleep 30
$anr = (& $adb -s $S logcat -d 2>&1 | Select-String -Pattern 'ANR in io.github.vvb2060.mahoshojo' | Select-Object -Last 3)
if ($anr) { 'ANR seen:' ; $anr | ForEach-Object { $_.Line.Trim() } } else { 'no ANR in current buffer' }
'--- responsiveness: swipe ---'
& $adb -s $S shell input swipe 450 1600 450 600 300 2>&1 | Out-Null
Start-Sleep 2
& $adb -s $S shell uiautomator dump /sdcard/ui_after.xml 2>&1 | Out-String
RunSh 'data=$(cat /sdcard/ui_after.xml); echo ${#data}'
