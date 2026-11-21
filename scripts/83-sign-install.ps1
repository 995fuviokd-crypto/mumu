$ErrorActionPreference = 'Continue'
$env:JAVA_HOME = 'D:\MuMuWork\ColorTheme\incoming\jdk\extracted\jdk-21.0.13.1+2'
$bt = 'D:\MuMuWork\ColorTheme\incoming\buildtools\extracted\android-15'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
$raw = 'D:\MuMuWork\momo\momo-patched-unsigned.apk'
$aligned = 'D:\MuMuWork\momo\momo-patched-aligned.apk'
$signed = 'D:\MuMuWork\momo\momo-patched.apk'
foreach ($p in @($aligned, $signed)) { if (Test-Path $p) { Remove-Item $p -Force } }
& (Join-Path $bt 'zipalign.exe') -f -p 4 $raw $aligned 2>&1 | Out-String
& (Join-Path $bt 'apksigner.bat') sign --key 'D:\MuMuWork\tools\testkeys\platform.pk8' --cert 'D:\MuMuWork\tools\testkeys\platform.x509.pem' --out $signed $aligned 2>&1 | Out-String
& (Join-Path $bt 'apksigner.bat') verify --print-certs $signed 2>&1 | Select-Object -First 5 | Out-String
'--- install ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S push $signed /data/local/tmp/momo-patched.apk 2>&1 | Out-Null
& $adb -s $S shell pm install -r /data/local/tmp/momo-patched.apk 2>&1 | Out-String
'--- launch ---'
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-String
Start-Sleep 6
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
'--- crash? ---'
& $adb -s $S logcat -d -b crash -t 60 2>&1 | Select-String -Pattern 'SIGSEGV|SIGABRT|pc 0000|Cause|AndroidRuntime|FATAL EXCEPTION' | Select-Object -First 10 | ForEach-Object { $_.Line.Trim() } | Out-String
'--- screenshot ---'
& $adb -s $S shell screencap -p /sdcard/_momo.png 2>&1 | Out-Null
& $adb -s $S pull /sdcard/_momo.png 'D:\MuMuWork\momo\momo-screen.png' 2>&1 | Out-Null
Get-Item 'D:\MuMuWork\momo\momo-screen.png' -ErrorAction SilentlyContinue | Select-Object Length | Format-Table -AutoSize | Out-String
