# Hermes Windows Deploy
Windows setup package for Hermes Agent.
## Requirements
- Windows 10 or Windows 11
- Python 3.11 or newer. Python 3.11/3.12 are tested; newer versions such as 3.14 are allowed with a warning.
- Git for Windows recommended
- Node.js optional, useful for some web and MCP workflows
## Quick Start
1. Clone or download this repository.
2. If Python 3.11+ is not installed, setup.bat will try to install Python 3.12 with winget.
3. Copy `.env.example` to `.env` if setup does not do it for you.
4. Edit `.env` and fill in your API keys.
5. Double-click `setup.bat`.
6. Press Win and search for `Hermes`, or run `launcher\launcher.bat`.
## Install Source
`setup.bat` installs Hermes Agent from the bundled local source folder:
`vendor\hermes-agent`
It does not use `pip install hermes-agent`, because Hermes Agent is not currently distributed through PyPI under that package name. This also avoids slow GitHub source downloads during setup.
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
- `vendor\hermes-agent` - bundled Hermes Agent source used by setup.
## Troubleshooting
If setup prints text such as "not recognized as an internal or external command", make sure you are using the latest version of this repository. The batch files are intentionally ASCII-only so Windows cmd.exe can parse them on any locale.
If setup cannot install Python automatically, install Python 3.12 manually from https://python.org and rerun setup. Python 3.14 is not blocked, but dependency installation may still fail because it is newer than the tested range.
If bundled source installation fails, make sure the `vendor\hermes-agent` folder exists and rerun setup.
