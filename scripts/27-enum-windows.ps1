Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WinEnum {
    public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    public static string Describe(IntPtr hWnd) {
        RECT r; GetWindowRect(hWnd, out r);
        StringBuilder t = new StringBuilder(256); GetWindowText(hWnd, t, 256);
        StringBuilder c = new StringBuilder(256); GetClassName(hWnd, c, 256);
        uint pid; GetWindowThreadProcessId(hWnd, out pid);
        return string.Format("hwnd=0x{0:X8} pid={1} vis={2} rect={3},{4},{5}x{6} class={7} title={8}",
            hWnd.ToInt64(), pid, IsWindowVisible(hWnd), r.Left, r.Top, r.Right-r.Left, r.Bottom-r.Top, c, t);
    }
}
"@
$targetPid = 22288
$found = New-Object System.Collections.Generic.List[IntPtr]
$cb = [WinEnum+EnumProc]{
    param($h, $l)
    $procId = 0
    [WinEnum]::GetWindowThreadProcessId($h, [ref]$procId) | Out-Null
    if ($procId -eq $targetPid) { $script:found.Add($h) }
    return $true
}
[WinEnum]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
'--- top-level windows ---'
foreach ($h in $found) { [WinEnum]::Describe($h) }
'--- child windows ---'
foreach ($h in $found) {
    $kids = New-Object System.Collections.Generic.List[IntPtr]
    $cb2 = [WinEnum+EnumProc]{
        param($c, $l)
        $script:kids.Add($c)
        return $true
    }
    [WinEnum]::EnumChildWindows($h, $cb2, [IntPtr]::Zero) | Out-Null
    foreach ($c in $kids) {
        $d = [WinEnum]::Describe($c)
        if ($d -match 'rect=(\d+),(\d+),(\d+)x(\d+)') {
            $w = [int]$matches[3]; $hh = [int]$matches[4]
            if ($w -gt 200 -and $hh -gt 200) { $d }
        }
    }
}
