$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
$h1 = (Get-FileHash 'D:\MuMuWork\image-edit\final-home.png' -Algorithm SHA256).Hash
$h2 = (Get-FileHash 'D:\MuMuWork\image-edit\final-via.png' -Algorithm SHA256).Hash
'home=' + $h1
'via =' + $h2
'equal=' + ($h1 -eq $h2)
'--- resumed activities ---'
(& $adb -s $S shell 'dumpsys activity activities | grep -E "ResumedActivity|topResumed" | head -6' 2>&1 | Out-String)
'--- displays ---'
(& $adb -s $S shell 'dumpsys display | grep -E "mDisplayId|DisplayDeviceInfo|state=" | head -20' 2>&1 | Out-String)
'--- via task ---'
(& $adb -s $S shell 'dumpsys activity recents | grep -E "mark.via|lawnchair" | head -10' 2>&1 | Out-String)
'--- launch via with explicit display ---'
(& $adb -s $S shell 'am start --display 0 -n mark.via/.Shell' 2>&1 | Out-String)
Start-Sleep 5
(& $adb -s $S shell 'dumpsys window windows | grep -E "mCurrentFocus|mFocusedApp|mark.via" | head -8' 2>&1 | Out-String)
