# Install Hermes Launcher shortcuts to Windows Start Menu
# Run:  powershell -ExecutionPolicy Bypass -File .\launcher\install_shortcut.ps1
# Usage:
#   .\install_shortcut.ps1                          （自动检测）
#   .\install_shortcut.ps1 -HermesHome "D:\hermes"  （指定 HERMES_HOME）

param(
    [string]$HermesHome = "$env:LOCALAPPDATA\hermes"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$startMenu = [Environment]::GetFolderPath("Programs")
$desktop = [Environment]::GetFolderPath("Desktop")

# ── 检测可用的启动方式 ──────────────────────────────────

# 方式 1: GUI 启动器 (Hermes.exe)
$exePaths = @(
    Join-Path $HermesHome "launcher\Hermes.exe",
    Join-Path $projectRoot "launcher\Hermes.exe",
    (Join-Path $projectRoot "Hermes.exe")
)
$exePath = ""
foreach ($p in $exePaths) {
    if (Test-Path $p) { $exePath = $p; break }
}

# 方式 2: CLI (hermes.exe in venv)
$cliPath = ""
$cliCandidates = @(
    (Join-Path $HermesHome "hermes-agent\venv\Scripts\hermes.exe"),
    (Join-Path $projectRoot ".venv\Scripts\hermes.exe")
)
foreach ($p in $cliCandidates) {
    if (Test-Path $p) { $cliPath = $p; break }
}

# 方式 3: 图标文件
$iconPaths = @(
    (Join-Path $scriptDir "icon.ico"),
    (Join-Path $HermesHome "launcher\icon.ico"),
    (Join-Path $projectRoot "launcher\icon.ico")
)
$iconPath = ""
foreach ($p in $iconPaths) {
    if (Test-Path $p) { $iconPath = $p; break }
}

# ── 创建快捷方式 ────────────────────────────────────────

$WshShell = New-Object -ComObject WScript.Shell
$created = 0

# 桌面快捷方式
if ($exePath) {
    $lnk = Join-Path $desktop "Hermes Agent.lnk"
    $Shortcut = $WshShell.CreateShortcut($lnk)
    $Shortcut.TargetPath = $exePath
    $Shortcut.WorkingDirectory = Split-Path $exePath -Parent
    $Shortcut.WindowStyle = 7
    $Shortcut.Description = "Hermes Agent — AI 助手"
    if ($iconPath) { $Shortcut.IconLocation = $iconPath }
    $Shortcut.Save()
    Write-Host "[OK] Desktop: $lnk" -ForegroundColor Green
    $created++
} else {
    Write-Host "[SKIP] Hermes.exe not found, skipping desktop shortcut" -ForegroundColor Yellow
}

# 开始菜单 — GUI 启动器
if ($exePath) {
    $lnk = Join-Path $startMenu "Hermes Agent.lnk"
    $Shortcut = $WshShell.CreateShortcut($lnk)
    $Shortcut.TargetPath = $exePath
    $Shortcut.WorkingDirectory = Split-Path $exePath -Parent
    $Shortcut.WindowStyle = 7
    $Shortcut.Description = "Hermes Agent — AI 助手 GUI 启动器"
    if ($iconPath) { $Shortcut.IconLocation = $iconPath }
    $Shortcut.Save()
    Write-Host "[OK] Start Menu: $lnk" -ForegroundColor Green
    $created++
}

# 开始菜单 — CLI
if ($cliPath) {
    $lnk = Join-Path $startMenu "Hermes CLI.lnk"
    $Shortcut = $WshShell.CreateShortcut($lnk)
    $Shortcut.TargetPath = $cliPath
    $Shortcut.WorkingDirectory = $HermesHome
    $Shortcut.WindowStyle = 7
    $Shortcut.Description = "Hermes Agent — 命令行界面"
    $Shortcut.Save()
    Write-Host "[OK] Start Menu: $lnk" -ForegroundColor Green
    $created++
} else {
    Write-Host "[SKIP] hermes.exe (CLI) not found" -ForegroundColor Yellow
}

if ($created -eq 0) {
    Write-Host ""
    Write-Host "[WARN] 未创建任何快捷方式。" -ForegroundColor Yellow
    Write-Host "  请先运行 basic/extended 安装，然后再执行本脚本。" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "[OK] $created 个快捷方式已创建" -ForegroundColor Green
    Write-Host "Now press Win, type 'Hermes', and launch!" -ForegroundColor Yellow
}
