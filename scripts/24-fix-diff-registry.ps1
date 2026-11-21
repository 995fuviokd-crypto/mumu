$ErrorActionPreference = 'Continue'
$vmDir = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0'
$nemu = Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu'
$diff = Join-Path $vmDir 'system-diff.vdi'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$oldDiffUuid = '812f8e95-6f8b-d70c-0000-000000000000'
$newDiffUuid = '978d6b74-39ca-4b3b-817e-176f64b49f5c'

'--- stop ---'
& $mgr control --vmindex 0 shutdown 2>&1 | Out-String
Start-Sleep 6
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNxDevice|VirtualBox|VBoxSVC' } | Select-Object ProcessName,Id | Format-Table -AutoSize | Out-String

'--- diff uuid back to created value ---'
& $vb internalcommands sethduuid $diff $newDiffUuid 2>&1 | Out-String

'--- patch nemu ---'
Copy-Item $nemu ($nemu + '.bak-uuid') -Force
$xml = [IO.File]::ReadAllText($nemu)
$xml = $xml.Replace('{' + $oldDiffUuid + '}', '{' + $newDiffUuid + '}')
[IO.File]::WriteAllText($nemu, $xml, (New-Object Text.UTF8Encoding($false)))
Select-String -Path $nemu -Pattern 'system-diff|HardDisk uuid|AttachedDevice|Image uuid' | ForEach-Object { $_.Line.Trim() } | Select-Object -First 20

'--- hd info ---'
& $vb showhdinfo $base 2>&1 | Out-String
& $vb showhdinfo $diff 2>&1 | Out-String

'--- launch ---'
& $mgr control --vmindex 0 launch 2>&1 | Out-String
Start-Sleep 10

'--- adb wait ---'
& $adb kill-server 2>&1 | Out-Null
& $adb connect 127.0.0.1:16384 2>&1 | Out-String
$ok = $false
for ($i = 0; $i -lt 120; $i++) {
    Start-Sleep 2
    $devices = (& $adb devices 2>&1) -join "`n"
    if ($devices -match '127\.0\.0\.1:16384\s+device') { $ok = $true; break }
}
'device online: ' + $ok + ' after ' + $i
if ($ok) {
    for ($j = 0; $j -lt 80; $j++) {
        Start-Sleep 3
        $boot = (& $adb -s 127.0.0.1:16384 shell getprop sys.boot_completed 2>&1) -join ''
        if ($boot.Trim() -eq '1') { 'boot_completed after ' + $j; break }
    }
}
'--- MuMu info ---'
& $mgr info --vmindex 0 2>&1 | Out-String
