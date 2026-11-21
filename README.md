# mumu

MuMu 6.0（Android 15）去 MuMu 化 + 镜像级烘焙 + Momo 4.4.1 环境研究的工作仓库。

私有仓库。不含任何账号凭据。

## 内容

```
docs/           分析报告
scripts/        镜像编辑与验证脚本（PowerShell，按编号顺序执行）
artifacts/      关键产物（APK / hosts / build.prop）
screenshots/    验证截图
```

## 已完成

1. **镜像级去 MuMu**：离线修改 MuMu 的 `system.vdi`（sda6 根分区），把桌面、Via、hosts、vivo 属性烧进基础盘，清空 overlay 上层后冷启动仍自包含。
   - 删除：MuMu 商店 / 账号 / 多开 / 内置 Chrome / KernelSU 安装包 / 原桌面及其 81MB oat
   - 写入：`lawnchair-final2.apk`（去搜索框与启动广告）+ 8 个 native 库、Via、18 行 hosts、vivo 化 build.prop
   - 详见 `docs/Image-Bake-Report.md`
2. **Momo 4.4.1 崩溃定位**：`libmahoshojo.so` 的 OLLVM 解密表未初始化，UI 协程直接调用 `App.check()` 空指针崩溃。
   - 环境项（qemu/vbox 属性、安全补丁、SELinux、ABI、库加载方式、READ_LOGS、竞态）逐项实测无效
   - 详见 `docs/Momo-Crash-Analysis.md`
3. **通过限制**：原版签名必崩于干净分支；任何改包被原生反篡改判定拦截（“检测到破坏行为”）。
   - 详见 `docs/Momo-Pass-Limit.md`

## 产物

| 文件 | 说明 |
| --- | --- |
| `artifacts/lawnchair-final2.apk` | 去 MuMu 桌面（平台签名，保留原资源） |
| `artifacts/momo-resigned.apk` | Momo 4.4.1 仅重签版：可稳定打开，显示真实检测信息 |
| `artifacts/momo-patched.apk` | Momo 增加 native 预热补丁（`App.get(0)` 先于 `check()`） |
| `artifacts/momo-pro.apk` | 预热 + 签名哈希绕过（会触发“破坏行为”判定，仅作研究） |
| `artifacts/hosts.txt` | 镜像内 hosts |
| `artifacts/build.prop.txt` | 镜像内 build.prop |

## 脚本用法

脚本按编号命名，依赖：

- Cygwin debugfs 1.44.5 + e2fsprogs（`scripts/` 中的流程会指引放置位置）
- MuMu 自带 `VBoxManage.exe`
- JDK 21、Android build-tools（apktool / zipalign / apksigner / d8）

典型流程：

1. `01-prepare` → 复制并解析 VDI
2. `05-vdi-merge` → 合并 base + diff
3. `19-write` / `20-meta` → 写入文件与权限、SELinux 标签
4. `36-scan-diffs` / `38-verify` → 全盘哈希复核
5. `41-mumu-deploy` / `42-launch-mumu` → 回写 VDI 并冷启动

注意：脚本中的绝对路径按本机 `D:\MuMuWork` 编写，迁移时需替换。

## 免责

仅用于自有设备与自有软件的研究、备份与兼容性验证。重签/修改第三方 App 会改变其签名与完整性状态。
