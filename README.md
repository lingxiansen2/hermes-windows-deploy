# Hermes Windows Deploy
Windows setup package for Hermes Agent.
## Requirements
- Windows 10 or Windows 11
- Python 3.8+
- Git for Windows recommended
- Node.js optional, useful for some web and MCP workflows
## Quick Start
1. Clone or download this repository.
2. Copy `.env.example` to `.env` if setup does not do it for you.
3. Edit `.env` and fill in your API keys.
4. Double-click `setup.bat`.
5. Press Win and search for `Hermes`, or run `launcher\launcher.bat`.
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
If Python is not found, reinstall Python and enable "Add Python to PATH".
