# 未上传内容清单（本机 ≠ 仓库）

本仓库保存的是**可复现的改版配方与关键产物**，不是整机镜像。以下内容留在本机 `D:\MuMuWork`，因为体积或可再生成原因不适合放进 Git：

| 类别 | 内容 | 体积 |
| --- | --- | --- |
| 磁盘镜像 | `image-edit/*.raw`、`*.vdi`、`part-*.img`（final/merged/base/root/vendor/3/…） | 14.7 GB |
| 备份 | `backup/`（原始 system.vdi、system-diff、data.vdi、pre-bake 备份等） | 7.8 GB |
| 工具 | `tools/`（MinGit、NASM、apktool、Cygwin e2fsprogs、7zr、zstd） | 158 MB |
| 桌面 APK 变体 | `lawnchair-*.apk` 约 20 个（最终版见 Release v1.0） | 801 MB |
| 春秋 APK 变体 | `chunqiu-*.apk` | 111 MB |
| Momo APK 变体 | `momo/*.apk`（仓库仅收录 resigned / patched / pro 三个） | 30 MB |
| 反编译/中间产物 | `lawnchair-smali/`、`momo/full/`、`chunqiu-smali/`、`image-edit/staging/Lawnchair-upper.apk`、trace、日志 | 数 GB |

本机 `D:\MuMuWork` 合计约 **132 GB**。

## 已上传且可复现的部分

- `scripts/`：从 VDI 解析、base+diff 合并、ext4 离线读写、镜像重建、部署验证到 Momo 逆向的完整脚本链
- `configs/`：写入镜像的 `build.prop`（新旧）、`hosts`（新旧）、SELinux 标签值
- `apps/`：Via APK、桌面依赖的 8 个 native 库
- `modules/`：KernelSU 模块（mumu_noads）与旧版脚本
- `harness/`：native 库独立验证的 Java 源码
- `artifacts/`：三个 Momo 改版 APK、hosts、build.prop
- `screenshots/`：桌面与 Momo 界面
- Release v1.0：`lawnchair-final2.apk`（49.4 MB）

## 说明

镜像本身（约 1.87 GiB 的 `system.vdi`）未放入仓库。需要的话可以：
1. 用本仓库脚本 + 配置 + `apps/` 在原版 MuMu 上重建；或
2. 将镜像切分为 <100 MB 分卷，以 Release 附件上传（需额外时间与稳定网络）。
