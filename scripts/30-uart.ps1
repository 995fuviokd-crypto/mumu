$ErrorActionPreference = 'Continue'
$nemu = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0\MuMuPlayer-15.0-0.nemu'
$serial = 'D:\MuMuWork\image-edit\serial.log'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
Copy-Item $nemu ($nemu + '.bak-uart') -Force
if (Test-Path $serial) { Remove-Item $serial -Force }
$xml = [IO.File]::ReadAllText($nemu)
$block = @"
      <UART>
        <Port slot="0" enabled="true" IOBase="0x3f8" IRQ="4" path="$serial" hostMode="RawFile"/>
      </UART>
"@
if ($xml -notmatch '<UART>') {
    $xml = $xml.Replace('      <AudioAdapter', $block + "`r`n      <AudioAdapter")
}
[IO.File]::WriteAllText($nemu, $xml, (New-Object Text.UTF8Encoding($false)))
Select-String -Path $nemu -Pattern 'UART|hostMode' | ForEach-Object { $_.Line.Trim() }
'--- launch ---'
& $mgr control --vmindex 0 launch 2>&1 | Out-String
Start-Sleep 30
'--- serial exists ---'
Get-Item $serial -ErrorAction SilentlyContinue | Select-Object Length,LastWriteTime | Format-Table -AutoSize | Out-String
'--- uart still in nemu ---'
Select-String -Path $nemu -Pattern 'UART|hostMode' | ForEach-Object { $_.Line.Trim() }
'--- serial tail ---'
if (Test-Path $serial) { Get-Content $serial -Tail 120 | Out-String }
