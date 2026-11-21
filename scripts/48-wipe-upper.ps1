$ErrorActionPreference = 'Continue'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$diff = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0\system-diff.vdi'
$reg = 'C:\Users\Administrator\.MUMUNX\VirtualBox.xml'
$diffUuid = '812f8e95-6f8b-d70c-0000-000000000000'

'--- shutdown ---'
& $mgr control --vmindex 0 shutdown 2>&1 | Out-String
Start-Sleep 8
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNx|VirtualBox|VBoxSVC|MuMuPlayer' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 4

'--- drop registry ---'
if (Test-Path $reg) { Remove-Item $reg -Force }

'--- base to normal, rebuild empty diff ---'
& $vb modifymedium $base --type normal 2>&1 | Out-String
if (Test-Path $diff) {
    Copy-Item $diff ('D:\MuMuWork\backup\system-diff.vdi.pre-wipe-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force
    Remove-Item $diff -Force
}
$cmds = @('createmedium','disk',('--filename='+$diff),'--sizebyte=2474687488',('--diffparent='+$base),'--format=VDI')
& $vb @cmds 2>&1 | Out-String
& $vb internalcommands sethduuid $diff $diffUuid 2>&1 | Out-String
if (Test-Path $reg) { Remove-Item $reg -Force }

'--- launch ---'
& $mgr control --vmindex 0 launch 2>&1 | Out-String
Start-Sleep 25
& $mgr info --vmindex 0 2>&1 | Out-String

'--- wait boot ---'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
& $adb kill-server 2>&1 | Out-Null
Start-Sleep 2
for ($i = 0; $i -lt 100; $i++) {
    Start-Sleep 4
    $dev = (& $adb devices 2>&1) -join "`n"
    if ($dev -match 'emulator-5554\s+device') { 'adb online at ' + (($i+1)*4) + 's'; break }
}
& $adb devices -l 2>&1 | Out-String
