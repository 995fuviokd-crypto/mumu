$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$img = 'D:/MuMuWork/image-edit/part-3.img'
$cmds = @(
    'ls -l /upperdir',
    'ls -l /upperdir/priv-app',
    'ls -l /upperdir/app',
    'ls -l /upperdir/etc',
    'ls -l /upperdir/product',
    'ls -l /upperdir/framework',
    'ls -l /upperdir/lib64',
    'ls -l /upperdir/bin',
    'ls -l /upperdir/system',
    'ls -l /upperdir/priv-app/Lawnchair',
    'stat /upperdir/priv-app/Lawnchair/Lawnchair.apk',
    'ls -l /upperdir/app/Via',
    'stat /upperdir/app/Via/Via.apk',
    'ls -l /upperdir/etc/hosts',
    'stat /upperdir/etc/hosts'
)
foreach ($c in $cmds) {
    '===== ' + $c + ' ====='
    $out = & $dbg -R $c $img 2>&1
    $out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}
'===== debugfs help ====='
$out = & $dbg -R 'help' $img 2>&1
$out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
