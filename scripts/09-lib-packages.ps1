$ErrorActionPreference = 'Continue'
$ini = 'D:\MuMuWork\image-edit\tools\download\setup.ini'
$all = Get-Content $ini
$targets = @('libext2fs2','libe2p2','libcom_err2','libblkid1','libuuid1','libss2','cygwin')
foreach ($t in $targets) {
    $hits = Select-String -Path $ini -Pattern ('^@ ' + [regex]::Escape($t) + '$')
    if (-not $hits) { 'NOT FOUND: ' + $t; continue }
    $start = $hits[0].LineNumber - 1
    '===== ' + $t + ' ====='
    $all[$start..([Math]::Min($start + 60, $all.Count - 1))] | Where-Object { $_ -match '^(version|install|depends2):' } | Select-Object -First 12
}
