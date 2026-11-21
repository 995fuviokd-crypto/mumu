$ErrorActionPreference = 'Continue'
$tr = 'D:\MuMuWork\momo\momo.trace'
$lines = Get-Content $tr
'--- lines mentioning libmahoshojo ---'
$hits = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'libmahoshojo') { $hits += [pscustomobject]@{ Index=$i; Line=$lines[$i] } }
}
'hits: ' + $hits.Count
$hits | Select-Object -First 16 | ForEach-Object { $_.Index.ToString() + ': ' + $_.Line.Trim() } | Out-String
'--- tids ---'
$tids = @($hits | ForEach-Object { if ($_.Line -match '^\s*(\d+)\s') { $matches[1] } } | Sort-Object -Unique)
'tids: ' + ($tids -join ', ')

'--- failed opens by path ---'
$failedOpens = @{}
foreach ($l in $lines) {
    if ($l -match 'openat\([^)]*"([^"]+)"[^)]*\)\s*=\s*-1\s+(\w+)') {
        $k = $matches[1] + ' [' + $matches[2] + ']'
        if (-not $failedOpens.ContainsKey($k)) { $failedOpens[$k] = 0 }
        $failedOpens[$k]++
    }
}
$failedOpens.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 50 | ForEach-Object { '{0,5}  {1}' -f $_.Value, $_.Key } | Out-String

'--- env-ish opens with result ---'
$out = New-Object System.Collections.Generic.List[string]
foreach ($l in $lines) {
    if ($l -match 'openat\([^)]*"(/proc/[^"]*|/sys/[^"]*|/system/[^"]*|/dev/__properties__[^"]*|/vendor/[^"]*)"') {
        if ($l -match '= (-?\d+)\s*$' -or $l -match '= -1 ') {
            $out.Add('    ' + $l.Trim())
        }
    }
}
'env-ish open results: ' + $out.Count
$out | Select-Object -Last 120 | Out-String
