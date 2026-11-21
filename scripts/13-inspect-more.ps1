$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$img = 'D:/MuMuWork/image-edit/part-root.img'
$cmds = @(
    'ls -l /system/product',
    'ls -l /system/system_ext',
    'ls -l /system/product/app',
    'ls -l /system/product/priv-app',
    'ls -l /system/system_ext/app',
    'ls -l /system/system_ext/priv-app',
    'ls -l /system/etc',
    'ls -l /system/etc/user_app',
    'ls -l /system/priv-app/Lawnchair/oat',
    'ls -l /system/priv-app/com.mumu.store',
    'ls -l /system/priv-app/com.mumu.acc',
    'ls -l /system/priv-app/com.netease.mumu.cloner',
    'ls -l /system/priv-app/com.mumu.shared.sdk',
    'stat /system/etc/hosts',
    'stat /system/etc/user_app/KernelSU.apk'
)
foreach ($c in $cmds) {
    '===== ' + $c + ' ====='
    $out = & $dbg -R $c $img 2>&1
    $out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}
'===== part-3 root ====='
$out = & $dbg -R 'ls -l /' 'D:/MuMuWork/image-edit/part-3.img' 2>&1
$out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
'===== build.prop dump ====='
& $dbg -R 'dump /system/build.prop D:/MuMuWork/image-edit/build.prop.orig' $img 2>&1 | Out-String | Write-Output
'===== hosts dump ====='
& $dbg -R 'dump /system/etc/hosts D:/MuMuWork/image-edit/hosts.orig' $img 2>&1 | Out-String | Write-Output
