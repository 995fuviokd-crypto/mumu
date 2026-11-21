$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$img = 'D:/MuMuWork/image-edit/part-root.img'
$cmds = @(
    'ls -l /system',
    'stat /product',
    'stat /system_ext',
    'stat /vendor',
    'ls -l /system/priv-app',
    'ls -l /system/app',
    'ls -l /system/priv-app/Lawnchair',
    'stat /system/priv-app/Lawnchair/Lawnchair.apk',
    'ls -l /system/etc | head -40',
    'stat /system/build.prop'
)
foreach ($c in $cmds) {
    '===== ' + $c + ' ====='
    $out = & $dbg -R $c $img 2>&1
    $out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}
