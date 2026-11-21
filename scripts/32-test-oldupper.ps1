$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$vmDir = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0'
$baseDir = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base'
$base = Join-Path $baseDir 'system.vdi'
$diff = Join-Path $vmDir 'system-diff.vdi'
$nemu = Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$serial = Join-Path $d 'serial-test2.log'
$baseUuid = '812f8e95-6f8b-d70c-0000-100000000000'
$testRaw = Join-Path $d 'test-oldupper.raw'
$testVdi = Join-Path $d 'test-oldupper.vdi'
$backup = 'D:\MuMuWork\backup'
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'

'--- poweroff ---'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
& $vb controlvm 'MuMuPlayer-15.0-0' poweroff 2>&1 | Out-String
Start-Sleep 8
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNxDevice|VirtualBox|VBoxSVC' } | Select-Object ProcessName,Id | Format-Table -AutoSize | Out-String

'--- backup current base/diff ---'
Copy-Item $base (Join-Path $backup ('system.vdi.before-oldupper-' + $ts)) -Force
Copy-Item $diff (Join-Path $backup ('system-diff.vdi.before-oldupper-' + $ts)) -Force

'--- build raw with old upperdir ---'
Copy-Item (Join-Path $d 'merged.raw') $testRaw -Force
$fs = [IO.File]::Open($testRaw, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    $src = [IO.File]::OpenRead((Join-Path $d 'part-3.orig.img'))
    try {
        $fs.Seek([int64]3784798 * 512, [IO.SeekOrigin]::Begin) | Out-Null
        $buf = New-Object byte[] (8MB)
        while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) { $fs.Write($buf, 0, $n) }
    } finally { $src.Close() }
    $fs.Flush()
} finally { $fs.Close() }

'--- convert ---'
if (Test-Path $testVdi) { Remove-Item $testVdi -Force }
& $vb convertfromraw $testRaw $testVdi --format VDI 2>&1 | Out-String
& $vb internalcommands sethduuid $testVdi $baseUuid 2>&1 | Out-String

'--- replace base, fresh diff ---'
Copy-Item $testVdi $base -Force
if (Test-Path $diff) { Remove-Item $diff -Force }
$cmds = @('createmedium','disk',('--filename=' + $diff),'--sizebyte=2474687488',('--diffparent=' + $base),'--format=VDI')
& $vb @cmds 2>&1 | Out-String
$newDiffUuid = ''
$out = & $vb showhdinfo $diff 2>&1 | Out-String
if ($out -match 'UUID:\s+([0-9a-f\-]+)') { $newDiffUuid = $matches[1] }
'new diff uuid: ' + $newDiffUuid

'--- patch nemu diff uuid ---'
$xml = [IO.File]::ReadAllText($nemu)
$xml = $xml -replace 'uuid="\{812f8e95-6f8b-d70c-0000-000000000000\}"', ('uuid="{' + $newDiffUuid + '}"')
[IO.File]::WriteAllText($nemu, $xml, (New-Object Text.UTF8Encoding($false)))
Select-String -Path $nemu -Pattern 'system-diff|Image uuid' | ForEach-Object { $_.Line.Trim() }

'--- uart check ---'
& $vb showvminfo 'MuMuPlayer-15.0-0' --machinereadable 2>&1 | Select-String -Pattern 'uart1|uartmode1' | ForEach-Object { $_.Line } | Out-String

'--- start headless + serial ---'
if (Test-Path $serial) { Remove-Item $serial -Force }
& $vb startvm 'MuMuPlayer-15.0-0' --type headless 2>&1 | Out-String
Start-Sleep 25
Get-Item $serial -ErrorAction SilentlyContinue | Select-Object Length,LastWriteTime | Format-Table -AutoSize | Out-String
if (Test-Path $serial) { Get-Content $serial -Tail 120 | Out-String }
'--- running ---'
& $vb list runningvms 2>&1 | Out-String
