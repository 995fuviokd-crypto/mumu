$ErrorActionPreference = 'Stop'
$staging = 'D:\MuMuWork\image-edit\staging'
$orig = Join-Path $staging 'build.prop.orig'
$new = Join-Path $staging 'build.prop.new'
$lines = [IO.File]::ReadAllLines($orig)
$out = New-Object System.Collections.Generic.List[string]
$replacements = @{
    'ro.product.system.brand=mumu_win' = 'ro.product.system.brand=vivo'
    'ro.product.system.device=mumu_win_x86_64' = 'ro.product.system.device=V2284A'
    'ro.product.system.manufacturer=kona' = 'ro.product.system.manufacturer=vivo'
    'ro.product.system.model=mumu_win_x86_64' = 'ro.product.system.model=V2284A'
    'ro.product.system.name=mumu_win_x86_64' = 'ro.product.system.name=V2284A'
    'ro.system.build.fingerprint=mumu_win/mumu_win_x86_64/mumu_win_x86_64:15/V417IR/1203:user/release-keys' = 'ro.system.build.fingerprint=vivo/V2284A/V2284A:15/V417IR/1203:user/release-keys'
    'ro.build.flavor=mumu_win_x86_64-user' = 'ro.build.flavor=vivo_V2284A-user'
    'ro.build.product=mumu_win_x86_64' = 'ro.build.product=V2284A'
    'ro.build.description=mumu_win_x86_64-user 15 V417IR 1203 release-keys' = 'ro.build.description=vivo V2284A-user 15 V417IR 1203 release-keys'
    'ro.build.host=6b29a8384f29' = 'ro.build.host=vivo'
    'ro.build.user=abc' = 'ro.build.user=vivo'
}
foreach ($line in $lines) {
    if ($replacements.ContainsKey($line)) { $out.Add($replacements[$line]) } else { $out.Add($line) }
}
$out.Add('')
$out.Add('####################################')
$out.Add('# de-MuMu image-level overrides')
$out.Add('####################################')
$out.Add('ro.build.version.overseas=true')
$out.Add('net.hostname=V2284A')
$out.Add('debug.hwui.renderer=skiagl')
$out.Add('ro.product.brand=vivo')
$out.Add('ro.product.manufacturer=vivo')
$out.Add('ro.product.model=V2284A')
$out.Add('ro.product.name=V2284A')
$out.Add('ro.product.device=V2284A')
[IO.File]::WriteAllText($new, (($out -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))
Copy-Item 'D:\MuMuWork\module\mumu_noads\hosts' (Join-Path $staging 'hosts.new') -Force
'--- build.prop new selected ---'
Get-Content $new | Select-String -Pattern 'ro.product.system|ro.build.flavor|ro.build.product|ro.build.description|overseas|net.hostname|debug.hwui|ro.product.brand|ro.product.manufacturer|ro.product.model|ro.product.name|ro.product.device|ro.build.host|ro.build.user' | ForEach-Object { $_.Line }
'--- hosts new ---'
Get-Content (Join-Path $staging 'hosts.new') | Out-String
'--- restore clean root image ---'
if (Test-Path 'D:\MuMuWork\image-edit\part-root.img') { Remove-Item 'D:\MuMuWork\image-edit\part-root.img' -Force }
Copy-Item 'D:\MuMuWork\image-edit\part-root.orig.img' 'D:\MuMuWork\image-edit\part-root.img'
Get-Item 'D:\MuMuWork\image-edit\part-root.img' | Select-Object Length | Format-Table -AutoSize | Out-String
