$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$srcBase = 'D:\Program Files\Netease\MuMu\nx_device\15.0\vms\MuMuPlayer-15.0-base\system.vdi'
$srcDiff = 'D:\Program Files\Netease\MuMu\vms\MuMuPlayer-15.0-0\system-diff.vdi'
$vb = 'D:\Program Files\Netease\MuMu\nx_device\15.0\hypervisor\VBoxManage.exe'
$qi = 'D:\MuMuWork\ColorOSLab\sdk\emulator\qemu-img.exe'

New-Item -ItemType Directory -Force $d | Out-Null
New-Item -ItemType Directory -Force (Join-Path $d 'scripts') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $d 'vboxhome') | Out-Null

if (-not (Test-Path (Join-Path $d 'base.vdi'))) { Copy-Item $srcBase (Join-Path $d 'base.vdi') }
if (-not (Test-Path (Join-Path $d 'diff.vdi'))) { Copy-Item $srcDiff (Join-Path $d 'diff.vdi') }
Get-ChildItem $d -File | Select-Object Name, Length | Format-Table -AutoSize | Out-String | Write-Output

${env:VBOX_USER_HOME} = Join-Path $d 'vboxhome'
& $vb list hdds 2>&1 | Out-String | Write-Output

'--- try clone diff ---' | Write-Output
& $vb clonemedium (Join-Path $d 'diff.vdi') (Join-Path $d 'merged.vdi') --format VDI 2>&1 | Out-String | Write-Output
if (Test-Path (Join-Path $d 'merged.vdi')) {
    Get-Item (Join-Path $d 'merged.vdi') | Select-Object Length | Format-Table -AutoSize | Out-String | Write-Output
}

'--- convert base to raw ---' | Write-Output
$baseRaw = Join-Path $d 'base.raw'
if (-not (Test-Path $baseRaw)) {
    & $qi convert -f vdi -O raw (Join-Path $d 'base.vdi') $baseRaw 2>&1 | Out-String | Write-Output
}
if (Test-Path $baseRaw) {
    Get-Item $baseRaw | Select-Object Length | Format-Table -AutoSize | Out-String | Write-Output

    $fs = [IO.File]::OpenRead($baseRaw)
    try {
        $hdr = New-Object byte[] 1024
        $fs.Read($hdr, 0, 1024) | Out-Null
        $sig = [Text.Encoding]::ASCII.GetString($hdr, 512, 8)
        'GPT sig: ' + $sig | Write-Output
        $lba = [BitConverter]::ToUInt64($hdr, 72)
        $num = [BitConverter]::ToUInt32($hdr, 80)
        $sz = [BitConverter]::ToUInt32($hdr, 84)
        'PartEntryLBA: ' + $lba + ' entries=' + $num + ' size=' + $sz | Write-Output
        $fs.Seek([int64]$lba * 512, [IO.SeekOrigin]::Begin) | Out-Null
        $eb = New-Object byte[] ($num * $sz)
        $fs.Read($eb, 0, $eb.Length) | Out-Null
        for ($i = 0; $i -lt $num; $i++) {
            $o = $i * $sz
            $t = [Text.Encoding]::Unicode.GetString($eb, $o, 72).Trim([char]0)
            if (-not $t) { continue }
            $s = [BitConverter]::ToUInt64($eb, $o + 32)
            $e = [BitConverter]::ToUInt64($eb, $o + 40)
            $n = [Text.Encoding]::Unicode.GetString($eb, $o + 56, 72).Trim([char]0)
            ('{0} type={1} start={2} end={3} sectors={4} name={5}' -f $i, $t, $s, $e, ($e - $s + 1), $n) | Write-Output
        }
    } finally { $fs.Close() }
}
