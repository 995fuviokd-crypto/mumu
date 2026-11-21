$ErrorActionPreference = 'Continue'
$e = 'D:\MuMuWork\momo\full\smali\Ei.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $e -Encoding UTF8)
$k = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'const/16 v4, 0x14') { $k = $i; break }
}
'const 0x14 at ' + ($k + 1)
if ($k -lt 0) { throw 'anchor not found' }
$done = $false
for ($i = $k; $i -lt [Math]::Min($k + 12, $lines.Count); $i++) {
    if ($lines[$i] -match 'if-gez v4, :cond_9') { $lines[$i] = '    goto :cond_a'; $done = $true; 'patched if-gez'; break }
}
if (-not $done) { throw 'if-gez not found' }
[IO.File]::WriteAllLines($e, $lines, (New-Object Text.UTF8Encoding($false)))
$c = Get-Content -LiteralPath $e
for ($i = $k; $i -le $k + 16; $i++) { '{0,5}: [{1}]' -f ($i+1), $c[$i] }
