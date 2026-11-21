$ErrorActionPreference = 'Stop'
$d = 'D:\MuMuWork\image-edit'
$diffPath = Join-Path $d 'diff.vdi'
$fs = [IO.File]::OpenRead($diffPath)
try {
    $len = $fs.Length
    'file length: ' + $len | Write-Output
    $h = New-Object byte[] 512
    $fs.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null
    $null = $fs.Read($h, 0, 512)
    $offBlocks = [BitConverter]::ToUInt32($h, 0x154)
    $offData = [BitConverter]::ToUInt32($h, 0x158)
    $bs = [BitConverter]::ToUInt32($h, 0x178)
    $total = [BitConverter]::ToUInt32($h, 0x180)
    $alloc = [BitConverter]::ToUInt32($h, 0x184)
    ('offBlocks={0} offData={1} blockSize={2} total={3} alloc={4}' -f $offBlocks, $offData, $bs, $total, $alloc) | Write-Output

    $fs.Seek($offBlocks, [IO.SeekOrigin]::Begin) | Out-Null
    $map = New-Object byte[] ([int]$total * 4)
    $n = 0
    while ($n -lt $map.Length) { $r = $fs.Read($map, $n, $map.Length - $n); if ($r -le 0) { break }; $n += $r }
    'map bytes read: ' + $n | Write-Output
    $vals = New-Object 'System.Collections.Generic.List[uint32]'
    for ($i = 0; $i -lt $total; $i++) { $vals.Add([BitConverter]::ToUInt32($map, $i * 4)) }
    $free = ($vals | Where-Object { $_ -eq [uint32]::MaxValue }).Count
    $zero = ($vals | Where-Object { $_ -eq 0 }).Count
    $other = $total - $free - $zero
    ('map stats: free(0xFFFFFFFF)={0} zero={1} other={2}' -f $free, $zero, $other) | Write-Output
    'first 48 entries:' | Write-Output
    for ($i = 0; $i -lt [Math]::Min(48, $total); $i++) {
        ('[{0}] 0x{1:X8} ({2})' -f $i, $vals[$i], $vals[$i]) | Write-Output
    }
    $nonFree = @()
    for ($i = 0; $i -lt $total; $i++) { if ($vals[$i] -ne [uint32]::MaxValue) { $nonFree += $i } }
    'non-free count: ' + $nonFree.Count | Write-Output
    'first non-free indices: ' + (($nonFree | Select-Object -First 20) -join ',') | Write-Output
    if ($nonFree.Count -gt 0) {
        $min = ($nonFree | ForEach-Object { $vals[$_] } | Measure-Object -Minimum).Minimum
        $max = ($nonFree | ForEach-Object { $vals[$_] } | Measure-Object -Maximum).Maximum
        ('non-free map value min={0} max={1}' -f $min, $max) | Write-Output
    }
    '--- data at offData 2MB, first 64 bytes ---' | Write-Output
    $fs.Seek($offData, [IO.SeekOrigin]::Begin) | Out-Null
    $db = New-Object byte[] 64
    $null = $fs.Read($db, 0, 64)
    (($db | ForEach-Object { '{0:X2}' -f $_ }) -join ' ') | Write-Output
    '--- data at offData+1MB, first 64 bytes ---' | Write-Output
    $fs.Seek([int64]$offData + $bs, [IO.SeekOrigin]::Begin) | Out-Null
    $null = $fs.Read($db, 0, 64)
    (($db | ForEach-Object { '{0:X2}' -f $_ }) -join ' ') | Write-Output
} finally { $fs.Close() }

# compare merged.raw and base.raw hashes of first blocks
$sha = [Security.Cryptography.SHA256]::Create()
function HashRange($path, $off, $len) {
    $f = [IO.File]::OpenRead($path)
    try {
        $f.Seek($off, [IO.SeekOrigin]::Begin) | Out-Null
        $b = New-Object byte[] $len
        $null = $f.Read($b, 0, $len)
        $hash = $sha.ComputeHash($b)
        return ([BitConverter]::ToString($hash)).Replace('-', '').ToLower()
    } finally { $f.Close() }
}
'base.raw block0: ' + (HashRange (Join-Path $d 'base.raw') 0 1048576) | Write-Output
'merged.raw block0: ' + (HashRange (Join-Path $d 'merged.raw') 0 1048576) | Write-Output
'base.raw block38: ' + (HashRange (Join-Path $d 'base.raw') (38 * 1048576) 1048576) | Write-Output
'merged.raw block38: ' + (HashRange (Join-Path $d 'merged.raw') (38 * 1048576) 1048576) | Write-Output
