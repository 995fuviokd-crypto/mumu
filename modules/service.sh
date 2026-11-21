#!/system/bin/sh
MODDIR=${0%/*}
mount --bind "$MODDIR/hosts" /system/etc/hosts
/data/adb/ksud resetprop -n ro.build.version.overseas true
/data/adb/ksud resetprop -n net.hostname V2284A
/data/adb/ksud resetprop -n debug.hwui.renderer skiagl
/system/bin/settings put global window_animation_scale 0
/system/bin/settings put global transition_animation_scale 0
/system/bin/settings put global animator_duration_scale 0
/system/bin/settings put global disable_window_blurs 1
