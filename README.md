# Hermes Agent One-Click Deploy

[Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research — an open-source self-evolving AI agent. This repo bundles the upstream release into a **zero-network, one-click** install package. Download, extract, double-click, done.

Bundled version: **v0.12.0** (2026-04-30)

---

## Download

Go to [Releases](../../releases/latest) and pick your platform:

| Platform | File | Notes |
|----------|------|-------|
| **Windows** 10 / 11 | `hermes-deploy-windows-x.x.x.zip` | Offline install — all Python deps pre-bundled as wheels + GUI launcher (Hermes.exe) |
| **Linux** / macOS / WSL2 | `hermes-deploy-linux-x.x.x.tar.gz` | CLI install |

Each release includes `checksums.txt` for file integrity verification.

---

## Windows Installation

### One-click install (CLI)

1. Download and extract `hermes-deploy-windows-x.x.x.zip`
2. Double-click `install.cmd`
3. When notepad opens, fill in your API Key, save, close
4. Restart terminal, run: `hermes`

**No network needed** — all Python dependencies are pre-bundled as `.whl` files. Install takes ~30 seconds on a typical machine.

Or via PowerShell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install.ps1
```

**Optional parameters:**

```powershell
.\install.ps1 -SkipSetup                  # Skip API key prompt
.\install.ps1 -HermesHome "D:\hermes"     # Custom data directory
```

### Extended install (with GUI launcher)

Adds **Hermes.exe** — a dark-themed Windows GUI launcher with:
- Multi-workspace (Profile) management
- Real-time DeepSeek balance display
- Start Menu / Desktop shortcuts

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\windows\install-extended.ps1
```

**Optional parameters:**

```powershell
.\windows\install-extended.ps1 -SkipSetup
.\windows\install-extended.ps1 -HermesHome "D:\hermes"
.\windows\install-extended.ps1 -BuildExe     # Compile EXE from source
```

Launch via:

| Method | Launcher |
|--------|----------|
| Start Menu | Hermes Agent (GUI) |
| Desktop | Hermes Agent shortcut |
| Terminal | `hermes` |

### Files after install

```
%LOCALAPPDATA%\hermes\
├── .env              ← API Key (required)
├── config.yaml       ← Config
├── sessions\         ← Chat history
├── logs\
├── profiles\         ← Multi-workspace configs
├── launcher\         ← GUI launcher (extended install)
│   ├── Hermes.exe
│   ├── icon.ico
│   └── app_icon.png
└── hermes-agent\     ← Program (both installs)
    └── venv\
```

---

## Linux / macOS / WSL2 Installation

**Requirements:** Ubuntu 20.04+, Debian 11+, Fedora 36+, Arch, openSUSE, Alpine, macOS 12+, WSL2

```bash
tar -xzf hermes-deploy-linux-x.x.x.tar.gz
cd hermes-deploy-linux-x.x.x
bash install.sh
# Reload shell: source ~/.bashrc (or ~/.zshrc)
hermes setup    # Configure API Key
hermes          # Start chatting
```

**Optional parameters:**

```bash
bash install.sh --skip-setup
bash install.sh --hermes-home /opt/hermes
```

**Files after install:**

```
~/.hermes/
├── .env              ← API Key (required)
├── config.yaml       ← Config
├── sessions/         ← Chat history
├── logs/
└── hermes-agent/     ← Program
```

---

## API Key Setup

Edit `.env` and fill in at least one provider's API Key:

| Provider | Env Variable | Get Key |
|----------|-------------|---------|
| DeepSeek (recommended) | `DEEPSEEK_API_KEY` | https://platform.deepseek.com/api_keys |
| OpenRouter (200+ models) | `OPENROUTER_API_KEY` | https://openrouter.ai/keys |
| Anthropic (Claude) | `ANTHROPIC_API_KEY` | https://console.anthropic.com |
| OpenAI | `OPENAI_API_KEY` | https://platform.openai.com |
| Google Gemini | `GOOGLE_API_KEY` | https://aistudio.google.com |
| Kimi / Moonshot | `KIMI_API_KEY` | https://platform.kimi.ai |
| GLM / z.ai | `GLM_API_KEY` | https://z.ai |
| MiniMax | `MINIMAX_API_KEY` | https://www.minimax.io |

Or run `hermes setup` for an interactive configuration wizard.

---

## GUI Launcher Features (Windows Extended)

Launch "Hermes Agent" from the Start Menu:

![Launcher preview](https://img.shields.io/badge/GUI-Dark%20Theme%20Launcher-0ea5e9)

- **Workspace management** — Multiple profiles, each with independent model, API key, and working directory
- **Balance monitor** — Auto-fetches DeepSeek account balance, refreshes every minute
- **Hotkeys** — `↑↓` switch workspace, `Enter` launch, `Esc` quit
- **One-click launch** — Opens Hermes chat after selecting a workspace

---

## Common Commands

```bash
hermes              # Start chatting
hermes setup        # Configure API key and settings
hermes model        # Switch LLM model
hermes gateway      # Start message gateway (Telegram / Discord / Slack)
hermes skills       # Browse and install skills (optional, on demand)
hermes doctor       # Diagnose issues
hermes update       # Online update to latest version
```

---

## FAQ

**Q: `hermes: command not found` after install**
A: Restart your terminal. Windows users open a new terminal window. Linux/macOS: `source ~/.bashrc` or `source ~/.zshrc`.

**Q: Windows says "running scripts is disabled"**
A: In PowerShell, run: `Set-ExecutionPolicy Bypass -Scope Process -Force`

**Q: Basic vs Extended install?**
A:

| | Basic | Extended |
|------|-------|----------|
| Hermes CLI | Yes | Yes |
| GUI launcher (Hermes.exe) | No | Yes |
| Start Menu / Desktop shortcuts | No | Yes |
| Balance display | No | Yes |
| Multi-workspace | No | Yes |
| Disk usage | ~500 MB | ~520 MB |

**Q: Does install need network? (Windows)**
A: No. All Python dependencies are pre-bundled as wheels in the zip. The installer only falls back to network if your Python version differs from the bundled wheels (Python 3.12).

**Q: How to update?**
A: Run `hermes update` for online updates. For new deploy package versions, re-download and run the installer — your existing `.env` and `config.yaml` are preserved.

**Q: Where to install Skills?**
A: Skills are optional. After installing Hermes Agent, run `hermes skills` anytime to browse and install on demand.

**Q: GUI launcher won't open?**
A: Make sure basic install completed (Python 3.11+, `%LOCALAPPDATA%\hermes\hermes-agent\venv\Scripts\hermes.exe` exists). If missing, re-run `.\windows\install-extended.ps1`.

**Q: How to uninstall?**
A: Delete the data directory:
- Windows: `%LOCALAPPDATA%\hermes\`
- Linux/macOS: `rm -rf ~/.hermes/`

Also remove hermes from PATH (Windows: System Environment Variables, Linux: remove lines from shell config).

---

## Project Structure

```
hermes-windows-deploy/
├── install.cmd                # Root entry point (Windows)
├── install.ps1                # Root entry point (PowerShell)
├── install.sh                 # Root entry point (Linux/macOS)
├── windows/                   # Windows installers
│   ├── install.ps1            #   Offline-first install (CLI)
│   ├── install.cmd            #   CMD entry point
│   └── install-extended.ps1   #   Extended install (with GUI launcher)
├── linux/                     # Linux / macOS installer
│   └── install.sh
├── launcher/                  # GUI launcher source
│   ├── launcher_deploy.py     #   Deploy launcher (auto path detection)
│   ├── Hermes_deploy.spec     #   PyInstaller build config
│   ├── launcher.bat           #   Launcher script
│   ├── install_shortcut.ps1   #   Shortcut installer
│   ├── icon.ico               #   Icon
│   └── app_icon.png           #   App icon
├── vendor/hermes-agent/       # Hermes Agent upstream source (v0.12.0)
├── .github/workflows/         # CI/CD (auto-build EXE + bundle wheels on tag)
│   └── release.yml
├── config.yaml                # Default config template
├── .env.example               # API Key template
└── README.md
```

The `wheels/` and `uv.exe` in the release zip are CI-generated offline bundles — not committed to source control.

---

## About This Repo

This repo packages [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) as an offline install bundle, solving:

- Upstream requires live GitHub clone — fails behind firewalls or slow networks
- Windows requires extra adaptation (upstream doesn't officially support native Windows)
- Unified cross-platform entry point with version snapshots
- Optional **Windows GUI launcher** with multi-workspace and balance monitoring

Release CI builds Hermes.exe and bundles all Python wheels on every tag push. The repo maintainer periodically syncs the latest upstream release.

---

## License

Hermes Agent is under [MIT License](vendor/hermes-agent/LICENSE).
