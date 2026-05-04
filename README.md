# Hermes Windows 一键部署包

> 10 分钟内拥有一个带网络搜索、编程 Skills、可视化启动器的本地 AI 编程助手

## 你将得到什么

- **Hermes Agent** — 开源 AI Agent，本地运行，支持 DeepSeek V4 等模型
- **联网搜索** — 通过 Tavily API 实时搜索网页
- **编程 Skills** — 13+ 编程相关技能（代码审查、调试、TDD、Docker、向量搜索等）
- **可视化启动器** — 图形化选择工作目录，实时显示 API 余额
- **多 Profile 支持** — 不同项目独立工作区，一键切换

## 前置要求

| 需求 | 说明 |
|------|------|
| Windows 10/11 | 64 位 |
| Python 3.8+ | [python.org](https://python.org) 下载 |
| Git | [git-scm.com](https://git-scm.com) 下载 |
| Node.js (可选) | 浏览器自动化需要，[nodejs.org](https://nodejs.org) |

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/YOUR_USERNAME/hermes-windows-deploy.git
cd hermes-windows-deploy
```

### 2. 获取 API Key

你需要两个 Key：

| Key | 用途 | 获取地址 | 费用 |
|-----|------|---------|------|
| **DeepSeek API Key** | 大模型推理 | [platform.deepseek.com](https://platform.deepseek.com) → API Keys | 按量付费 |
| **Tavily API Key** | 网页搜索 | [tavily.com](https://tavily.com) → Dashboard → API Keys | 免费 1000次/月 |
| **GitHub Token** (可选) | GitHub API 高限额 | [github.com/settings/tokens](https://github.com/settings/tokens) | 免费 |

### 3. 配置 Key

复制 `.env.example` 为 `.env`，填入你的 Key：

```bash
copy .env.example .env
```

然后用记事本编辑 `.env`：

```
DEEPSEEK_API_KEY=sk-你的deepseek-key
TAVILY_API_KEY=tvly-你的tavily-key
GITHUB_TOKEN=github_pat_你的github-token
```

### 4. 一键安装

双击 **`setup.bat`**，脚本会自动：

1. 检查 Python / Git 环境
2. 安装 Hermes Agent
3. 部署配置文件和 Skills
4. 创建桌面快捷方式

### 5. 启动

安装完成后，有三种方式启动：

| 方式 | 操作 |
|------|------|
| Win 搜索 | 按 `Win` 键 → 输入 `Hermes` → 点击图标 |
| 桌面快捷方式 | 双击 `Hermes Launcher` |
| 命令行 | `hermes` |

## 目录结构

```
hermes-windows-deploy/
├── README.md                 ← 本文件
├── setup.bat                 ← 一键安装脚本
├── config.yaml               ← Hermes 配置模板
├── .env.example              ← 环境变量模板
├── .gitignore
├── install_skills.bat        ← 批量安装编程 Skills
├── launcher/                 ← 可视化启动器
│   ├── launcher.py           ← Python GUI 程序
│   ├── launcher.bat          ← 启动包装
│   └── install_shortcut.ps1  ← 注册到开始菜单
└── scripts/                  ← 辅助脚本
    └── balance_monitor.py    ← API 余额监控
```

## 已安装的 Skills

安装后自动获得以下编程技能：

| 分类 | Skills |
|------|--------|
| 代码委托 | blackbox（Blackbox AI） |
| 代码审查 | code-review, systematic-debugging |
| 测试 | test-driven-development |
| 开发流程 | plan, spike, writing-plans |
| Docker | docker-management |
| 代码库分析 | gitnexus-explorer |
| 向量搜索 | chroma, faiss |
| 结构化输出 | guidance, instructor |
| 网页抓取 | scrapling |
| 搜索 | duckduckgo-search |
| 架构图 | concept-diagrams |
| MCP 工具 | fastmcp |

## 常见问题

**Q: 如何切换模型？**
A: 编辑 `.hermes/config.yaml` 中的 `models.default` 部分，支持 Anthropic、OpenAI、OpenRouter 等 20+ 提供商。

**Q: 如何添加新项目的 Profile？**
A: 打开启动器 GUI → 点击 `+ 新建 Profile` → 输入名称和工作目录。

**Q: 浏览器自动化不工作？**
A: 确保安装了 Node.js，然后在终端运行：
```
npm install -g playwright
playwright install chromium
```

**Q: 如何更新 Hermes？**
A: 在 Hermes 对话中输入 `/update`，或在终端运行 `pip install --upgrade hermes-agent`。

## License

MIT
