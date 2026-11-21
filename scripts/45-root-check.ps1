$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
function ShRoot([string]$cmd) {
    $out = & $adb -s $S shell ("su -c " + [char]39 + $cmd + [char]39) 2>&1
    return (($out | Out-String).Trim())
}
'--- root test ---'
ShRoot 'id'
'--- modules ---'
ShRoot 'ls -la /data/adb/modules'
'--- hosts runtime ---'
ShRoot 'ls -l /system/etc/hosts'
ShRoot 'wc -l /system/etc/hosts'
ShRoot 'mount | grep -i hosts'
'--- system mount ---'
ShRoot 'mount | grep -E "overlay|/system "'
'--- upperdir ---'
ShRoot 'ls -la /mnt/scratch/upperdir 2>/dev/null || ls -la /mnt/scratch 2>/dev/null'
