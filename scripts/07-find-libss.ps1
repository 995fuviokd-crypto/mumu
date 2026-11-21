$ErrorActionPreference = 'Continue'
$candidates = @(
    'https://mirrors.kernel.org/sourceware/cygwin/x86_64/release/e2fsprogs/libss2-1.42.12-2.tar.xz',
    'https://mirrors.kernel.org/sourceware/cygwin/x86_64/release/e2fsprogs/libss2-1.42.12-1.tar.xz',
    'https://mirrors.kernel.org/sourceware/cygwin/x86_64/release/libss2/libss2-1.42.12-2.tar.xz',
    'https://mirrors.kernel.org/sourceware/cygwin/x86_64/release/libs/libss2-1.42.12-2.tar.xz',
    'https://mirrors.kernel.org/sourceware/cygwin/x86_64/release/e2fsprogs/libss-1.42.12-2.tar.xz'
)
foreach ($u in $candidates) {
    try {
        $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -TimeoutSec 30
        'OK ' + $r.StatusCode + ' ' + $r.Headers['Content-Length'] + ' ' + $u
    } catch {
        'NO ' + $u + ' :: ' + $_.Exception.Message
    }
}
'--- setup.ini ---'
$ini = Join-Path 'D:\MuMuWork\image-edit\tools\download' 'setup.ini'
if (-not (Test-Path $ini)) {
    curl.exe -L --fail --retry 2 -o $ini 'https://mirrors.kernel.org/sourceware/cygwin/x86_64/setup.ini'
}
if (Test-Path $ini) {
    Get-Item $ini | Select-Object Length | Format-Table -AutoSize | Out-String | Write-Output
    $lines = Select-String -Path $ini -Pattern 'libss|cygss|@ .*ss' -SimpleMatch:$false
    $lines | Select-Object -First 20 | ForEach-Object { $_.Line } | Write-Output
    $idx = (Select-String -Path $ini -Pattern '^@ libss2' | Select-Object -First 1)
    if ($idx) {
        $all = Get-Content $ini
        $start = $idx.LineNumber - 1
        $all[$start..([Math]::Min($start + 30, $all.Count - 1))] | Write-Output
    }
}
