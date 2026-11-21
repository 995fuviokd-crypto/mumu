$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$S = 'emulator-5554'
$script = @'
#!/system/bin/sh
echo "=== displays ==="
dumpsys SurfaceFlinger --display-id
echo "=== display state ==="
dumpsys display | grep -E "mDisplayId=|uniqueId=|state=" | head -30
echo "=== resumed ==="
dumpsys activity activities | grep -E "ResumedActivity" | head -8
echo "=== focus ==="
dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -8
echo "=== via proc ==="
ps -A | grep -i via
'@
$local = 'D:\MuMuWork\image-edit\check.sh'
[IO.File]::WriteAllText($local, ($script -replace "`r`n", "`n"), (New-Object Text.UTF8Encoding($false)))
& $adb -s $S push $local /data/local/tmp/check.sh 2>&1 | Out-Null
& $adb -s $S shell sh /data/local/tmp/check.sh 2>&1 | Out-String
'=== capture all displays ==='
$ids = & $adb -s $S shell dumpsys SurfaceFlinger --display-id 2>&1
$ids | Out-String
