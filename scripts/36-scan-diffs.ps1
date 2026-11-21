$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$root = Join-Path $d 'tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = Join-Path $d 'tools\e2fsprogs\usr\sbin\debugfs.exe'
$orig = 'D:/MuMuWork/image-edit/part-root.orig.img'
$cur  = 'D:/MuMuWork/image-edit/part-root.img'
$tmp  = Join-Path $d 'scan-tmp.bin'
$report = Join-Path $d 'diff-report.txt'

function Dbg([string]$img, [string]$cmd) {
    $out = & $dbg -R $cmd $img 2>&1
    return ($out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' })
}

function ListDir([string]$img, [string]$path) {
    $res = @()
    foreach ($line in (Dbg $img ('ls -l ' + $path))) {
        if ($line -match '^\s*(\d+)\s+([0-7]+)\s+\(\d+\)\s+(\d+)\s+(\d+)\s+(\d+)\s+\S+\s+\S+\s+(.+?)\s*$') {
            $ino = [int]$matches[1]; $mode = $matches[2]; $uid = [int]$matches[3]; $gid = [int]$matches[4]; $size = [int64]$matches[5]; $name = $matches[6]
            if ($name -eq '.' -or $name -eq '..') { continue }
            $type = $mode.Substring(0,1)
            $res += [pscustomobject]@{ Inode=$ino; Mode=$mode; Uid=$uid; Gid=$gid; Size=$size; Name=$name; Type=$type }
        }
    }
    return $res
}

function HashPath([string]$img, [string]$path, [int64]$size) {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
    $win = $tmp
    $cyg = '/cygdrive/' + $win.Substring(0,1).ToLower() + ($win.Substring(2) -replace '\\','/')
    $null = Dbg $img ('dump ' + $path + ' ' + $cyg)
    if (-not (Test-Path $tmp)) { return $null }
    $len = (Get-Item $tmp).Length
    if ($len -ne $size) { return ('SIZE:' + $len) }
    $h = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
    return $h
}

$lines = New-Object System.Collections.Generic.List[string]
$diffCount = 0
$scanCount = 0
$queue = New-Object System.Collections.Queue
$queue.Enqueue('/')
while ($queue.Count -gt 0) {
    $dirPath = $queue.Dequeue().TrimEnd('/')
    if ($dirPath -eq '') { $dirPath = '/' }
    $entries = ListDir $orig $dirPath
    $curEntries = ListDir $cur $dirPath
    $curMap = @{}
    foreach ($e in $curEntries) { $curMap[$e.Name] = $e }
    foreach ($e in $entries) {
        $child = if ($dirPath -eq '/') { '/' + $e.Name } else { $dirPath + '/' + $e.Name }
        if ($e.Type -eq '4') { $queue.Enqueue($child); continue }
        if ($e.Type -ne '1') { continue }
        $scanCount++
        if ($scanCount % 200 -eq 0) { 'progress files=' + $scanCount + ' diffs=' + $diffCount | Write-Output }
        if (-not $curMap.ContainsKey($e.Name)) { continue }
        $c = $curMap[$e.Name]
        if ($c.Size -ne $e.Size) { $lines.Add('SIZEDIF ' + $child + ' orig=' + $e.Size + ' cur=' + $c.Size); $diffCount++; continue }
        $ho = HashPath $orig $child $e.Size
        $hc = HashPath $cur $child $e.Size
        if ($ho -ne $hc) {
            $lines.Add('DIFF ' + $child + ' size=' + $e.Size + ' orig=' + $ho + ' cur=' + $hc)
            $diffCount++
        }
    }
}
'===== scan done ====='
'files compared: ' + $scanCount
'diffs: ' + $diffCount
$lines | Set-Content -Path $report -Encoding UTF8
$lines | Select-Object -First 120
