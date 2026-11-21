$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$img = 'D:/MuMuWork/image-edit/part-3.img'

function Run-Dbg([string]$cmd, [switch]$Write) {
    $dbgArgs = @()
    if ($Write) { $dbgArgs += '-w' }
    $dbgArgs += @('-R', $cmd, $img)
    $out = & $dbg @dbgArgs 2>&1
    return ($out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS' })
}

function Clear-Dir([string]$path) {
    $out = Run-Dbg "ls -l $path"
    foreach ($line in $out) {
        if ($line -match '^\s*(\d+)\s+([0-7]+)\s+\(\d+\)\s+\d+\s+\d+\s+\d+\s+\S+\s+\S+\s+(.+?)\s*$') {
            $mode = $matches[2]
            $name = $matches[3]
            if ($name -eq '.' -or $name -eq '..') { continue }
            $child = ($path.TrimEnd('/') + '/' + $name)
            if ($mode.StartsWith('4')) {
                Clear-Dir $child
                $r = Run-Dbg "rmdir $child" -Write
                ($r -join ' ') | Where-Object { $_ } | Write-Output
                'rmdir ' + $child | Write-Output
            } else {
                $r = Run-Dbg "rm $child" -Write
                ($r -join ' ') | Where-Object { $_ } | Write-Output
                'rm ' + $child | Write-Output
            }
        }
    }
}

foreach ($base in @('/upperdir', '/workdir')) {
    '===== clearing ' + $base + ' ====='
    Clear-Dir $base
    '--- remaining ' + $base + ' ---'
    (Run-Dbg "ls -l $base") | Out-String | Write-Output
}

'--- stat dirs ---'
(Run-Dbg 'stat /upperdir') | Select-Object -First 12 | Out-String | Write-Output
(Run-Dbg 'stat /workdir') | Select-Object -First 12 | Out-String | Write-Output

'--- fsck part3 ---'
$fsck = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\e2fsck.exe'
& $fsck -fy $img 2>&1 | Out-String | Write-Output
& $fsck -fn $img 2>&1 | Out-String | Write-Output
