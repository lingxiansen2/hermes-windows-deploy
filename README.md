# Hermes Windows Deploy

这是一个面向 Windows 用户的 Hermes Agent 一键部署包。

目标是让用户下载项目后，直接运行 `setup.bat` 完成基础环境、Hermes Agent、本地配置、可选 skills 和开始菜单快捷方式的安装。

## 系统要求

- Windows 10 或 Windows 11
- Python 3.11 或更高版本
- 推荐使用 Python 3.11 / 3.12；Python 3.14 不会被拦截，但会显示兼容性警告
- Git for Windows 推荐安装，但不是基础安装的强依赖
- Node.js 可选，部分 Web / MCP 工作流可能会用到

## 快速开始

1. 下载或克隆本仓库。
2. 复制 `.env.example` 为 `.env`，或让 `setup.bat` 首次运行时自动创建。
3. 编辑 `.env`，填入自己的 API Key。
4. 双击运行 `setup.bat`。
5. 安装完成后，按 `Win` 搜索 `Hermes` 启动，或运行 `launcher\launcher.bat`。

如果没有可用的 Python 3.11+，`setup.bat` 会尝试通过 `winget` 安装 Python 3.12。若自动安装失败，请手动安装 Python 3.12 后重新运行。

## 安装来源

`setup.bat` 会从仓库内置源码安装 Hermes Agent：

```text
vendor\hermes-agent
```

它不会执行：

```text
pip install hermes-agent
```

原因是 Hermes Agent 当前不通过这个 PyPI 包名分发。把源码放进本仓库后，也可以避免用户在安装阶段下载 GitHub 源码过慢的问题。

注意：Python 依赖包仍然需要通过 `pip` 安装。如果用户访问 PyPI 很慢，可以后续再增加镜像源或离线 wheels 包。

## API Key

`.env` 中常用字段：

```env
DEEPSEEK_API_KEY=
TAVILY_API_KEY=
GITHUB_TOKEN=
```

- `DEEPSEEK_API_KEY`：默认模型配置需要。
- `TAVILY_API_KEY`：可选，用于部分 Web 搜索工作流。
- `GITHUB_TOKEN`：可选，用于 GitHub API 工作流。

不要把填写了真实 key 的 `.env` 提交到 GitHub，也不要发给别人。

## 文件说明

- `setup.bat`：主安装脚本。
- `install_skills.bat`：安装可选 Hermes skills。
- `config.yaml`：Hermes 配置模板，会复制到 `.hermes`。
- `.env.example`：API Key 模板。
- `launcher\launcher.bat`：启动 Python launcher。
- `launcher\install_shortcut.ps1`：注册开始菜单快捷方式。
- `vendor\hermes-agent`：内置 Hermes Agent 源码。

## 编码说明

本项目里的 `.bat` 文件刻意保持英文 ASCII 输出，避免 Windows `cmd.exe` 在不同系统区域设置下把中文误解析成命令。

`README.md` 使用中文是安全的，GitHub 会按 UTF-8 正常渲染，不影响 `setup.bat` 执行。

## 常见问题

### setup.bat 提示 “not recognized as an internal or external command”

请确认你使用的是最新版本。本仓库的批处理脚本已经改为 ASCII-only，正常情况下不会再因为中文编码导致命令被拆开执行。

### Python 3.14 能不能用？

可以继续尝试。脚本不会拦截 Python 3.14，只会提示它比已测试范围更新。

如果后续依赖安装失败，建议安装 Python 3.12，删除已有 `.venv` 后重新运行 `setup.bat`。

### 提示找不到 vendor\hermes-agent

说明你可能只复制了部分文件。请下载或发送完整项目目录，不能只发送 `setup.bat`。
