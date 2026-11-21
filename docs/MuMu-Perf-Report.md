# MuMu 6.0 深度性能优化报告

日期：2026-11-21
对象：MuMu 6.0（6.8.11.0，Android 15，实例 `vivo V2284A`）

## 宿主环境

- CPU：Intel Xeon E5-2678 v3，12 核 24 线程，2.5GHz
- 内存：68.6GB
- GPU：NVIDIA GeForce GTX 1060 5GB，驱动 32.0.15.8180
- 电源计划：高性能（已是）
- MuMu 玩家进程：`MuMuNxDevice` 优先级已设为 High（每次 VM 重启后需重设）

## MuMu 资源调整

| 项目 | 优化前 | 优化后 |
| --- | --- | --- |
| CPU | 4 核 | **8 核** |
| 内存 | 4GB | **8GB** |
| 性能模式 | middle | **custom (8C/8GB)** |
| GPU 模式 | middle（Adreno 640 伪装） | **high（Adreno 740 伪装）** |
| 渲染器 | vk | vk（保留） |
| 帧率上限 | 60 | 60 |
| 动态帧率 | 关闭 | 关闭 |
| 分辨率 | 1080×2400 @420（259 万像素） | **900×2000 @360（180 万像素，-30.6%）** |

分辨率仍然保持约 400dp 逻辑宽度，竖屏手机布局不变，只是像素填充量减少约三成。

## 客户机优化

- **ART speed 全量编译**（10 个包）：
  - `app.lawnchair`、`mark.via`、`com.android.settings`、`com.android.systemui`
  - `org.fossify.phone/messages/contacts/clock/calendar/math`
- **动画缩放归零**：window / transition / animator 全部 0
- **关闭窗口模糊**：`disable_window_blurs=1`，减少 GPU 合成开销
- **HWUI 渲染器切到 SkiaGL**：`debug.hwui.renderer=skiagl`，在 MuMu 虚拟 GPU 上比默认 Vulkan 更稳、部分场景更快
- **CPU governor**：已是 `performance`
- **持久化**：以上设置写入 KernelSU 模块 `/data/adb/modules/mumu_noads/post-fs-data.sh` 和 `service.sh`，冷启动自动恢复
  - `resetprop -n debug.hwui.renderer skiagl`
  - `settings put global window_animation_scale 0` 等

## 前后对比（冷启动耗时）

测量方式：`am force-stop <pkg>` 后 `am start -W -n <component>`，取 `TotalTime`。
基线是 4 核/4GB、1080×2400、动画 0.5、Vulkan；优化后是 8 核/8GB、900×2000、动画 0、模糊关闭、speed 编译 + SkiaGL。

| 应用 | 优化前 | 优化后（3 次平均） | 变化 |
| --- | --- | --- | --- |
| Via | 1364ms | **963ms** | **-29.4%** |
| 设置 | 1253ms | **1161ms** | **-7.3%** |
| 电话 | 1377ms | **922ms** | **-33.1%** |
| 信息 | 953ms | **880ms** | **-7.7%** |

说明：

- 表格是系统稳定运行后的冷启动数据；**冷启动后的第一次启动**会慢一些（约 1.3–1.4s），因为页缓存还是冷的。
- 启动耗时里包含 MuMu TaskTab 的副显示接管开销，这部分不是应用本身能优化的。
- 内存：8GB 总量，稳定占用约 1.3–1.4GB，空闲约 6.6GB；swap 未使用。
- 关机+重新启动到 `is_android_started` 的等待约 31–34 秒（不是精确内核启动时间）。
- UI 验证截图：`D:\MuMuWork\work\mumu-perf-home2.png`

## 各项优化的作用

- **8 核/8GB**：应用冷启动提升约 3–10%，后台驻留更宽裕（`app_keptlive` 可保留更多应用）。
- **分辨率 -30% 像素**：直接减少 GPU 填充和合成压力，对滑动/动画/多任务切换更明显；启动耗时影响较小。
- **ART speed 编译**：稳定后 Via/设置启动明显变快；首次编译后的第一次启动可能因 I/O 反而略慢。
- **SkiaGL**：实测 Via 约 -4%、信息约 -7%，无渲染异常；如果某个应用出现图形问题，可回退默认。
- **动画 0 + 关模糊**：主要提升“手感”和合成效率，不改变 `TotalTime`。
- **宿主进程 High 优先级**：降低后台 Windows 任务抢占；不是持久设置。

## 可以继续加的选项

- 更激进：分辨率降到 **720×1600 @320**（像素再 -36%），但文字/图标会明显变软。
- 更清晰：回到 1080×2400 @420，性能会退回一部分。
- 把宿主 `MuMuNxDevice` 优先级用计划任务在每次启动时自动设为 High。
- 将 Windows Defender 对 MuMu 安装目录/VDI 做排除（会降低安全性，未做）。

## 回滚

### 恢复 MuMu 资源设置

```
MuMuManager.exe setting --vmindex 0 --key performance_mode --value middle --key performance_cpu.custom --value 4 --key performance_mem.custom --value 4 --key gpu_mode --value middle --key resolution_mode --value custom --key resolution_width.custom --value 1080 --key resolution_height.custom --value 2400 --key resolution_dpi.custom --value 420
```

