# MuMu 镜像级改造报告（Image Bake）

日期：2026-11-21
对象：MuMu Player 6.8.11.0 / Android 15 / `MuMuPlayer-15.0-0`
产物：离线烘焙的 system 基础盘（`system.vdi`）+ 空 diff + 原始 `.nemu`
状态：冷启动验证通过，桌面 / Via / props / hosts 全部来自镜像本身，不再依赖 overlay 补丁与 KernelSU 模块

---

## 1. 目标

把此前所有运行时补丁（桌面去 MuMu、去商店/账号/多开、Via、hosts、overseas/hostname/SkiaGL）**烧进 system 基础盘**，再丢掉 overlay/preload 依赖，使冷启动自包含。

---

## 2. 镜像结构（实测）

| 层 | 文件 | 大小 | 说明 |
| --- | --- | --- | --- |
| base | `nx_device/15.0/vms/MuMuPlayer-15.0-base/system.vdi` | 2,360 MB 虚拟 | MBR + 扩展分区，GRUB 引导 |
| diff | `vms/MuMuPlayer-15.0-0/system-diff.vdi` | 差异盘 | 运行时写层（含 overlay upperdir） |
| data | `vms/MuMuPlayer-15.0-0/data.vdi` | 931 GB 稀疏 | /data |
| ota | `vms/MuMuPlayer-15.0-0/ota.vdi` | 6 MB | ota |

分区（sda）：

| 设备 | 偏移 | 大小 | 文件系统 | 用途 |
| --- | --- | --- | --- | --- |
| sda3 | 0x1000000 | 14 MB | ext4 | boot：`/kernel` `/initrd` `/ramdisk` `/cmdline` |
| sda6 | 0x26940000 | 1.63 GB | ext4，卷标 `/` | Android system-as-root（本报告改动处） |
| sda7 | 0x6AFE0000 | 136 MB | ext4，卷标 `vendor` | vendor |
| sda8 | 0x738C0000 | 512 MB | ext4 | overlay `/upperdir` + `/workdir` |

启动链：BIOS → GRUB → kernel(`console=ttyS0`) → initrd（Android-x86 init 脚本）→ 挂 sda6 到 `/android` → `switch_root` → `/init`（symlink → `/system/bin/init`）→ overlay 以 sda8 为 upperdir 覆盖 /system。

---

## 3. 方法（自建离线流程）

1. **解析 VDI**：按 VDI 头（0x154/0x158/0x170/0x178/0x180）读取块表与数据偏移，1 MB 块，把 diff 的 112 个已分配块覆盖到 base 的 raw 副本，得到"当前真实系统盘"。
2. **分区提取**：按 MBR/EBR 链算出 sda6 / sda8 的字节偏移，切出 `part-root.img`、`part-3.img`、`part-boot.img`。
3. **ext4 读写**：用 Cygwin 版 e2fsprogs（debugfs 1.44.5 + 64 位 cygwin 运行库，来自 Cygwin 源）离线挂载/修改，`-R` 单命令与 `-f` 脚本两种方式；`write / sif / ea_set -f` 完成文件、权限、SELinux 标签写入。
4. **安全写入策略**：删除集中一次会话；**每个文件单独一次会话**写入；每阶段之间跑 `e2fsck -fy` 校正空闲块计数；最后全盘哈希复核。
5. **重建 VDI**：`VBoxManage convertfromraw` → `sethduuid` 还原原基础盘 UUID；清空媒体注册表后由 MuMu 自建注册，避免 UUID 陈旧冲突。
6. **启动验证**：给 VM 增加 RawFile 串口（`.nemu` 内 `<UART>` 或 `modifyvm --uart1 0x3f8 4 --uartmode1 file`）拿内核/init 日志；功能验证走 MuMuManager + adb。

---

## 4. 一次真实的踩坑（已修复，记录备查）

第一版直接在原镜像上做批量写入，结果系统 `Kernel panic`：

