# Hermes Agent 一键部署

[Hermes Agent](https://github.com/NousResearch/hermes-agent) 是 Nous Research 出品的开源自进化 AI Agent。本仓库将官方版本打包为**开箱即用**的一键安装包，下载后无需额外网络即可完成安装。

当前内置版本：**v0.12.0**（2026-04-30）

---

## 下载

前往 [Releases 页面](../../releases/latest) 下载对应平台的安装包：

| 平台 | 文件 | 说明 |
|------|------|------|
| **Windows** 10 / 11 | `hermes-deploy-windows-x.x.x.zip` | 含 GUI 启动器 (Hermes.exe) |
| **Linux** / macOS / WSL2 | `hermes-deploy-linux-x.x.x.tar.gz` | 命令行安装 |

每个 Release 还附有 `checksums.txt`，可用于校验文件完整性。

---

## Windows 安装

### 方式一：基础安装（仅 CLI）

最轻量的安装方式，只安装 Hermes Agent 命令行工具。

**第一步：** 下载并解压 `hermes-deploy-windows-x.x.x.zip`

**第二步：** 进入解压目录，双击 `windows\install.cmd`

或在 PowerShell 中运行：

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\windows\install.ps1
```

**第三步：** 安装完成后，**重启终端**，运行：

```powershell
hermes setup    # 配置 API Key（必须）
hermes          # 开始对话
```

**可选参数：**

```powershell
.\windows\install.ps1 -SkipSetup                  # 跳过配置向导
.\windows\install.ps1 -HermesHome "D:\hermes"     # 自定义数据目录
```

### 方式二：拓展安装（含 GUI 启动器）

在基础安装之上，额外安装 **Hermes.exe** — 一个可视化的 Windows 启动器，支持：
- 🎨 深色主题 GUI 界面
- 📂 多工作区 (Profile) 管理
- 💰 DeepSeek 实时余额显示
- 🚀 一键启动 + 开始菜单/桌面快捷方式

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\windows\install-extended.ps1
```

**可选参数：**

```powershell
.\windows\install-extended.ps1 -SkipSetup           # 跳过配置向导
.\windows\install-extended.ps1 -HermesHome "D:\hermes" # 自定义数据目录
.\windows\install-extended.ps1 -BuildExe             # 从源码编译 EXE（而非用预编译版）
```

安装完成后通过以下方式启动：

| 方式 | 启动器 |
|------|--------|
| 开始菜单 | Hermes Agent (GUI) |
| 桌面 | Hermes Agent 快捷方式 |
| 命令行 | `hermes` |

### 安装后文件位置

```
%LOCALAPPDATA%\hermes\
├── .env              ← API Key（必填）
├── config.yaml       ← 配置文件
├── sessions\         ← 对话记录
├── logs\
├── profiles\         ← 多工作区配置
├── launcher\         ← GUI 启动器 (拓展安装)
│   ├── Hermes.exe
│   ├── icon.ico
│   └── app_icon.png
└── hermes-agent\     ← 程序目录 (基础/拓展均安装)
    └── venv\
```

---

## Linux / macOS / WSL2 安装

**系统要求：** Ubuntu 20.04+、Debian 11+、Fedora 36+、Arch、openSUSE、Alpine、macOS 12+、WSL2

**第一步：** 下载并解压 `hermes-deploy-linux-x.x.x.tar.gz`

```bash
tar -xzf hermes-deploy-linux-x.x.x.tar.gz
cd hermes-deploy-linux-x.x.x
```

**第二步：** 运行安装脚本：

```bash
bash linux/install.sh
```

**第三步：** 重载 shell，然后配置 API Key：

```bash
source ~/.bashrc    # 或 source ~/.zshrc
hermes setup        # 配置 API Key（必须）
hermes              # 开始对话
```

**可选参数：**

```bash
bash linux/install.sh --skip-setup                  # 跳过配置向导
bash linux/install.sh --hermes-home /opt/hermes     # 自定义数据目录
```

**安装后文件位置：**

```
~/.hermes/
├── .env              ← API Key（必填）
├── config.yaml       ← 配置文件
├── sessions/         ← 对话记录
├── logs/
└── hermes-agent/     ← 程序目录
```

---

## 配置 API Key

安装完成后编辑 `.env` 文件，填入至少一个模型提供商的 API Key：

| 提供商 | 环境变量 | 获取地址 |
|--------|----------|----------|
| DeepSeek（推荐） | `DEEPSEEK_API_KEY` | https://platform.deepseek.com/api_keys |
| OpenRouter（200+ 模型） | `OPENROUTER_API_KEY` | https://openrouter.ai/keys |
| Anthropic（Claude） | `ANTHROPIC_API_KEY` | https://console.anthropic.com |
| OpenAI | `OPENAI_API_KEY` | https://platform.openai.com |
| Google Gemini | `GOOGLE_API_KEY` | https://aistudio.google.com |
| Kimi / Moonshot | `KIMI_API_KEY` | https://platform.kimi.ai |
| GLM / z.ai | `GLM_API_KEY` | https://z.ai |
| MiniMax | `MINIMAX_API_KEY` | https://www.minimax.io |

也可以直接运行 `hermes setup` 通过交互向导完成配置。

---

## GUI 启动器功能 (Windows 拓展安装)

拓展安装后，从开始菜单启动 "Hermes Agent" 即可打开可视化启动器：

![启动器预览](https://img.shields.io/badge/GUI-Dark%20Theme%20Launcher-0ea5e9)

- **工作区管理** — 创建多个 Profile，每个 Profile 独立配置模型、API Key 和工作目录
- **余额监控** — 自动查询 DeepSeek 账户余额，每分钟刷新一次
- **快捷键** — `↑↓` 切换工作区，`Enter` 启动，`Esc` 退出
- **一键启动** — 选择工作区后自动进入 Hermes 对话界面

---

## 常用命令

```bash
hermes              # 开始对话
hermes setup        # 配置 API Key 和设置
hermes model        # 切换 LLM 模型
hermes gateway      # 启动消息网关（Telegram / Discord / Slack 等）
hermes skills       # 浏览和安装 Skills（可选功能，按需安装）
hermes doctor       # 诊断问题
hermes update       # 在线更新到最新版本
```

---

## 常见问题

**Q：安装后提示 `hermes: command not found`**  
A：重启终端，或手动执行 `source ~/.bashrc`（Linux）。Windows 用户打开新的终端窗口。

**Q：Windows 提示"此系统上禁止运行脚本"**  
A：在 PowerShell 中先运行：`Set-ExecutionPolicy Bypass -Scope Process -Force`

**Q：基础安装 vs 拓展安装的区别？**  
A：

| | 基础安装 | 拓展安装 |
|------|----------|----------|
| Hermes CLI | ✅ | ✅ |
| GUI 启动器 (Hermes.exe) | ❌ | ✅ |
| 开始菜单/桌面快捷方式 | ❌ | ✅ |
| 余额显示 | ❌ | ✅ |
| 多工作区管理 | ❌ | ✅ |
| 磁盘占用 | ~300 MB | ~320 MB |

**Q：依赖安装很慢**  
A：脚本使用 uv 安装依赖，比 pip 快 10-100 倍。若仍缓慢，可能是 PyPI 网络问题，稍后重试。

**Q：如何更新？**  
A：运行 `hermes update` 在线更新。若要使用本仓库新版安装包，重新下载并运行安装脚本即可，已有的 `.env` 和 `config.yaml` 不会被覆盖。

**Q：Skills 在哪里安装？**  
A：Skills 是可选功能，安装好 Hermes Agent 后随时可以通过 `hermes skills` 命令按需安装，无需在初始安装时处理。

**Q：GUI 启动器打不开？**  
A：确保已安装基础环境（Python 3.11+），并且 `%LOCALAPPDATA%\hermes\hermes-agent\venv\Scripts\hermes.exe` 存在。如缺失，重新运行 `windows\install-extended.ps1`。

**Q：如何卸载？**  
A：删除数据目录即可：
- Windows：删除 `%LOCALAPPDATA%\hermes\`
- Linux/macOS：`rm -rf ~/.hermes/`

并从 PATH 中移除对应路径（Windows 用系统环境变量设置，Linux 删除 shell 配置里的相关行）。

---

## 项目结构

```
hermes-windows-deploy/
├── windows/                  # Windows 安装
│   ├── install.ps1           #    基础安装（仅 CLI）
│   ├── install.cmd           #    基础安装 .cmd 入口
│   └── install-extended.ps1  #    拓展安装（含 GUI 启动器）
├── linux/                    # Linux / macOS 安装
│   └── install.sh
├── launcher/                 # GUI 启动器源码
│   ├── launcher_deploy.py    #    部署版启动器（路径自动发现）
│   ├── Hermes_deploy.spec    #    PyInstaller 编译配置
│   ├── launcher.bat          #    启动脚本
│   ├── install_shortcut.ps1  #    快捷方式安装脚本
│   ├── icon.ico              #    图标
│   └── app_icon.png          #    应用图标
├── vendor/hermes-agent/      # Hermes Agent 上游源码（v0.12.0）
├── .github/workflows/        # CI/CD (Release 自动构建 EXE)
│   └── release.yml
├── config.yaml               # 默认配置模板
├── .env.example              # API Key 模板
└── README.md
```

---

## 关于本仓库

本仓库将 [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) 打包为离线安装包，解决以下问题：

- 官方脚本需要从 GitHub 实时 clone，在网络受限环境下体验差
- Windows 原生安装需要额外适配（官方标注不支持 Windows 原生）
- 提供统一的跨平台安装入口与版本快照
- 提供可选的 **Windows 原生 GUI 启动器**，支持多工作区和余额监控

Release CI 在每次打 tag 时自动在 Windows 环境中编译 Hermes.exe 并打包进发布包。

仓库由维护者定期同步上游最新版本并发布新的 Release。

---

## 许可证

Hermes Agent 遵循 [MIT License](vendor/hermes-agent/LICENSE)。
