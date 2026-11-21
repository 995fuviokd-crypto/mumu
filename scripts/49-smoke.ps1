$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function Sh([string]$c) { return ((& $adb -s $S shell $c 2>&1 | Out-String).Trim()) }
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }

'--- home screenshot ---'
Sh 'screencap -p /sdcard/_home.png' | Out-Null
& $adb -s $S pull /sdcard/_home.png 'D:\MuMuWork\image-edit\final-home.png' 2>&1 | Out-Null

'--- smoke: Via ---'
Sh 'am start -n mark.via/.Shell'
Start-Sleep 6
Sh 'dumpsys window | grep -m2 mCurrentFocus'
Sh 'screencap -p /sdcard/_via.png' | Out-Null
& $adb -s $S pull /sdcard/_via.png 'D:\MuMuWork\image-edit\final-via.png' 2>&1 | Out-Null

'--- smoke: Settings ---'
Sh 'am start -a android.settings.SETTINGS'
Start-Sleep 5
Sh 'dumpsys window | grep -m2 mCurrentFocus'
Sh 'input keyevent 3'
Start-Sleep 2

'--- smoke: Phone ---'
Sh 'am start -a android.intent.action.DIAL'
Start-Sleep 4
Sh 'dumpsys window | grep -m2 mCurrentFocus'
Sh 'input keyevent 3'

'--- cleanup modules ---'
RunSh 'rm -rf /data/adb/modules/mumu_noads /data/adb/modules/lawnchair_preload'
RunSh 'ls -la /data/adb/modules'
RunSh 'rm -rf /data/local/lawnchair'
RunSh 'ls /data/local | head'

'--- final props ---'
'model=' + (Sh 'getprop ro.product.model')
'overseas=' + (Sh 'getprop ro.build.version.overseas')
'hosts_lines=' + (Sh 'wc -l < /system/etc/hosts')
'HOME=' + (Sh 'cmd role get-role-holders android.app.role.HOME')
'BROWSER=' + (Sh 'cmd role get-role-holders android.app.role.BROWSER')
Get-Item 'D:\MuMuWork\image-edit\final-home.png','D:\MuMuWork\image-edit\final-via.png' | Select-Object Name,Length | Format-Table -AutoSize | Out-String
