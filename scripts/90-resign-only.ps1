$ErrorActionPreference = 'Continue'
$env:JAVA_HOME = 'D:\MuMuWork\ColorTheme\incoming\jdk\extracted\jdk-21.0.13.1+2'
$bt = 'D:\MuMuWork\ColorTheme\incoming\buildtools\extracted\android-15'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
$src = 'D:\MuMuWork\momo\momo.apk'
$out = 'D:\MuMuWork\momo\momo-resigned.apk'
if (Test-Path $out) { Remove-Item $out -Force }
& (Join-Path $bt 'apksigner.bat') sign --key 'D:\MuMuWork\tools\testkeys\platform.pk8' --cert 'D:\MuMuWork\tools\testkeys\platform.x509.pem' --out $out $src 2>&1 | Out-String
& (Join-Path $bt 'apksigner.bat') verify --print-certs $out 2>&1 | Select-Object -First 3 | Out-String
'--- install resigned original ---'
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S push $out /data/local/tmp/momo-resigned.apk 2>&1 | Out-Null
& $adb -s $S shell pm install -r /data/local/tmp/momo-resigned.apk 2>&1 | Out-String
'--- launch x3 ---'
for ($i = 1; $i -le 3; $i++) {
    & $adb -s $S logcat -c 2>&1 | Out-Null
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
    Start-Sleep 5
    $p = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
    $crash = ((& $adb -s $S logcat -d -b crash -t 20 2>&1 | Out-String))
    $sig = if ($crash -match 'SIGSEGV') { 'SIGSEGV' } elseif ($crash -match 'FATAL') { 'FATAL' } else { 'none' }
    "attempt ${i}: pid=[$p] crash=$sig"
}
'--- ui text sample ---'
& $adb -s $S shell uiautomator dump /sdcard/ui_rs.xml 2>&1 | Out-Null
& $adb -s $S pull /sdcard/ui_rs.xml 'D:\MuMuWork\momo\ui-resigned.xml' 2>&1 | Out-Null
$txt = Get-Content 'D:\MuMuWork\momo\ui-resigned.xml' -Raw -Encoding UTF8
[regex]::Matches($txt,'text="([^"]{2,60})"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 25 | Out-String
