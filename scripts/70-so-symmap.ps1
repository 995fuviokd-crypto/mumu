$ErrorActionPreference = 'Continue'
$so = 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so'
$b = [IO.File]::ReadAllBytes($so)
function ReadCStr([int]$off) {
    $e = $off; while ($e -lt $b.Length -and $b[$e] -ne 0) { $e++ }
    return [Text.Encoding]::ASCII.GetString($b, $off, $e - $off)
}
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
    }
}
$dyn = $secs['.dynsym']; $dstr = $secs['.dynstr']
$syms = @()
for ($i = 0; $i -lt [int]($dyn.Size / 24); $i++) {
    $o = $dyn.Off + $i * 24
    $nameOff = [BitConverter]::ToUInt32($b, $o)
    if ($nameOff -eq 0) { continue }
    $value = [BitConverter]::ToUInt64($b, $o + 8)
    $size = [BitConverter]::ToUInt64($b, $o + 16)
    $shndx = [BitConverter]::ToUInt16($b, $o + 6)
    if ($shndx -eq 0 -or $value -eq 0) { continue }
    $name = ReadCStr ($dstr.Off + $nameOff)
    $syms += [pscustomobject]@{ Name=$name; Addr=$value; Size=$size }
}
'--- exported functions sorted by addr (first 20 / last 10) ---'
$s = $syms | Sort-Object Addr
$s | Select-Object -First 12 | ForEach-Object { ('0x{0:X} size=0x{1:X} {2}' -f $_.Addr,$_.Size,$_.Name) }
'...'
$s | Select-Object -Last 8 | ForEach-Object { ('0x{0:X} size=0x{1:X} {2}' -f $_.Addr,$_.Size,$_.Name) }
'--- locate addresses ---'
foreach ($target in @(0x19EB9, 0x1BDD3, 0x1BFB2, 0x1C480, 0x21E30)) {
    $f = $s | Where-Object { $_.Addr -le $target -and ($_.Addr + [Math]::Max([int]$_.Size,1)) -gt $target } | Select-Object -First 1
    if ($f) {
        ('0x{0:X} is inside 0x{1:X} (size 0x{2:X}) {3} +0x{4:X}' -f $target,$f.Addr,$f.Size,$f.Name,($target-$f.Addr))
    } else {
        # find nearest symbol <= target
        $n = $s | Where-Object { $_.Addr -le $target } | Sort-Object Addr | Select-Object -Last 1
        if ($n) { ('0x{0:X} nearest 0x{1:X} {2} +0x{3:X} (size 0x{4:X})' -f $target,$n.Addr,$n.Name,($target-$n.Addr),$n.Size) } else { ('0x{0:X} no symbol' -f $target) }
    }
}
'--- JNI_OnLoad ---'
($syms | Where-Object { $_.Name -eq 'JNI_OnLoad' } | ForEach-Object { ('0x{0:X} size=0x{1:X}' -f $_.Addr,$_.Size) }) | Out-String
