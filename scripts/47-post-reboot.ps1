$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function Sh([string]$c) { return ((& $adb -s $S shell $c 2>&1 | Out-String).Trim()) }
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }
'--- uptime / boot ---'
'uptime=' + (Sh 'cat /proc/uptime')
'boot_completed=' + (Sh 'getprop sys.boot_completed')
'--- props with modules disabled ---'
'model=' + (Sh 'getprop ro.product.model')
'brand=' + (Sh 'getprop ro.product.brand')
'overseas=' + (Sh 'getprop ro.build.version.overseas')
'hostname=' + (Sh 'getprop net.hostname')
'renderer=' + (Sh 'getprop debug.hwui.renderer')
'animation=' + (Sh 'settings get global window_animation_scale')
'blur=' + (Sh 'settings get global disable_window_blurs')
'--- hosts (module disabled) ---'
RunSh 'ls -l /system/etc/hosts'
RunSh 'wc -l /system/etc/hosts'
RunSh 'mount | grep -c "mumu_noads/hosts"'
'--- module disable markers ---'
RunSh 'ls /data/adb/modules/mumu_noads/ /data/adb/modules/lawnchair_preload/'
'--- home/roles ---'
'HOME=' + (Sh 'cmd role get-role-holders android.app.role.HOME')
'BROWSER=' + (Sh 'cmd role get-role-holders android.app.role.BROWSER')
