#!/bin/bash
# =============================================================================
# Hermes Agent 安装脚本 — Linux / macOS / WSL2
# =============================================================================
# 用法：
#   bash install.sh
#   bash install.sh --skip-setup          跳过交互式配置向导
#   bash install.sh --hermes-home /path   自定义数据目录（默认 ~/.hermes）
# =============================================================================

set -euo pipefail

# ── 颜色 ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; BOLD='\033[1m'; GRAY='\033[0;90m'; NC='\033[0m'

info()    { echo -e "  ${CYAN}→${NC} $*"; }
success() { echo -e "  ${GREEN}✓${NC} $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC} $*"; }
err()     { echo -e "  ${RED}✗${NC} $*"; }
hr()      { echo -e "  ${GRAY}─────────────────────────────────────────────────${NC}"; }

# ── 默认值 ────────────────────────────────────────────────────────────────
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKIP_SETUP=false
PYTHON_MIN_MAJOR=3
PYTHON_MIN_MINOR=11
PYTHON_INSTALL_FALLBACK="3.12"

# ── 解析参数 ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-setup)   SKIP_SETUP=true; shift ;;
        --hermes-home)  HERMES_HOME="$2"; shift 2 ;;
        -h|--help)
            echo "用法: bash install.sh [选项]"
            echo "  --skip-setup              跳过交互式配置向导"
            echo "  --hermes-home <路径>      自定义数据目录（默认 ~/.hermes）"
            exit 0 ;;
        *) err "未知参数: $1"; exit 1 ;;
    esac
done

# ── 定位 vendor 目录（脚本在 linux/ 子目录里，vendor 在上一级）────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/vendor/hermes-agent"
INSTALL_DIR="$HERMES_HOME/hermes-agent"

if [[ ! -d "$VENDOR_DIR" ]]; then
    err "找不到 vendor/hermes-agent 目录"
    err "请解压完整的安装包后再运行本脚本。"
    err "预期路径：$VENDOR_DIR"
    exit 1
fi

# ── Banner ────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${MAGENTA}${BOLD}┌────────────────────────────────────────────────┐${NC}"
echo -e "  ${MAGENTA}${BOLD}│    Hermes Agent  Linux/macOS 安装程序          │${NC}"
echo -e "  ${MAGENTA}${BOLD}│    by Nous Research  /  v0.12.0                │${NC}"
echo -e "  ${MAGENTA}${BOLD}└────────────────────────────────────────────────┘${NC}"
echo ""
info "源码路径：$VENDOR_DIR"
info "安装目标：$INSTALL_DIR"
info "数据目录：$HERMES_HOME"
hr

# ── Step 1：检测系统 ────────────────────────────────────────────────────────
OS="unknown"; DISTRO="unknown"
case "$(uname -s)" in
    Linux*)
        OS="linux"
        [[ -f /etc/os-release ]] && { source /etc/os-release; DISTRO="${ID:-unknown}"; }
        # WSL2 检测
        if grep -qi microsoft /proc/version 2>/dev/null; then
            success "检测到系统：Linux / WSL2 ($DISTRO)"
        else
            success "检测到系统：Linux ($DISTRO)"
        fi ;;
    Darwin*)
        OS="macos"; DISTRO="macos"
        success "检测到系统：macOS $(sw_vers -productVersion 2>/dev/null || true)" ;;
    CYGWIN*|MINGW*|MSYS*)
        err "检测到 Windows Git Bash / MSYS 环境"
        err "请改用 windows/ 目录下的 install.ps1 或 install.cmd"
        exit 1 ;;
    *)
        warn "未能识别的操作系统，将继续尝试安装" ;;
esac

# ── Step 2：检查 Git（vendor 已本地，git 仅作版本管理保留） ────────────────
info "检查 Git..."
if command -v git &>/dev/null; then
    success "Git $(git --version | awk '{print $3}')"
