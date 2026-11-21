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