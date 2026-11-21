$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
& $adb -s $S shell am force-stop io.github.vvb2060.mahoshojo 2>&1 | Out-Null
Start-Sleep 1
& $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
Start-Sleep 5
'pid=' + ((& $adb -s $S shell pidof io.github.vvb2060.mahoshojo 2>&1 | Out-String).Trim())
$dump = (& $adb -s $S shell dumpsys activity activities 2>&1 | Out-String)
$lines = $dump -split "`n"
$display = ''
$found = $false
foreach ($l in $lines) {
    if ($l -match 'ResumedActivity:.*mahoshojo') { $found = $true }
    if ($found -and $l -match 'mDisplayId=(\d+)') { $display = $matches[1]; break }
}
'display=' + $display
if ($display) {
    RunSh ('screencap -d ' + $display + ' -p /data/user/0/io.github.vvb2060.mahoshojo/cache/shot.png 2>&1; ls -l /data/user/0/io.github.vvb2060.mahoshojo/cache/shot.png 2>&1')
    $code = ((& $adb -s $S shell dumpsys package io.github.vvb2060.mahoshojo 2>&1 | Select-String -Pattern 'dataDir=' | Select-Object -First 1).Line)
    'dataDir line: ' + $code
    RunSh ('cp /data/user/0/io.github.vvb2060.mahoshojo/cache/shot.png /data/local/tmp/shot.png; chmod 666 /data/local/tmp/shot.png; ls -l /data/local/tmp/shot.png')
    & $adb -s $S pull /data/local/tmp/shot.png 'D:\MuMuWork\momo\shot.png' 2>&1 | Out-String
    Get-Item 'D:\MuMuWork\momo\shot.png' -ErrorAction SilentlyContinue | Select-Object Length | Format-Table -AutoSize | Out-String
}
