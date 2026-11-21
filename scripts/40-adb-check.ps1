$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = '127.0.0.1:16384'
& $adb devices -l 2>&1 | Out-String | Write-Output
function Sh([string]$cmd) {
    $out = & $adb -s $S shell $cmd 2>&1
    return ($out -join "`n")
}
'--- props ---'
'boot_completed=' + (Sh 'getprop sys.boot_completed')
'bootanim=' + (Sh 'getprop init.svc.bootanim')
'model=' + (Sh 'getprop ro.product.model')
'overseas=' + (Sh 'getprop ro.build.version.overseas')
'hostname=' + (Sh 'getprop net.hostname')
'renderer=' + (Sh 'getprop debug.hwui.renderer')
'--- services ---'
'activity: ' + (Sh 'service check activity')
'package: ' + (Sh 'service check package')
'--- processes ---'
Sh 'ps -A -o USER,PID,NAME | grep -E "system_server|zygote|dex2oat|lawnchair|mumu" | head -40'
'--- pm list (mumu/via/lawnchair) ---'
Sh 'pm list packages | grep -E "lawnchair|via|mumu|nemu|netease|trichrome"'
'--- launcher role ---'
Sh 'cmd role get-role-holders android.app.role.HOME'
Sh 'cmd role get-role-holders android.app.role.BROWSER'
'--- logcat crash tail ---'
Sh 'logcat -d -b crash -t 60'