```
linker: failed to find generated linker configuration from /linkerconfig/ld.config.txt
CANNOT LINK EXECUTABLE "/init": cannot locate symbol _ZNSt13runtime_errorD2Ev referenced by /system/lib64/libbase.so
Attempted to kill init!
```

全盘逐文件哈希比对（3725 个文件）发现 **53 处差异**，其中约 40 处与本次改动无关：`/system/lib64/libc++.so`、多个 `.apex`、`Settings.apk`、`SystemUI.apk`、铃声 `.ogg` 等，大小相同但内容被覆盖。

根因：该根分区**空闲块计数本身不准**（e2fsck 报告 group #0 记 16 空闲、实际 0），debugfs 单会话批量分配时按过期计数复用"看似空闲"的块，覆盖了包括 libc++ 在内的在用数据，导致 `/init` 链接失败。

修复：从原始镜像重来，删除/写入分阶段、写入逐文件独立会话、阶段间 e2fsck 校正。复核后差异降为 **17 处，全部为预期改动**，新文件与宿主源 SHA-256 逐一相同。

---

## 5. 镜像内改动清单

### 删除

| 路径 | 说明 |
| --- | --- |
| `/system/priv-app/Lawnchair/Lawnchair.apk` + `oat/x86_64/*`（81 MB odex/vdex） | 原 MuMu 桌面及其预编译产物 |
| `/system/priv-app/com.mumu.store` | MuMu 应用商店 |
| `/system/priv-app/com.mumu.acc` | MuMu 账号 |
| `/system/priv-app/com.netease.mumu.cloner` | 多开/应用克隆 |
| `/system/product/app/TrichromeChrome` | 内置 Chromium 浏览器 |
| `/system/etc/user_app/KernelSU.apk` | 开机安装的 KernelSU 管理器 |

### 写入（均 0644/0600，uid/gid 0，SELinux `u:object_r:system_file:s0`）

| 路径 | 大小 | 来源 |
| --- | --- | --- |
| `/system/priv-app/Lawnchair/Lawnchair.apk` | 49,400,357 | `lawnchair-final2.apk`（去搜索框/启动广告、平台签名） |
| `/system/priv-app/Lawnchair/lib/x86_64/*.so` ×8 | 3,013,132 | 原 native 库（libnrb、sentry、hoko_blur 等） |
| `/system/app/Via/Via.apk` | 2,714,021 | Via 官方 CN 版 |
| `/system/etc/hosts` | 545 | 18 行，屏蔽 MuMu 广告/统计/商店域名 |
| `/system/build.prop` | 5,738 | vivo 型号 + overseas/hostname/SkiaGL |

`build.prop` 关键项：

```
ro.product.system.brand=vivo
ro.product.system.device=V2284A
ro.product.system.manufacturer=vivo
ro.product.system.model=V2284A
ro.product.system.name=V2284A
ro.system.build.fingerprint=vivo/V2284A/V2284A:15/V417IR/1203:user/release-keys
ro.build.flavor=vivo_V2284A-user
ro.build.product=V2284A
ro.build.description=vivo V2284A-user 15 V417IR 1203 release-keys
ro.build.version.overseas=true
net.hostname=V2284A
debug.hwui.renderer=skiagl
ro.product.brand=vivo
ro.product.manufacturer=vivo
ro.product.model=V2284A
ro.product.name=V2284A
ro.product.device=V2284A
```

---

## 6. 验证结果

### 镜像层

- `e2fsck -fn`：干净（421,544 块，379,548 已用，约 21 MB 空闲）
- 全盘哈希比对：仅 17 处预期差异（3 改写 + 7 删除 + 7 个原镜像自身 ogg 被 fsck 修正）
- 新文件与宿主源 SHA-256：Lawnchair、Via、hosts、build.prop、libnrb、libsentry 全部 `match=True`

### 运行层（MuMuManager 正常冷启动）

