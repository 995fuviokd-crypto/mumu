$ErrorActionPreference = 'Continue'
# 1) revert debug injection in Ff
$f = 'D:\MuMuWork\momo\full\smali\Ff.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
$start = -1
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '# debug: log Fi.a and Fi.w') { $start = $i; break } }
if ($start -ge 0) {
    # block is from start-1 (blank) to the line before 'if-eqz v10, :cond_3'
    $end = -1
    for ($i = $start; $i -lt [Math]::Min($start + 30, $lines.Count); $i++) {
        if ($lines[$i] -match 'if-eqz v10, :cond_3') { $end = $i; break }
    }
    if ($end -gt $start) { $lines.RemoveRange($start - 1, ($end - $start) - 1); 'removed debug block' }
}
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match '^\s*\.locals 19') { $lines[$i] = '    .locals 17'; 'restored locals'; break } }
[IO.File]::WriteAllLines($f, $lines, (New-Object Text.UTF8Encoding($false)))
'--- Ff verify ---'
$c = Get-Content -LiteralPath $f
for ($i = 176; $i -le 190; $i++) { '{0,5}: [{1}]' -f ($i+1), $c[$i] }

# 2) force cert branch in Ei
$e = 'D:\MuMuWork\momo\full\smali\Ei.smali'
$el = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $e -Encoding UTF8)
$j = -1
for ($i = 0; $i -lt $el.Count; $i++) { if ($el[$i] -match 'iget-boolean v6, v4, Lj2;->j:Z') { $j = $i; break } }
'j anchor at ' + ($j + 1)
if ($j -ge 0) {
    for ($k = $j; $k -lt [Math]::Min($j + 6, $el.Count); $k++) {
        if ($el[$k] -match 'if-nez v6, :cond_6') { $el[$k] = '    goto :cond_6'; 'forced cert branch'; break }
    }
}
[IO.File]::WriteAllLines($e, $el, (New-Object Text.UTF8Encoding($false)))
'--- Ei verify ---'
$ec = Get-Content -LiteralPath $e
for ($i = $j - 2; $i -le $j + 6; $i++) { '{0,5}: [{1}]' -f ($i+1), $ec[$i] }
