$ErrorActionPreference = 'Continue'
$so = 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so'
$b = [IO.File]::ReadAllBytes($so)
# .init_array file off 0x22178 size 0x578
$iaOff = 0x22178; $iaSize = 0x578
$ctors = @()
for ($i = 0; $i -lt [int]($iaSize/8); $i++) {
    $v = [BitConverter]::ToUInt64($b, $iaOff + $i*8)
    if ($v -ne 0) { $ctors += $v }
}
'init_array entries: ' + $ctors.Count
$ctors | Select-Object -First 30 | ForEach-Object { '  0x{0:X}' -f $_ } | Out-String
'--- ctors in 0x16600-0x21CA0 (core region) ---'
$core = @($ctors | Where-Object { $_ -ge 0x16600 -and $_ -le 0x21CA0 })
'count: ' + $core.Count
$core | ForEach-Object { '  0x{0:X}' -f $_ } | Out-String
'--- scan calls (E8 rel32) targeting 0x19C00..0x19E30 ---'
$textOff = 0x5770; $textSize = 0x1C530
$targets = @{}
for ($o = $textOff; $o -lt $textOff + $textSize - 5; $o++) {
    if ($b[$o] -eq 0xE8) {
        $rel = [BitConverter]::ToInt32($b, $o + 1)
        $tgt = [int64]($o - $textOff + 0x5770) + 5 + $rel
        if ($tgt -ge 0x19C00 -and $tgt -le 0x19E30) {
            if (-not $targets.ContainsKey($tgt)) { $targets[$tgt] = 0 }
            $targets[$tgt]++
        }
    }
}
$targets.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object { '  0x{0:X} called {1}x' -f $_.Key, $_.Value } | Out-String
'--- calls to 0x16670 exactly ---'
$cnt = 0
for ($o = $textOff; $o -lt $textOff + $textSize - 5; $o++) {
    if ($b[$o] -eq 0xE8) {
        $rel = [BitConverter]::ToInt32($b, $o + 1)
        $tgt = [int64]($o - $textOff + 0x5770) + 5 + $rel
        if ($tgt -eq 0x16670) { $cnt++ }
    }
}
'0x16670 calls: ' + $cnt
