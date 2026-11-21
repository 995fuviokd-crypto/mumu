#!/system/bin/sh
MODDIR=${0%/*}
mount --bind "$MODDIR/hosts" /system/etc/hosts
/data/adb/ksud resetprop -n ro.build.version.overseas true
/data/adb/ksud resetprop -n net.hostname V2284A
/data/adb/ksud resetprop -n debug.hwui.renderer skiagl
