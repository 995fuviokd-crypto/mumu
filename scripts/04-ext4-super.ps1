$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$raw = Join-Path $d 'base.raw'
$fs = [IO.File]::OpenRead($raw)
function ReadAt([int64]$off, [int]$len) {
    $fs.Seek($off, [IO.SeekOrigin]::Begin) | Out-Null
    $b = New-Object byte[] $len
    $null = $fs.Read($b, 0, $len)
    return ,$b
}
$parts = @(
    @{Name='p2'; Lba=34304; Sectors=28634},
    @{Name='logical1'; Lba=79068; Sectors=3426584},
    @{Name='logical2'; Lba=3505653; Sectors=279144},
    @{Name='logical3'; Lba=3784798; Sectors=1048576}
)
foreach ($p in $parts) {
    $po = [int64]$p.Lba * 512
    $sb = ReadAt ($po + 1024) 1024
    $magic = '{0:X4}' -f [BitConverter]::ToUInt16($sb, 0x38)
    $vol = [Text.Encoding]::UTF8.GetString($sb, 0x78, 16).Trim([char]0)
    $last = [Text.Encoding]::UTF8.GetString($sb, 0x88, 64).Trim([char]0)
    $uuid = ([Guid]::new([byte[]]$sb[0x68..0x77])).ToString()
    $blocksLo = [BitConverter]::ToUInt32($sb, 0x4)
    $logBlock = [BitConverter]::ToUInt32($sb, 0x18)
    $incompat = [BitConverter]::ToUInt32($sb, 0x60)
    $compat = [BitConverter]::ToUInt32($sb, 0x5C)
    $ro = [BitConverter]::ToUInt32($sb, 0x64)
    $blockSize = 1024 -shl $logBlock
    $sizeBytes = [int64]$blocksLo * $blockSize
    ('{0}: off={1} size={2}MB magic={3} vol="{4}" last="{5}" uuid={6} blocks={7} bs={8} incompat=0x{9:X}' -f $p.Name, $po, ([math]::Round($p.Sectors*512/1MB,1)), $magic, $vol, $last, $uuid, $blocksLo, $blockSize, $incompat) | Write-Output
}
$fs.Close()
