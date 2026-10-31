#!/usr/bin/env python3
import os
import shutil
import subprocess
from pathlib import Path

from PySide6.QtCore import Qt, QProcess, QSize
from PySide6.QtGui import QColor, QFont, QIcon, QPainter, QPixmap
from PySide6.QtWidgets import (
    QApplication,
    QCheckBox,
    QFrame,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QMessageBox,
    QPushButton,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

APP_VERSION = "1.1.0"
ACCENT = "#0078D4"
ACCENT_PRESSED = "#005A9E"
SURFACE = "#F3F6FB"
CARD_BG = "#FFFFFF"
TEXT_PRIMARY = "#1B2738"
TEXT_SECONDARY = "#5A6B82"
CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "xuanos"
DONE_MARK = CONFIG_DIR / "welcome-done"
LOGO_PATH = "/usr/share/icons/xuanos/xuanos-logo.svg"
WALLPAPER_PATH = "/usr/share/wallpapers/xuanos/xuanos-default.svg"


def is_live_session() -> bool:
    if Path("/run/archiso/bootmnt").exists():
        return True
    try:
        host = subprocess.run(
            ["hostname"], capture_output=True, text=True, check=False
        ).stdout.strip()
        return "live" in host
    except OSError:
        return False


def detect_gpu() -> str:
    if not shutil.which("lspci"):
        return "unknown"
    try:
        out = subprocess.run(
            ["lspci"], capture_output=True, text=True, check=False
        ).stdout
    except OSError:
        return "unknown"
    for line in out.splitlines():
        lowered = line.lower()
        if "vga" in lowered or "3d controller" in lowered:
            if "nvidia" in lowered:
                return "nvidia"
            if "amd" in lowered or "radeon" in lowered or "ati" in lowered:
                return "amd"
            if "intel" in lowered:
                return "intel"
    return "unknown"


def run_detached(command: list[str]) -> None:
    QProcess.startDetached(command[0], command[1:])


class ActionCard(QFrame):
    def __init__(self, title: str, subtitle: str, icon_name: str, on_click) -> None:
        super().__init__()
        self.setObjectName("ActionCard")
        self.setFixedHeight(128)
        self.setCursor(Qt.PointingHandCursor)
        self._on_click = on_click

        layout = QHBoxLayout(self)
        layout.setContentsMargins(18, 18, 18, 18)
        layout.setSpacing(16)

        icon_label = QLabel()
        icon = QIcon.fromTheme(icon_name)
        if icon.isNull():
            icon = QIcon.fromTheme("applications-system")
        icon_label.setPixmap(icon.pixmap(QSize(40, 40)))
        icon_label.setFixedSize(48, 48)

        text_box = QVBoxLayout()
        text_box.setSpacing(6)
        title_label = QLabel(title)
        title_label.setObjectName("CardTitle")
        sub_label = QLabel(subtitle)
        sub_label.setObjectName("CardSubtitle")
        sub_label.setWordWrap(True)
        text_box.addWidget(title_label)
        text_box.addWidget(sub_label)

        layout.addWidget(icon_label)
        layout.addLayout(text_box, 1)

    def mousePressEvent(self, event) -> None:
        if event.button() == Qt.LeftButton:
            self._on_click()
        super().mousePressEvent(event)


class WelcomeWindow(QWidget):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("xuan OS 欢迎中心")
        self.setMinimumSize(960, 660)
        self.gpu = detect_gpu()
        self.live = is_live_session()
        self._build_ui()

    def _build_ui(self) -> None:
        outer = QVBoxLayout(self)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)

        header = QFrame()
        header.setObjectName("Header")
        header.setFixedHeight(170)
        header_layout = QHBoxLayout(header)
        header_layout.setContentsMargins(44, 30, 44, 30)
        header_layout.setSpacing(22)

        logo = QLabel()
        if Path(LOGO_PATH).exists():
            logo.setPixmap(QIcon(LOGO_PATH).pixmap(QSize(84, 84)))
        else:
            logo.setPixmap(self._fallback_logo().pixmap(QSize(84, 84)))

        titles = QVBoxLayout()
        titles.setSpacing(8)
        welcome = QLabel("欢迎使用 xuan OS")
        welcome.setObjectName("WelcomeTitle")
        mode_text = "Live 试用环境" if self.live else "已安装系统"
        subtitle = QLabel(
            f"兼具 Linux 的自由与 Windows 的易用 · 当前模式：{mode_text} · 版本 {APP_VERSION}"
        )
        subtitle.setObjectName("WelcomeSubtitle")
        titles.addWidget(welcome)
        titles.addWidget(subtitle)
        header_layout.addWidget(logo)
        header_layout.addLayout(titles, 1)
        outer.addWidget(header)

        body = QWidget()
        body.setObjectName("Body")
        body_layout = QVBoxLayout(body)
        body_layout.setContentsMargins(44, 34, 44, 24)
        body_layout.setSpacing(20)

        section = QLabel("开始使用")
        section.setObjectName("SectionLabel")
        body_layout.addWidget(section)

        grid = QGridLayout()
        grid.setSpacing(16)

        cards = [
            ActionCard(
                "安装 xuan OS",
                "启动图形化安装器，将系统安装到本机磁盘",
                "system-installer",
                self._launch_installer,
            ),
            ActionCard(
                "更新系统",
                "刷新镜像源并升级全部软件包与内核",
                "system-software-update",
                self._update_system,
            ),
            ActionCard(
                "运行 Windows 程序",
                "打开 Bottles 管理 .exe 与游戏兼容环境",
                "wine",
                lambda: run_detached(["bottles"]),
            ),
            ActionCard(
                "驱动与硬件",
                self._driver_hint(),
                "preferences-desktop-display",
                self._driver_action,
            ),
            ActionCard(
                "防火墙设置",
                "查看网络规则与端口放行状态",
                "preferences-system-firewall",
                lambda: run_detached(["gufw"]),
            ),
            ActionCard(
                "终端管理工具",
                "在终端中使用 xuan-ctl 进行系统管理",
                "utilities-terminal",
                lambda: run_detached(["konsole", "-e", "xuan-ctl", "help"]),
            ),
        ]

        for index, card in enumerate(cards):
            grid.addWidget(card, index // 2, index % 2)
        if not self.live:
            cards[0].setEnabled(False)
            cards[0].setToolTip("仅在 Live 试用环境中可安装")

        body_layout.addLayout(grid)
        body_layout.addStretch(1)

        footer = QHBoxLayout()
        self.autostart_box = QCheckBox("登录时不再自动显示欢迎中心")
        self.autostart_box.setChecked(DONE_MARK.exists())
        close_btn = QPushButton("完成")
        close_btn.setObjectName("PrimaryButton")
        close_btn.setFixedSize(120, 42)
        close_btn.clicked.connect(self._finish)
        footer.addWidget(self.autostart_box)
        footer.addStretch(1)
        footer.addWidget(close_btn)
        body_layout.addLayout(footer)

        outer.addWidget(body, 1)

    def _driver_hint(self) -> str:
        if self.gpu == "nvidia":
            return "检测到 NVIDIA 显卡，点击查看专有驱动安装方式"
        if self.gpu == "amd":
            return "AMD 开源驱动已就绪，点击查看 Vulkan 状态"
        if self.gpu == "intel":
            return "Intel 核显驱动已就绪，点击查看硬件信息"
        return "查看显卡、声卡与外设状态"

    def _driver_action(self) -> None:
        if self.gpu == "nvidia":
            run_detached(["konsole", "-e", "bash", "-c",
                          "echo '推荐安装: sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils'; "
                          "echo '安装后重启即可获得完整硬件加速'; exec bash"])
        else:
            run_detached(["konsole", "-e", "bash", "-c", "lspci -k; glxinfo | grep -E 'renderer|OpenGL'; exec bash"])

    def _launch_installer(self) -> None:
        if not self.live:
            QMessageBox.information(self, "提示", "系统已安装，无需重复运行安装器。")
            return
        if not shutil.which("calamares"):
            QMessageBox.warning(self, "错误", "未找到安装器 calamares。")
            return
        run_detached(["calamares"])

    def _update_system(self) -> None:
        run_detached(["konsole", "-e", "xuan-ctl", "update"])

    def _finish(self) -> None:
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)
        if self.autostart_box.isChecked():
            DONE_MARK.write_text("completed\n", encoding="utf-8")
        elif DONE_MARK.exists():
            DONE_MARK.unlink()
        self.close()

    def _fallback_logo(self) -> QIcon:
        pix = QPixmap(64, 64)
        pix.fill(QColor(ACCENT))
        return QIcon(pix)


