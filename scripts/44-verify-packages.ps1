$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
function Sh([string]$cmd) {
    $out = & $adb -s $S shell $cmd 2>&1
    return (($out | Out-String).Trim())
}
'--- all packages (filtered) ---'
Sh "pm list packages | grep -Ei 'mumu|nemu|netease|trichrome|chrome|lawnchair|via|fossify'"
'--- count ---'
Sh "pm list packages | wc -l"
'--- mumu dirs in /system (should be gone except shared sdk/nlp/oaid/vinput) ---'
Sh "ls /system/priv-app"
'--- data modules ---'
Sh "ls -la /data/adb/modules 2>/dev/null"
Sh "cat /data/adb/modules/lawnchair_preload/module.prop 2>/dev/null"
'--- overlay mount ---'
Sh "mount | grep -E 'overlay| /system '"
'--- running mumu processes ---'
Sh "ps -A -o NAME | grep -Ei 'mumu|nemu' | sort -u"
'--- home screen test: launch settings then home ---'
Sh "am start -a android.intent.action.MAIN -c android.intent.category.HOME"
