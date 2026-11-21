$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$rootDll = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $rootDll -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$qi = 'D:\MuMuWork\ColorOSLab\sdk\emulator\qemu-img.exe'
$merged = Join-Path $d 'merged.raw'
$rootImg = Join-Path $d 'part-root.img'
$part3 = Join-Path $d 'part-3.img'
$newVdi = Join-Path $d 'system-new.vdi'

'--- verify part3 dirs ---'
& $dbg -R 'ls -l /upperdir' 'D:/MuMuWork/image-edit/part-3.img' 2>&1 | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
& $dbg -R 'ls -l /workdir' 'D:/MuMuWork/image-edit/part-3.img' 2>&1 | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output

'--- write partitions back into merged.raw ---'
$fs = [IO.File]::Open($merged, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    function Write-At([string]$path, [int64]$offset) {
        $src = [IO.File]::OpenRead($path)
        try {
            $fs.Seek($offset, [IO.SeekOrigin]::Begin) | Out-Null
            $buf = New-Object byte[] (8MB)
            while (($n = $src.Read($buf, 0, $buf.Length)) -gt 0) { $fs.Write($buf, 0, $n) }
        } finally { $src.Close() }
    }
    Write-At $rootImg ([int64]79068 * 512)
    Write-At $part3 ([int64]3784798 * 512)
    $fs.Flush()
    'merged.raw size: ' + $fs.Length | Write-Output
} finally { $fs.Close() }

'--- convert to VDI ---'
if (Test-Path $newVdi) { Remove-Item $newVdi -Force }
& $vb convertfromraw $merged $newVdi --format VDI 2>&1 | Out-String | Write-Output
if (-not (Test-Path $newVdi)) { throw 'convertfromraw failed' }
Get-Item $newVdi | Select-Object Length | Format-Table -AutoSize | Out-String | Write-Output

'--- set UUID ---'
$baseUuid = '812f8e95-6f8b-d70c-0000-100000000000'
& $vb internalcommands sethduuid $newVdi $baseUuid 2>&1 | Out-String | Write-Output

'--- showhdinfo ---'
& $vb showhdinfo $newVdi 2>&1 | Out-String | Write-Output
'--- qemu-img info ---'
& $qi info $newVdi 2>&1 | Out-String | Write-Output
