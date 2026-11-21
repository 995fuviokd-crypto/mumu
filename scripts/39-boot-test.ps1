$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$serial = Join-Path $d 'serial.log'
$raw = Join-Path $d 'boot-new.raw'
$vdi = Join-Path $d 'boot-new.vdi'
$uuid = '812f8e95-6f8b-d70c-0000-100000000000'

'--- poweroff ---'
& $vb controlvm 'MuMuPlayer-15.0-0' poweroff 2>&1 | Out-Null
Start-Sleep 6

'--- compose raw ---'
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
    Write-At (Join-Path $d 'part-3.orig.img') ([int64]3784798 * 512)
    $fs.Flush()
} finally { $fs.Close() }

'--- to vdi ---'
if (Test-Path $vdi) { Remove-Item $vdi -Force }
& $vb convertfromraw $raw $vdi --format VDI 2>&1 | Out-Null
& $vb internalcommands sethduuid $vdi $uuid 2>&1 | Out-String

'--- deploy ---'
Copy-Item $vdi $base -Force
'base size ' + (Get-Item $base).Length

'--- boot ---'
if (Test-Path $serial) { Remove-Item $serial -Force }
& $vb startvm 'MuMuPlayer-15.0-0' --type headless 2>&1 | Out-String
Start-Sleep 30
'--- serial markers ---'
if (Test-Path $serial) {
    Get-Item $serial | Select-Object Length | Format-Table -AutoSize | Out-String
    Select-String -Path $serial -Pattern 'CANNOT LINK|linkerconfig generated|failed to find generated|Kernel panic|zygote|SystemServer|boot_completed|BOOT FAILURE' | Select-Object -Last 25 | ForEach-Object { $_.Line.Trim() }
} else { 'no serial' }
'--- running ---'
& $vb list runningvms 2>&1 | Out-String
