# =============================================================================
# Hermes Agent 拓展安装 — Windows（含 GUI 启动器 Hermes.exe）
# =============================================================================
# 用法：
#   .\windows\install-extended.ps1
#   .\windows\install-extended.ps1 -SkipSetup
#   .\windows\install-extended.ps1 -HermesHome "D:\hermes"
#   .\windows\install-extended.ps1 -BuildExe    （从源码编译 Hermes.exe）
# =============================================================================

param(
    [switch]$SkipSetup,
    [switch]$BuildExe,
    [string]$HermesHome = "$env:LOCALAPPDATA\hermes",
    [string]$InstallDir = "$env:LOCALAPPDATA\hermes\hermes-agent"
)

$ErrorActionPreference = "Stop"

# ── 打印函数 ──────────────────────────────────────────────
function info    { param($m); Write-Host "  → $m" -ForegroundColor Cyan }
function success { param($m); Write-Host "  ✓ $m" -ForegroundColor Green }
function warn    { param($m); Write-Host "  ⚠ $m" -ForegroundColor Yellow }
function err     { param($m); Write-Host "  ✗ $m" -ForegroundColor Red }
function hr      { Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray }

# ── 定位脚本和资源目录 ──────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$VendorDir  = Join-Path $ProjectRoot "vendor\hermes-agent"
$LauncherDir = Join-Path $ProjectRoot "launcher"

# ── Banner ────────────────────────────────────────────────
Write-Host ""
Write-Host "  ┌────────────────────────────────────────────────┐" -ForegroundColor Magenta
Write-Host "  │    Hermes Agent  拓展安装 (含 GUI 启动器)     │" -ForegroundColor Magenta
Write-Host "  │    by Nous Research  /  v0.12.0                │" -ForegroundColor Magenta
Write-Host "  └────────────────────────────────────────────────┘" -ForegroundColor Magenta
Write-Host ""
info "安装目标：$InstallDir"
info "数据目录：$HermesHome"
info "启动器源：$LauncherDir"
hr

# ── Step 1：运行基础安装 ──────────────────────────────────
info "正在运行基础安装 (windows\install.ps1)..."
$basicInstaller = Join-Path $ScriptDir "install.ps1"

if (Test-Path $basicInstaller) {
    $params = @{
        HermesHome = $HermesHome
        InstallDir = $InstallDir
    }
    if ($SkipSetup) { $params["SkipSetup"] = $true }

    # 用子进程调用基础安装
    $result = & powershell -NoProfile -ExecutionPolicy ByPass -File $basicInstaller `
        -HermesHome $HermesHome -InstallDir $InstallDir `
        $(if ($SkipSetup) { "-SkipSetup" })
    if ($LASTEXITCODE -ne 0) {
        err "基础安装失败，退出。"
        pause; exit 1
    }
} else {
    err "找不到基础安装脚本：$basicInstaller"
    err "请确保 windows\install.ps1 存在于同一目录。"
    pause; exit 1
}
success "基础安装完成"

# ── Step 2：准备 GUI 启动器文件 ──────────────────────────
info "正在部署 GUI 启动器..."

$launcherDest = Join-Path $HermesHome "launcher"
New-Item -ItemType Directory -Force -Path $launcherDest | Out-Null

# 复制图标文件
foreach ($file in @("icon.ico", "app_icon.png")) {
    $src = Join-Path $LauncherDir $file
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $launcherDest $file) -Force
        success "已复制 $file"
    } else {
        warn "未找到 $file"
    }
}

# ── Step 3：准备/构建 Hermes.exe ──────────────────────────
$exeSrc = Join-Path $LauncherDir "Hermes.exe"
$exeDest = Join-Path $launcherDest "Hermes.exe"

if ($BuildExe) {
    # 从源码构建
    info "正在从源码编译 Hermes.exe (PyInstaller)..."
    hr
    Write-Host ""
    Write-Host "  ⚠  编译需要在有 Python 的环境中执行" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  请在安装了 PyInstaller 的环境中运行：" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    pip install pyinstaller" -ForegroundColor Green
    Write-Host "    cd ""$LauncherDir""" -ForegroundColor Green
    Write-Host "    pyinstaller Hermes_deploy.spec" -ForegroundColor Green
    Write-Host ""
    Write-Host "  编译完成后将 dist\Hermes.exe 复制到：" -ForegroundColor Gray
    Write-Host "    $exeDest" -ForegroundColor Green
    Write-Host ""
    hr
    info "当前跳过自动编译。编译完成后重新运行本脚本即可。"
} elseif (Test-Path $exeSrc) {
    # 直接复制预编译的 EXE
    Copy-Item $exeSrc $exeDest -Force
    $exeSize = [math]::Round((Get-Item $exeDest).Length / 1MB, 1)
    success "Hermes.exe 已部署 ($exeSize MB)"
} else {
    warn "未找到预编译的 Hermes.exe"
    warn "请使用 -BuildExe 参数从源码编译，或手动将 Hermes.exe 放到 $launcherDest"
}

