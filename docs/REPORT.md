# MuMu 6.0 去广告完成报告

## 结论

已在这台机器上完成 MuMu 6.0 的下载、安装和去广告。宿主端开屏/弹窗广告、Android 客户机桌面广告均已移除，并做了重启后的持久化验证。

- 安装包：官方中国区在线安装器 `MuMu_6.0.6_gw-win_zh-Hans_1794391155.exe`
- 下载入口：`https://mumu.nie.netease.com/api/dl/win?channel=gw-win` → `a11.gdl.netease.com`
- SHA256：`9E5BA9FDE27FBCE38696935A129F524801FD53AAE836695F15C92F61FE7284D8`
- 签名：`NetEase (Hangzhou) Network Co., Ltd`，Valid
- 安装后产品版本：`6.8.11.0`（产品名 `MuMu6.0`，Android 15 内核）
- 安装目录：`D:\Program Files\Netease\MuMu`（约 3.69 GB）
- 实例：`MuMu安卓设备`，4 核 / 6 GB / Android 15 / 1600x900 / 240 DPI

## 广告面定位

### 宿主端

1. 开屏广告：
   - `%APPDATA%\Netease\MuMuPlayer\data\startupImage\imageManager.json`
   - 缓存素材目录：`2mSIgo`、`7tl1KR`
   - 实际广告：appId `26854`（斗罗大陆）、appId `29915`，campaign `7tl1KR` / `2mSIgo`
2. 推广弹窗缓存：`%APPDATA%\Netease\MuMuPlayer\data\ProgramAds`
3. 相关接口/统计域名：
   - `mumu.nie.netease.com`、`api.mumu.nie.netease.com`、`report.mumu.nie.netease.com`
   - `shence-api.mumu.163.com`、`event.sc.gearupportal.com`、`hubble.mumu.163.com`
   - `fcount-api.webapp.163.com`、`fcount-api.webapp.easebar.com`
   - `sentry.netease.com`、`pr.da.netease.com`
   - `adl.netease.com`、`adl.easebar.com`
   - `store-api.mumu.163.com`、`api-pro.mumu.163.com`、`api.mumuglobal.com`
   - `sigma-agentlog-mumusdk.proxima.nie.netease.com`

### 客户机端（Android 15）

桌面上的「广告轮播 / 每日新发现」不是启动器自己画的，而是 `com.mumu.store` 通过 AppWidget 注入 `app.lawnchair`：

- `com.mumu.store:id/widgetAdvertiseBannerLayout`
- `com.mumu.store:id/widgetAdBannerFlipper*`
- `com.mumu.store:id/widgetDailyDiscovery*`
- 广告文案样例：`斗罗大陆：诛邪传说`、`每日新发现`、`新故事，新冒险，下载抽5060ti！`

启动器自身还带有 `searchAdListView` / `fetchPopupAdData` 搜索广告位。

## 已实施改动

### 宿主端

1. `startupImage` 目录已替换为**只读空文件**：
   - `C:\Users\Administrator\AppData\Roaming\Netease\MuMuPlayer\data\startupImage`
   - 原目录（含两套开屏广告图）已备份。
2. `ProgramAds` 目录已替换为**只读空文件**。
3. Windows hosts 已追加屏蔽段（标记 `# MuMu ad/telemetry block BEGIN/END`），上面列出的域名全部解析到 `0.0.0.0`。
4. 清空 DNS 缓存。

### 客户机端

1. 禁用游戏中心广告提供方：
   - `pm disable-user --user 0 com.mumu.store`
   - 状态：`disabled-user`
2. 安装 KernelSU 模块 `mumu_noads`：
   - 模块包：`D:\MuMuWork\module\mumu_noads.zip`
   - 内容：`module.prop`、`post-fs-data.sh`、`service.sh`、`hosts`
   - 开机执行：
     - `mount --bind "$MODDIR/hosts" /system/etc/hosts`
     - `/data/adb/ksud resetprop -n ro.build.version.overseas true`
