$ErrorActionPreference = 'Continue'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$serial = 'D:\MuMuWork\image-edit\serial.log'
$baseUuid = '812f8e95-6f8b-d70c-0000-100000000000'
$d = 'D:\MuMuWork\image-edit'
$raw = Join-Path $d 'test-origroot.raw'
$vdi = Join-Path $d 'test-origroot.vdi'

'--- poweroff ---'
& $vb controlvm 'MuMuPlayer-15.0-0' poweroff 2>&1 | Out-String
Start-Sleep 6

'--- build original root + old upperdir raw ---'
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
    Write-At (Join-Path $d 'part-root.orig.img') ([int64]79068 * 512)
    Write-At (Join-Path $d 'part-3.orig.img') ([int64]3784798 * 512)
    $fs.Flush()
} finally { $fs.Close() }

'--- convert ---'
if (Test-Path $vdi) { Remove-Item $vdi -Force }
& $vb convertfromraw $raw $vdi --format VDI 2>&1 | Out-String
& $vb internalcommands sethduuid $vdi $baseUuid 2>&1 | Out-String

'--- replace base ---'
Copy-Item $vdi $base -Force
'base size: ' + (Get-Item $base).Length

'--- start ---'
if (Test-Path $serial) { Remove-Item $serial -Force }
& $vb startvm 'MuMuPlayer-15.0-0' --type headless 2>&1 | Out-String
Start-Sleep 22
'--- serial ---'
Get-Item $serial -ErrorAction SilentlyContinue | Select-Object Length,LastWriteTime | Format-Table -AutoSize | Out-String
if (Test-Path $serial) { Get-Content $serial -Tail 100 | Out-String }
'--- running ---'
& $vb list runningvms 2>&1 | Out-String
