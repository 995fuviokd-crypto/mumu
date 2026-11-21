$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }

$code = ((& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'codePath=' | Select-Object -First 1).Line -replace '.*codePath=','').Trim()
'codePath=' + $code
$libdir = $code + '/lib/x86_64'
'libdir=' + $libdir
RunSh ('mkdir -p ' + $libdir + '; ls -ld ' + $code + ' ' + $code + '/lib ' + $libdir + ' 2>&1')
'--- push lib ---'
& $adb -s $S push 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so' /data/local/tmp/libmahoshojo.so 2>&1 | Out-Null
RunSh ('cp /data/local/tmp/libmahoshojo.so ' + $libdir + '/libmahoshojo.so; chmod 755 ' + $code + '/lib; chmod 755 ' + $libdir + '; chmod 644 ' + $libdir + '/libmahoshojo.so; ls -l ' + $libdir)
'--- relaunch ---'
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
Start-Sleep 1
& $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-String
Start-Sleep 6
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
& $adb -s $S logcat -d -b crash -t 40 2>&1 | Select-String -Pattern 'Cause|pc 0000|SIGSEGV|FATAL' | Select-Object -First 5 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- nativeloader path ---'
& $adb -s $S logcat -d 2>&1 | Select-String -Pattern 'library_path=' | Select-Object -Last 2 | ForEach-Object { $_.Line.Trim() } | Out-String
