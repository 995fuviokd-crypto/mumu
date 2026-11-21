$ErrorActionPreference = 'Continue'
$vmDir = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0'
$baseDir = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base'
$base = Join-Path $baseDir 'system.vdi'
$diff = Join-Path $vmDir 'system-diff.vdi'
$newVdi = 'D:\MuMuWork\image-edit\system-new.vdi'
$backup = 'D:\MuMuWork\backup'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

'--- ensure stopped ---'
& $mgr control --vmindex 0 shutdown 2>&1 | Out-String
Start-Sleep 5
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNxDevice|VirtualBox|VBoxSVC' } | Select-Object ProcessName,Id | Format-Table -AutoSize | Out-String

'--- backup current base/diff ---'
$baseBak = Join-Path $backup ('system.vdi.pre-bake-' + $ts)
if (-not (Test-Path $baseBak)) { Copy-Item $base $baseBak }
$diffBak = Join-Path $backup ('system-diff.vdi.pre-bake-' + $ts)
if (-not (Test-Path $diffBak)) { Copy-Item $diff $diffBak }
Get-Item $baseBak, $diffBak | Select-Object Name,Length | Format-Table -AutoSize | Out-String

'--- replace base ---'
Copy-Item $newVdi $base -Force
'base size: ' + (Get-Item $base).Length

'--- remove old diff, create fresh diff ---'
if (Test-Path $diff) { Remove-Item $diff -Force }
$cmds = @(
    'createmedium', 'disk',
    ('--filename=' + $diff),
    '--sizebyte=2474687488',
    ('--diffparent=' + $base),
    '--format=VDI'
)
& $vb @cmds 2>&1 | Out-String
if (-not (Test-Path $diff)) { throw 'fresh diff creation failed' }
& $vb internalcommands sethduuid $diff '812f8e95-6f8b-d70c-0000-000000000000' 2>&1 | Out-String

'--- hd info ---'
& $vb showhdinfo $base 2>&1 | Out-String
& $vb showhdinfo $diff 2>&1 | Out-String

'--- launch ---'
& $mgr control --vmindex 0 launch 2>&1 | Out-String

'--- wait for adb ---'
$env:ADB_SERVER_SOCKET = ''
$serial = '127.0.0.1:16384'
& $adb connect $serial 2>&1 | Out-String
$ok = $false
for ($i = 0; $i -lt 90; $i++) {
    Start-Sleep 2
    $state = & $adb -s $serial get-state 2>&1
    if ($state -match 'device') { $ok = $true; break }
}
'booting via adb: ' + $ok + ' after ' + $i
if ($ok) {
    for ($j = 0; $j -lt 60; $j++) {
        Start-Sleep 3
        $boot = (& $adb -s $serial shell getprop sys.boot_completed 2>&1) -join ''
        if ($boot.Trim() -eq '1') { 'boot_completed after ' + $j; break }
    }
}
