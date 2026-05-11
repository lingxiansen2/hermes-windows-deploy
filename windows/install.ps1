# =============================================================================
# Hermes Agent 安装脚本 — Windows
# =============================================================================
# 用法：
#   .\install.ps1
#   .\install.ps1 -SkipSetup          跳过交互式配置向导
#   .\install.ps1 -HermesHome "D:\hermes"   自定义数据目录
# =============================================================================

param(
    [switch]$SkipSetup,
    [string]$HermesHome = "$env:LOCALAPPDATA\hermes",
    [string]$InstallDir = "$env:LOCALAPPDATA\hermes\hermes-agent"
)

$ErrorActionPreference = "Stop"

# ── 常量 ──────────────────────────────────────────────────────────────────
$PYTHON_VERSION = "3.11"

# ── 打印函数 ──────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "  │    Hermes Agent  Windows 安装程序              │" -ForegroundColor Magenta
    Write-Host "  │    by Nous Research  /  v0.12.0                │" -ForegroundColor Magenta
    Write-Host "  └────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
}
function info    { param($m); Write-Host "  → $m" -ForegroundColor Cyan }
function success { param($m); Write-Host "  ✓ $m" -ForegroundColor Green }
function warn    { param($m); Write-Host "  ⚠ $m" -ForegroundColor Yellow }
function err     { param($m); Write-Host "  ✗ $m" -ForegroundColor Red }
function hr      { Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray }

# ── 定位 vendor 目录 ──────────────────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$VendorDir  = Join-Path (Split-Path $ScriptDir -Parent) "vendor\hermes-agent"

if (-not (Test-Path $VendorDir)) {
    err "找不到 vendor\hermes-agent 目录"
    err "请解压完整的安装包后再运行本脚本。"
    err "预期路径：$VendorDir"
    pause
    exit 1
}

Write-Banner
info "源码路径：$VendorDir"
info "安装目标：$InstallDir"
info "数据目录：$HermesHome"
hr

# ── Step 1：安装 uv ────────────────────────────────────────────────────────
info "正在检查 uv..."
$UvCmd = $null

foreach ($p in @("uv", "$env:USERPROFILE\.local\bin\uv.exe", "$env:USERPROFILE\.cargo\bin\uv.exe")) {
    if ($p -eq "uv") {
        if (Get-Command uv -ErrorAction SilentlyContinue) { $UvCmd = "uv"; break }
    } elseif (Test-Path $p) {
        $UvCmd = $p; break
    }
}

if (-not $UvCmd) {
    info "uv 未找到，正在安装..."
    try {
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex" 2>&1 | Out-Null
        # 刷新 PATH 后再找一次
        $env:Path = [Environment]::GetEnvironmentVariable("Path","User") + ";" + [Environment]::GetEnvironmentVariable("Path","Machine")
        foreach ($p in @("$env:USERPROFILE\.local\bin\uv.exe","$env:USERPROFILE\.cargo\bin\uv.exe")) {
            if (Test-Path $p) { $UvCmd = $p; break }
        }
        if (-not $UvCmd -and (Get-Command uv -ErrorAction SilentlyContinue)) { $UvCmd = "uv" }
    } catch {}
}

if (-not $UvCmd) {
    err "uv 安装失败。请手动安装后重试：https://docs.astral.sh/uv/"
    pause; exit 1
}
success "uv 就绪：$UvCmd"

# ── Step 2：确保 Python 3.11 ────────────────────────────────────────────────
info "正在检查 Python $PYTHON_VERSION..."
$PythonOk = $false
try {
    $p = & $UvCmd python find $PYTHON_VERSION 2>$null
    if ($p) { $PythonOk = $true; success "Python 已找到：$(& $p --version 2>$null)" }
} catch {}

if (-not $PythonOk) {
    info "未找到 Python $PYTHON_VERSION，通过 uv 安装..."
    try {
        & $UvCmd python install $PYTHON_VERSION 2>&1 | Out-Null
        $p = & $UvCmd python find $PYTHON_VERSION 2>$null
        if ($p) { $PythonOk = $true; success "Python 安装完成：$(& $p --version 2>$null)" }
    } catch {}
}

if (-not $PythonOk) {
    err "Python $PYTHON_VERSION 安装失败。"
    info "请手动安装：winget install Python.Python.3.11"
    pause; exit 1
}

# ── Step 3：复制源码到安装目录 ────────────────────────────────────────────
info "正在部署程序文件..."
$parent = Split-Path $InstallDir -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
if (Test-Path $InstallDir)    { Remove-Item -Recurse -Force $InstallDir }
Copy-Item -Recurse -Path $VendorDir -Destination $InstallDir
success "程序文件已部署到：$InstallDir"

