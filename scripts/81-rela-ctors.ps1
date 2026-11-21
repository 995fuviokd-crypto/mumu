$ErrorActionPreference = 'Continue'
$so = 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so'
$b = [IO.File]::ReadAllBytes($so)
$relaOff = 0x2D00; $relaSize = 0x12A8
$iaStart = 0x23178; $iaEnd = 0x23178 + 0x578
$ctors = @()
for ($o = $relaOff; $o -lt $relaOff + $relaSize; $o += 24) {
    $r_offset = [BitConverter]::ToUInt64($b, $o)
    $r_info = [BitConverter]::ToUInt64($b, $o + 8)
    $r_addend = [BitConverter]::ToInt64($b, $o + 16)
    $type = $r_info -band 0xffffffff
    if ($r_offset -ge $iaStart -and $r_offset -lt $iaEnd) {
        $ctors += [pscustomobject]@{ Offset=$r_offset; Type=$type; Addend=([uint64]$r_addend) }
    }
}
'ctor relocations: ' + $ctors.Count
$ctors | Select-Object -First 40 | ForEach-Object { '  slot=0x{0:X} type={1} -> 0x{2:X}' -f $_.Offset, $_.Type, $_.Addend } | Out-String
'--- min/max/summary in core region ---'
$core = @($ctors | Where-Object { $_.Addend -ge 0x16600 -and $_.Addend -le 0x21CA0 })
'core ctors: ' + $core.Count
$core | Sort-Object Addend | Select-Object -First 20 | ForEach-Object { '  0x{0:X}' -f $_.Addend } | Out-String
'--- all unique ctor addends (sorted) ---'
($ctors | ForEach-Object { $_.Addend } | Sort-Object -Unique | Select-Object -First 60 | ForEach-Object { '  0x{0:X}' -f $_ }) | Out-String
