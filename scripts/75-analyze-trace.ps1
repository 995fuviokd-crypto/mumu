$ErrorActionPreference = 'Continue'
$tr = 'D:\MuMuWork\momo\momo.trace'
$lines = Get-Content $tr
'lines: ' + $lines.Count
'--- signals / crash marker ---'
$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'SIGSEGV|killed by|+++ killed|exited with') { $script:idx = $i }
}
'last signal line index: ' + $idx
if ($idx -gt 0) { $lines[($idx-40)..$idx] | Out-String }
'--- failing syscalls (last 120) ---'
$fails = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '= -1 ') { $fails += $lines[$i] }
}
'fail count: ' + $fails.Count
$fails | Select-Object -Last 120 | Out-String
'--- mmap/mprotect/openat key calls (last 80) ---'
$key = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'mmap\(|mprotect\(|memfd_create|openat\(.*(cpuinfo|dmi|maps|status|enforce|properties|build\.prop)') { $key += $lines[$i] }
}
$key | Select-Object -Last 80 | Out-String
