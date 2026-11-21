# MuMu 6.0 全面巡检报告

日期：2026-11-21
对象：MuMu 6.0（产品版本 6.8.11.0，Android 15，实例已改名 `vivo V2284A`）
范围：宿主 MuMu 客户端 + Android 15 客户机

## 结论

- 去广告 / 去 MuMu 化状态完好，冷启动后仍然生效。
- 本轮又修了 4 项：VM/窗口名、`net.hostname`、MuMu 域名拦截扩容、客户机测试残留清理。
- 没有发现系统级崩溃或 ANR；crash buffer 里只有测试工具 `uiautomator` 在关机时的 SIGSEGV，`/data/anr` 只有实验阶段的旧文件。
- 剩余 MuMu 组件均为系统级，逐项评估后保留（需要或无害），没有为了“更干净”去冒破坏桌面的风险。

## 宿主侧

- 版本 6.8.11.0，VT 已开启，Android 15。
- 进程正常：`MuMuNxMain`、`MuMuNxDevice`、`MuMuNxService`、`MuMuNxSVC`、`MuMuRemote*`。
- 去广告补丁仍在：
  - `startupImage` 0 字节、只读
  - `ProgramAds` 0 字节、只读
  - hosts 现为 26 条 MuMu 广告/遥测域名拦截
  - MuMu 数据目录下没有缓存广告图片或横幅目录（无大于 200KB 的文件）
- **已改进**：VM 从“MuMu安卓设备”改名为 `vivo V2284A`，玩家窗口标题同步为 `vivo V2284A`。
- 主客户端窗口标题仍是“MuMu模拟器”（MuMuNxMain，exe 级资源，未动）。
- `msgCenter` 文件 1 字节且被 MuMu 占用，无实际内容，未动。
- hosts 备份：`D:\MuMuWork\backup\hosts-audit-20261121-074206.bak`

## 客户机侧

### 应用与默认项

- 共 68 个包，第三方应用为空；Via 和 Lawnchair 都是系统应用。
- 默认 HOME：`app.lawnchair`
- 默认浏览器：`mark.via`（Via 7.4.1，`/system/app/Via/Via.apk`）
- 默认输入法：Sogou（`com.sohu.inputmethod.sogou.chuizi`）
- 默认短信：无（镜像本身没有短信 App，也没有 telephony）

### MuMu 残留组件（评估后保留）

| 包 | 作用 | 处理 |
| --- | --- | --- |
| `com.mumu.shared.sdk` | MuMu 共享 SDK / provider | 未见运行服务；可能被桌面的 label/display provider 依赖，保留 |
| `com.nemu.nlp` | 网络定位 provider | 正在运行，保留（位置服务需要） |
| `com.nemu.oaidmanager` | OAID 提供者 | 保留 |
| `nemu-vinput-pack` + Sogou | 输入法包 | 保留（默认输入法） |

### 身份与显示

- `ro.product.model` / `settings global device_name`：`V2284A`
- 指纹：`vivo/PD2284/PD2284:15/V417IR/1203:user/release-keys`
- 内核：`6.1.90-perf+`（aarch64，无 MuMu 字样）
- `net.hostname`：`V2284A`（本轮新设并持久化）
- `ro.build.version.overseas=true`
- 显示：900×1600 @240dpi，60fps 限制
- 存储：126G，已用约 224M

### 广告与界面

- hosts 拦截 26 条：`mumu.nie.netease.com`、`api/report.mumu.163.com`、`mumuplayer.com`、`mumuglobal.com`、`adl.easebar.com`、easebar CDN 等
- 实测：客户机 `ping mumu.163.com` 解析到 127.0.0.1；宿主 `Resolve-DnsName mumu.163.com` 返回 0.0.0.0
- 桌面搜索框、启动广告已从 APK 代码层移除
- 桌面无 MuMu 幽灵安装项、无“小工具”文件夹、无 KernelSU 图标
- 内置 Chromium 已移除，dock 第 4 格为 Via

### 稳定性

- crash buffer：仅 `uiautomator` 在 VM 关机时 SIGSEGV（测试工具，不是系统问题）
- `/data/anr`：仅 06:31 实验阶段留下的一个旧 ANR 文件
- 当前没有系统级 FATAL / ANR
- 巡检结束时已清理旧 ANR 和 crash buffer，客户机 `/data/local/tmp` 只剩 `dalvik-cache`、`mnt`

