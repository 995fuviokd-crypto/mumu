# MuMu 6.0 去模拟器化 · 镜像级改动报告

日期：2026-11-21
对象：MuMu 6.0（产品版本 6.8.11.0，Android 15，实例 `MuMuPlayer-15.0-0`，adb `127.0.0.1:16384`）

## 目标

- 去掉 MuMu 自带的内置广告（宿主 + 客户机）
- 让系统/桌面看起来像真机，而不是模拟器
- 重点是用户点名的：搜索框、多开，以及正常手机不会有的明显 MuMu UI

## 已完成的镜像级改动

### 1. 桌面 APK 字节级补丁（Lawnchair 15.0.0.7）

原厂桌面把搜索栏和广告直接编进了 APK：

- `res/layout/mumu_search_bar_view.xml`：搜索栏，内含 `searchAdListView` 广告列表
- `res/layout/mumu_startup_ad.xml`：桌面启动广告
- `r7.i.c(Launcher)`：搜索栏的唯一挂载点（`addView` 到 drag_layer）
- `com.mumu.core.ad.a.h(Launcher)`：启动广告入口

处理方式（最小改动，保留原 dex 039 与全部资源字节）：

- 把 `r7.i.c` 的首条指令改成 `return-void`，其余指令置 nop
- 把 `com.mumu.core.ad.a.h` 的首条指令改成 `return-void`，其余指令置 nop
- 只替换 `classes5.dex`；其余 4 个 dex、`resources.arsc`、全部 `res/` 条目原样保留（包含 Windows 大小写不敏感会互相覆盖的 `res/9B.xml` 与 `res/9b.xml`）
- 用 AOSP platform testkey 重签，证书 SHA-256 `c8a2e9bccf597c2fb6dc66bee293fc13f2fc47ec77bc6b2b0d52c11f51192ab8`，与原厂签名完全一致，保留平台签名和 priv-app 权限
- 部署到 `/system/priv-app/Lawnchair/Lawnchair.apk`
- 原厂 `lib/x86_64/*.so` 放到 `/system/priv-app/Lawnchair/lib/x86_64/`

### 2. 移除 MuMu 应用与桌面推广项

- 已移除系统里的 `com.mumu.store`（商店）、`com.mumu.acc`（账号）、`com.netease.mumu.cloner`（多开）
- 桌面数据库 `launcher_4_7_4.db` 中删除 MuMu 写入的推广幽灵项：
  - Chrome / Amaze（`mumu_item_type=1000`，下载地址 `adl.easebar.com`，永远卡在“正在安装 0%”）
  - “小工具”文件夹
- 当前桌面只保留 dock 的 4 个图标：设置、图库、文件、浏览器

### 3. KernelSU 图标与开机安装源

- 完整卸载 `me.weishu.kernelsu`
- 找到并删除 MuMu 每次开机的安装源 `/system/etc/user_app/KernelSU.apk`
  - `/vendor/etc/init/hw/init.kona.rc:74` 每次开机执行 `pm install --user 0 /system/etc/user_app/KernelSU.apk`
- 备份 APK：`D:\MuMuWork\backup\mumu-apps\me.weishu.kernelsu.apk`
- 说明：卸载的是管理器 App；KernelSU 内核驱动、`/data/adb` 模块和 root 仍然工作，`mumu_noads` 的 hosts 拦截仍然生效（`/system/etc/hosts` 仍 bind 自 `/adb/modules/mumu_noads/hosts`）

### 4. 壁纸

- 原壁纸是 MuMu 太空 + 大 M logo（系统默认/回退壁纸）
- 当前壁纸是 **vivo OriginOS 内置壁纸（VIVO12，来源 `github.com/kelecn/Built-in-wallpaper` 的 VIVO 目录）**，裁切为 900×2000 后通过临时工具 APK 的 `WallpaperManager.setBitmap` 写入
- `dumpsys wallpaper` 显示 `mBindSource=SET_STATIC`，冷启动后保持
- 工具 APK 已卸载；桌面数据库里没有残留 WPSet 图标

### 5. 冷启动桌面注册修复

现象：MuMu 的 `/system` overlay upperdir 每次冷启动会重建，PackageManager 冷启动扫描时看不到只存在于 upperdir 的 Lawnchair，于是误判“系统包不存在”并清空桌面数据；框架重启才能扫到。

修复：KernelSU 模块 `/data/adb/modules/lawnchair_preload/`：

- `post-fs-data.sh` 在 system_server 之前执行
- 从 `/data/local/lawnchair/Lawnchair.apk` 和 `lib/x86_64/*.so` 预置到 `/system/priv-app/Lawnchair/`
- 证据：`/data/local/lawnchair/preload.log` 每次开机记录 `apk copied`；冷启动后无需框架重启，`pm path app.lawnchair` 直接为 `/system/priv-app/Lawnchair/Lawnchair.apk`

### 6. 内置浏览器替换为 Via

