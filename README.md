# Hermes Agent One-Click Deploy

[Hermes Agent](https://github.com/NousResearch/hermes-agent) by Nous Research — an open-source self-evolving AI agent. This repo bundles it into a **zero-dependency, zero-network** install package. No Python required. No pip. No compilation. Just extract and double-click.

Bundled version: **v0.12.0** (2026-04-30)

---

## Download

Go to [Releases](../../releases/latest):

| Platform | File | Notes |
|----------|------|-------|
| **Windows** 10 / 11 | `hermes-deploy-windows-x.x.x.zip` | Complete portable Python 3.12 + all deps + GUI launcher |
| **Linux** / macOS / WSL2 | `hermes-deploy-linux-x.x.x.tar.gz` | CLI install |

---

## Windows Installation

### How it works

The zip contains a complete, self-contained Python 3.12 environment with Hermes Agent and ALL dependencies pre-installed. No detection, no download, no compilation. The installer just copies files and sets PATH.

```
1. Download and extract the zip
2. Double-click install.cmd
3. Fill in your API key when notepad opens
4. Restart terminal, run: hermes
```

That's it. **Works on ANY Windows 10/11 machine** — clean install, corporate laptop with no admin rights, behind Great Firewall, anywhere.

### What the installer does

1. Copies `python/` (Python 3.12 + hermes-agent + all deps) to `%LOCALAPPDATA%\hermes\python\`
2. Adds `python\Scripts\` to user PATH
3. Creates `.env` for your API key and opens it in notepad
4. Done

### Optional: PowerShell

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install.ps1
.\install.ps1 -SkipSetup              # Skip API key prompt
.\install.ps1 -HermesHome "D:\hermes" # Custom directory
```

### Files after install

```
%LOCALAPPDATA%\hermes\
├── python\              ← Complete Python 3.12 + hermes + all deps
│   ├── python.exe
│   ├── Scripts\
│   │   └── hermes.exe   ← Run this
│   └── Lib\site-packages\
├── .env                  ← Your API key
├── sessions\             ← Chat history
├── logs\
├── memories\
└── cron\
```

---

## Linux / macOS / WSL2 Installation

```bash
tar -xzf hermes-deploy-linux-x.x.x.tar.gz
cd hermes-deploy-linux-x.x.x
bash install.sh
# Reload shell: source ~/.bashrc
hermes setup
hermes
```

---

## API Key Setup

After install, edit `%LOCALAPPDATA%\hermes\.env` (Windows) or `~/.hermes/.env` (Linux):

| Provider | Variable | Get Key |
|----------|----------|---------|
| DeepSeek (recommended) | `DEEPSEEK_API_KEY` | https://platform.deepseek.com/api_keys |
| OpenRouter | `OPENROUTER_API_KEY` | https://openrouter.ai/keys |
| Anthropic | `ANTHROPIC_API_KEY` | https://console.anthropic.com |
| OpenAI | `OPENAI_API_KEY` | https://platform.openai.com |

---

## FAQ

**Q: Do I need Python installed?**
A: No. The zip includes a complete Python 3.12 environment. It runs independently of any system Python.

**Q: Does it need internet during install?**
A: No. All dependencies are pre-installed. Zero network.

**Q: Will it conflict with my existing Python?**
A: No. The bundled Python runs from its own directory (`%LOCALAPPDATA%\hermes\python\`). Your system Python is untouched.

**Q: How large is the download?**
A: ~100 MB zip. Includes Python 3.12 (~30 MB compressed) + hermes-agent + all dependencies (~50 MB) + GUI launcher (~10 MB).

**Q: How to update?**
A: Run `hermes update` for online updates. For new versions, download the latest release zip and re-run install.cmd — your `.env` is preserved.

**Q: How to uninstall?**
A: Delete `%LOCALAPPDATA%\hermes\` and remove `python\Scripts\` from PATH (System Environment Variables).

---

## Project Structure

```
hermes-windows-deploy/
├── install.cmd                # Root entry point (double-click)
├── install.ps1                # Root entry point (PowerShell)
├── install.sh                 # Root entry point (Linux)
├── windows/                   # Windows installer
│   └── install.ps1            #   Copy python/, set PATH, create .env
├── linux/                     # Linux installer
│   └── install.sh
├── vendor/hermes-agent/       # Upstream source (v0.12.0)
├── launcher/                  # GUI launcher source
├── .github/workflows/         # CI: builds Hermes.exe + bundles portable Python
│   └── release.yml
├── config.yaml                # Default config
├── .env.example               # API key template
└── README.md
```

The `python/` directory in the release zip is CI-generated — a portable Python 3.12 with hermes-agent and all deps pre-installed. Not committed to source control.

---

## License

Hermes Agent is under [MIT License](vendor/hermes-agent/LICENSE).
