$ErrorActionPreference = 'Continue'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
function RunSh([string]$cmd) {
    $out = & $mgr sh --vmindex 0 --cmd $cmd 2>&1
    return (($out | Out-String).Trim())
}
'--- modules ---'
RunSh 'ls -la /data/adb/modules'
'--- disable modules ---'
RunSh 'for d in /data/adb/modules/*; do n=$(basename $d); touch $d/disable; echo disabled:$n; done'
RunSh 'ls -la /data/adb/modules/* | grep -E "disable|module.prop"'
'--- hosts ---'
RunSh 'ls -l /system/etc/hosts'
RunSh 'wc -l /system/etc/hosts'
RunSh 'mount | grep -i hosts'
'--- system mount ---'
RunSh 'mount | grep -E "overlay|/system "'
'--- upperdir content ---'
RunSh 'ls -la /mnt/scratch/upperdir'
'--- reboot ---'
RunSh 'reboot'
