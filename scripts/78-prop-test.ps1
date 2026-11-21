$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
function TryLaunch([string]$tag) {
    & $adb -s $S logcat -c 2>&1 | Out-Null
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 5
    $alive = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
    $crash = ((& $adb -s $S logcat -d -b crash -t 40 2>&1 | Out-String))
    $sig = if ($crash -match 'SIGSEGV') { 'SIGSEGV' } elseif ($crash -match 'SIGABRT') { 'SIGABRT' } elseif ($crash -match 'FATAL') { 'FATAL' } else { 'none' }
    "[$tag] pid=[$alive] crash=$sig"
    if ($sig -ne 'none') { ($crash -split "`n" | Select-String -Pattern 'pc 0000|Cause' | Select-Object -First 2 | ForEach-Object { '    ' + $_.Line.Trim() }) | Out-String }
}
'--- ksud available ---'
RunSh 'ls -l /data/adb/ksud; /data/adb/ksud -V 2>&1 | head -3'
'--- baseline launch ---'
TryLaunch 'baseline'
'--- hide qemu/hv props ---'
RunSh '/data/adb/ksud resetprop -d ro.kernel.qemu 2>&1'
RunSh '/data/adb/ksud resetprop -n ro.build.hv.platform "" 2>&1'
RunSh 'getprop ro.kernel.qemu; getprop ro.build.hv.platform'
TryLaunch 'no-qemu-no-hv'
