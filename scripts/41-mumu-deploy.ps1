$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$vmDir = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0'
$diff = Join-Path $vmDir 'system-diff.vdi'
$nemu = Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu'
$reg = 'C:\Users\Administrator\.MUMUNX\VirtualBox.xml'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$raw = Join-Path $d 'final.raw'
$vdi = Join-Path $d 'final.vdi'
$baseUuid = '812f8e95-6f8b-d70c-0000-100000000000'
$diffUuid = '812f8e95-6f8b-d70c-0000-000000000000'

'--- stop everything ---'
& $vb controlvm 'MuMuPlayer-15.0-0' poweroff 2>&1 | Out-Null
& $mgr control --vmindex 0 shutdown 2>&1 | Out-Null
Start-Sleep 6
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNx|VirtualBox|VBoxSVC|MuMuPlayer' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 4

'--- compose raw with cleared upperdir ---'
Copy-Item (Join-Path $d 'merged.raw') $raw -Force
$fs = [IO.File]::Open($raw, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    function Write-At([string]$path, [int64]$offset) {
        $src = [IO.File]::OpenRead($path)
        try {
            $fs.Seek($offset, [IO.SeekOrigin]::Begin) | Out-Null
            $buf = New-Object byte[] (8MB)
            while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) { $fs.Write($buf, 0, $n) }
        } finally { $src.Close() }
    }
    Write-At (Join-Path $d 'part-root.img') ([int64]79068 * 512)
    Write-At (Join-Path $d 'part-3.img') ([int64]3784798 * 512)
    $fs.Flush()
} finally { $fs.Close() }

'--- convert + uuid ---'
if (Test-Path $vdi) { Remove-Item $vdi -Force }
& $vb convertfromraw $raw $vdi --format VDI 2>&1 | Out-Null
& $vb internalcommands sethduuid $vdi $baseUuid 2>&1 | Out-String

'--- drop registry so VBoxSVC rebuilds cleanly ---'
if (Test-Path $reg) { Remove-Item $reg -Force }

'--- deploy base, rebuild diff chain ---'
Copy-Item $vdi $base -Force
& $vb modifymedium $base --type normal 2>&1 | Out-String
if (Test-Path $diff) { Remove-Item $diff -Force }
$cmds = @('createmedium','disk',('--filename='+$diff),'--sizebyte=2474687488',('--diffparent='+$base),'--format=VDI')
& $vb @cmds 2>&1 | Out-String
& $vb internalcommands sethduuid $diff $diffUuid 2>&1 | Out-String
& $vb modifymedium $base --type readonly 2>&1 | Out-String
& $vb showhdinfo $base 2>&1 | Select-String -Pattern 'UUID|Type|Child|State' | ForEach-Object { $_.Line } | Out-String
& $vb showhdinfo $diff 2>&1 | Select-String -Pattern 'UUID|Parent|Type|State|Access' | ForEach-Object { $_.Line } | Out-String

'--- restore pristine nemu (base readonly + child diff) ---'
$candidates = @(
    (Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu.bak-uart'),
    (Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu.bak-uuid'),
    (Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu-prev')
)
foreach ($c in $candidates) {
    if (Test-Path $c) {
        'using ' + $c
        Copy-Item $c $nemu -Force
        break
    }
}
Select-String -Path $nemu -Pattern 'HardDisk uuid|Image uuid|type=' | ForEach-Object { $_.Line.Trim() } | Out-String
