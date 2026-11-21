$ErrorActionPreference = 'Continue'
$mgr = 'D:\Program Files\Netease\MuMu\nx_main\MuMuManager.exe'
$info = (& $mgr info --vmindex 0 2>&1 | Out-String)
$info
$mw = ''
if ($info -match '"main_wnd"\s*:\s*"([0-9A-Fa-f]+)"') { $mw = $matches[1] }
'main_wnd=' + $mw
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public class Shot2 {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    public static string Capture(long hwndVal, string path) {
        IntPtr h = new IntPtr(hwndVal);
        if (!IsWindow(h)) return "not a window";
        ShowWindow(h, 9);  // SW_RESTORE
        ShowWindow(h, 5);  // SW_SHOW
        SetWindowPos(h, IntPtr.Zero, 40, 40, 0, 0, 0x0001 | 0x0040);
        SetForegroundWindow(h);
        System.Threading.Thread.Sleep(2000);
        RECT cr; GetClientRect(h, out cr);
        POINT p = new POINT(); p.X = 0; p.Y = 0; ClientToScreen(h, ref p);
        int w = cr.Right - cr.Left; int hh = cr.Bottom - cr.Top;
        if (w <= 0 || hh <= 0) return "zero client " + w + "x" + hh;
        using (Bitmap bmp = new Bitmap(w, hh))
        using (Graphics g = Graphics.FromImage(bmp)) {
            g.CopyFromScreen(p.X, p.Y, 0, 0, new Size(w, hh));
            bmp.Save(path, ImageFormat.Png);
        }
        return "ok client=" + w + "x" + hh + " at " + p.X + "," + p.Y;
    }
}
"@ -ReferencedAssemblies System.Drawing
if ($mw) {
    $path = 'D:\MuMuWork\momo\player-shot.png'
    if (Test-Path $path) { Remove-Item $path -Force }
    [Shot2]::Capture([Convert]::ToInt64($mw, 16), $path)
    if (Test-Path $path) { Get-Item $path | Select-Object Length | Format-Table -AutoSize | Out-String }
}
