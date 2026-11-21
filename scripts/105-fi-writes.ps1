$ErrorActionPreference = 'Continue'
$src = 'D:\MuMuWork\momo\full\smali'
'--- Fi.a writes ---'
Get-ChildItem $src -Recurse -Filter '*.smali' | Select-String -Pattern 'LFi;->a:I' | ForEach-Object { $_.Path.Replace($src,'') + ':' + $_.LineNumber + ': ' + $_.Line.Trim() } | Out-String
'--- Fi constructor call sites (arg counts) ---'
Get-ChildItem $src -Recurse -Filter '*.smali' | Select-String -Pattern 'LFi;-><init>' | ForEach-Object { $_.Path.Replace($src,'') + ':' + $_.LineNumber + ': ' + $_.Line.Trim() } | Out-String
