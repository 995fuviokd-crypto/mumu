$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$root = Join-Path $d 'tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = Join-Path $d 'tools\e2fsprogs\usr\sbin\debugfs.exe'

# extract vendor (sda7) from final.raw
$final = Join-Path $d 'final.raw'
$vendor = Join-Path $d 'part-vendor.img'
$off = [int64]3505653 * 512
$len = [int64]279144 * 512
if (-not (Test-Path $vendor)) {
    $in = [IO.File]::OpenRead($final)
    $out = [IO.File]::Open($vendor, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $in.Seek($off, [IO.SeekOrigin]::Begin) | Out-Null
        $buf = New-Object byte[] (4MB)
        $left = $len
        while ($left -gt 0) { $n = $in.Read($buf, 0, [int][Math]::Min($buf.Length, $left)); if ($n -le 0) { break }; $out.Write($buf, 0, $n); $left -= $n }
        $out.Flush()
    } finally { $in.Close(); $out.Close() }
}
'vendor size: ' + (Get-Item $vendor).Length
'--- vendor build.prop keys of interest ---'
$v = 'D:/MuMuWork/image-edit/part-vendor.img'
(& $dbg -R 'cat /build.prop' $v 2>&1) | Where-Object { $_ -match 'qemu|hv\.platform|native\.bridge|hardware|mainkeys' } | Out-String
'--- vendor prop files ---'
(& $dbg -R 'ls -l /' $v 2>&1) | Where-Object { $_ -match 'prop' } | Out-String
'--- root image prop files ---'
$r = 'D:/MuMuWork/image-edit/part-root.img'
foreach ($p in @('/system/build.prop','/system/etc/prop.default','/system/product/etc/build.prop','/system/system_ext/etc/build.prop','/system/etc/build.prop')) {
    '== ' + $p
    (& $dbg -R ('cat ' + $p) $r 2>&1) | Where-Object { $_ -match 'qemu|hv\.platform|native\.bridge|mainkeys' } | Out-String
}