def apply_styles(app: QApplication) -> None:
    app.setStyleSheet(
        f"""
        QWidget {{ background: {SURFACE}; color: {TEXT_PRIMARY}; font-family: Inter, sans-serif; }}
        #Header {{ background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #0E2A52, stop:1 #0078D4); }}
        #WelcomeTitle {{ color: #FFFFFF; font-size: 30px; font-weight: 700; background: transparent; }}
        #WelcomeSubtitle {{ color: #C9D8EE; font-size: 14px; background: transparent; }}
        #SectionLabel {{ font-size: 17px; font-weight: 700; color: {TEXT_PRIMARY}; }}
        #ActionCard {{ background: {CARD_BG}; border: 1px solid #DCE3EE; border-radius: 14px; }}
        #ActionCard:hover {{ border: 1px solid {ACCENT}; }}
        #CardTitle {{ font-size: 16px; font-weight: 700; color: {TEXT_PRIMARY}; background: transparent; }}
        #CardSubtitle {{ font-size: 13px; color: {TEXT_SECONDARY}; background: transparent; }}
        #PrimaryButton {{ background: {ACCENT}; color: #FFFFFF; border: none;
                          border-radius: 10px; font-size: 15px; font-weight: 700; }}
        #PrimaryButton:hover {{ background: #1A86D8; }}
        #PrimaryButton:pressed {{ background: {ACCENT_PRESSED}; }}
        QCheckBox {{ font-size: 14px; color: {TEXT_SECONDARY}; }}
        """
    )


def main() -> int:
    app = QApplication([])
    app.setApplicationName("xuan-welcome")
    apply_styles(app)
    window = WelcomeWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
