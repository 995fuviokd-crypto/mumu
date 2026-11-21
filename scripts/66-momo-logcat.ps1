$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
Start-Sleep 7
$log = & $adb -s $S logcat -d -v threadtime 2>&1
'--- lines mentioning momo/maho ---'
$log | Select-String -Pattern 'mahoshojo|momo|Momo|MAHO' | Select-Object -Last 60 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- lines from system_server about the pkg (proc start/died) ---'
$log | Select-String -Pattern 'Start proc.*mahoshojo|mahoshojo.*died|Force finishing|ANR in' | Select-Object -Last 20 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- any libc/signal lines ---'
$log | Select-String -Pattern 'libc.*Fatal|SIGSEGV|Abort message' | Select-Object -Last 10 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- app own logs by pid ---'
$pidLine = $log | Select-String -Pattern 'Start proc [0-9]+:io\.github\.vvb2060\.mahoshojo' | Select-Object -Last 1
if ($pidLine) {
    'start line: ' + $pidLine.Line.Trim()
    if ($pidLine.Line -match 'Start proc ([0-9]+)') {
        $procId = $matches[1]
        $log | Select-String -Pattern ('\s' + $procId + '\s') | Select-Object -Last 80 | ForEach-Object { $_.Line.Trim() } | Out-String
    }
}
