Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public class WinCap {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT r);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint flags);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    public static string Capture(IntPtr hwnd, string path) {
        if (!IsWindow(hwnd)) return "not a window";
        RECT r;
        GetWindowRect(hwnd, out r);
        int w = r.Right - r.Left;
        int h = r.Bottom - r.Top;
        if (w <= 0 || h <= 0) { GetClientRect(hwnd, out r); w = r.Right; h = r.Bottom; }
        if (w <= 0 || h <= 0) return "zero size";
        using (Bitmap bmp = new Bitmap(w, h))
        using (Graphics g = Graphics.FromImage(bmp)) {
            IntPtr hdc = g.GetHdc();
            bool ok = PrintWindow(hwnd, hdc, 2);
            g.ReleaseHdc(hdc);
            bmp.Save(path, ImageFormat.Png);
            return "ok=" + ok + " size=" + w + "x" + h + " visible=" + IsWindowVisible(hwnd);
        }
    }
}
"@ -ReferencedAssemblies System.Drawing
$outdir = 'D:\MuMuWork\image-edit'
foreach ($pair in @(@('display', 0x004304C0))) {
    $name = $pair[0]
    $hwnd = [IntPtr]::new([int64]$pair[1])
    $path = Join-Path $outdir ('screen-' + $name + '.png')
    if (Test-Path $path) { Remove-Item $path -Force }
    $res = [WinCap]::Capture($hwnd, $path)
    $name + ': ' + $res
    if (Test-Path $path) { Get-Item $path | Select-Object Length | Format-Table -AutoSize | Out-String }
}
