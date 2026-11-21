$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$img3 = 'D:/MuMuWork/image-edit/part-3.img'
$imgRoot = 'D:/MuMuWork/image-edit/part-root.img'
$staging = 'D:\MuMuWork\image-edit\staging'
New-Item -ItemType Directory -Force $staging | Out-Null
New-Item -ItemType Directory -Force (Join-Path $staging 'lib') | Out-Null

$cmds = @(
    'ls -l /upperdir/priv-app/Lawnchai',
    'ls -l /upperdir/product/app',
    'ls -l /upperdir/etc/user_app',
    'ls -l /upperdir/priv-app/Lawnchair/lib',
    'ls -l /upperdir/priv-app/Lawnchair/lib/x86_64'
)
foreach ($c in $cmds) {
    '===== ' + $c + ' ====='
    $out = & $dbg -R $c $img3 2>&1
    $out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}

'===== dump launcher apk ====='
& $dbg -R 'dump /upperdir/priv-app/Lawnchair/Lawnchair.apk /cygdrive/d/MuMuWork/image-edit/staging/Lawnchair-upper.apk' $img3 2>&1 | Out-String | Write-Output
'===== rdump lib ====='
& $dbg -R 'rdump /upperdir/priv-app/Lawnchair/lib /cygdrive/d/MuMuWork/image-edit/staging/lib' $img3 2>&1 | Out-String | Write-Output
'===== dump via ====='
& $dbg -R 'dump /upperdir/app/Via/Via.apk /cygdrive/d/MuMuWork/image-edit/staging/Via.apk' $img3 2>&1 | Out-String | Write-Output
'===== dump build.prop ====='
& $dbg -R 'dump /system/build.prop /cygdrive/d/MuMuWork/image-edit/staging/build.prop.orig' $imgRoot 2>&1 | Out-String | Write-Output
'===== dump hosts ====='
& $dbg -R 'dump /system/etc/hosts /cygdrive/d/MuMuWork/image-edit/staging/hosts.orig' $imgRoot 2>&1 | Out-String | Write-Output
'===== staging ====='
Get-ChildItem $staging -Recurse -File | Select-Object FullName,Length | Format-Table -AutoSize | Out-String | Write-Output
'===== hash compare ====='
$h1 = (Get-FileHash (Join-Path $staging 'Lawnchair-upper.apk') -Algorithm SHA256).Hash
$h2 = (Get-FileHash 'D:\MuMuWork\lawnchair-final2.apk' -Algorithm SHA256).Hash
'upper: ' + $h1
'host : ' + $h2
'equal: ' + ($h1 -eq $h2)
