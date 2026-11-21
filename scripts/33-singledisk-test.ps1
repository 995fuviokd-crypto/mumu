$ErrorActionPreference = 'Continue'
$env:VBOX_USER_HOME = 'C:\Users\Administrator\.MUMUNX'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$vmDir = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0'
$base = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$diff = Join-Path $vmDir 'system-diff.vdi'
$nemu = Join-Path $vmDir 'MuMuPlayer-15.0-0.nemu'
$reg = 'C:\Users\Administrator\.MUMUNX\VirtualBox.xml'
$baseUuid = '812f8e95-6f8b-d70c-0000-100000000000'
$diffUuid = '812f8e95-6f8b-d70c-0000-000000000000'
$serial = 'D:\MuMuWork\image-edit\serial-test2.log'

'--- poweroff / kill ---'
& $vb controlvm 'MuMuPlayer-15.0-0' poweroff 2>&1 | Out-String
Start-Sleep 5
Get-Process | Where-Object { $_.ProcessName -match 'MuMuNxDevice|VirtualBox|VBoxSVC' } | Select-Object ProcessName,Id | Format-Table -AutoSize | Out-String
Get-Process | Where-Object { $_.ProcessName -match 'VBoxSVC|VirtualBox' } | Stop-Process -Force -ErrorAction SilentlyContinue

'--- clear global registry (backup) ---'
if (Test-Path $reg) {
    Copy-Item $reg ($reg + '.bak-singledisk') -Force
    Remove-Item $reg -Force
}

'--- base normal ---'
& $vb modifymedium $base --type normal 2>&1 | Out-String
Get-Item $base | Select-Object Length,IsReadOnly | Format-Table -AutoSize | Out-String

'--- edit nemu: base direct, no diff ---'
Copy-Item $nemu ($nemu + '.bak-singledisk') -Force
$xml = [IO.File]::ReadAllText($nemu)
$xml = $xml -replace '\s*<HardDisk uuid="\{[0-9a-f\-]+\}" location="system-diff\.vdi" format="VDI"/>', ''
$xml = $xml.Replace('type="Readonly"', 'type="Normal"')
$xml = $xml.Replace(('uuid="{' + $diffUuid + '}"'), ('uuid="{' + $baseUuid + '}"'))
if ($xml -notmatch '<UART>') {
    $uartBlock = "      <UART>`r`n        <Port slot=`"0`" enabled=`"true`" IOBase=`"0x3f8`" IRQ=`"4`" path=`"$serial`" hostMode=`"RawFile`"/>`r`n      </UART>`r`n"
    $xml = $xml.Replace('      <AudioAdapter', $uartBlock + '      <AudioAdapter')
}
[IO.File]::WriteAllText($nemu, $xml, (New-Object Text.UTF8Encoding($false)))
'--- nemu relevant ---'
Select-String -Path $nemu -Pattern 'system-diff|HardDisk uuid|Image uuid|UART|hostMode' | ForEach-Object { $_.Line.Trim() } | Out-String

'--- remove diff ---'
if (Test-Path $diff) { Remove-Item $diff -Force }

'--- start ---'
if (Test-Path $serial) { Remove-Item $serial -Force }
& $vb startvm 'MuMuPlayer-15.0-0' --type headless 2>&1 | Out-String
Start-Sleep 25
'--- serial ---'
Get-Item $serial -ErrorAction SilentlyContinue | Select-Object Length,LastWriteTime | Format-Table -AutoSize | Out-String
if (Test-Path $serial) { Get-Content $serial -Tail 120 | Out-String }
'--- running ---'
& $vb list runningvms 2>&1 | Out-String
