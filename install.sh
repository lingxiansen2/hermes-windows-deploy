#!/bin/bash
# =============================================================================
# Hermes Agent 一键安装 — Linux / macOS / WSL2 入口
# 用法：bash install.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER="$SCRIPT_DIR/linux/install.sh"

if [ ! -f "$INSTALLER" ]; then
    echo "  [ERROR] 找不到 linux/install.sh"
    echo "  请解压完整的安装包后再运行本脚本。"
    echo "  安装包下载：https://github.com/lingxiansen2/hermes-windows-deploy/releases"
    exit 1
fi

# 委托到 linux/install.sh（传递所有参数）
exec bash "$INSTALLER" "$@"