### 界面巡检

- 通知面板：显示 `CHINA MOBILE`、98% 电量、日期“11月21日周六”，无 MuMu 磁贴，无通知。
- 设置页：MuMu 把 Settings 放在 TaskTab 的 display 2（虚拟 secure 显示，`screencap -d 2` 返回 -2），不是崩溃；AOSP Settings 正常。
- Wi-Fi SSID：`Huawei_9797f9756421`，是 MuMu 模拟的热点名，看起来像真实家用路由器，不含 MuMu 品牌。
- 宿主 MuMu 主窗口当前是隐藏/最小化状态（160×28），没有可见广告位；玩家窗口标题为 `vivo V2284A`。
- 桌面截图：`D:\MuMuWork\work\mumu-audit-final.png`
- 通知面板截图：`D:\MuMuWork\work\guest-qs.png`

### 其它观察

- `com.android.bluetooth` 被 MuMu 默认禁用（镜像没有蓝牙 radio）；没有启用，避免出现不可用的蓝牙开关。
- 通知策略数据库里还有已卸载的 `com.mumu.store`、`com.mumu.acc`、`com.netease.mumu.cloner` 的 AppSettings 残留，不可见，未清理。
- 安全姿态：`adb root` + SELinux Permissive（MuMu 默认，KernelSU 模块需要）；adb 只监听 `127.0.0.1:16384`。

## 本轮已做改进

1. **VM / 玩家窗口改名**：`MuMuManager rename --vmindex 0 --name "vivo V2284A"`，窗口标题同步。
2. **net.hostname 设为 V2284A**：写入 `mumu_noads` 的 `post-fs-data.sh` 和 `service.sh`，每次开机 `resetprop` 持久化。
3. **MuMu 域名拦截扩容**：宿主 hosts 和客户机模块 hosts 各新增 10 条（`mumu.163.com`、`www.mumu.163.com`、`api/report.mumu.163.com`、`mumuplayer.com`、`mumuglobal.com`、`mumu-global.fp.ps.easebar.com` 等），总数 26 条。
4. **清理客户机测试残留**：删除 `/data/local/tmp` 下的 `lawnchair-libs`、`hosts.noads`、`mumu_noads.zip`。

## 冷启动验证（07:43）

- `sys.boot_completed=1`
- `getprop net.hostname` → `V2284A`
- `/system/etc/hosts` 26 条拦截，无 CRLF
- `pm path mark.via` → `/system/app/Via/Via.apk`，BROWSER role = `mark.via`
- `pm path app.lawnchair` → `/system/priv-app/Lawnchair/Lawnchair.apk`，HOME role = `app.lawnchair`
- VM 名 / 玩家窗口标题 → `vivo V2284A`
- 桌面截图：`D:\MuMuWork\work\mumu-audit-final.png`

## 未做的建议（附原因）

- **移除 `com.mumu.shared.sdk`**：可能影响桌面的 label/display provider，收益低、风险高。
- **启用蓝牙**：镜像没有蓝牙 radio，启用只会多一个不可用的开关。
- **修改 `nemud.*` props**（`nemud.player_product=MuMu6.0` 等）：宿主输入/显示/保活依赖这些属性，改了可能破坏模拟器功能。
- **修改主客户端“MuMu模拟器”标题**：需要改 MuMuNxMain 的 exe 资源，风险高。
- **清理通知策略残留**：不可见，`notification_policy.xml` 是 ABX，编辑风险大于收益。
- **加时钟 widget**：需要 AppWidgetService 分配 ID，复杂且容易被桌面重置。
- **装短信 App**：镜像没有 telephony，装了也不能收发。

## 回滚

- VM 名：`MuMuManager rename --vmindex 0 --name "MuMu安卓设备"`
- `net.hostname`：删除 `mumu_noads` 两个脚本里的 `resetprop -n net.hostname V2284A`，重启
- hosts：宿主恢复 `D:\MuMuWork\backup\hosts-audit-20261121-074206.bak`；客户机模块 hosts 恢复原来的 16 条
- 桌面/Via/壁纸等改动回滚见 `D:\MuMuWork\DeMuMu-Report.md`
