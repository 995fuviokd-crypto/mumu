$ErrorActionPreference = 'Continue'
$src = 'D:\MuMuWork\momo\full'
$pub = Join-Path $src 'res\values\public.xml'
$strs = Join-Path $src 'res\values\strings.xml'
$pubLines = Get-Content $pub
$map = @{}
foreach ($l in $pubLines) {
    if ($l -match 'type="string"\s+name="([^"]+)"\s+id="(0x[0-9a-f]+)"') { $map[$matches[2]] = $matches[1] }
}
'--- string for 0x7f10003b ---'
if ($map.ContainsKey('0x7f10003b')) {
    $name = $map['0x7f10003b']
    'name=' + $name
    Select-String -Path $strs -Pattern ('name="' + $name + '"') | ForEach-Object { $_.Line.Trim() } | Out-String
}
'--- all strings containing 环境/损坏/正常 ---'
Select-String -Path $strs -Pattern '环境|损坏|签名|更新' | ForEach-Object { $_.Line.Trim() } | Select-Object -First 20 | Out-String
'--- ids for those names ---'
$targets = @('环境损坏','签名验证失败','环境正常','安全更新已过期')
foreach ($k in $map.Keys) {
    $n = $map[$k]
    foreach ($t in $targets) { }
}
'--- vendor security patch ---'
