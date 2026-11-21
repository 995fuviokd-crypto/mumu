$ErrorActionPreference = 'Continue'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$reg = 'C:\Users\Administrator\.MUMUNX\VirtualBox.xml'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$diff = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0\system-diff.vdi'

'--- kill services ---'
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNx|VirtualBox|VBoxSVC|MuMuPlayer' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 4
if (Test-Path $reg) { Remove-Item $reg -Force }
'base type check (no registry write): ' + ((Get-Item $base).Length)

'--- launch via MuMuManager ---'
& $mgr control --vmindex 0 launch 2>&1 | Out-String
Start-Sleep 20
'--- info ---'
& $mgr info --vmindex 0 2>&1 | Out-String
'--- registry exists ---'
Test-Path $reg

'--- wait for boot ---'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
& $adb kill-server 2>&1 | Out-Null
Start-Sleep 2
$ok = $false
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep 3
    $dev = (& $adb devices 2>&1) -join "`n"
    if ($dev -match '127\.0\.0\.1:16384\s+device') { $ok = $true; 'adb online at ' + (($i+1)*3) + 's'; break }
}
if ($ok) {
    for ($j = 0; $j -lt 80; $j++) {
        Start-Sleep 3
        $b = (& $adb -s 127.0.0.1:16384 shell getprop sys.boot_completed 2>&1) -join ''
        if ($b.Trim() -eq '1') { 'boot_completed at ' + (($j+1)*3) + 's'; break }
    }
}
'--- info after ---'
& $mgr info --vmindex 0 2>&1 | Out-String
'--- devices ---'
& $adb devices -l 2>&1 | Out-String
