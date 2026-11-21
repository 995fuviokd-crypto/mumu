# MuMu 6.0 真机化大改报告

日期：2026-11-21
对象：MuMu 6.0（6.8.11.0，Android 15，实例 `vivo V2284A`）

## 这次改了什么

### 1. 屏幕从横屏平板改成竖屏手机

原设置：

- `resolution_mode=tablet.1`
- 1600×900 @ 240dpi（横屏平板形态）

现设置：

- `resolution_mode=custom`
- 后期性能优化后为 **900×2000 @ 360dpi**（逻辑宽度约 400dp，20:9 竖屏手机；最初曾设 1080×2400 @420）
- `wm size` 验证：Physical size 900x2000
- `wm density` 验证：360

宿主玩家窗口随之变成竖屏手机比例，窗口标题 `vivo V2284A`。

### 2. 补全完整电话应用套件

原镜像只有相机、图库、设置、文件、浏览器，没有电话/短信/联系人/时钟/日历/计算器。已安装 6 个真实的开源电话应用（Fossify 官方 GitHub Releases，全部同一签名证书）：

| 应用 | 包名 | 版本 |
| --- | --- | --- |
| 电话 | `org.fossify.phone` | 1.11.1 |
| 信息 | `org.fossify.messages` | 1.10.2 |
| 联系人 | `org.fossify.contacts` | 1.6.0 |
| 时钟 | `org.fossify.clock` | 1.6.0 |
| 日历 | `org.fossify.calendar` | 1.12.2 |
| 计算器 | `org.fossify.math` | 1.4.0 |

- 来源：`github.com/FossifyOrg/*/releases`
- 签名证书 SHA-256：`affdb124d3f4720c2f98dbca9eacba0514fba4306e20a2786c861c3c0d6ff292`（六个 APK 一致）
- 安装方式：`adb install -r -g`（同时授予运行时权限）
- 默认角色：
  - `android.app.role.DIALER` → `org.fossify.phone`
  - `android.app.role.SMS` → `org.fossify.messages`
- 已补授权限：电话（联系人/通话/电话状态/通知）、信息（短信/联系人/通知）、联系人、时钟（精确闹钟/通知）、日历

### 3. 主屏重排成真机布局

桌面数据库：`/data/data/app.lawnchair/databases/launcher_7_4_4.db`

Dock（4 格）：

1. 电话（Fossify Phone）
2. 信息（Fossify Messages）
3. Via（`mark.via/.Shell`）
4. 相机（`com.android.camera2/com.android.camera.CameraLauncher`）

主屏第一页：

- 第一行：时钟、日历、计算器、联系人
- 第二行：设置、图库、文件

桌面仍然使用系统 Lawnchair（已去掉 MuMu 搜索框/启动广告），Via 仍是默认浏览器。竖屏下标签、图标、状态栏均正常。

## 为什么用 Fossify，而不是 AOSP 系统应用

- SDK 里的 API35 镜像是 **arm64-v8a**；标准 Android Emulator 37.3.10 在 x86_64 宿主上明确拒绝 ARM64 镜像（`Avd's CPU Architecture 'arm64' is not supported ...`）。
- MuMu 的宿主是 x86_64；把 ARM64 AOSP 应用硬塞进系统既不能保证签名/权限，也不是“真机”做法。
- 没有做换皮/仿制：Fossify 是活跃维护的真实开源应用，六个 APK 同一官方签名，功能和界面都是真实应用。

## 冷启动验证（08:55）

- `sys.boot_completed=1`
- `wm size` → 900x2000；`wm density` → 360（性能优化后的最终值）
- 六个应用 `pm path` 均在 `/data/app/...`
- `mark.via` → `/system/app/Via/Via.apk`
- `app.lawnchair` → `/system/priv-app/Lawnchair/Lawnchair.apk`
- HOME=`app.lawnchair`，BROWSER=`mark.via`，DIALER=`org.fossify.phone`，SMS=`org.fossify.messages`
- 桌面 rows 11 条，无残留小组件
- 点击电话/信息/时钟均能打开对应 `MainActivity`
- 无 FATAL EXCEPTION
- 截图：`D:\MuMuWork\work\mumu-final-phone.png`

## 回滚

### 恢复横屏平板

```
MuMuManager.exe setting --vmindex 0 --key resolution_mode --value tablet.1 --key resolution_width.custom --value 1600 --key resolution_height.custom --value 900 --key resolution_dpi.custom --value 240
```

然后 `MuMuManager.exe control --vmindex 0 shutdown` / `launch`。

### 卸载电话套件

```
adb uninstall org.fossify.phone
adb uninstall org.fossify.messages
adb uninstall org.fossify.contacts
adb uninstall org.fossify.clock
adb uninstall org.fossify.calendar
adb uninstall org.fossify.math
```

并移除 DIALER/SMS 角色、恢复桌面 dock（原来的设置/图库/文件/Via 四项）。桌面数据可清空后让 MuMu 默认布局重建，或从备份的 `launcher_7_4_4.db` 恢复。

### 恢复原来的主屏

原布局是 4 个 dock 图标（设置、图库、文件、Via），无工作区图标；删除现有 favorites 里 container=-100 的行即可回到类似状态。

## 说明

- 模拟器没有 SIM/telephony 射频，电话/短信界面可以正常打开和使用，但真实拨号/收发短信需要宿主侧电话能力；这是模拟器本身限制，不是应用问题。
- 6 个应用是用户应用（非 system），可以正常卸载/更新；如果要“预装进 system”，可以再把 APK 放进 `/system/priv-app`，但会牺牲可更新性，当前没这么做。
- 时钟小组件尝试过 1x2/4x2，实际渲染是黑底大表盘，不好看，已移除；主屏保持干净图标布局。
