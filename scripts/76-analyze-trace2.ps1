$ErrorActionPreference = 'Continue'
$tr = 'D:\MuMuWork\momo\momo.trace'
$lines = Get-Content $tr
'lines: ' + $lines.Count
$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'SIGSEGV|killed by|\+\+\+ killed') { $idx = $i }
}
'last signal line index: ' + $idx
if ($idx -gt 0) {
    '--- context before signal ---'
    $lines[[Math]::Max(0,$idx-45)..$idx] | Out-String
}
'--- failing syscalls summary by name (counts) ---'
$fails = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '= -1 ') { $fails += $lines[$i] }
}
'fail count: ' + $fails.Count
$fails | ForEach-Object { if ($_ -match '^\s*(\w+)\(') { $matches[1] } } | Group-Object | Sort-Object Count -Descending | Select-Object -First 15 Count,Name | Format-Table -AutoSize | Out-String
'--- last 60 failures ---'
$fails | Select-Object -Last 60 | Out-String
'--- last 40 mmap/mprotect/memfd ---'
$key = @()
foreach ($l in $lines) { if ($l -match 'mmap\(|mprotect\(|memfd_create') { $key += $l } }
$key | Select-Object -Last 40 | Out-String
