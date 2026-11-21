$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
$path = ((& $adb -s emulator-5554 shell pm path io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim()) -replace '^package:',''
'apk=' + $path
$run = 'CLASSPATH=/data/local/tmp/h.dex:' + $path + ' /system/bin/app_process /data/local/tmp H '
'===== COLD (check without get) ====='
RunSh ($run + 'cold')
'===== WARM (get then check) ====='
RunSh ($run + 'warm')
