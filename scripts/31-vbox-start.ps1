$ErrorActionPreference = 'Continue'
$nemu = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0\MuMuPlayer-15.0-0.nemu'
$serial = 'D:\MuMuWork\image-edit\serial.log'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
Copy-Item $nemu ($nemu + '.bak-vboxstart') -Force
if (Test-Path $serial) { Remove-Item $serial -Force }
$xml = [IO.File]::ReadAllText($nemu)
if ($xml -notmatch '<UART>') {
    $block = @"
      <UART>
        <Port slot="0" enabled="true" IOBase="0x3f8" IRQ="4" path="$serial" hostMode="RawFile"/>
      </UART>
"@
    $xml = $xml.Replace('      <AudioAdapter', $block + "`r`n      <AudioAdapter")
}
[IO.File]::WriteAllText($nemu, $xml, (New-Object Text.UTF8Encoding($false)))
'--- list vms ---'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
& $vb list vms 2>&1 | Out-String
'--- startvm ---'
& $vb startvm 'MuMuPlayer-15.0-0' --type headless 2>&1 | Out-String
Start-Sleep 20
'--- serial ---'
Get-Item $serial -ErrorAction SilentlyContinue | Select-Object Length,LastWriteTime | Format-Table -AutoSize | Out-String
if (Test-Path $serial) { Get-Content $serial -Tail 80 | Out-String }
'--- running ---'
& $vb list runningvms 2>&1 | Out-String
