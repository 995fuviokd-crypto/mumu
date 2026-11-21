$ErrorActionPreference = 'Continue'
$f = 'D:\MuMuWork\momo\full\smali\Ff.smali'
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
$keep = New-Object System.Collections.Generic.List[string]
foreach ($l in $lines) {
    if ($l -match 'MOMODBG') { continue }
    if ($l -match 'invoke-static \{v18, v17\}, Landroid/util/Log;') { continue }
    if ($l -match 'invoke-static \{v10\}, Ljava/lang/String;->valueOf\(I\)') { continue }
    if ($l -match 'invoke-static \{v9\}, Ljava/lang/String;->valueOf\(Z\)') { continue }
    if ($l -match '^\s*move-result-object v17\s*$') { continue }
    if ($l -match 'debug: log Fi.a') { continue }
    $keep.Add($l)
}
[IO.File]::WriteAllLines($f, $keep, (New-Object Text.UTF8Encoding($false)))
'--- verify region ---'
$c = Get-Content -LiteralPath $f
for ($i = 176; $i -le 188; $i++) { '{0,5}: [{1}]' -f ($i+1), $c[$i] }
'--- any MOMODBG left ---'
(Select-String -Path $f -Pattern 'MOMODBG' | Measure-Object).Count
