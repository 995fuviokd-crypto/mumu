$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
foreach ($id in @(0,2,3,4,5)) {
    $remote = "/sdcard/_d$id.png"
    & $adb -s $S shell screencap -d $id -p $remote 2>&1 | Out-Null
    $local = "D:\MuMuWork\image-edit\d$id.png"
    & $adb -s $S pull $remote $local 2>&1 | Out-Null
    if (Test-Path $local) {
        $h = (Get-FileHash $local -Algorithm SHA256).Hash.Substring(0,12)
        "display $id -> $local len=$((Get-Item $local).Length) hash=$h"
    } else {
        "display $id -> no file"
    }
}
'--- task displays ---'
& $adb -s $S shell dumpsys activity activities 2>&1 | Select-String -Pattern 'ActivityRecord\{|displayId' | Select-Object -First 40 | ForEach-Object { $_.Line.Trim() } | Out-String
