$ErrorActionPreference = 'Continue'
$src = 'D:\MuMuWork\momo\full\smali'
'--- Bi context 120-210 ---'
$lines = Get-Content -LiteralPath (Join-Path $src 'Bi.smali')
for ($i = 120; $i -le 210; $i++) { '{0,5}: {1}' -f $i, $lines[$i-1] }
'--- hashCode call sites ---'
Get-ChildItem $src -Recurse -Filter '*.smali' | Select-String -Pattern 'hashCode\(\)I' | Select-Object -First 12 | ForEach-Object { $_.Path.Replace($src,'') + ':' + $_.LineNumber }
'--- patch date props ---'
