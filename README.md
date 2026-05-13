# Hermes Agent Windows Deploy

One-click Windows packages for [Hermes Agent](https://github.com/NousResearch/hermes-agent).

> Download from **Releases**, not from the green **Code -> Download ZIP** button. The source ZIP does not contain the bundled Python runtime.

## Download

Get the latest package from [Releases](../../releases/latest).

| Platform | Download | Install |
| --- | --- | --- |
| Windows 10/11 | `hermes-deploy-windows-*.zip` | Extract, then double-click `install.cmd` |
| Linux / macOS / WSL2 | `hermes-deploy-linux-*.tar.gz` | Extract, then run `bash install.sh` |

Bundled Hermes Agent: **v0.12.0**.

## Windows Quick Start

1. Open [latest release](../../releases/latest).
2. Download `hermes-deploy-windows-*.zip`.
3. Extract the ZIP.
4. Double-click `install.cmd`.
5. Fill in your API key when Notepad opens.
6. Restart your terminal and run `hermes`.

The Windows package includes portable Python 3.12, Hermes Agent dependencies, PortableGit, and the GUI launcher. No system Python or pip setup is required.

## What Gets Installed

By default the installer writes to:

```text
%LOCALAPPDATA%\hermes\
  python\      portable Python + Hermes Agent
  git\         portable Git and Bash support
  .env         your API keys
  sessions\    chat history
  logs\
  memories\
  cron\
```

For a custom install location:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install.ps1 -HermesHome "D:\hermes"
```

## API Keys

After install, edit `%LOCALAPPDATA%\hermes\.env`.

| Provider | Variable | Key page |
| --- | --- | --- |
| DeepSeek | `DEEPSEEK_API_KEY` | https://platform.deepseek.com/api_keys |
| Tavily | `TAVILY_API_KEY` | https://tavily.com |
| OpenRouter | `OPENROUTER_API_KEY` | https://openrouter.ai/keys |
| Anthropic | `ANTHROPIC_API_KEY` | https://console.anthropic.com |
| OpenAI | `OPENAI_API_KEY` | https://platform.openai.com |

## Common Questions

**Do I need Python installed?**
No. The Windows release contains its own portable Python.

**Does install need internet access?**
No for the Windows release package. Dependencies are pre-bundled.

**Will it change my system Python?**
No. Hermes runs from `%LOCALAPPDATA%\hermes\python\`.

**How do I update?**
Download the newest release ZIP and run `install.cmd` again. Your existing `.env` is preserved.

**How do I uninstall?**
Delete `%LOCALAPPDATA%\hermes\` and remove the Hermes Python `Scripts` path from your user PATH if it was added.

## Repository Layout

```text
install.cmd / install.ps1   Windows entry points shipped in the release ZIP
install.sh                  Linux/macOS entry point
windows/                    Windows installer implementation
linux/                      Linux/macOS installer implementation
launcher/                   GUI launcher source and assets
vendor/hermes-agent/        Bundled upstream Hermes Agent source
.github/workflows/          Release packaging workflow
tools/                      Maintainer and legacy helper scripts
```

The generated release also contains `python/` and `git/`; those directories are created by CI and are intentionally not committed to this repository.

## License

Hermes Agent is distributed under the [MIT License](vendor/hermes-agent/LICENSE).
