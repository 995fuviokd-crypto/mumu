$ErrorActionPreference = 'Continue'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
'--- anr files ---'
RunSh 'ls -lt /data/anr | head -5'
$f = RunSh 'ls -t /data/anr/anr_* 2>/dev/null | head -1'
'file=' + $f
if ($f) {
    $txt = RunSh ('cat ' + $f)
    $lines = $txt -split "`n"
    $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^"main"') { $idx = $i; break } }
    'main thread at line ' + $idx
    if ($idx -ge 0) { $lines[$idx..([Math]::Min($idx+45,$lines.Count-1))] | Out-String }
}
