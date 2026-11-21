$ErrorActionPreference = 'Stop'
function Get-Imports([string]$path) {
    $b = [IO.File]::ReadAllBytes($path)
    if ($b.Length -lt 64) { return @() }
    $pe = [BitConverter]::ToInt32($b, 0x3C)
    if ($pe -le 0 -or $pe -ge $b.Length - 24) { return @() }
    $numSections = [BitConverter]::ToUInt16($b, $pe + 6)
    $sizeOpt = [BitConverter]::ToUInt16($b, $pe + 20)
    $opt = $pe + 24
    $magic = [BitConverter]::ToUInt16($b, $opt)
    $is64 = ($magic -eq 0x20B)
    $dd = $opt + $(if ($is64) { 0x70 } else { 0x60 })
    $importRva = [BitConverter]::ToUInt32($b, $dd + 8)
    if ($importRva -eq 0) { return @() }
    $sec = $opt + $sizeOpt
    $sections = @()
    for ($i = 0; $i -lt $numSections; $i++) {
        $o = $sec + $i * 40
        $va = [BitConverter]::ToUInt32($b, $o + 12)
        $rawSize = [BitConverter]::ToUInt32($b, $o + 16)
        $rawPtr = [BitConverter]::ToUInt32($b, $o + 20)
        $sections += [pscustomobject]@{ VA=$va; RawSize=$rawSize; RawPtr=$rawPtr }
    }
    $off = $null
    foreach ($s in $sections) {
        if ($importRva -ge $s.VA -and $importRva -lt ($s.VA + $s.RawSize)) { $off = $importRva - $s.VA + $s.RawPtr; break }
    }
    if ($null -eq $off) { return @() }
    $imports = @()
    for ($i = 0; $i -lt 64; $i++) {
        $o = $off + $i * 20
        if ($o + 20 -gt $b.Length) { break }
        $nameRva = [BitConverter]::ToUInt32($b, $o + 12)
        if ($nameRva -eq 0) { break }
        $no = $null
        foreach ($s in $sections) {
            if ($nameRva -ge $s.VA -and $nameRva -lt ($s.VA + $s.RawSize)) { $no = $nameRva - $s.VA + $s.RawPtr; break }
        }
        if ($null -eq $no) { break }
        $end = $no
        while ($end -lt $b.Length -and $b[$end] -ne 0) { $end++ }
        if ($end -gt $no) { $imports += [Text.Encoding]::ASCII.GetString($b, $no, $end - $no) }
    }
    return $imports
}

$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$searchDirs = @()
$searchDirs += Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$searchDirs += 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin'
$searchDirs += 'C:\Windows\System32'
$allDlls = Get-ChildItem $root -Recurse -Filter '*.dll' | Select-Object -ExpandProperty FullName
$allDlls += 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'

function Find-Dll([string]$name) {
    foreach ($d in $searchDirs) {
        $p = Join-Path $d $name
        if (Test-Path $p) { return $p }
    }
    return $null
}

$queue = New-Object System.Collections.Queue
$queue.Enqueue('D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe')
$seen = @{}
$missing = @{}
while ($queue.Count -gt 0) {
    $p = $queue.Dequeue()
    if ($seen.ContainsKey($p)) { continue }
    $seen[$p] = $true
    $imports = Get-Imports $p
    if ($imports.Count -gt 0) {
        (Split-Path $p -Leaf) + ' imports: ' + ($imports -join ', ') | Write-Output
    }
    foreach ($imp in $imports) {
        $found = Find-Dll $imp
        if ($found) {
            if (-not $seen.ContainsKey($found)) { $queue.Enqueue($found) }
        } else {
            if (-not $missing.ContainsKey($imp)) { $missing[$imp] = @() }
            $missing[$imp] += (Split-Path $p -Leaf)
        }
    }
}
'--- missing ---'
foreach ($k in $missing.Keys) { $k + ' needed by ' + ($missing[$k] -join ', ') }
