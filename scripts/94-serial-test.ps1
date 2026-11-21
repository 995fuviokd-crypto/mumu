$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
'--- set serial props ---'
RunSh '/data/adb/ksud resetprop -n ro.serialno 2C7D9A5F1B 2>&1'
RunSh '/data/adb/ksud resetprop -n ro.boot.serialno 2C7D9A5F1B 2>&1'
RunSh '/data/adb/ksud resetprop -n ro.product.serial 2C7D9A5F1B 2>&1'
RunSh 'getprop ro.serialno; getprop ro.boot.serialno; getprop ro.product.serial'
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
