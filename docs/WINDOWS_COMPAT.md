# Windows 兼容说明

xuan OS 不包含任何 Windows 专有代码，对 Windows 程序的支持全部由开源
兼容层实现。

## 组件构成

| 组件 | 职责 |
| --- | --- |
| Wine | Win32/Win64 API 的开源实现，运行 `.exe`/`.dll` |
| wine-mono / wine_gecko | .NET 与内嵌网页组件的开源替代 |
| winetricks | 安装运行库与字体的辅助脚本 |
| DXVK | Direct3D 9/10/11 → Vulkan 转译 |
| VKD3D | Direct3D 12 → Vulkan 转译 |
| Bottles | 图形化前缀（容器）管理器，隔离不同应用环境 |
| Proton | 面向 Steam 游戏的 Wine 分支，集成常用补丁 |

## 三种使用方式

### 1. 双击运行

`.exe`/`.msi` 已通过 `mimeapps.list` 关联到 `xuan-winrun`，双击即可
启动，日志位于 `~/.local/share/xuanos/logs/winrun.log`。

### 2. 命令行

```bash
xuan-winrun ./Setup.exe
# 或在启用 binfmt 后直接
./Setup.exe
```

### 3. Bottles 管理复杂应用

对于需要特定运行库、独立前缀的软件（办公套件、老游戏等），在应用菜单
打开 Bottles，新建环境后安装程序，可获得独立的 Wine 版本与配置隔离。

## 前缀管理

```bash
xuan-ctl wine init     # 初始化默认前缀并安装 CJK 字体
xuan-ctl wine reset    # 删除并重建前缀（需确认）
xuan-ctl wine shell    # 进入 Wine 控制台
```

## 中文与字体

- 系统预置 Noto CJK 字体，Wine 初始化时通过 winetricks 配置字体平滑，
  避免 Windows 程序出现方框乱码；
- 输入法在 `environment.d` 中全局配置为 Fcitx5，Windows 程序内可直接
  唤起中文输入。

## 兼容性边界与建议

- 兼容层对多数桌面软件、老游戏和 .NET 程序支持良好；
- 依赖内核级反作弊、专有驱动或最新 Windows 内核特性的程序可能无法运行，
  可在 Wine AppDB 与 Bottles 数据库查询具体软件评级；
- 企业专用程序若必须运行在真实 Windows，建议使用双系统或虚拟机，
  xuan OS 已内置 KVM/QEMU 所需的虚拟化支持。

## 安全提示

仅运行来源可信的 Windows 可执行文件。Wine 程序拥有当前用户权限，
恶意软件同样可以访问用户目录；防火墙默认拒绝入站连接，但不能替代
对来源的甄别。
