Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public class WinShot {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr lp);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    public static string Capture(string path) {
        IntPtr target = IntPtr.Zero;
        EnumWindows((h, l) => {
            StringBuilder t = new StringBuilder(256); GetWindowText(h, t, 256);
            string s = t.ToString();
            if (s.Contains("vivo") || s.Contains("MuMu")) {
                RECT r; GetWindowRect(h, out r);
                if (r.Right - r.Left > 300) { target = h; return false; }
            }
            return true;
        }, IntPtr.Zero);
        if (target == IntPtr.Zero) return "no window";
        ShowWindow(target, 9);
        SetWindowPos(target, IntPtr.Zero, 100, 100, 0, 0, 0x0001);
        SetForegroundWindow(target);
        System.Threading.Thread.Sleep(1500);
        RECT wr; GetWindowRect(target, out wr);
        RECT cr; GetClientRect(target, out cr);
        POINT p = new POINT(); p.X = 0; p.Y = 0; ClientToScreen(target, ref p);
        int w = cr.Right - cr.Left; int hgt = cr.Bottom - cr.Top;
        if (w <= 0 || hgt <= 0) return "zero client";
        using (Bitmap bmp = new Bitmap(w, hgt))
        using (Graphics g = Graphics.FromImage(bmp)) {
            g.CopyFromScreen(p.X, p.Y, 0, 0, new Size(w, hgt));
            bmp.Save(path, ImageFormat.Png);
        }
        return "ok hwnd=0x" + target.ToInt64().ToString("X") + " client=" + w + "x" + hgt + " at " + p.X + "," + p.Y;
    }
}
"@ -ReferencedAssemblies System.Drawing
$path = 'D:\MuMuWork\momo\host-shot.png'
if (Test-Path $path) { Remove-Item $path -Force }
[WinShot]::Capture($path)
if (Test-Path $path) { Get-Item $path | Select-Object Length | Format-Table -AutoSize | Out-String }
