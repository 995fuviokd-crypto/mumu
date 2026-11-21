$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
$p = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
'pid=' + $p
if ($p) {
    $ppid = RunSh ('cat /proc/' + $p + '/stat | cut -d" " -f4')
    'ppid=' + $ppid
    RunSh ('cat /proc/' + $ppid + '/cmdline | tr "\0" " "; echo')
}
'--- kernelsu traces ---'
RunSh 'ls /data/adb 2>/dev/null; getprop | grep -i ksu; cat /proc/kallsyms 2>/dev/null | grep -c ksu_'
'--- selinux ---'
RunSh 'getenforce'
