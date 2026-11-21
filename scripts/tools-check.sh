#!/system/bin/sh
for t in strace ltrace gdb simpleperf perf tcpdump; do
  p=`which $t 2>/dev/null`
  echo "$t=$p"
done
echo "--- ls matches ---"
ls /system/bin /system/xbin /system/system_ext/bin 2>/dev/null | grep -iE 'strace|perf|gdb|trace' | sort -u
echo "--- selinux ---"
getenforce
echo "--- kernel ---"
uname -a
echo "--- props ---"
getprop ro.build.hv.platform
getprop ro.hardware
getprop ro.boot.hardware
getprop ro.dalvik.vm.native.bridge
getprop ro.kernel.qemu
getprop qemu.hw.mainkeys
echo "--- dmi ---"
cat /sys/class/dmi/id/product_name 2>/dev/null
cat /sys/class/dmi/id/sys_vendor 2>/dev/null
cat /sys/class/dmi/id/board_name 2>/dev/null
echo "--- cpuinfo head ---"
head -12 /proc/cpuinfo
echo "--- cpuinfo templates ---"
ls -l /system/etc/cpuinfo* /system/lib64/x86_64/ 2>/dev/null