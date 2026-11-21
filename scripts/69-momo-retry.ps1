$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
function Sh([string]$c) { return ((& $adb -s $S shell $c 2>&1 | Out-String).Trim()) }

'--- grant READ_LOGS attempts ---'
RunSh 'pm grant io.github.vvb2060.mahoshojo android.permission.READ_LOGS 2>&1; echo rc=$?'
RunSh 'appops set io.github.vvb2060.mahoshojo android:read_logs allow 2>&1; echo rc=$?'
Sh 'dumpsys package io.github.vvb2060.mahoshojo | grep -E "READ_LOGS|granted=true" | head -5'

'--- 5 launch attempts ---'
for ($i = 1; $i -le 5; $i++) {
    & $adb -s $S logcat -c 2>&1 | Out-Null
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 4
    $alive = (& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim()
    $crash = (& $adb -s $S logcat -d -b crash -t 20 2>&1 | Out-String)
    $sig = if ($crash -match 'SIGSEGV') { 'SIGSEGV' } elseif ($crash -match 'SIGABRT') { 'SIGABRT' } else { 'none' }
    "attempt $i pid=[$alive] crash=$sig"
    if ($sig -ne 'none') {
        ($crash -split "`n" | Select-String -Pattern 'pc 0000|Cause|Abort message' | Select-Object -First 3 | ForEach-Object { '    ' + $_.Line.Trim() }) | Out-String
    }
}
