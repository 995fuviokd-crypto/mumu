$ErrorActionPreference = 'Continue'
$f = 'D:\MuMuWork\momo\full\smali\Ei.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'const v6, -0x1456f89e') { $idx = $i; break }
}
'hash const at line ' + ($idx + 1)
if ($idx -lt 0) { throw 'hash constant not found' }
'--- before ---'
$lines[($idx)..($idx+8)] | ForEach-Object { '|' + $_ } | Out-String
$replacement = @(
    '    const/4 v4, 0x1',
    '',
    '    goto :goto_2'
)
$lines.RemoveRange($idx, 4)
$lines.InsertRange($idx, [string[]]$replacement)
[IO.File]::WriteAllLines($f, $lines, (New-Object Text.UTF8Encoding($false)))
'--- after ---'
$check = Get-Content -LiteralPath $f
$check[($idx-2)..($idx+10)] | ForEach-Object { '|' + $_ } | Out-String