else
    warn "未找到 Git。Git 不是运行 Hermes 的必须条件，但建议安装。"
    case "$DISTRO" in
        ubuntu|debian)  warn "  sudo apt install git" ;;
        fedora|rhel*)   warn "  sudo dnf install git" ;;
        arch|manjaro)   warn "  sudo pacman -S git" ;;
        opensuse*)      warn "  sudo zypper install git" ;;
        alpine)         warn "  apk add git" ;;
        macos)          warn "  brew install git  或  xcode-select --install" ;;
    esac
fi

# ── Step 3：安装 uv ────────────────────────────────────────────────────────
info "检查 uv..."
UV_CMD=""
for try_uv in "uv" "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv"; do
    if command -v "$try_uv" &>/dev/null 2>&1; then
        UV_CMD="$try_uv"; break
    elif [[ -x "$try_uv" ]]; then
        UV_CMD="$try_uv"; break
    fi
done

if [[ -z "$UV_CMD" ]]; then
    info "uv 未找到，正在安装..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null; then
        for try_uv in "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv"; do
            [[ -x "$try_uv" ]] && { UV_CMD="$try_uv"; break; }
        done
        command -v uv &>/dev/null && UV_CMD="uv"
    fi
fi

if [[ -z "$UV_CMD" ]]; then
    err "uv 安装失败。请手动安装后重试：https://docs.astral.sh/uv/"
    exit 1
fi
success "uv 就绪：$UV_CMD ($($UV_CMD --version 2>/dev/null))"

# ── Step 4：确保 Python >= 3.11 ──────────────────────────────────────────────
info "检查 Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR..."
PYTHON_PATH=""
FOUND_PY_VERSION=""

# 辅助函数：检查版本字符串是否 >= 3.11
check_py_version() {
    local ver_str="$1"
    local major minor
    major=$(echo "$ver_str" | grep -oP '(\d+)(?=\.\d+)' | head -1)
    minor=$(echo "$ver_str" | grep -oP '\d+\.(\d+)' | head -1 | cut -d. -f2)
    [[ -z "$major" || -z "$minor" ]] && return 1
    (( major > PYTHON_MIN_MAJOR )) && return 0
    (( major == PYTHON_MIN_MAJOR && minor >= PYTHON_MIN_MINOR )) && return 0
    return 1
}

# 策略 1：用 uv python list 动态发现所有已安装版本，选最高的 >= 3.11
best_ver="" best_major=0 best_minor=0
if uv_list=$($UV_CMD python list --only-installed 2>/dev/null); then
    while IFS= read -r line; do
        if [[ "$line" =~ cpython-([0-9]+)\.([0-9]+) ]]; then
            maj="${BASH_REMATCH[1]}"
            min="${BASH_REMATCH[2]}"
            meets_min=false
            (( maj > PYTHON_MIN_MAJOR )) && meets_min=true
            (( maj == PYTHON_MIN_MAJOR && min >= PYTHON_MIN_MINOR )) && meets_min=true
            if $meets_min; then
                if (( maj > best_major )) || (( maj == best_major && min > best_minor )); then
                    best_major=$maj; best_minor=$min
                    best_ver="$maj.$min"
                fi
            fi
        fi
    done <<< "$uv_list"
fi

if [[ -n "$best_ver" ]]; then
    if PYTHON_PATH="$($UV_CMD python find "$best_ver" 2>/dev/null)" && [[ -n "$PYTHON_PATH" ]]; then
        FOUND_PY_VERSION="$best_ver"
        success "Python 已找到（通过 uv）：$($PYTHON_PATH --version 2>/dev/null)"
    fi
fi

# 策略 2：尝试系统 PATH 中的 python3 / python
if [[ -z "$FOUND_PY_VERSION" ]]; then
    for cmd in python3 python; do
        if command -v "$cmd" &>/dev/null; then
            ver_str=$($cmd --version 2>&1)
            if check_py_version "$ver_str"; then
                PYTHON_PATH="$(command -v "$cmd")"
                # 提取 major.minor
                FOUND_PY_VERSION=$(echo "$ver_str" | grep -oP '\d+\.\d+' | head -1)
                success "Python 已找到（系统）：$ver_str"
                break
            else
                warn "发现 $ver_str，但版本低于 $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR，跳过"
            fi
        fi
    done
fi

