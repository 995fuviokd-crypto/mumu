# Momo（io.github.vvb2060.mahoshojo）闪退定位与处理

日期：2026-11-21
环境：MuMu 6.8.11.0 / Android 15 / x86_64 + libnb（houdini）
App：Momo 4.4.1（versionCode 23，targetSdk 33，签名 CN=Magic Detector，DSA）

---

## 1. 现象

点击 Momo 图标后约 1 秒进程死亡，界面不出现。

崩溃栈（每次完全一致）：

```
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0
tid ... (DefaultDispatch)  pid ... (b2060.mahoshojo)
#00 pc 0x1bdd3  base.apk!libmahoshojo.so
Cause: null pointer dereference
```

`DefaultDispatch` 是 Linux 对 Kotlin 协程线程名 `DefaultDispatcher` 的 15 字符截断，即崩溃发生在协程里调用 native 方法时。

---

## 2. 反汇编结论

`libmahoshojo.so`（x86_64，OLLVM 控制流平坦化，导出 139 个 `decrypt.<hash>` + `JNI_OnLoad`）：

崩溃指令：

```
0x1bdbc  mov rax, [rel 0x25880]     ; rax = 全局表指针
0x1bdc3  lea rcx, [rbp*8]
0x1bdd3  mov rax, [rcx+rax]         ; 表指针为 0 → 读地址 0 → SIGSEGV
```

崩溃时 `rax=0, rcx=0`。`0x25880` 位于 `.bss`，由 `0x19eb9`（解密循环内）写入，说明该**解密/符号表从未被初始化**。

Java 侧对应调用链：

- `App` 有 3 个 native 方法：`check([B)V`、`get(I)I`、`get2(I)Ljava/lang/String;`
- `Ff.a()`（结果渲染，协程）在“应用完好”分支里直接调用 `App.check(randomUUID 字节)`
- `App.get/get2` 的调用方是 `Gi`（Binder 服务端，运行在 `MahoService` 隔离进程）和检测引擎 `Ei/zi`

即：**native 表在首次 `get()/get2()` 时惰性初始化；UI 进程从未调用过 get()，却在 check() 里直接使用该表**。在 `HomeActivity.onCreate` 最前面人为调用一次 `App.get(0)` 后，同样的 `check()` 正常返回，进程不再崩溃——这条实验直接证明上述结论。

---

## 3. 已排除的环境因素（逐项实测）

| 猜测 | 做法 | 结果 |
| --- | --- | --- |
| APK 内加载导致自定位失败 | 把 `libmahoshojo.so` 放到 `/data/app/.../lib/x86_64`，让 linker 优先加载真实文件（崩溃栈地址变为该路径） | 仍崩，同一 PC |
| ABI/翻译层问题 | 分别以 `--abi x86_64`、`--abi arm64-v8a`（houdini 翻译）安装 | 两种都崩，同一初始化阶段 |
| qemu/vbox 属性 | `resetprop` 改 `ro.build.hv.platform`、`ro.kernel.qemu` | 仍崩 |
| 安全补丁过期告警 | `resetprop ro.build.version.security_patch=2026-10-05` | 仍崩 |
| SELinux Permissive | `setenforce 1` | 仍崩 |
| READ_LOGS 权限（native 导入 `android_logger_*`） | `pm grant android.permission.READ_LOGS` | 仍崩 |
| 初始化竞态 | 连续强杀重启 5 次 | 100% 同一 PC，确定性 |
| 签名/改包 | 只重签原始 APK（不动代码） | **不崩**，进入“环境损坏/签名验证失败”分支，跳过 check() |

strace（通过 `wrap.<pkg>` 注入，原始签名版本）显示崩溃前**没有任何失败的系统调用**，进一步说明不是“某个 check 失败”，而是初始化分支根本没走到。

---

## 4. 代码分支（为什么重签能绕过）

`Ff.a()` 中：

```
v4 = (Fi.a != 0)
v9 = Fi.w
if (v4 == 0) goto cond_4      // 跳过
if (v9 == 0) goto cond_4      // 跳过
... 显示卡片 + App.check(uuid) ...
```

- 原始签名（App 自检通过）：`Fi.a != 0` → 进入分支 → `check()` → 空表 → 崩溃
- 重签（App 判定“环境损坏”）：`Fi.a == 0` → 跳过分支 → 不崩，显示“环境损坏 / 签名验证失败”

因此这不是模拟器检测触发的“自杀”，而是 **App 自身在“完好”分支上的初始化顺序缺陷**；当前环境只是让它走到了这条分支。

---

## 5. 目前采用的处理

**只重签、不改任何代码**的原始 APK：

- `D:\MuMuWork\momo\momo-resigned.apk`
- 已安装并验证：连续 3 次启动存活，界面可交互，检测页正常显示（系统指纹、安全补丁级别、背景说明等）
- 唯一副作用：首卡片显示“环境损坏 / 签名验证失败”（因为签名确实被换掉）

已验证的两种进一步方案（未采用）：

1. **改 App**：在 `HomeActivity.onCreate` 注入 `App.get(0)` 预热（已做出 `momo-patched.apk` 并验证可用）；若同时改掉签名校验，还能让首卡片显示正常，但那是让检测工具谎报自身状态。
2. **运行时注入**：Frida/LSPosed 在启动时调用 `App.get(0)`，可保留原始签名；但 Momo 本身集成 XposedDetector/NativeDetector，注入框架极可能被它自己检出，且需要常驻服务。

---

## 6. 结论

- 该闪退**不是环境检测导致的**，也没有某个“环境开关”能修好：qemu/vbox 属性、补丁日期、SELinux、ABI、库加载方式、日志权限全部实测无效。
- 根因是 Momo 4.4.1 的 native 引擎惰性初始化缺陷，在“应用完好”分支被触发。
- 在不改 App 代码的前提下，重签是唯一稳定的规避方式；代价是 App 自报签名异常。
- 若要求“原签名 + 无异常卡片”，必须修改 App 或引入运行时注入，两者都有代价（前者改变 App 完整性状态，后者可能被检测）。
