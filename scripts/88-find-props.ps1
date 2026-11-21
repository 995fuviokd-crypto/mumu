$ErrorActionPreference = 'Continue'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
'--- grep props across partitions ---'
RunSh 'grep -rn -E "ro.kernel.qemu|ro.build.hv.platform|qemu.hw.mainkeys|ro.dalvik.vm.native.bridge" /system/build.prop /system/etc /system/product /system/system_ext /vendor /odm /product 2>/dev/null | head -40'
'--- all prop files matching ---'
RunSh 'for f in /system/build.prop /system/etc/prop.default /system/product/etc/build.prop /system/system_ext/etc/build.prop /vendor/build.prop /vendor/default.prop /odm/etc/build.prop; do [ -f $f ] && echo "== $f"; done'
'--- values now ---'
RunSh 'getprop | grep -E "qemu|hv.platform|native.bridge|hardware" | head -20'
