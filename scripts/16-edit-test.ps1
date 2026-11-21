$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$img = 'D:/MuMuWork/image-edit/part-root.img'
$orig = 'D:\MuMuWork\image-edit\part-root.orig.img'
$orig3 = 'D:\MuMuWork\image-edit\part-3.orig.img'
if (-not (Test-Path $orig)) { Copy-Item 'D:\MuMuWork\image-edit\part-root.img' $orig }
if (-not (Test-Path $orig3)) { Copy-Item 'D:\MuMuWork\image-edit\part-3.img' $orig3 }
Get-Item $orig, $orig3 | Select-Object Name,Length | Format-Table -AutoSize | Out-String | Write-Output

$cmds = @(
    'ls -l /system/priv-app/Lawnchair/oat/x86_64',
    'ls -l /system/product/app/TrichromeChrome',
    'ls -l /system/priv-app/com.mumu.store',
    'ls -l /system/priv-app/com.mumu.acc',
    'ls -l /system/priv-app/com.netease.mumu.cloner',
    'ls -l /system/app'
)
foreach ($c in $cmds) {
    '===== ' + $c + ' ====='
    $out = & $dbg -R $c $img 2>&1
    $out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}

'===== write/sif/ea_set test ====='
$testCmds = @(
    'write /cygdrive/d/MuMuWork/image-edit/staging/hosts.orig /testfile',
    'sif /testfile mode 0100644',
    'sif /testfile uid 0',
    'sif /testfile gid 0',
    'ea_set /testfile security.selinux u:object_r:system_file:s0',
    'ea_get /testfile security.selinux',
    'stat /testfile',
    'rm /testfile'
)
foreach ($c in $testCmds) {
    '--- ' + $c
    $out = & $dbg -w -R $c $img 2>&1
    $out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' } | Out-String | Write-Output
}
