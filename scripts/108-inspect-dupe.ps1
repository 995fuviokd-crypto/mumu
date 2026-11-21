$ErrorActionPreference = 'Continue'
$f = 'D:\MuMuWork\momo\full\smali\Ei.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match 'const v6, -0x1456f89e') { $idx = $i; break } }
if ($idx -lt 0) { for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match 'const/4 v4, 0x1') { $idx = $i; break } } }
'idx=' + ($idx+1)
for ($i = $idx - 2; $i -le $idx + 12; $i++) { '{0,5}: [{1}]' -f ($i+1), $lines[$i] }
