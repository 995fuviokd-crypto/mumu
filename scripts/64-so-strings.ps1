$ErrorActionPreference = 'Continue'
$so = 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so'
$b = [IO.File]::ReadAllBytes($so)
$s = [Text.Encoding]::ASCII.GetString($b)
'all strings count: ' + ([regex]::Matches($s,'[ -~]{4,}').Count)
'--- suspicious paths / keywords ---'
$pat = 'DefaultDispatch|/proc|/sys|/dev|sensor|Sensor|qemu|vbox|mumu|nemu|goldfish|houdini|pipe|ptrace|hook|frida|xposed|magisk|ksu|kernelsu|su\b|ro\.|boot_id|maps|status|cmdline|init\.rc|property'
$m = [regex]::Matches($s,'[ -~]{4,}') | ForEach-Object { $_.Value } | Where-Object { $_ -match $pat } | Select-Object -Unique
$m | Select-Object -First 200 | Out-String
'--- JNI symbols ---'
[regex]::Matches($s,'Java_[A-Za-z0-9_]+') | ForEach-Object { $_.Value } | Select-Object -Unique | Select-Object -First 60 | Out-String
'--- ELF header / sections ---'
$e_shoff = [BitConverter]::ToUInt64($b, 0x28)
$e_shentsize = [BitConverter]::ToUInt16($b, 0x3A)
$e_shnum = [BitConverter]::ToUInt16($b, 0x3C)
$e_shstrndx = [BitConverter]::ToUInt16($b, 0x3E)
'shoff=' + $e_shoff + ' entsize=' + $e_shentsize + ' num=' + $e_shnum
$strOff = [BitConverter]::ToUInt64($b, [int]($e_shoff + $e_shstrndx * $e_shentsize + 0x18))
for ($i = 0; $i -lt $e_shnum; $i++) {
    $o = [int]($e_shoff + $i * $e_shentsize)
    $nameOff = [BitConverter]::ToUInt32($b, $o)
    $type = [BitConverter]::ToUInt32($b, $o + 4)
    $addr = [BitConverter]::ToUInt64($b, $o + 0x10)
    $off = [BitConverter]::ToUInt64($b, $o + 0x18)
    $size = [BitConverter]::ToUInt64($b, $o + 0x20)
    $nEnd = [int]($strOff + $nameOff)
    $nEnd2 = $nEnd; while ($b[$nEnd2] -ne 0) { $nEnd2++ }
    $name = [Text.Encoding]::ASCII.GetString($b, $nEnd, $nEnd2 - $nEnd)
    if ($name -and $size -gt 0) { ('{0} type={1} addr=0x{2:X} off=0x{3:X} size=0x{4:X}' -f $name,$type,$addr,$off,$size) }
}
