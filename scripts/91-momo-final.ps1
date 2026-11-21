$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
'--- launch via monkey (as if tapping icon) ---'
for ($i = 1; $i -le 3; $i++) {
    & $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
    Start-Sleep 1
    & $adb -s $S shell monkey -p io.github.vvb2060.mahoshojo -c android.intent.category.LAUNCHER 1 2>&1 | Select-Object -Last 2 | Out-String
    Start-Sleep 6
    $p = ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
    "launch ${i}: pid=[$p]"
}
'--- ui after swipe ---'
& $adb -s $S shell input swipe 450 1500 450 500 300 2>&1 | Out-Null
Start-Sleep 2
& $adb -s $S shell uiautomator dump /sdcard/ui_final.xml 2>&1 | Out-Null
& $adb -s $S pull /sdcard/ui_final.xml 'D:\MuMuWork\momo\ui-final.xml' 2>&1 | Out-Null
$txt = Get-Content 'D:\MuMuWork\momo\ui-final.xml' -Raw -Encoding UTF8
[regex]::Matches($txt,'text="([^"]{2,80})"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 30 | Out-String
'--- still alive after 20s ---'
Start-Sleep 20
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
