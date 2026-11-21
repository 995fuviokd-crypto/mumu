$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
$d = 'D:\MuMuWork\momo'
New-Item -ItemType Directory -Force $d | Out-Null
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim()) }
'--- locate apk ---'
$path = ((& $adb -s $S shell pm path io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim()) -replace '^package:',''
'path=' + $path
RunSh ('cp ' + $path + ' /sdcard/momo.apk; chmod 644 /sdcard/momo.apk; ls -l /sdcard/momo.apk')
& $adb -s $S pull /sdcard/momo.apk (Join-Path $d 'momo.apk') 2>&1 | Out-String
Get-Item (Join-Path $d 'momo.apk') | Select-Object Length | Format-Table -AutoSize | Out-String
'--- extract libs ---'
$ex = Join-Path $d 'apk'
if (Test-Path $ex) { Remove-Item $ex -Recurse -Force }
New-Item -ItemType Directory -Force $ex | Out-Null
$null = tar -xf (Join-Path $d 'momo.apk') -C $ex 2>&1
Get-ChildItem $ex -Recurse -Filter '*.so' | Select-Object FullName,Length | Format-Table -AutoSize | Out-String
