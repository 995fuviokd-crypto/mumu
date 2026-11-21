$ErrorActionPreference = 'Continue'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
$f = '/data/anr/anr_2026-11-21-16-03-48-942'
$txt = RunSh ('cat ' + $f)
$lines = $txt -split "`n"
'lines: ' + $lines.Count
'--- process headers ---'
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^----- pid ') { $lines[$i] }
}
'--- app block main thread ---'
$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'Cmd line: io\.github\.vvb2060\.mahoshojo$') { $start = $i; break }
}
'block start: ' + $start
if ($start -ge 0) {
    $mt = -1
    for ($i = $start; $i -lt [Math]::Min($start + 400, $lines.Count); $i++) {
        if ($lines[$i] -match '^"main"') { $mt = $i; break }
        if ($lines[$i] -match '^----- pid ') { break }
    }
    'main at ' + $mt
    if ($mt -ge 0) { $lines[$mt..([Math]::Min($mt+40,$lines.Count-1))] | Out-String }
    '--- native threads holding locks / DefaultDispatcher ---'
    for ($i = $start; $i -lt [Math]::Min($start + 500, $lines.Count); $i++) {
        if ($lines[$i] -match 'DefaultDispatch|Native|state=') { }
    }
}
