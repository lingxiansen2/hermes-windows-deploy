# Hermes Agent Windows Deploy

One-click release packages for [Hermes Agent](https://github.com/NousResearch/hermes-agent).

## Download

Download the latest installer from [Releases](https://github.com/lingxiansen2/hermes-windows-deploy/releases/latest).

| Platform | File | How to install |
| --- | --- | --- |
| Windows 10/11 | `hermes-deploy-windows-*.zip` | Extract, then double-click `install.cmd` |
| Linux / macOS / WSL2 | `hermes-deploy-linux-*.tar.gz` | Extract, then run `bash install.sh` |

Do not use **Code -> Download ZIP** for installation. That button downloads source code only and does not include the bundled Python runtime.

## Windows Install Steps

1. Open the [latest release](https://github.com/lingxiansen2/hermes-windows-deploy/releases/latest).
2. Download `hermes-deploy-windows-*.zip`.
3. Extract the ZIP file.
4. Double-click `install.cmd`.
5. Fill in your API key when Notepad opens.
6. Restart your terminal and run `hermes`.

The Windows release includes portable Python 3.12, Hermes Agent dependencies, PortableGit, and the GUI launcher.

## Source Code

The source and packaging workflow live on the [`master`](https://github.com/lingxiansen2/hermes-windows-deploy/tree/master) branch.

## License

Hermes Agent is distributed under the [MIT License](https://github.com/NousResearch/hermes-agent/blob/main/LICENSE).
