$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$raw = Join-Path $d 'base.raw'
$fs = [IO.File]::OpenRead($raw)
$diskSectors = [int64]([IO.FileInfo]$raw).Length / 512

function Read-At([int64]$offset, [int]$len) {
    $fs.Seek($offset, [IO.SeekOrigin]::Begin) | Out-Null
    $b = New-Object byte[] $len
    $n = $fs.Read($b, 0, $len)
    if ($n -lt $len) { $b = $b[0..($n-1)] }
    return ,$b
}
function Probe([int64]$lba, [int64]$sectors, [string]$label) {
    $off = $lba * 512
    $b = Read-At $off 4096
    $ext4 = ('{0:X4}' -f [BitConverter]::ToUInt16($b, 0x438))
    $fat = [Text.Encoding]::ASCII.GetString($b, 54, 8)
    $boot = [Text.Encoding]::ASCII.GetString($b, 0, 8)
    $gz = ('{0:X2}{1:X2}' -f $b[0], $b[1])
    $erofs = ('{0:X8}' -f [BitConverter]::ToUInt32($b, 1024))
    $f2fs = ('{0:X8}' -f [BitConverter]::ToUInt32($b, 1024))
    $luks = [Text.Encoding]::ASCII.GetString($b, 0, 4)
    $sq = [Text.Encoding]::ASCII.GetString($b, 0, 4)
    ('{0}: lba={1} sectors={2} off={3} ext4magic@438={4} boot8={5} fat={6} gz={7} erofs@400={8} f2fs@400={9} luks={10} sq={11}' -f $label, $lba, $sectors, $off, $ext4, $boot, $fat, $gz, $erofs, $f2fs, $luks, $sq) | Write-Output
}

'disk sectors: ' + $diskSectors | Write-Output
$mbr = Read-At 0 512
$prim = @()
for ($p = 0; $p -lt 4; $p++) {
    $o = 446 + $p * 16
    $type = $mbr[$o + 4]
    $lba = [BitConverter]::ToUInt32($mbr, $o + 8)
    $cnt = [BitConverter]::ToUInt32($mbr, $o + 12)
    if ($type -eq 0) { continue }
    $prim += [pscustomobject]@{ Index = $p; Type = $type; LBA = [int64]$lba; Sectors = [int64]$cnt }
    ('primary{0}: type={1:X2} lba={2} sectors={3} end={4}' -f $p, $type, $lba, $cnt, ([int64]$lba + [int64]$cnt)) | Write-Output
}
foreach ($p in $prim) { Probe $p.LBA $p.Sectors ('p' + $p.Index) }

# extended partition chain
$ext = $prim | Where-Object { $_.Type -eq 5 -or $_.Type -eq 0x0F } | Select-Object -First 1
if ($ext) {
    '--- EBR chain ---' | Write-Output
    $baseLba = $ext.LBA
    $ebrLba = $baseLba
    $idx = 0
    $seen = @{}
    while ($ebrLba -gt 0 -and $ebrLba -lt $diskSectors -and -not $seen.ContainsKey($ebrLba) -and $idx -lt 32) {
        $seen[$ebrLba] = $true
        $ebr = Read-At ($ebrLba * 512) 512
        if ($ebr[510] -ne 0x55 -or $ebr[511] -ne 0xAA) { 'EBR sig invalid at ' + $ebrLba | Write-Output; break }
        $type = $ebr[446 + 4]
        $lba = [BitConverter]::ToUInt32($ebr, 446 + 8)
        $cnt = [BitConverter]::ToUInt32($ebr, 446 + 12)
        if ($type -ne 0) {
            $abs = $ebrLba + [int64]$lba
            ('logical{0}: type={1:X2} ebr={2} lba={3} sectors={4} abs={5}' -f $idx, $type, $ebrLba, $lba, $cnt, $abs) | Write-Output
            Probe $abs ([int64]$cnt) ('logical' + $idx)
            $idx++
        }
        $nextType = $ebr[462 + 4]
        $nextLba = [BitConverter]::ToUInt32($ebr, 462 + 8)
        if ($nextType -eq 0 -or $nextLba -eq 0) { break }
        $ebrLba = $baseLba + [int64]$nextLba
    }
}
$fs.Close()
