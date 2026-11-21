$ErrorActionPreference = 'Stop'
function Get-PeInfo([string]$path) {
    $b = [IO.File]::ReadAllBytes($path)
    $pe = [BitConverter]::ToInt32($b, 0x3C)
    $machine = [BitConverter]::ToUInt16($b, $pe + 4)
    $numSections = [BitConverter]::ToUInt16($b, $pe + 6)
    $sizeOpt = [BitConverter]::ToUInt16($b, $pe + 20)
    $opt = $pe + 24
    $magic = [BitConverter]::ToUInt16($b, $opt)
    $is64 = ($magic -eq 0x20B)
    $dd = $opt + $(if ($is64) { 0x70 } else { 0x60 })
    $importRva = [BitConverter]::ToUInt32($b, $dd + 8)
    $importSize = [BitConverter]::ToUInt32($b, $dd + 12)
    $sec = $opt + $sizeOpt
    $sections = @()
    for ($i = 0; $i -lt $numSections; $i++) {
        $o = $sec + $i * 40
        $name = [Text.Encoding]::ASCII.GetString($b, $o, 8).Trim([char]0)
        $va = [BitConverter]::ToUInt32($b, $o + 12)
        $rawSize = [BitConverter]::ToUInt32($b, $o + 16)
        $rawPtr = [BitConverter]::ToUInt32($b, $o + 20)
        $sections += [pscustomobject]@{ Name=$name; VA=$va; RawSize=$rawSize; RawPtr=$rawPtr }
    }
    function RvaToOff($rva) {
        foreach ($s in $sections) {
            if ($rva -ge $s.VA -and $rva -lt ($s.VA + $s.RawSize)) { return ($rva - $s.VA + $s.RawPtr) }
        }
        return $null
    }
    $imports = @()
    $off = RvaToOff $importRva
    if ($null -ne $off) {
        for ($i = 0; $i -lt 64; $i++) {
            $o = $off + $i * 20
            $nameRva = [BitConverter]::ToUInt32($b, $o + 12)
            if ($nameRva -eq 0) { break }
            $no = RvaToOff $nameRva
            if ($null -eq $no) { break }
            $end = $no
            while ($b[$end] -ne 0) { $end++ }
            $imports += [Text.Encoding]::ASCII.GetString($b, $no, $end - $no)
        }
    }
    return [pscustomobject]@{
        Path = $path
        Machine = ('0x{0:X4}' -f $machine)
        Magic = ('0x{0:X4}' -f $magic)
        Is64 = $is64
        ImportRva = $importRva
        ImportSize = $importSize
        Imports = ($imports -join ', ')
    }
}
$files = @(
    'D:\MuMuWork\image-edit\tools\e2fsprogs142\usr\sbin\debugfs.exe',
    'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe',
    'D:\MuMuWork\ColorOSLab\sdk\emulator\bin64\cygwin1.dll',
    'D:\MuMuWork\ColorOSLab\sdk\emulator\bin64\cygext2fs-2.dll',
    'D:\MuMuWork\image-edit\tools\libss2\usr\bin\cygss-2.dll',
    'D:\MuMuWork\ColorOSLab\sdk\emulator\bin64\cygcom_err-2.dll'
)
foreach ($f in $files) {
    if (Test-Path $f) { Get-PeInfo $f | Format-List | Out-String | Write-Output }
}
