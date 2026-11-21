$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$raw = Join-Path $d 'base.raw'
$fs = [IO.File]::OpenRead($raw)
try {
    $buf = New-Object byte[] 4096
    $fs.Read($buf, 0, $buf.Length) | Out-Null
    function HexDump($bytes, $offset, $len) {
        for ($i = 0; $i -lt $len; $i += 16) {
            $line = ('{0:X8}  ' -f ($offset + $i))
            for ($j = 0; $j -lt 16; $j++) { $line += ('{0:X2} ' -f $bytes[$i + $j]) }
            $line += ' |'
            for ($j = 0; $j -lt 16; $j++) { $c = $bytes[$i + $j]; if ($c -ge 32 -and $c -lt 127) { $line += [char]$c } else { $line += '.' } }
            $line += '|'
            Write-Output $line
        }
    }
    HexDump $buf 0 256
    '--- offset 0x400..0x500 ---'
    HexDump ($buf[0x400..0x500]) 0x400 256
    'ext4 magic at 0x438: ' + ('{0:X4}' -f [BitConverter]::ToUInt16($buf, 0x438))
    'iso9660 magic at 0x8001: (need seek)'
    $fs.Seek(0x8001, [IO.SeekOrigin]::Begin) | Out-Null
    $b2 = New-Object byte[] 5
    $fs.Read($b2, 0, 5) | Out-Null
    'iso9660: ' + [Text.Encoding]::ASCII.GetString($b2)
    '--- search first 32MB for EFI PART / ext4 superblock ---'
    $fs.Seek(0, [IO.SeekOrigin]::Begin) | Out-Null
    $chunk = New-Object byte[] (16 * 1024 * 1024)
    $read = $fs.Read($chunk, 0, $chunk.Length)
    $efi = -1
    for ($i = 0; $i -le $read - 8; $i++) { if ($chunk[$i] -eq 0x45 -and $chunk[$i+1] -eq 0x46 -and $chunk[$i+2] -eq 0x49 -and $chunk[$i+3] -eq 0x20 -and $chunk[$i+4] -eq 0x50 -and $chunk[$i+5] -eq 0x41 -and $chunk[$i+6] -eq 0x52 -and $chunk[$i+7] -eq 0x54) { $efi = $i; break } }
    'EFI PART offset in first 16MB: ' + $efi
    $ext = -1
    for ($i = 0x438; $i -le $read - 2; $i += 1024) { if ($chunk[$i] -eq 0x53 -and $chunk[$i+1] -eq 0xEF) { $ext = $i; break } }
    'ext4 magic offset (1KB stride from 0x438): ' + $ext
    '--- MBR partition table ---'
    for ($p = 0; $p -lt 4; $p++) {
        $o = 446 + $p * 16
        $status = $buf[$o]
        $type = $buf[$o + 4]
        $lba = [BitConverter]::ToUInt32($buf, $o + 8)
        $cnt = [BitConverter]::ToUInt32($buf, $o + 12)
        if ($type -ne 0) { ('part{0} status={1:X2} type={2:X2} lba={3} sectors={4}' -f $p, $status, $type, $lba, $cnt) | Write-Output }
    }
    'MBR boot sig: ' + ('{0:X2}{1:X2}' -f $buf[510], $buf[511])
} finally { $fs.Close() }