# ── Step 4：创建启动快捷方式 ─────────────────────────────
info "正在创建启动器快捷方式..."

# 判断用哪种启动方式
$exeExists = Test-Path $exeDest
$hermesCli = Join-Path $InstallDir "venv\Scripts\hermes.exe"

$startMenu = [Environment]::GetFolderPath("Programs")

# 快捷方式 1：GUI 启动器 (Hermes.exe)
if ($exeExists) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcutExe = Join-Path $startMenu "Hermes Agent.lnk"
    $Shortcut = $WshShell.CreateShortcut($shortcutExe)
    $Shortcut.TargetPath = $exeDest
    $Shortcut.WorkingDirectory = Split-Path $exeDest -Parent
    $Shortcut.WindowStyle = 7
    $Shortcut.Description = "Hermes Agent — AI \u52a9\u624b GUI \u542f\u52a8\u5668"
    $iconPath = Join-Path $launcherDest "icon.ico"
    if (Test-Path $iconPath) {
        $Shortcut.IconLocation = $iconPath
    }
    $Shortcut.Save()
    success "Start Menu: Hermes Agent (GUI \u542f\u52a8\u5668)"
}

# 快捷方式 2：Hermes CLI（始终可用）
if (Test-Path $hermesCli) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcutCLI = Join-Path $startMenu "Hermes CLI.lnk"
    $Shortcut = $WshShell.CreateShortcut($shortcutCLI)
    $Shortcut.TargetPath = $hermesCli
    $Shortcut.WorkingDirectory = $Installdir
    $Shortcut.WindowStyle = 7
    $Shortcut.Description = "Hermes Agent — \u547d\u4ee4\u884c\u754c\u9762"
    $Shortcut.Save()
    success "Start Menu: Hermes CLI"
}

# 快捷方式 3：桌面快捷方式
if ($exeExists) {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcutDesktop = Join-Path $desktop "Hermes Agent.lnk"
    $Shortcut = $WshShell.CreateShortcut($shortcutDesktop)
    $Shortcut.TargetPath = $exeDest
    $Shortcut.WorkingDirectory = Split-Path $exeDest -Parent
    $Shortcut.WindowStyle = 7
    $Shortcut.Description = "Hermes Agent — AI \u52a9\u624b"
    $iconPath = Join-Path $launcherDest "icon.ico"
    if (Test-Path $iconPath) {
        $Shortcut.IconLocation = $iconPath
    }
    $Shortcut.Save()
    success "Desktop: Hermes Agent"
}

# ── 完成 ──────────────────────────────────────────────────
hr
Write-Host ""
Write-Host "  ✓ 拓展安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  数据目录    " -NoNewline; Write-Host $HermesHome -ForegroundColor Gray
Write-Host "  程序目录    " -NoNewline; Write-Host $InstallDir -ForegroundColor Gray
Write-Host "  API Key     " -NoNewline; Write-Host "$HermesHome\.env" -ForegroundColor Gray

if ($exeExists) {
    Write-Host "  GUI 启动器  " -NoNewline; Write-Host "$exeDest" -ForegroundColor Gray
}

Write-Host ""
Write-Host "  启动方式：" -ForegroundColor Yellow
if ($exeExists) {
    Write-Host "    1. 开始菜单 → Hermes Agent (GUI 启动器)" -ForegroundColor Green
    Write-Host "    2. 桌面快捷方式 → Hermes Agent" -ForegroundColor Green
}
Write-Host "    3. 终端运行 hermes          ← CLI 界面" -ForegroundColor Green
Write-Host "    4. 开始菜单 → Hermes CLI" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  首次使用请先配置 API Key：" -ForegroundColor Yellow
Write-Host "    hermes setup" -ForegroundColor Green
Write-Host ""

if (-not $exeExists -and -not (Test-Path $exeSrc)) {
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  ⚠ Hermes.exe 未找到" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  如需 GUI 启动器，请：" -ForegroundColor Gray
    Write-Host "  1. 将 Hermes.exe 复制到：$launcherDest" -ForegroundColor Cyan
    Write-Host "  2. 或重新运行本脚本并加 -BuildExe 参数编译" -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
}

hr