然后 `MuMuManager.exe control --vmindex 0 shutdown` / `launch`。

### 恢复客户机默认

- 删除 `mumu_noads` 两个脚本里的性能行（`debug.hwui.renderer`、动画、模糊）。
- 动画恢复：`settings put global window_animation_scale 0.5` 等；模糊恢复 `disable_window_blurs 0`。
- `debug.hwui.renderer` 是 debug 属性，重启后自动恢复默认。
- 取消 ART 编译：`cmd package compile --reset <pkg>`（对 10 个包）。
- 宿主优先级：`(Get-Process MuMuNxDevice).PriorityClass = 'Normal'`。

## 结论

在不牺牲竖屏真机形态的前提下，CPU/内存翻倍、GPU 提到高档、渲染像素减少 30%，配合 ART 编译和 SkiaGL，常用应用冷启动提升约 7%–33%。设置已通过冷启动验证并持久化。

## 根因分析（为什么调参到了上限）

- 客户机 `ro.product.cpu.abi=x86_64`，`abilist=x86_64,arm64-v8a,x86`；Via 无 native-code，Fossify/Lawnchair/SystemUI/WebView 的 `primaryCpuAbi` 都是 `x86_64`。**应用全部走原生 x86_64，没有 ARM 翻译开销**，`libnb` 只服务 ARM-only 应用。
- 宿主磁盘是 Samsung SSD 870 EVO；GTX 1060 利用率约 4%（711MiB/5GiB）。**I/O 和 GPU 都不是瓶颈**。
- 剩余瓶颈是 **CPU 单线程 + MuMu Android 15 的 system_server/TaskTab**。宿主 Xeon E5-2678 v3 是 2014 年的 12 核，2.5GHz，单核性能有限。
- 实测 TaskTab 开销（普通启动 vs `am start --display 0` 强制主显示）：
  - Via：1024ms → 878ms（**-14%**）
  - 设置：1166ms → 1044ms（**-10%**）
  - TaskTab 没有公开开关；`persist.tab_manager.use_vaddress=false` 没有关闭它，反而让 TaskTab 抛异常，已回滚 `true`。
- 其他根因实验（均已回滚）：
  - 12 vCPU：3 次平均无稳定提升（Via 1145 / 设置 1384 / 电话 953），回 8 核。
  - 禁用 `com.mumu.shared.sdk`：冷启动无稳定收益，且会丢 MuMu 登录/商店相关能力，已恢复启用。
  - `renderer_strategy=perf`：无提升，回 `auto`。
  - 8 核/8GB、900×2000、SkiaGL、ART 编译、动画 0、关模糊：保留。

## 真正的根本方案（按可行性排序）

1. **真机 / 云真机**（OPPO 云机器、Firebase Test Lab 等）：原生 ARM SoC，绝对性能最好，也是唯一能真正跨过这层天花板的方式；需要账号/付费/网络，无法在本机离线完成。
2. **MuMu Android 12 引擎**：更轻，可能更快；当前只安装了 15.0 引擎，需要下载 12 引擎并重做全部去 MuMu/桌面/电话套件定制，工作量大，且 Android 版本从 15 降到 12。
3. **给 `services.jar` 打补丁禁用 TaskTab**：可拿回 10–14% 启动提升，但改的是 system_server 启动类，风险高（可能 bootloop），需要 `system.vdi.bak` 兜底。
4. **宿主 CPU 升级**：单核性能是硬上限，换现代 CPU 提升最大，但属于硬件方案。

### TaskTab 绕过实验（已回滚）

- 在桌面 APK 的 `ActivityOptionsWrapper.toBundle()` 里强制 `setLaunchDisplayId(0)`，只替换 classes4.dex（apktool 035 → 手动升 039），classes5 保留原有搜索/广告补丁，平台重签。
- 结果：应用确实直接开在主显示（截图确认，不再是 TaskTab 页），Via 暖启动 933ms/1.03s、电话 966–973ms；与稳定基线（Via 963ms、电话 922ms）没有可靠提升，且 TaskTab 持续输出异常栈。
- 按“做完美”标准回滚到 `lawnchair-final2.apk`，TaskTab 保持原状；实验 APK 留在 `D:\MuMuWork\lawnchair-tasktab.apk` 备查。
- 附带发现：`input keyevent 3` 在应用内回不到桌面（Via/电话都一样，属 MuMu 输入映射的既有问题；`am start HOME` 或 MuMu 工具栏可用）。

## 当前最终配置（稳定，已回滚失败实验）

- MuMu：8 核 / 8GB / GPU high / 900×2000 @360 / vk / 60fps
- 客户机：SkiaGL、动画 0、关窗口模糊、ART speed 编译 10 个包、governor=performance
- 宿主：SSD、电源高性能、MuMuNxDevice 优先级 High（VM 重启后需重设）
- 稳定冷启动：Via ≈0.96s、设置 ≈1.16s、电话 ≈0.92s、信息 ≈0.88s
- 失败实验均已回滚：`persist.tab_manager.use_vaddress=true`、`com.mumu.shared.sdk` 启用、`renderer_strategy=auto`、8 核、TaskTab 绕过（final2 稳定版）。
