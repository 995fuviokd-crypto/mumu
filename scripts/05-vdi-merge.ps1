$ErrorActionPreference = 'Stop'
$d = 'D:\MuMuWork\image-edit'

function ReadVdiHeader([string]$path) {
    $fs = [IO.File]::OpenRead($path)
    try {
        $b = New-Object byte[] 512
        $null = $fs.Read($b, 0, 512)
        $h = [ordered]@{}
        $h.Path = $path
        $h.Signature = '{0:X8}' -f [BitConverter]::ToUInt32($b, 0x40)
        $h.Version = '{0:X8}' -f [BitConverter]::ToUInt32($b, 0x44)
        $h.HeaderSize = [BitConverter]::ToUInt32($b, 0x48)
        $h.ImageType = [BitConverter]::ToUInt32($b, 0x4C)
        $h.Flags = '0x{0:X8}' -f [BitConverter]::ToUInt32($b, 0x50)
        $h.OffsetBlocks = [BitConverter]::ToUInt32($b, 0x154)
        $h.OffsetData = [BitConverter]::ToUInt32($b, 0x158)
        $h.Cylinders = [BitConverter]::ToUInt32($b, 0x15C)
        $h.Heads = [BitConverter]::ToUInt32($b, 0x160)
        $h.Sectors = [BitConverter]::ToUInt32($b, 0x164)
        $h.SectorSize = [BitConverter]::ToUInt32($b, 0x168)
        $h.DiskSize = [BitConverter]::ToUInt64($b, 0x170)
        $h.BlockSize = [BitConverter]::ToUInt32($b, 0x178)
        $h.BlockExtra = [BitConverter]::ToUInt32($b, 0x17C)
        $h.BlocksTotal = [BitConverter]::ToUInt32($b, 0x180)
        $h.BlocksAllocated = [BitConverter]::ToUInt32($b, 0x184)
        $h.Uuid = ([Guid]::new([byte[]]$b[0x188..0x197])).ToString()
        $h.ParentUuid = ([Guid]::new([byte[]]$b[0x198..0x1A7])).ToString()
        return [pscustomobject]$h
    } finally { $fs.Close() }
}

$baseH = ReadVdiHeader (Join-Path $d 'base.vdi')
$diffH = ReadVdiHeader (Join-Path $d 'diff.vdi')
'=== base header ===' | Write-Output
$baseH | Format-List | Out-String | Write-Output
'=== diff header ===' | Write-Output
$diffH | Format-List | Out-String | Write-Output

if ($baseH.BlockSize -ne $diffH.BlockSize) { throw 'block size mismatch' }
if ($baseH.BlockExtra -ne 0 -or $diffH.BlockExtra -ne 0) { throw 'block extra data not supported' }
if ($baseH.BlocksTotal -ne $diffH.BlocksTotal) { throw 'block count mismatch' }

$baseRaw = Join-Path $d 'base.raw'
$mergedRaw = Join-Path $d 'merged.raw'
if (-not (Test-Path $mergedRaw)) {
    'copy base.raw -> merged.raw' | Write-Output
    Copy-Item $baseRaw $mergedRaw
}

$bs = [int]$diffH.BlockSize
$diff = [IO.File]::OpenRead((Join-Path $d 'diff.vdi'))
$out = [IO.File]::Open($mergedRaw, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    $diff.Seek([int64]$diffH.OffsetBlocks, [IO.SeekOrigin]::Begin) | Out-Null
    $mapBytes = New-Object byte[] ([int]$diffH.BlocksTotal * 4)
    $read = 0
    while ($read -lt $mapBytes.Length) {
        $n = $diff.Read($mapBytes, $read, $mapBytes.Length - $read)
        if ($n -le 0) { break }
        $read += $n
    }
    $allocated = 0
    $buf = New-Object byte[] $bs
    for ($i = 0; $i -lt $diffH.BlocksTotal; $i++) {
        $idx = [BitConverter]::ToUInt32($mapBytes, $i * 4)
        if ($idx -eq 0xFFFFFFFF) { continue }
        $srcOff = [int64]$diffH.OffsetData + ([int64]$idx * $bs)
        $diff.Seek($srcOff, [IO.SeekOrigin]::Begin) | Out-Null
        $got = 0
        while ($got -lt $bs) {
            $n = $diff.Read($buf, $got, $bs - $got)
            if ($n -le 0) { break }
            $got += $n
        }
        $out.Seek([int64]$i * $bs, [IO.SeekOrigin]::Begin) | Out-Null
        $out.Write($buf, 0, $got)
        $allocated++
    }
    $out.Flush()
    ('merged {0} allocated blocks ({1} MB) of {2}' -f $allocated, [math]::Round($allocated * $bs / 1MB, 1), $diffH.BlocksTotal) | Write-Output
} finally {
    $diff.Close(); $out.Close()
}

'=== merged ext4 partitions ===' | Write-Output
$fs = [IO.File]::OpenRead($mergedRaw)
try {
    $parts = @(
        @{Name='p2'; Lba=34304},
        @{Name='logical1-root'; Lba=79068},
        @{Name='logical2-vendor'; Lba=3505653},
        @{Name='logical3'; Lba=3784798}
    )
    foreach ($p in $parts) {
        $fs.Seek([int64]$p.Lba * 512 + 1024, [IO.SeekOrigin]::Begin) | Out-Null
        $sb = New-Object byte[] 1024
        $null = $fs.Read($sb, 0, 1024)
        $magic = '{0:X4}' -f [BitConverter]::ToUInt16($sb, 0x38)
        $vol = [Text.Encoding]::UTF8.GetString($sb, 0x78, 16).Trim([char]0)
        $last = [Text.Encoding]::UTF8.GetString($sb, 0x88, 64).Trim([char]0)
        ('{0}: magic={1} vol="{2}" last="{3}"' -f $p.Name, $magic, $vol, $last) | Write-Output
    }
} finally { $fs.Close() }
