$ErrorActionPreference = 'Continue'
$f = 'D:\MuMuWork\momo\full\smali\Ff.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
# find method a(Ljava/lang/Object;)V and its .locals
$m = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\.method public final a\(Ljava/lang/Object;\)V') { $m = $i; break }
}
'method at ' + ($m + 1)
$loc = -1
for ($i = $m; $i -lt [Math]::Min($m + 8, $lines.Count); $i++) {
    if ($lines[$i] -match '^\s*\.locals\s+(\d+)') { $loc = $i; 'locals=' + $matches[1]; break }
}
if ($loc -lt 0) { throw 'locals not found' }
$lines[$loc] = '    .locals 19'
# find the iget v10 Fi.a anchor
$a = -1
for ($i = $m; $i -lt [Math]::Min($m + 400, $lines.Count); $i++) {
    if ($lines[$i] -match 'iget v10, v2, LFi;->a:I') { $a = $i; break }
}
'anchor at ' + ($a + 1)
if ($a -lt 0) { throw 'anchor not found' }
$inject = @(
    '',
    '    # debug: log Fi.a and Fi.w',
    '    invoke-static {v10}, Ljava/lang/String;->valueOf(I)Ljava/lang/String;',
    '',
    '    move-result-object v17',
    '',
    '    const-string v18, "MOMODBG"',
    '',
    '    invoke-static {v18, v17}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I',
    '',
    '    invoke-static {v9}, Ljava/lang/String;->valueOf(Z)Ljava/lang/String;',
    '',
    '    move-result-object v17',
    '',
    '    const-string v18, "MOMODBG_W"',
    '',
    '    invoke-static {v18, v17}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;)I'
)
$lines.InsertRange($a + 1, [string[]]$inject)
[IO.File]::WriteAllLines($f, $lines, (New-Object Text.UTF8Encoding($false)))
'--- context ---'
$c = Get-Content -LiteralPath $f
$c[($a-4)..($a+22)] | ForEach-Object { '|' + $_ } | Out-String
