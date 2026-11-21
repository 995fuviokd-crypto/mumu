$ErrorActionPreference = 'Continue'
$env:JAVA_HOME = 'D:\MuMuWork\ColorTheme\incoming\jdk\extracted\jdk-21.0.13.1+2'
$bt = 'D:\MuMuWork\ColorTheme\incoming\buildtools\extracted\android-15'
$java = Join-Path $env:JAVA_HOME 'bin\java.exe'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
$raw = 'D:\MuMuWork\momo\momo-it-unsigned.apk'
$al = 'D:\MuMuWork\momo\momo-it-aligned.apk'
$sg = 'D:\MuMuWork\momo\momo-it.apk'
foreach ($p in @($raw, $al, $sg)) { if (Test-Path $p) { Remove-Item $p -Force } }
& $java -jar 'D:\MuMuWork\tools\apktool_2.11.1.jar' b 'D:\MuMuWork\momo\full' -o $raw 2>&1 | Select-Object -Last 2 | Out-String
if (-not (Test-Path $raw)) { 'BUILD FAILED'; exit 1 }
& (Join-Path $bt 'zipalign.exe') -f -p 4 $raw $al 2>&1 | Out-Null
& (Join-Path $bt 'apksigner.bat') sign --key 'D:\MuMuWork\tools\testkeys\platform.pk8' --cert 'D:\MuMuWork\tools\testkeys\platform.x509.pem' --out $sg $al 2>&1 | Out-Null
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S push $sg /data/local/tmp/momo-it.apk 2>&1 | Out-Null
& $adb -s $S shell pm install -r /data/local/tmp/momo-it.apk 2>&1 | Out-String
& $adb -s $S logcat -c 2>&1 | Out-Null
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
Start-Sleep 6
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
& $adb -s $S logcat -d -b crash -t 20 2>&1 | Select-String -Pattern 'SIGSEGV|FATAL' | Select-Object -First 3 | ForEach-Object { $_.Line.Trim() } | Out-String
