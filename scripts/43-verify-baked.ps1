$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
function Sh([string]$cmd) {
    $out = & $adb -s $S shell $cmd 2>&1
    return (($out | Out-String).Trim())
}
'--- props ---'
'boot_completed=' + (Sh 'getprop sys.boot_completed')
'model=' + (Sh 'getprop ro.product.model')
'brand=' + (Sh 'getprop ro.product.brand')
'fingerprint=' + (Sh 'getprop ro.build.fingerprint')
'overseas=' + (Sh 'getprop ro.build.version.overseas')
'hostname=' + (Sh 'getprop net.hostname')
'renderer=' + (Sh 'getprop debug.hwui.renderer')
'--- roles ---'
'HOME=' + (Sh 'cmd role get-role-holders android.app.role.HOME')
'BROWSER=' + (Sh 'cmd role get-role-holders android.app.role.BROWSER')
'DIALER=' + (Sh 'cmd role get-role-holders android.app.role.DIALER')
'SMS=' + (Sh 'cmd role get-role-holders android.app.role.SMS')
'--- packages ---'
Sh 'pm list packages | grep -E "lawnchair|via|mumu|nemu|netease|trichrome|chrome"'
'--- launcher activity ---'
Sh 'dumpsys window | grep -E "mCurrentFocus|mFocusedApp"'
'--- hosts ---'
Sh 'cat /system/etc/hosts'
'--- home dir listing ---'
Sh 'ls /system/priv-app/Lawnchair /system/app/Via'
'--- screen ---'
Sh 'wm size'
Sh 'screencap -p /sdcard/_check.png'
& $adb -s $S pull /sdcard/_check.png 'D:\MuMuWork\image-edit\baked-home.png' 2>&1 | Out-String
Get-Item 'D:\MuMuWork\image-edit\baked-home.png' -ErrorAction SilentlyContinue | Select-Object Length | Format-Table -AutoSize | Out-String
