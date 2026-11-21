$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$root = Join-Path $d 'tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = Join-Path $d 'tools\e2fsprogs\usr\sbin\debugfs.exe'
$fsck = Join-Path $d 'tools\e2fsprogs\usr\sbin\e2fsck.exe'

$baseImgWin = Join-Path $d 'part-root.origfsck.img'
$base = 'D:/MuMuWork/image-edit/part-root.origfsck.img'
$cur = 'D:/MuMuWork/image-edit/part-root.img'
$tmp = Join-Path $d 'scan-tmp.bin'

if (-not (Test-Path $baseImgWin)) {
    '--- create fsck baseline ---'
    Copy-Item (Join-Path $d 'part-root.orig.img') $baseImgWin
    & $fsck -fy $baseImgWin 2>&1 | Select-Object -Last 3
}

function Dbg([string]$img, [string]$cmd) {
    $out = & $dbg -R $cmd $img 2>&1
    return ($out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' })
}
function ListDir([string]$img, [string]$path) {
    $res = @()
    foreach ($line in (Dbg $img ('ls -l ' + $path))) {
        if ($line -match '^\s*(\d+)\s+([0-7]+)\s+\(\d+\)\s+(\d+)\s+(\d+)\s+(\d+)\s+\S+\s+\S+\s+(.+?)\s*$') {
            $name = $matches[6]
            if ($name -eq '.' -or $name -eq '..') { continue }
            $res += [pscustomobject]@{ Mode=$matches[2]; Size=[int64]$matches[5]; Name=$name; Type=$matches[2].Substring(0,1) }
        }
    }
    return $res
}
function HashPath([string]$img, [string]$path, [int64]$size) {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
    $cyg = '/cygdrive/' + $tmp.Substring(0,1).ToLower() + ($tmp.Substring(2) -replace '\\','/')
    $null = Dbg $img ('dump ' + $path + ' ' + $cyg)
    if (-not (Test-Path $tmp)) { return 'MISSING' }
    $len = (Get-Item $tmp).Length
    if ($len -ne $size) { return ('SIZE:' + $len) }
    return (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
}

$lines = New-Object System.Collections.Generic.List[string]
$diffs = 0
$queue = New-Object System.Collections.Queue
$queue.Enqueue('/')
while ($queue.Count -gt 0) {
    $dirPath = $queue.Dequeue().TrimEnd('/')
    if ($dirPath -eq '') { $dirPath = '/' }
    $entries = ListDir $base $dirPath
    $curEntries = ListDir $cur $dirPath
    $curMap = @{}
    foreach ($e in $curEntries) { $curMap[$e.Name] = $e }
    foreach ($e in $entries) {
        $child = if ($dirPath -eq '/') { '/' + $e.Name } else { $dirPath + '/' + $e.Name }
        if ($e.Type -eq '4') { $queue.Enqueue($child); continue }
        if ($e.Type -ne '1') { continue }
        if (-not $curMap.ContainsKey($e.Name)) { $lines.Add('DELETED ' + $child); $diffs++; continue }
        $c = $curMap[$e.Name]
        if ($c.Size -ne $e.Size) { $lines.Add('SIZEDIF ' + $child + ' base=' + $e.Size + ' cur=' + $c.Size); $diffs++; continue }
        $hb = HashPath $base $child $e.Size
        $hc = HashPath $cur $child $e.Size
        if ($hb -ne $hc) { $lines.Add('DIFF ' + $child + ' size=' + $e.Size); $diffs++ }
    }
}
'===== compare done ====='
'diffs vs fsck-baseline: ' + $diffs
$lines | Set-Content (Join-Path $d 'diff-report2.txt') -Encoding UTF8
$lines

'===== verify new files match host sources ====='
$checks = @(
    @{ Path='/system/priv-app/Lawnchair/Lawnchair.apk'; Src="$d\staging\Lawnchair-upper.apk" },
    @{ Path='/system/app/Via/Via.apk'; Src="$d\staging\Via.apk" },
    @{ Path='/system/etc/hosts'; Src="$d\staging\hosts.new" },
    @{ Path='/system/build.prop'; Src="$d\staging\build.prop.new" },
    @{ Path='/system/priv-app/Lawnchair/lib/x86_64/libnrb.so'; Src="$d\staging\lib\lib\x86_64\libnrb.so" },
    @{ Path='/system/priv-app/Lawnchair/lib/x86_64/libsentry.so'; Src="$d\staging\lib\lib\x86_64\libsentry.so" }
)
foreach ($c in $checks) {
    $size = (Get-Item $c.Src).Length
    $hImg = HashPath $cur $c.Path $size
    $hSrc = (Get-FileHash $c.Src -Algorithm SHA256).Hash.ToLower()
    $ok = ($hImg -eq $hSrc)
    $c.Path + ' match=' + $ok
}

'===== deleted paths check ====='
foreach ($p in @('/system/priv-app/com.mumu.store','/system/priv-app/com.mumu.acc','/system/priv-app/com.netease.mumu.cloner','/system/product/app/TrichromeChrome','/system/etc/user_app/KernelSU.apk','/system/priv-app/Lawnchair/oat')) {
    $o = Dbg $cur ('stat ' + $p)
    $exists = ($o -join ' ') -notmatch 'File not found'
    $p + ' stillExists=' + $exists
}
