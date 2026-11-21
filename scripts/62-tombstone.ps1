$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }
'--- tombstones ---'
RunSh 'ls -lt /data/tombstones | head -5'
'--- latest tombstone ---'
$t = RunSh 'ls -t /data/tombstones/tombstone_* 2>/dev/null | head -1'
't=' + $t
if ($t) { RunSh ('cat ' + $t) }
'--- exit info ---'
& $adb -s $S shell dumpsys activity exit-info io.github.vvb2060.mahoshojo 2>&1 | Select-Object -First 40 | Out-String
