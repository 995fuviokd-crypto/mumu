$ErrorActionPreference = 'Continue'
$so = 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so'
$b = [IO.File]::ReadAllBytes($so)
function ReadCStr([int]$off) {
    $e = $off; while ($e -lt $b.Length -and $b[$e] -ne 0) { $e++ }
    return [Text.Encoding]::ASCII.GetString($b, $off, $e - $off)
}
# section headers
$shoff = [int][BitConverter]::ToUInt64($b, 0x28)
$shentsize = [int][BitConverter]::ToUInt16($b, 0x3A)
$shnum = [int][BitConverter]::ToUInt16($b, 0x3C)
$shstrndx = [int][BitConverter]::ToUInt16($b, 0x3E)
$strOff = [int][BitConverter]::ToUInt64($b, $shoff + $shstrndx * $shentsize + 0x18)
$secs = @{}
for ($i = 0; $i -lt $shnum; $i++) {
    $o = $shoff + $i * $shentsize
    $name = ReadCStr ($strOff + [int][BitConverter]::ToUInt32($b, $o))
    $secs[$name] = [pscustomobject]@{
        Off = [int][BitConverter]::ToUInt64($b, $o + 0x18)
        Size = [int][BitConverter]::ToUInt64($b, $o + 0x20)
        Link = [int][BitConverter]::ToUInt32($b, $o + 0x28)
        Info = [int][BitConverter]::ToUInt32($b, $o + 0x2C)
        EntSize = [int][BitConverter]::ToUInt64($b, $o + 0x38)
    }
}
$dyn = $secs['.dynsym']; $dstr = $secs['.dynstr']
'--- dynamic symbols ---'
$imports = @(); $exports = @()
for ($i = 0; $i -lt [int]($dyn.Size / 24); $i++) {
    $o = $dyn.Off + $i * 24
    $nameOff = [BitConverter]::ToUInt32($b, $o)
    if ($nameOff -eq 0) { continue }
    $info = $b[$o + 4]
    $shndx = [BitConverter]::ToUInt16($b, $o + 6)
    $name = ReadCStr ($dstr.Off + $nameOff)
    if ($shndx -eq 0) { $imports += $name } else { $exports += $name }
}
'IMPORTS (' + $imports.Count + '):'
($imports | Sort-Object -Unique) -join ', '
''
'EXPORTS (' + $exports.Count + '):'
($exports | Sort-Object -Unique) -join ', '
