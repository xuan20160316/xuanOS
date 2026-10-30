# 贡献指南

感谢你参与 xuan OS。这是一个纯开源项目，任何贡献都应能被自由审计。

## 提交 Issue

- 报告缺陷时写明：构建主机版本、复现步骤、期望与实际结果、相关日志；
- 兼容问题请附上 `~/.local/share/xuanos/logs/winrun.log` 中的相关片段；
- 功能建议请说明使用场景，而不仅是想要的实现。

## 提交代码

1. Fork 仓库并基于最新 `main` 创建分支，分支名使用描述性英文，如
   `fix/sddm-autologin`、`feat/update-mirror-ranking`。
2. 遵循现有代码风格：
   - Shell 使用 `set -euo pipefail`，变量加引号，注释用英文；
   - Python 遵循 PEP 8，通过 `python3 -m py_compile` 校验；
   - 提交信息使用祈使句，首行不超过 72 字符。
3. 提交前运行 `./tests/run_tests.sh`，确保全部静态检查通过。
4. 发起 Pull Request 时说明动机、改动范围与测试方式。

## 许可证约定

提交到本仓库的原创代码默认以 MIT 许可证授权。引入第三方代码时，必须
确认其许可证与 MIT 兼容，并在 PR 中注明来源与许可证；不得提交无法
自由再分发的专有素材（包括 Windows 商标、字体或图标）。

## 上游优先

如果你修复的问题来自上游组件（内核、KDE、Wine、archiso 等），请同时
考虑向上游提交；xuan OS 只在上游合并前维护必要的临时补丁。

## 沟通

请在公开 Issue 与讨论区交流，保持礼貌与就事论事，遵守
[行为准则](CODE_OF_CONDUCT.md)。
