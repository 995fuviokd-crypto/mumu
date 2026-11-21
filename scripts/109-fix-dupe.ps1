$ErrorActionPreference = 'Continue'
$f = 'D:\MuMuWork\momo\full\smali\Ei.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
# remove duplicated pair at 0-based 420..422 if they match
if ($lines[420].Trim() -eq 'const/4 v4, 0x1' -and $lines[422].Trim() -eq 'goto :goto_2') {
    $lines.RemoveRange(420, 3)
    'removed duplicate'
}
[IO.File]::WriteAllLines($f, $lines, (New-Object Text.UTF8Encoding($false)))
'--- verify ---'
$c = Get-Content -LiteralPath $f
for ($i = 415; $i -le 428; $i++) { '{0,5}: [{1}]' -f ($i+1), $c[$i] }
