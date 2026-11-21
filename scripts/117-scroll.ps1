$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
# reinstall the plain resigned build (most informative state)
& $adb -s $S shell pm uninstall io.github.vvb2060.mahoshojo 2>&1 | Out-Null
& $adb -s $S shell pm install -r /data/local/tmp/momo-resigned.apk 2>&1 | Out-String
& $adb -s $S shell am start -W -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
Start-Sleep 5
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
# find display id
$dump = (& $adb -s $S shell dumpsys activity activities 2>&1 | Out-String)
$lines = $dump -split "`n"
$disp = ''
$found = $false
foreach ($l in $lines) {
    if ($l -match 'ResumedActivity:.*mahoshojo') { $found = $true }
    if ($found -and $l -match 'mDisplayId=(\d+)') { $disp = $matches[1]; break }
}
'display=' + $disp
if ($disp) {
    & $adb -s $S shell input -d $disp swipe 450 1700 450 600 400 2>&1 | Out-String
    Start-Sleep 2
    & $adb -s $S shell input -d $disp swipe 450 1700 450 600 400 2>&1 | Out-String
    Start-Sleep 2
}