- 原内置浏览器：`com.android.chromium`（`/system/product/app/TrichromeChrome`），同时是默认浏览器角色 holder
- 已删除 `/system/product/app/TrichromeChrome`，Chromium 不再注册
- Via 官方 APK：`https://res.viayoo.com/v1/via-release-cn.apk`
  - 包名 `mark.via`，版本 7.4.1（versionCode 20261113）
  - 启动 Activity：`mark.via.Shell`
  - 证书 SHA-1 `af5d11b1703127167e23b45fa706f0dd9865499b`，与官方发布一致
- 安装为系统应用：`/system/app/Via/Via.apk`
- 默认浏览器角色：`mark.via`（注册时系统自动设为 `android.app.role.BROWSER` holder）
- 桌面 dock 第 4 格（原浏览器位置）更新为 Via，intent 显式指向 `mark.via/.Shell`，标题 `Via`
- WebView 不受影响：系统 WebView provider 是独立的 `com.android.webview` 110.0.5481.154.1
- 冷启动后：Via 仍在 `/system/app/Via/Via.apk`，Chromium 不存在，BROWSER role 仍为 `mark.via`，dock 图标点击打开 `mark.via/mark.via.Shell`

## 验证结果（2026-11-21 07:36，冷启动后）

- `sys.boot_completed=1`
- `pm path app.lawnchair` → `package:/system/priv-app/Lawnchair/Lawnchair.apk`
- `pkgFlags=[ SYSTEM ... ]`，`privatePkgFlags=[ ... PRIVILEGED ... ]`
- HOME role：`app.lawnchair`
- 桌面 UI：无 `mumu_search_bar`，无 KernelSU，无“小工具”文件夹/Chrome/Amaze 幽灵项
- 壁纸：`mBindSource=SET_STATIC`
- 系统 APK md5：`478fd6fac77f1556b9bba429213a16d6`
- 浏览器：dock 第 4 格为 Via（`mark.via`），点击打开 `mark.via/mark.via.Shell`；Chromium 已移除；BROWSER role = `mark.via`
- 截图：`D:\MuMuWork\work\mumu-final4-home.png`、`D:\MuMuWork\work\mumu-via-cold-home2.png`

## 回滚

### 恢复原厂桌面

```
adb push D:\MuMuWork\backup\mumu-apps\Lawnchair.apk /system/priv-app/Lawnchair/Lawnchair.apk
adb shell rm -rf /data/adb/modules/lawnchair_preload
adb shell sync
```

然后重启。原厂 APK 内部已含原生库，`/system/priv-app/Lawnchair/lib` 可留可删。

### 整盘回滚

恢复 `D:\MuMuWork\backup\system.vdi.bak`，会丢掉 Phase 3 的全部改动（包括去广告、桌面补丁、壁纸、KernelSU 变更）。

### 恢复 KernelSU 管理器

```
adb install D:\MuMuWork\backup\mumu-apps\me.weishu.kernelsu.apk
```

### 恢复 MuMu 商店/多开

原 APK 在 `D:\MuMuWork\backup\mumu-apps\`（`com.mumu.store.apk`、`com.mumu.acc.apk`、`com.netease.mumu.cloner.apk`）。需要重新放回 `/system/priv-app` 或 `/system/app` 对应目录并重启。

### 恢复内置 Chromium

- 从 `D:\MuMuWork\backup\system.vdi.bak` 或原镜像取回 `/system/product/app/TrichromeChrome`，重启
- 或重新安装 Chrome APK，并把 dock 第 5 行 intent 改回 Chromium 组件
- 如需恢复浏览器默认角色：`adb shell cmd role add-role-holder --user 0 android.app.role.BROWSER com.android.chromium`

### 卸载 Via

```
adb shell pm uninstall mark.via
adb shell rm -rf /system/app/Via
adb shell cmd role remove-role-holder --user 0 android.app.role.BROWSER mark.via
```

同时删除 `/data/local/lawnchair/Via.apk` 和 preload 模块里复制 Via 的段落；dock 行可删除或改回 Chromium。

## 注意

- `/system` 目前是可写 overlay（`system_disk_readonly=false`），基础 `system.vdi` 未直接改写；冷启动依赖 `lawnchair_preload` 模块恢复桌面。
- 删除 `/system/etc/user_app/KernelSU.apk` 后，MuMu 开机仍会执行 `pm install` 并失败（仅日志噪音，不影响启动）。
- 如果关闭 KernelSU/root，`post-fs-data.sh` 不会执行，冷启动桌面会回落到 FallbackHome；需要保留 root，或改用其它方式把桌面固化进基础镜像。
- Via 使用的是中国版官方 APK（`mark.via` 7.4.1），不是 Google Play 的 `mark.via.gp`；更新时从 `res.viayoo.com` 或官网获取同签名 APK 覆盖安装即可。
- Chromium 移除后系统 WebView 仍由独立的 `com.android.webview` 提供，Via 可正常渲染网页。
- `lawnchair_preload` 的 `post-fs-data.sh` 里也包含复制 Via 和删除 TrichromeChrome 的段落，用于兜底；实际持久化来自运行期对 `/system` overlay 的写入。
- 早期尝试过的 AOSP Launcher3 / Launcher3QuickStep 方案未采用：API 27 版本不支持 Direct Boot，API 35 QuickStep 与 MuMu 定制 SystemUI 不兼容。