# ── Step 4：创建虚拟环境 ────────────────────────────────────────────────────
info "正在创建 Python 虚拟环境..."
Push-Location $InstallDir
if (Test-Path "venv") { Remove-Item -Recurse -Force "venv" }
& $UvCmd venv venv --python $PYTHON_VERSION
success "虚拟环境就绪"

# ── Step 5：安装 Python 依赖（仅核心，不含 skills/RL）────────────────────────
info "正在安装 Python 依赖（首次可能需要几分钟）..."
$env:VIRTUAL_ENV = "$InstallDir\venv"

# 只安装核心依赖，跳过 rl / optional-skills 等重型 extras
$installed = $false
foreach ($spec in @(".[messaging,mcp,pty,honcho,cron,cli]", ".")) {
    try {
        & $UvCmd pip install -e $spec 2>&1 | Out-Null
        $installed = $true
        break
    } catch {}
}

if (-not $installed) {
    err "依赖安装失败，请检查网络连接后重试。"
    Pop-Location; pause; exit 1
}
success "Python 依赖安装完成"
Pop-Location

# ── Step 6：配置 PATH 与环境变量 ────────────────────────────────────────────
info "正在配置环境变量..."
$hermesBin = "$InstallDir\venv\Scripts"

$curPath = [Environment]::GetEnvironmentVariable("Path","User")
if ($curPath -notlike "*$hermesBin*") {
    [Environment]::SetEnvironmentVariable("Path","$hermesBin;$curPath","User")
    success "已将 $hermesBin 加入用户 PATH"
} else {
    info "PATH 已包含 hermes 目录，无需修改"
}

$curHome = [Environment]::GetEnvironmentVariable("HERMES_HOME","User")
if ($curHome -ne $HermesHome) {
    [Environment]::SetEnvironmentVariable("HERMES_HOME",$HermesHome,"User")
    success "已设置 HERMES_HOME = $HermesHome"
}
$env:HERMES_HOME = $HermesHome
$env:Path = "$hermesBin;$env:Path"

# ── Step 7：初始化数据目录（最小化，不同步 skills）─────────────────────────
info "正在初始化数据目录..."
foreach ($sub in @("sessions","logs","memories","cron","hooks")) {
    New-Item -ItemType Directory -Force -Path "$HermesHome\$sub" | Out-Null
}

# .env（首次创建模板，已有则保留）
$envPath = "$HermesHome\.env"
if (-not (Test-Path $envPath)) {
    $tmpl = "$InstallDir\.env.example"
    if (Test-Path $tmpl) { Copy-Item $tmpl $envPath }
    else { New-Item -ItemType File -Force -Path $envPath | Out-Null }
    success "已创建 $envPath  ← 请填入你的 API Key"
} else {
    info ".env 已存在，保留原文件"
}

# config.yaml
$cfgPath = "$HermesHome\config.yaml"
if (-not (Test-Path $cfgPath)) {
    $tmpl = "$InstallDir\cli-config.yaml.example"
    if (Test-Path $tmpl) {
        Copy-Item $tmpl $cfgPath
        success "已创建 $cfgPath"
    }
} else {
    info "config.yaml 已存在，保留原文件"
}

success "数据目录就绪：$HermesHome"

# ── Step 8：可选配置向导 ────────────────────────────────────────────────────
if (-not $SkipSetup) {
    hr
    Write-Host ""
    Write-Host "  下一步：配置你的 API Key" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  在新终端中运行：" -ForegroundColor White
    Write-Host "    hermes setup" -ForegroundColor Green
    Write-Host ""
    Write-Host "  或直接编辑：" -ForegroundColor White
    Write-Host "    $envPath" -ForegroundColor Green
    Write-Host ""
}

# ── 完成 ────────────────────────────────────────────────────────────────────
hr
Write-Host ""
Write-Host "  ✓ 安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  数据目录 " -NoNewline -ForegroundColor Gray; Write-Host $HermesHome
Write-Host "  API Key  " -NoNewline -ForegroundColor Gray; Write-Host "$HermesHome\.env"
Write-Host "  程序目录 " -NoNewline -ForegroundColor Gray; Write-Host $InstallDir
Write-Host ""
Write-Host "  重启终端后运行：" -ForegroundColor Yellow
Write-Host "    hermes setup    ← 首次配置 API Key" -ForegroundColor Green
Write-Host "    hermes          ← 开始对话" -ForegroundColor Green
Write-Host ""
Write-Host "  Skills 安装（可选，安装后再按需添加）：" -ForegroundColor Gray
Write-Host "    hermes skills   ← 浏览可用 Skills" -ForegroundColor DarkGray
Write-Host ""
hr