# 策略 3：以上全部失败，通过 uv 自动安装
if [[ -z "$FOUND_PY_VERSION" ]]; then
    info "未找到 Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR，通过 uv 安装 $PYTHON_INSTALL_FALLBACK..."
    $UV_CMD python install "$PYTHON_INSTALL_FALLBACK"
    PYTHON_PATH="$($UV_CMD python find "$PYTHON_INSTALL_FALLBACK")"
    FOUND_PY_VERSION="$PYTHON_INSTALL_FALLBACK"
    success "Python 安装完成：$($PYTHON_PATH --version 2>/dev/null)"
fi

if [[ -z "$FOUND_PY_VERSION" ]]; then
    err "Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR 安装失败。"
    err "请手动安装 Python 3.12 或更高版本："
    case "$DISTRO" in
        ubuntu|debian) err "  sudo apt install python3" ;;
        fedora|rhel*)  err "  sudo dnf install python3" ;;
        arch|manjaro)  err "  sudo pacman -S python" ;;
        macos)         err "  brew install python@3.12" ;;
        *)             err "  从 https://python.org 下载" ;;
    esac
    exit 1
fi

# ── Step 5：安装必要的系统编译工具（Ubuntu/Debian）────────────────────────
if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    missing_build=false
    for pkg in gcc python3-dev libffi-dev; do
        dpkg -s "$pkg" &>/dev/null || { missing_build=true; break; }
    done
    if $missing_build; then
        info "安装编译依赖（build-essential）..."
        if [[ "$(id -u)" -eq 0 ]]; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential python3-dev libffi-dev >/dev/null 2>&1 || true
        elif sudo -n true 2>/dev/null; then
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq build-essential python3-dev libffi-dev >/dev/null 2>&1 || true
        else
            warn "缺少编译依赖，若安装失败请手动运行：sudo apt install build-essential python3-dev libffi-dev"
        fi
    fi
fi

# ── Step 6：复制源码到安装目录 ────────────────────────────────────────────
info "部署程序文件..."
mkdir -p "$(dirname "$INSTALL_DIR")"
[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"
cp -r "$VENDOR_DIR" "$INSTALL_DIR"
success "程序文件已部署到：$INSTALL_DIR"

# ── Step 7：创建虚拟环境 ────────────────────────────────────────────────────
info "创建 Python 虚拟环境..."
cd "$INSTALL_DIR"
[[ -d "venv" ]] && rm -rf venv
$UV_CMD venv venv --python "$FOUND_PY_VERSION"
success "虚拟环境就绪"

# ── Step 8：安装 Python 依赖（核心 + 常用 extras，跳过 RL/skills）────────────
info "安装 Python 依赖（首次可能需要几分钟）..."
export VIRTUAL_ENV="$INSTALL_DIR/venv"

installed=false
for spec in ".[messaging,mcp,pty,honcho,cron,cli]" "."; do
    if $UV_CMD pip install -e "$spec" 2>/dev/null; then
        installed=true; break
    fi
done

if ! $installed; then
    err "依赖安装失败，请检查网络连接后重试。"
    exit 1
fi
success "Python 依赖安装完成"

# ── Step 9：链接 hermes 命令到 PATH ────────────────────────────────────────
info "配置 hermes 命令..."
HERMES_BIN="$INSTALL_DIR/venv/bin/hermes"

if [[ ! -x "$HERMES_BIN" ]]; then
    warn "hermes 可执行文件未找到，依赖可能未完整安装"
else
    LINK_DIR="$HOME/.local/bin"
    mkdir -p "$LINK_DIR"
    ln -sf "$HERMES_BIN" "$LINK_DIR/hermes"
    success "hermes → $LINK_DIR/hermes"

    # 写入 shell 配置（只要 ~/.local/bin 不在 PATH 里才写）
    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$LINK_DIR"; then
        LOGIN_SHELL="$(basename "${SHELL:-bash}")"
        CONFIGS=()
        case "$LOGIN_SHELL" in
            zsh)
                [[ -f "$HOME/.zshrc" ]] && CONFIGS+=("$HOME/.zshrc") || { touch "$HOME/.zshrc"; CONFIGS+=("$HOME/.zshrc"); }
                ;;
            bash)
                [[ -f "$HOME/.bashrc" ]]      && CONFIGS+=("$HOME/.bashrc")
                [[ -f "$HOME/.bash_profile" ]] && CONFIGS+=("$HOME/.bash_profile")
                ;;
            fish)
                FISH_CFG="$HOME/.config/fish/config.fish"
                mkdir -p "$(dirname "$FISH_CFG")"; touch "$FISH_CFG"
                grep -q 'fish_add_path.*\.local/bin' "$FISH_CFG" 2>/dev/null || \
                    printf '\n# Hermes Agent\nfish_add_path "$HOME/.local/bin"\n' >> "$FISH_CFG"
                export PATH="$LINK_DIR:$PATH"
                success "hermes 命令就绪（fish）"
                ;;
            *)
                [[ -f "$HOME/.bashrc" ]] && CONFIGS+=("$HOME/.bashrc")
                [[ -f "$HOME/.zshrc"  ]] && CONFIGS+=("$HOME/.zshrc")
                ;;
        esac
        [[ -f "$HOME/.profile" ]] && CONFIGS+=("$HOME/.profile")

        for cfg in "${CONFIGS[@]}"; do
            grep -v '^[[:space:]]*#' "$cfg" 2>/dev/null | grep -qE 'PATH.*\.local/bin' && continue
            printf '\n# Hermes Agent\n%s\n' "$PATH_LINE" >> "$cfg"
            success "已更新 $cfg"
        done
        export PATH="$LINK_DIR:$PATH"
    else
        info "~/.local/bin 已在 PATH 中"
    fi
