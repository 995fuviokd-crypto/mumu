$ErrorActionPreference = 'Continue'
$java = 'D:\MuMuWork\ColorTheme\incoming\jdk\extracted\jdk-21.0.13.1+2\bin\java.exe'
$apktool = 'D:\MuMuWork\tools\apktool_2.11.1.jar'
$src = 'D:\MuMuWork\momo\full'
if (Test-Path $src) { Remove-Item $src -Recurse -Force }
'--- decode full ---'
& $java -jar $apktool d -f -o $src 'D:\MuMuWork\momo\momo.apk' 2>&1 | Select-Object -Last 6 | Out-String
$f = Join-Path $src 'smali\io\github\vvb2060\mahoshojo\home\HomeActivity.smali'
if (-not (Test-Path $f)) { 'missing ' + $f; exit 1 }
$lines = [System.Collections.Generic.List[string]](Get-Content -LiteralPath $f -Encoding UTF8)
$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\.method public final onCreate\(Landroid/os/Bundle;\)V') { $idx = $i; break }
}
'onCreate line: ' + ($idx + 1)
if ($idx -lt 0) { exit 1 }
# find the invoke-super line inside onCreate
$sup = -1
for ($i = $idx; $i -lt [Math]::Min($idx + 12, $lines.Count); $i++) {
    if ($lines[$i] -match 'invoke-super') { $sup = $i; break }
}
'invoke-super line: ' + ($sup + 1)
if ($sup -lt 0) { exit 1 }
$inject = @(
    '',
    '    # warmup: force native engine init before the random-UUID check',
    '    const/4 v0, 0x0',
    '    invoke-static {v0}, Lio/github/vvb2060/mahoshojo/App;->get(I)I',
    '    move-result v0'
)
$lines.InsertRange($sup + 1, [string[]]$inject)
[IO.File]::WriteAllLines($f, $lines, (New-Object Text.UTF8Encoding($false)))
'--- verify ---'
$check = Get-Content -LiteralPath $f
$start = ($check | Select-String -Pattern '^\.method public final onCreate' | Select-Object -First 1).LineNumber
$check[($start-1)..($start+14)] | Out-String
'--- rebuild ---'
$out = 'D:\MuMuWork\momo\momo-patched-unsigned.apk'
if (Test-Path $out) { Remove-Item $out -Force }
& $java -jar $apktool b $src -o $out 2>&1 | Select-Object -Last 8 | Out-String
if (Test-Path $out) { Get-Item $out | Select-Object Length | Format-Table -AutoSize | Out-String } else { 'build failed' }
