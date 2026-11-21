$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
& $adb -s $S shell uiautomator dump /sdcard/ui_ok.xml 2>&1 | Out-String
& $adb -s $S pull /sdcard/ui_ok.xml 'D:\MuMuWork\momo\ui-ok.xml' 2>&1 | Out-Null
if (Test-Path 'D:\MuMuWork\momo\ui-ok.xml') {
    $t = Get-Content 'D:\MuMuWork\momo\ui-ok.xml' -Raw -Encoding UTF8
    [regex]::Matches($t, 'text="([^"]{1,90})"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 15 | Out-String
}
Start-Sleep 15
'pid after 15s=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