3. 开启 MuMu 的 root：
   - `root_permission=true`
   - `adb root` 可用，`id` 为 `uid=0(root)`

## 验证结果（重启后）

| 检查项 | 结果 |
| --- | --- |
| 宿主启动帧 `boot-03.png` / `boot-06.png` | 只有 MuMu 默认 Logo，无开屏广告图 |
| `startupImage` 路径 | 只读空文件，`imageManager.json` 不再生成 |
| `ProgramAds` 路径 | 只读空文件 |
| `Resolve-DnsName mumu.nie.netease.com` 等 | `0.0.0.0` |
| 客户机 `getprop ro.build.version.overseas` | `true`（重启后仍为 true） |
| 客户机 `/system/etc/hosts` | 16 条 `0.0.0.0` 屏蔽项 |
| `ping store-api.mumu.163.com` | 解析到 `127.0.0.1` |
| `pm list packages -d` | 包含 `com.mumu.store` |
| `ksud module list` | `mumu_noads`，`enabled=true`，`update=false` |
| `uiautomator` 桌面 dump | `com.mumu.store` 出现 0 次，`widgetAd` 0 次 |
| `MuMuManager info --vmindex 0` | `is_android_started=true`，`player_state=start_finished`，`vt_enabled=true` |
| 最终截图 `final-state.png` | 宿主主界面只有设备卡片，客户机桌面无广告卡 |

证据文件：

- `D:\MuMuWork\work\boot-03.png`
- `D:\MuMuWork\work\boot-06.png`
- `D:\MuMuWork\work\ui5.xml`（重启后桌面 dump）
- `D:\MuMuWork\work\final-state.png`
- `D:\MuMuWork\backup\mumu-patch-20261120-232845\startupImage\imageManager.json`（原始开屏广告配置）
- `D:\MuMuWork\backup\mumu-patch-20261120-232845\patch-report.txt`（补丁执行日志）

## 回滚

管理员运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\MuMuWork\rollback\rollback.ps1
```

备份目录：`D:\MuMuWork\backup\mumu-patch-20261120-232845`

- `startupImage\`：原始开屏广告目录（含 `2mSIgo`、`7tl1KR` 和图片）
- `ProgramAds\`
- `msgCenter\`
- `hosts.bak`：追加屏蔽段之前的原始 hosts
- `patch-report.txt`

回滚脚本会：

1. 客户机内卸载 `mumu_noads` 模块、`pm enable com.mumu.store`、删除 `ro.build.version.overseas`。
2. 关闭 MuMu 主程序与实例。
3. 删除只读空文件，恢复原始 `startupImage` / `ProgramAds` 目录。
4. 用 `hosts.bak` 覆盖 Windows hosts 并刷新 DNS。
5. 把 `root_permission` 恢复为 `false`。
6. 重新启动 MuMu 主界面。

## 注意事项

- `com.mumu.store`（游戏中心/商店）已被禁用；装 APK 可直接拖进模拟器或用 `adb install`。需要恢复商店：`adb shell pm enable com.mumu.store`。
- 屏蔽了网易统计、崩溃上报和更新检查域名；如需检查 MuMu 更新，先回滚 hosts，更新后重新执行宿主补丁。其他网易系软件的统计/推广链路也可能受影响。
- MuMu 升级后，宿主端的 `startupImage` / `ProgramAds` 可能被重新创建，需要重新替换为只读空文件；客户机模块在实例数据里，通常能保留，但重建实例后需要重新安装 `D:\MuMuWork\module\mumu_noads.zip`。
- Root 已开启，桌面会出现 KernelSU 图标；不需要 root 时可执行回滚脚本或把 `root_permission` 设为 `false` 后重启。
- 启动器搜索栏仍保留；其搜索广告数据受 `ro.build.version.overseas=true` 和 hosts 屏蔽限制，未再观察到广告内容。
