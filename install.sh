#!/bin/bash
# =============================================================================
# Hermes Agent one-click installer - Linux / macOS / WSL2 entry point
# Usage: bash install.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALLER="$SCRIPT_DIR/linux/install.sh"

if [ ! -f "$INSTALLER" ]; then
    echo "  [ERROR] linux/install.sh was not found."
    echo "  Please extract the full release package before running this script."
    echo "  Download: https://github.com/lingxiansen2/hermes-windows-deploy/releases"
    exit 1
fi

# Delegate to linux/install.sh and pass all arguments through.
exec bash "$INSTALLER" "$@"
