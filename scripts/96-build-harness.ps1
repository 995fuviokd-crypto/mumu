$ErrorActionPreference = 'Continue'
$d = 'D:\MuMuWork\momo\harness'
New-Item -ItemType Directory -Force $d | Out-Null
$java = @'
import java.lang.reflect.Method;

public class H {
    public static void main(String[] args) throws Throwable {
        String mode = args.length > 0 ? args[0] : "cold";
        System.load("/data/local/tmp/libmahoshojo.so");
        Class<?> app = Class.forName("io.github.vvb2060.mahoshojo.App");
        Method get = app.getDeclaredMethod("get", int.class);
        get.setAccessible(true);
        Method check = app.getDeclaredMethod("check", byte[].class);
        check.setAccessible(true);
        if (mode.equals("warm")) {
            System.out.println("HARNESS warm get(0)=" + get.invoke(null, 0));
        } else {
            System.out.println("HARNESS cold (no get)");
        }
        check.invoke(null, (Object) "11111111-2222-3333-4444-555555555555".getBytes("UTF-8"));
        System.out.println("HARNESS check returned OK, mode=" + mode);
        if (mode.equals("cold")) {
            System.out.println("HARNESS post-check get(0)=" + get.invoke(null, 0));
        }
    }
}
'@
$src = Join-Path $d 'H.java'
[IO.File]::WriteAllText($src, $java, (New-Object Text.UTF8Encoding($false)))
$env:JAVA_HOME = 'D:\MuMuWork\ColorTheme\incoming\jdk\extracted\jdk-21.0.13.1+2'
$bt = 'D:\MuMuWork\ColorTheme\incoming\buildtools\extracted\android-15'
'--- javac ---'
& (Join-Path $env:JAVA_HOME 'bin\javac.exe') -source 8 -target 8 -d $d $src 2>&1 | Out-String
'--- d8 ---'
$classes = Join-Path $d 'classes'
if (Test-Path $classes) { Remove-Item $classes -Recurse -Force }
New-Item -ItemType Directory -Force $classes | Out-Null
& (Join-Path $bt 'd8.bat') --min-api 26 --output $classes (Join-Path $d 'H.class') 2>&1 | Out-String
Get-ChildItem $classes | Select-Object Name,Length | Format-Table -AutoSize | Out-String
$adb = 'D:\MuMuWork\ColorOSLab\sdk\platform-tools\adb.exe'
& $adb -s emulator-5554 push (Join-Path $classes 'classes.dex') /data/local/tmp/h.dex 2>&1 | Out-Null
& $adb -s emulator-5554 push 'D:\MuMuWork\momo\apk\lib\x86_64\libmahoshojo.so' /data/local/tmp/libmahoshojo.so 2>&1 | Out-Null
& $adb -s emulator-5554 shell ls -l /data/local/tmp/h.dex /data/local/tmp/libmahoshojo.so 2>&1 | Out-String
