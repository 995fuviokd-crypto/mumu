$ErrorActionPreference = 'Continue'
$bt = 'D:\MuMuWork\ColorTheme\incoming\buildtools\extracted\android-15'
$aapt = Join-Path $bt 'aapt2.exe'
if (-not (Test-Path $aapt)) { Get-ChildItem 'D:\MuMuWork' -Recurse -Filter 'aapt2.exe' -ErrorAction SilentlyContinue | Select-Object -First 3 FullName | Format-Table -AutoSize | Out-String }
'--- permissions ---'
& $aapt dump permissions 'D:\MuMuWork\momo\momo.apk' 2>&1 | Out-String
'--- sdk / abi in manifest ---'
& $aapt dump badging 'D:\MuMuWork\momo\momo.apk' 2>&1 | Select-String -Pattern 'sdkVersion|targetSdkVersion|native-code|package:|application-label' | ForEach-Object { $_.Line.Trim() } | Out-String
