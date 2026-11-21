$ErrorActionPreference = 'Continue'
$src = 'D:\MuMuWork\momo\full'
$xml = [xml](Get-Content (Join-Path $src 'res\values\strings.xml') -Raw -Encoding UTF8)
$want1 = [string]([char]0x7B7E + [char]0x540D + [char]0x9A8C + [char]0x8BC1 + [char]0x5931 + [char]0x8D25)  # signature failed
$want2 = [string]([char]0x73AF + [char]0x5883 + [char]0x635F + [char]0x574F)                              # environment damaged
'search1=' + $want1
'search2=' + $want2
$hits = @()
foreach ($s in $xml.resources.string) {
    if ($s.'#text' -and $s.'#text'.Contains($want1)) { $hits += [pscustomobject]@{Name=$s.name; Text=$s.'#text'; Kind='sigfail'} }
    if ($s.'#text' -and $s.'#text'.Contains($want2)) { $hits += [pscustomobject]@{Name=$s.name; Text=$s.'#text'; Kind='damaged'} }
}
$hits | Format-Table -AutoSize | Out-String
# map names to ids
$pub = [xml](Get-Content (Join-Path $src 'res\values\public.xml') -Raw -Encoding UTF8)
$map = @{}
foreach ($p in $pub.resources.public) { if ($p.type -eq 'string') { $map[$p.name] = $p.id } }
foreach ($h in $hits) { $h.Name + ' -> ' + $map[$h.Name] }
