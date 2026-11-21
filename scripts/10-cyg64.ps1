$ErrorActionPreference = 'Continue'
$root = 'D:\MuMuWork\image-edit\tools\cyg64'
New-Item -ItemType Directory -Force $root | Out-Null
$ini = 'D:\MuMuWork\image-edit\tools\download\setup.ini'
$all = Get-Content $ini
$seven = 'D:\MuMuWork\image-edit\tools\7zr.exe'
$baseUrl = 'https://mirrors.kernel.org/sourceware/cygwin/'
$dl = 'D:\MuMuWork\image-edit\tools\download'

function Get-InstallPath([string]$pkg) {
    $hit = Select-String -Path $ini -Pattern ('^@ ' + [regex]::Escape($pkg) + '$') | Select-Object -First 1
    if (-not $hit) { return $null }
    $start = $hit.LineNumber
    for ($i = $start; $i -lt [Math]::Min($start + 80, $all.Count); $i++) {
        if ($all[$i] -match '^install:\s+(\S+)') { return $matches[1] }
    }
    return $null
}

$packages = @('cygwin','libgcc1','libintl8','libiconv2','libzstd1','zlib0','libext2fs2','libe2p2','libcom_err2','libss2','libblkid1','libuuid1')
foreach ($pkg in $packages) {
    $rel = Get-InstallPath $pkg
    if (-not $rel) { 'NO INSTALL PATH: ' + $pkg; continue }
    $name = Split-Path $rel -Leaf
    $pkgFile = Join-Path $dl $name
    if (-not (Test-Path $pkgFile)) {
        'download ' + $rel
        curl.exe -L --fail --retry 3 -o $pkgFile ($baseUrl + $rel) 2>&1 | Select-Object -Last 2 | Out-Null
    }
    if (-not (Test-Path $pkgFile)) { 'FAILED DOWNLOAD: ' + $pkg; continue }
    $ex = Join-Path $root $pkg
    if (-not (Test-Path (Join-Path $ex '.done'))) {
        if (Test-Path $ex) { Remove-Item $ex -Recurse -Force }
        New-Item -ItemType Directory -Force $ex | Out-Null
        & $seven x $pkgFile ('-o'+$ex) -y 2>&1 | Select-Object -Last 2 | Out-Null
        $tar = Join-Path $ex ([IO.Path]::GetFileNameWithoutExtension($name))
        if (Test-Path $tar) { $null = tar -xf $tar -C $ex 2>&1 }
        New-Item -ItemType File -Path (Join-Path $ex '.done') -Force | Out-Null
    }
    $dlls = Get-ChildItem $ex -Recurse -Filter '*.dll' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    ($pkg + ' -> ' + ($dlls -join ', ')) | Write-Output
}

'--- PATH DLL dirs ---'
$dirs = Get-ChildItem $root -Directory | ForEach-Object { Join-Path $_.FullName 'usr\bin' } | Where-Object { Test-Path $_ }
$dirs | Write-Output
$env:PATH = ($dirs -join ';') + ';' + $env:PATH
'--- debugfs 1.44.5 ---'
$dbg = 'D:\MuMuWork\image-edit\tools\e2fsprogs\usr\sbin\debugfs.exe'
$out = & $dbg -V 2>&1
'exit=' + $LASTEXITCODE
$out | Out-String | Write-Output
'--- list root ---'
$img = 'D:/MuMuWork/image-edit/part-root.img'
$out2 = & $dbg -R 'ls -l /' $img 2>&1
'exit=' + $LASTEXITCODE
$out2 | Select-Object -First 80 | Out-String | Write-Output
