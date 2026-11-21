# mumu

MuMu 6.0（Android 15）去 MuMu 化 + 镜像级烘焙 + Momo 4.4.1 环境研究。

私有仓库。不含任何账号凭据。**不是整机镜像**，是可复现的改版配方与关键产物；未上传内容见 `docs/EXCLUDED.md`。

## 目录

```
README.md
docs/                  报告 + EXCLUDED.md（未上传清单）
scripts/               镜像解析/合并/编辑/构建/验证/逆向脚本（117 个）
configs/               写入镜像的 build.prop（新旧）、hosts（新旧）、SELinux 标签值
apps/                  Via.apk + 桌面依赖的 8 个 native 库
modules/               KernelSU 模块（mumu_noads）与旧版脚本
artifacts/             hosts.txt / build.prop.txt / 三个 Momo 改版 APK
harness/H.java         native 库独立验证源码
screenshots/           验证截图
MANIFEST.sha256        仓库文件 + 镜像包 + Release 附件的 SHA-256
mumu-modified.zip      以上内容的打包快照
```

Release **v1.0** 附带 `lawnchair-final2.apk`（49.4 MB，去 MuMu 桌面，平台签名）。

## 已完成

1. **镜像级去 MuMu**：离线修改 MuMu 的 `system.vdi`（sda6 根分区），把桌面、Via、hosts、vivo 属性烧进基础盘；清空 overlay 上层并停用全部 KernelSU 模块后冷启动，仍保持自包含。
   - 删除：MuMu 商店 / 账号 / 多开 / 内置 Chrome / KernelSU 安装包 / 原桌面及其 81 MB oat
   - 写入：`lawnchair-final2.apk` + 8 个 native 库、Via、18 行 hosts、vivo 化 build.prop
   - 详见 `docs/Image-Bake-Report.md`
2. **Momo 4.4.1 崩溃定位**：`libmahoshojo.so` 的 OLLVM 解密表从未初始化，UI 协程直接调用 `App.check()` → 空指针崩溃（PC 0x1bdd3）。
   - 逐项排除：qemu/vbox 属性、安全补丁日期、SELinux、x86_64/arm64、APK 内加载 vs 真实文件、READ_LOGS、冷启动竞态
   - 详见 `docs/Momo-Crash-Analysis.md`
3. **通过限制**：原版签名必崩于干净分支；任何改包被原生反篡改判定拦截（“检测到破坏行为，例如 MagiskHide”）。
   - 详见 `docs/Momo-Pass-Limit.md`

## 产物

| 文件 | 说明 |
| --- | --- |
| `artifacts/momo-resigned.apk` | Momo 4.4.1 仅重签版：可稳定打开，显示真实检测信息 |
| `artifacts/momo-patched.apk` | 增加 native 预热补丁（`App.get(0)` 先于 `check()`） |
| `artifacts/momo-pro.apk` | 预热 + 签名哈希绕过（会触发“破坏行为”判定，仅作研究） |
| `artifacts/hosts.txt` / `build.prop.txt` | 镜像内最终文件 |
| Release v1.0 | `lawnchair-final2.apk` |

## 脚本依赖

- Cygwin debugfs 1.44.5 + e2fsprogs
- MuMu 自带 `VBoxManage.exe`
- JDK 21、Android build-tools（apktool / zipalign / apksigner / d8）

脚本中的绝对路径按本机 `D:\MuMuWork` 编写，迁移时需替换。

## 完整性

`MANIFEST.sha256` 覆盖仓库内全部文件、`mumu-modified.zip` 与 Release 附件。逐文件 SHA-256 与本机一致。

## 免责

仅用于自有设备与自有软件的研究、备份与兼容性验证。重签/修改第三方 App 会改变其签名与完整性状态。
