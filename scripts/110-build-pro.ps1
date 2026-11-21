$ErrorActionPreference = 'Continue'
$env:JAVA_HOME = 'D:\MuMuWork\ColorTheme\incoming\jdk\extracted\jdk-21.0.13.1+2'
$bt = 'D:\MuMuWork\ColorTheme\incoming\buildtools\extracted\android-15'
$java = Join-Path $env:JAVA_HOME 'bin\java.exe'
$apktool = 'D:\MuMuWork\tools\apktool_2.11.1.jar'
$src = 'D:\MuMuWork\momo\full'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- confirm warmup still present ---'
Select-String -Path (Join-Path $src 'smali\io\github\vvb2060\mahoshojo\home\HomeActivity.smali') -Pattern 'warmup' | ForEach-Object { $_.Line.Trim() } | Out-String
'--- build ---'
$raw = 'D:\MuMuWork\momo\momo-pro-unsigned.apk'
if (Test-Path $raw) { Remove-Item $raw -Force }
& $java -jar $apktool b $src -o $raw 2>&1 | Select-Object -Last 5 | Out-String
if (-not (Test-Path $raw)) { throw 'build failed' }
Get-Item $raw | Select-Object Length | Format-Table -AutoSize | Out-String
$aligned = 'D:\MuMuWork\momo\momo-pro-aligned.apk'
$signed = 'D:\MuMuWork\momo\momo-pro.apk'
foreach ($p in @($aligned, $signed)) { if (Test-Path $p) { Remove-Item $p -Force } }
& (Join-Path $bt 'zipalign.exe') -f -p 4 $raw $aligned 2>&1 | Out-String
& (Join-Path $bt 'apksigner.bat') sign --key 'D:\MuMuWork\tools\testkeys\platform.pk8' --cert 'D:\MuMuWork\tools\testkeys\platform.x509.pem' --out $signed $aligned 2>&1 | Out-String
& (Join-Path $bt 'apksigner.bat') verify --print-certs $signed 2>&1 | Select-Object -First 3 | Out-String
'--- install ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S push $signed /data/local/tmp/momo-pro.apk 2>&1 | Out-Null
& $adb -s $S shell pm install -r /data/local/tmp/momo-pro.apk 2>&1 | Out-String
'--- launch ---'
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-String
Start-Sleep 6
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
'--- crash? ---'
& $adb -s $S logcat -d -b crash -t 30 2>&1 | Select-String -Pattern 'SIGSEGV|FATAL|pc 0000' | Select-Object -First 5 | ForEach-Object { $_.Line.Trim() } | Out-String