fi

# ── Step 10：初始化数据目录（最小化，不同步 skills）─────────────────────────
info "初始化数据目录..."
mkdir -p "$HERMES_HOME"/{sessions,logs,memories,cron,hooks}

# .env
if [[ ! -f "$HERMES_HOME/.env" ]]; then
    tmpl="$INSTALL_DIR/.env.example"
    [[ -f "$tmpl" ]] && cp "$tmpl" "$HERMES_HOME/.env" || touch "$HERMES_HOME/.env"
    success "已创建 $HERMES_HOME/.env  ← 请填入你的 API Key"
else
    info ".env 已存在，保留原文件"
fi

# config.yaml
if [[ ! -f "$HERMES_HOME/config.yaml" ]]; then
    tmpl="$INSTALL_DIR/cli-config.yaml.example"
    [[ -f "$tmpl" ]] && { cp "$tmpl" "$HERMES_HOME/config.yaml"; success "已创建 $HERMES_HOME/config.yaml"; }
else
    info "config.yaml 已存在，保留原文件"
fi

success "数据目录就绪：$HERMES_HOME"

# ── 完成 ────────────────────────────────────────────────────────────────────
hr
echo ""
echo -e "  ${GREEN}${BOLD}✓ 安装完成！${NC}"
echo ""
echo -e "  ${GRAY}数据目录${NC}  $HERMES_HOME"
echo -e "  ${GRAY}API Key${NC}   $HERMES_HOME/.env"
echo -e "  ${GRAY}程序目录${NC}  $INSTALL_DIR"
echo ""

LOGIN_SHELL="$(basename "${SHELL:-bash}")"
echo -e "  ${YELLOW}重载 shell 后即可使用 hermes 命令：${NC}"
case "$LOGIN_SHELL" in
    zsh)  echo "    source ~/.zshrc" ;;
    bash) echo "    source ~/.bashrc" ;;
    fish) echo "    source ~/.config/fish/config.fish" ;;
    *)    echo "    source ~/.bashrc" ;;
esac
echo ""
echo -e "  ${CYAN}首次使用：${NC}"
echo -e "    ${GREEN}hermes setup${NC}    ← 配置 API Key"
echo -e "    ${GREEN}hermes${NC}          ← 开始对话"
echo ""
echo -e "  ${GRAY}Skills 安装（可选，安装后再按需添加）：${NC}"
echo -e "    ${GRAY}hermes skills${NC}"
echo ""
hr
