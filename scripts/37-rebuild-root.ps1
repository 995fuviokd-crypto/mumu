$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\image-edit'
$root = Join-Path $d 'tools\cyg64'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
$dbg = Join-Path $d 'tools\e2fsprogs\usr\sbin\debugfs.exe'
$fsck = Join-Path $d 'tools\e2fsprogs\usr\sbin\e2fsck.exe'
$staging = Join-Path $d 'staging'
$img = 'D:/MuMuWork/image-edit/part-root.img'
$imgWin = Join-Path $d 'part-root.img'
$selinux = '/cygdrive/d/MuMuWork/image-edit/selinux.value'

function Dbg([string[]]$cmds, [switch]$Write) {
    $cf = Join-Path $d 'tmp-cmds.txt'
    [IO.File]::WriteAllLines($cf, $cmds)
    $argv = @()
    if ($Write) { $argv += '-w' }
    $argv += @('-f', $cf, $img)
    $out = & $dbg @argv 2>&1
    return ($out | Where-Object { $_ -notmatch '^debugfs 1\.44\.5|Using EXT2FS|^debugfs: ' })
}

'--- fresh copy from orig ---'
if (Test-Path $imgWin) { Remove-Item $imgWin -Force }
Copy-Item (Join-Path $d 'part-root.orig.img') $imgWin
'--- fsck orig ---'
& $fsck -fy $imgWin 2>&1 | Select-Object -Last 3

'--- deletions (single session, no data writes) ---'
$del = @(
    'cd /system/priv-app/Lawnchair/oat/x86_64',
    'rm Lawnchair.odex',
    'rm Lawnchair.vdex',
    'cd /system/priv-app/Lawnchair/oat',
    'rmdir x86_64',
    'cd /system/priv-app/Lawnchair',
    'rmdir oat',
    'rm Lawnchair.apk',
    'cd /system/priv-app/com.mumu.store',
    'rm com.mumu.store.apk',
    'cd /system/priv-app',
    'rmdir com.mumu.store',
    'cd /system/priv-app/com.mumu.acc',
    'rm com.mumu.acc.apk',
    'cd /system/priv-app',
    'rmdir com.mumu.acc',
    'cd /system/priv-app/com.netease.mumu.cloner',
    'rm com.netease.mumu.cloner.apk',
    'cd /system/priv-app',
    'rmdir com.netease.mumu.cloner',
    'cd /system/product/app/TrichromeChrome',
    'rm TrichromeChrome.apk',
    'cd /system/product/app',
    'rmdir TrichromeChrome',
    'cd /system/etc/user_app',
    'rm KernelSU.apk',
    'cd /system/etc',
    'rm hosts',
    'cd /system',
    'rm build.prop'
)
Dbg $del -Write | Where-Object { $_ -notmatch '^$' }

'--- fsck after deletions ---'
& $fsck -fy $imgWin 2>&1 | Select-Object -Last 4

'--- create dirs ---'
$mk = @(
    'cd /system/priv-app/Lawnchair',
    'mkdir lib',
    'cd /system/priv-app/Lawnchair/lib',
    'mkdir x86_64',
    'cd /system/app',
    'mkdir Via'
)
Dbg $mk -Write | Where-Object { $_ -notmatch '^$' }

$ops = @(
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libMTQ5ODQ1MTMz.so'; Src="$staging\lib\lib\x86_64\libMTQ5ODQ1MTMz.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libandroidx.graphics.path.so'; Src="$staging\lib\lib\x86_64\libandroidx.graphics.path.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libdatastore_shared_counter.so'; Src="$staging\lib\lib\x86_64\libdatastore_shared_counter.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libhoko_blur.so'; Src="$staging\lib\lib\x86_64\libhoko_blur.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libnrb.so'; Src="$staging\lib\lib\x86_64\libnrb.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libpl_droidsonroids_gif.so'; Src="$staging\lib\lib\x86_64\libpl_droidsonroids_gif.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libsentry-android.so'; Src="$staging\lib\lib\x86_64\libsentry-android.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair/lib/x86_64'; Name='libsentry.so'; Src="$staging\lib\lib\x86_64\libsentry.so"; Mode='0100644' },
    @{ Dir='/system/priv-app/Lawnchair'; Name='Lawnchair.apk'; Src="$staging\Lawnchair-upper.apk"; Mode='0100644' },
    @{ Dir='/system/app/Via'; Name='Via.apk'; Src="$staging\Via.apk"; Mode='0100644' },
    @{ Dir='/system/etc'; Name='hosts'; Src="$staging\hosts.new"; Mode='0100644' },
    @{ Dir='/system'; Name='build.prop'; Src="$staging\build.prop.new"; Mode='0100600' }
)

$i = 0
foreach ($op in $ops) {
    $i++
    $cyg = '/cygdrive/' + $op.Src.Substring(0,1).ToLower() + ($op.Src.Substring(2) -replace '\\','/')
    $cmds = @(
        ('cd ' + $op.Dir),
        ('write ' + $cyg + ' ' + $op.Name),
        ('sif ' + $op.Name + ' mode ' + $op.Mode),
        ('sif ' + $op.Name + ' uid 0'),
        ('sif ' + $op.Name + ' gid 0'),
        ('ea_set -f ' + $selinux + ' ' + $op.Name + ' security.selinux')
    )
    $out = Dbg $cmds -Write
    '[' + $i + '/' + $ops.Count + '] ' + $op.Dir + '/' + $op.Name
    $out | Where-Object { $_ -notmatch '^$' } | ForEach-Object { '    ' + $_ }
}

'--- fsck final ---'
& $fsck -fy $imgWin 2>&1 | Select-Object -Last 6
& $fsck -fn $imgWin 2>&1 | Select-Object -Last 4