```
boot_completed=1
model=V2284A / brand=vivo
fingerprint=vivo/PD2284/PD2284:15/V417IR/1203:user/release-keys
overseas=true / hostname=V2284A / renderer=skiagl
HOME=app.lawnchair
BROWSER=mark.via
DIALER=org.fossify.phone
SMS=org.fossify.messages
hosts: 545 B / 18 行（无模块 bind mount）
pm list packages: 无 com.mumu.store / com.mumu.acc / com.netease.mumu.cloner / Trichrome
```

桌面截图：vivo 壁纸、底部 Phone / Messages / Via / Camera、无 MuMu 搜索框；应用冒烟：Via、Settings、Fossify 电话均为 `topResumedActivity`（MuMu 将其分配到独立 display）。

### 自包含证明

1. 把 `/data/adb/modules/mumu_noads`、`lawnchair_preload` 写入 `disable` 后重启 → props、hosts、桌面、角色全部保持不变；
2. 删除两个模块目录，并**整体清空 overlay 上层**（重建空 `system-diff.vdi`，sda8 的 `/upperdir`、`/workdir` 归零）后冷启动 → `uptime` 全新，上述各项仍全部正确。

即：桌面、Via、hosts、props 已由基础盘本身提供，不依赖运行时补丁或模块。

---

## 7. 当前磁盘布局

| 项 | 值 |
| --- | --- |
| base UUID | `812f8e95-6f8b-d70c-0000-100000000000`（原基础盘 UUID） |
| base 类型 | Normal（可写；子盘仍为 diff，写入落在 diff） |
| diff UUID | `812f8e95-6f8b-d70c-0000-000000000000` |
| 媒体注册表 | 每次改 UUID 后清空 `C:\Users\Administrator\.MUMUNX\VirtualBox.xml`，由 MuMu 重建 |
| 串口 | 已从 `.nemu` 移除（仅排障用）；如复测可再加 `<UART><Port slot="0" ... hostMode="RawFile"/></UART>` |

---

## 8. 回滚

1. 关闭 MuMu（`MuMuManager control --vmindex 0 shutdown`），结束 `MuMuNxDevice/VBoxSVC`。
2. 恢复原始基础盘：
   `D:\MuMuWork\backup\system.vdi.bak`（1,890,582,528 B，2026-11-20）
   或 `system.vdi.pre-bake-20261121-134213`（烘焙前原盘）。
3. 恢复差异盘：`system-diff.vdi.pre-bake-20261121-134213`。
4. 恢复 `.nemu`：`MuMuPlayer-15.0-0.nemu.bak-uart` / `.nemu-prev`。
5. 删除 `C:\Users\Administrator\.MUMUNX\VirtualBox.xml` 后启动。

保留的中间产物：`D:\MuMuWork\image-edit\part-root.img`（烘焙后根分区）、`part-root.orig.img`（原始）、`part-3.img`（空 upperdir）、`merged.raw`、`final.vdi`。

---

## 9. 保留项与后续

仍存在但不显示 UI 的 MuMu 组件：`com.mumu.shared.sdk`、`com.nemu.nlp`、`com.nemu.oaidmanager`、`nemu-vinput-pack`、`nemuinit/nemuinput/nemuhotd` 进程。它们属于兼容层（OAID/NLP/输入），删除可能影响应用兼容性，暂保留。

未处理：`services.jar` 内 TaskTab（每应用独立 display，约 10–14% 启动开销）；KernelSU 内核仍在但管理器已移除。

后续可选：
- 若要彻底去 MuMu 启动器痕迹，替换 SystemUI/Launcher 图标包与开机动画资源；
- 若要去 TaskTab，需要在 `services.jar` 层打补丁并重新签名，风险高于本次镜像改动；
- 壁纸目前存放在 `/data`（不在 base），如需镜像级固化可写入 `/system/media` 并在 overlay 前设置。
