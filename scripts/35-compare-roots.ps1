$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$root = Join-Path $d 'tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = Join-Path $d 'tools\e2fsprogs\usr\sbin\debugfs.exe'

$imgs = @{
    orig = 'D:/MuMuWork/image-edit/part-root.orig.img'
    cur  = 'D:/MuMuWork/image-edit/part-root.img'
}
$files = @(
    '/system/bin/init',
    '/system/bin/bootstrap/linker64',
    '/system/lib64/libc++.so',
    '/system/lib64/libbase.so',
    '/system/lib64/libc.so',
    '/system/lib64/libdl.so',
    '/system/etc/linker.config.pb',
    '/system/apex/com.android.runtime.apex'
)

foreach ($tag in $imgs.Keys) {
    $outDir = Join-Path $d ('cmp-' + $tag)
    if (Test-Path $outDir) { Remove-Item $outDir -Recurse -Force }
    New-Item -ItemType Directory -Force $outDir | Out-Null
    foreach ($f in $files) {
        $name = ($f -replace '/', '_')
        $winPath = (Join-Path $outDir $name)
        $cyg = '/cygdrive/' + $winPath.Substring(0,1).ToLower() + ($winPath.Substring(2) -replace '\\', '/')
        & $dbg -R ('dump ' + $f + ' ' + $cyg) $imgs[$tag] 2>&1 | Out-Null
    }
    '===== ' + $tag + ' ====='
    Get-ChildItem $outDir -File | ForEach-Object {
        $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
        $_.Name + ' ' + $_.Length + ' ' + $h
    } | Sort-Object
    '===== ' + $tag + ' dir counts ====='
    foreach ($dir in @('/system/lib64', '/system/apex', '/system/bin', '/system/lib', '/system/etc')) {
        $lines = (& $dbg -R ('ls -l ' + $dir) $imgs[$tag] 2>&1) | Where-Object { $_ -match '^\s+\d+\s+[0-7]+\s+\(' }
        $dir + ' entries=' + $lines.Count
    }
}
'===== fs stats ====='
foreach ($tag in $imgs.Keys) {
    '--- ' + $tag
    (& $dbg -R 'stats' $imgs[$tag] 2>&1) | Select-String -Pattern 'Block count|Free blocks|Inode count|Free inodes' | ForEach-Object { $_.Line.Trim() }
}
