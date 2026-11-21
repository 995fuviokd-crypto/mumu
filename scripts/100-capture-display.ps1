$ErrorActionPreference = 'Continue'
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$S = 'emulator-5554'
function RunSh([string]$c) { return ((& $mgr sh --vmindex 0 --cmd $c 2>&1 | Out-String).Trim() ) }
'--- start app ---'
& $adb -s $S shell am start -n io.github.vvb2060.mahoshojo/.home.HomeActivity 2>&1 | Out-Null
Start-Sleep 5
'--- find display of app ---'
$d = (& $adb -s $S shell dumpsys activity activities 2>&1 | Out-String)
$lines = $d -split "`n"
$disp = ''
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'mDisplayId=(\d+)' -and $lines[$i] -match 'organized') { $disp = $matches[1] }
    if ($lines[$i] -match 'ResumedActivity.*mahoshojo') {
        # search nearby display line
        for ($j = $i; $j -lt [Math]::Min($i+4, $lines.Count); $j++) {
            if ($lines[$j] -match 'mDisplayId=(\d+)') { $disp = $matches[1] }
        }
    }
}
'display=' + $disp
'--- root screencap ---'
if ($disp -ne '') {
    RunSh ('screencap -d ' + $disp + ' -p /data/local/tmp/momo_shot.png; ls -l /data/local/tmp/momo_shot.png; chmod 644 /data/local/tmp/momo_shot.png')
    & $adb -s $S pull /data/local/tmp/momo_shot.png 'D:\MuMuWork\momo\shot.png' 2>&1 | Out-String
    Get-Item 'D:\MuMuWork\momo\shot.png' -ErrorAction SilentlyContinue | Select-Object Length | Format-Table -AutoSize | Out-String
}
'--- try uiautomator on display via cmd ---'
RunSh ('uiautomator dump --display ' + $disp + ' /data/local/tmp/ui.xml 2>&1; ls -l /data/local/tmp/ui.xml 2>&1')
