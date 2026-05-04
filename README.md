# Hermes Windows Deploy
Windows setup package for Hermes Agent.
## Requirements
- Windows 10 or Windows 11
- Python 3.11 or 3.12. Python 3.14 is not supported by this deploy package yet.
- Git for Windows recommended
- Node.js optional, useful for some web and MCP workflows
## Quick Start
1. Install Python 3.12 from https://python.org and enable "Add Python to PATH".
2. Clone or download this repository.
3. Copy `.env.example` to `.env` if setup does not do it for you.
4. Edit `.env` and fill in your API keys.
5. Double-click `setup.bat`.
6. Press Win and search for `Hermes`, or run `launcher\launcher.bat`.
## Install Source
`setup.bat` installs Hermes Agent from the official GitHub source archive:
`https://github.com/NousResearch/hermes-agent/archive/refs/heads/main.zip`
It does not use `pip install hermes-agent`, because Hermes Agent is not currently distributed through PyPI under that package name.
## API Keys
- `DEEPSEEK_API_KEY` is required for the default model configuration.
- `TAVILY_API_KEY` is optional for web search workflows.
- `GITHUB_TOKEN` is optional for GitHub API workflows.
## Files
- `setup.bat` - installs Hermes and prepares local config.
- `install_skills.bat` - installs optional Hermes skills.
- `config.yaml` - Hermes configuration copied into `.hermes`.
- `.env.example` - API key template.
- `launcher\launcher.bat` - starts the Python launcher.
- `launcher\install_shortcut.ps1` - registers a Start Menu shortcut.
## Troubleshooting
If setup prints text such as "not recognized as an internal or external command", make sure you are using the latest version of this repository. The batch files are intentionally ASCII-only so Windows cmd.exe can parse them on any locale.
If setup says Python is unsupported, install Python 3.12 and rerun setup. If `.venv` was already created with Python 3.14, delete `.venv` first.
If GitHub source installation fails, check network access to `github.com` and rerun setup.
