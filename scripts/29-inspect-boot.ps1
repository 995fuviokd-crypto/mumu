$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$root = Join-Path $d 'tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = Join-Path $d 'tools\e2fsprogs\usr\sbin\debugfs.exe'
$merged = Join-Path $d 'merged.raw'
$bootImg = Join-Path $d 'part-boot.img'
$off = [int64]34304 * 512
$len = [int64]28634 * 512
if (-not (Test-Path $bootImg)) {
    $in = [IO.File]::OpenRead($merged)
    $out = [IO.File]::Open($bootImg, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $in.Seek($off, [IO.SeekOrigin]::Begin) | Out-Null
        $buf = New-Object byte[] (1MB)
        $left = $len
        while ($left -gt 0) { $n = $in.Read($buf, 0, [int][Math]::Min($buf.Length, $left)); if ($n -le 0) { break }; $out.Write($buf, 0, $n); $left -= $n }
        $out.Flush()
    } finally { $in.Close(); $out.Close() }
}
Get-Item $bootImg | Select-Object Length | Format-Table -AutoSize | Out-String | Write-Output
$cmds = @('ls -l /', 'ls -l /boot', 'ls -l /boot/grub', 'ls -l /grub')
foreach ($c in $cmds) {
    '===== ' + $c + ' ====='
    (& $dbg -R $c $bootImg 2>&1) | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}
'===== menu.lst ====='
(& $dbg -R 'cat /boot/grub/menu.lst' $bootImg 2>&1) | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
'===== grub.conf ====='
(& $dbg -R 'cat /boot/grub/grub.conf' $bootImg 2>&1) | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
