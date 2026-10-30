# 构建指南

## 构建主机要求

- 架构：x86_64
- 系统：最新的 Arch Linux（或包含 `archiso` 的等价环境，如基于 Arch 的
  容器镜像）
- 磁盘：至少 8 GB 可用空间
- 网络：可访问 Arch 官方仓库
- 权限：root（pacstrap 需要）

## 安装构建依赖

```bash
sudo pacman -S --needed archiso rsync librsvg grub fontconfig freetype2 \
    bash python python-pyqt? shellcheck yamllint
```

最小依赖为 `archiso rsync librsvg grub fontconfig`；`shellcheck`、
`python-yaml`、`xmllint` 仅用于运行测试套件。

## 标准构建

```bash
git clone https://github.com/xuanos/xuanos.git
cd xuanos
./build.sh
```

构建脚本会依次执行：

1. 校验 `mkarchiso` 等工具存在；
2. `scripts/build_assets.sh` 生成 PNG 背景与 GRUB 字体；
3. `scripts/apply_overlays.sh` 同步 overlay 与原创工具；
4. `mkarchiso` 安装软件、执行 chroot 定制并打包 ISO；
5. 生成 `SHA256SUMS.txt`。

产物路径：`build/out/xuanos-YYYY.MM.DD-x86_64.iso`。

## 固定时间戳的可复现构建

```bash
export SOURCE_DATE_EPOCH=$(date -d '2026-10-30' +%s)
./build.sh
```

`profiledef.sh` 与版本号均读取该变量，两次构建应得到相同的版本标识。

## 制作启动盘

- **Ventoy**（推荐）：把 ISO 直接拷入 Ventoy U 盘，支持 BIOS/UEFI。
- **命令行 DD**：
  ```bash
  sudo dd if=build/out/xuanos-*.iso of=/dev/sdX bs=4M status=progress conv=fsync
  ```
- **Windows 下 Rufus**：选择镜像后使用 DD 模式写入。

## 虚拟化测试

无需写盘即可在 QEMU 中验证：

```bash
run_archiso -i build/out/xuanos-*.iso
# 或
qemu-system-x86_64 -m 4096 -enable-kvm -cdrom build/out/xuanos-*.iso -boot d
```

## 运行测试

```bash
./tests/run_tests.sh
```

测试不依赖 root，包含 Bash/Python 语法、YAML 解析、包清单去重、
关键文件存在性与 SVG 合法性检查。

## 常见问题

| 现象 | 处理 |
| --- | --- |
| `mkarchiso missing` | `sudo pacman -S archiso` |
| 包签名或密钥环错误 | `sudo pacman-key --init && sudo pacman-key --populate archlinux` |
| 空间不足 | `./build.sh clean` 后重新构建 |
| 字体生成失败 | 确认已安装 `inter-font` 与 `ttf-jetbrains-mono` |
