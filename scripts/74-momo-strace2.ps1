$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }

$trace = '/data/user/0/io.github.vvb2060.mahoshojo/cache/momo.trace'
RunSh ('rm -f ' + $trace)
'--- set wrap (adb, quoted) ---'
& $adb -s $S shell ("setprop wrap.io.github.vvb2060.mahoshojo 'strace -f -o " + $trace + " -s 200'") 2>&1 | Out-String
'wrap=' + ((& $adb -s $S shell "getprop wrap.io.github.vvb2060.mahoshojo" 2>&1 | Out-String).Trim())

'--- launch ---'
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
Start-Sleep 1
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-String
Start-Sleep 12

'--- trace info ---'
RunSh ('ls -l ' + $trace + ' 2>/dev/null')
RunSh ('wc -l ' + $trace + ' 2>/dev/null')
'--- copy + pull ---'
RunSh ('cp ' + $trace + ' /data/local/tmp/momo.trace 2>/dev/null; chmod 644 /data/local/tmp/momo.trace 2>/dev/null; ls -l /data/local/tmp/momo.trace 2>/dev/null')
& $adb -s $S pull /data/local/tmp/momo.trace 'D:\MuMuWork\momo\momo.trace' 2>&1 | Out-String
'--- clear wrap ---'
& $adb -s $S shell "setprop wrap.io.github.vvb2060.mahoshojo ''" 2>&1 | Out-Null
