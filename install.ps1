# =============================================================================
# Hermes Agent 一键安装 — PowerShell 入口（备选）
# 推荐双击 install.cmd，本文件也可用 PowerShell 直接运行。
# =============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Installer = Join-Path $ScriptDir "windows\install.ps1"

if (-not (Test-Path $Installer)) {
    Write-Host "  [ERROR] 找不到 windows\install.ps1" -ForegroundColor Red
    Write-Host "  请解压完整的安装包后再运行本脚本。" -ForegroundColor Red
    Write-Host "  安装包下载：https://github.com/lingxiansen2/hermes-windows-deploy/releases" -ForegroundColor Gray
    pause
    exit 1
}

# 委托到 windows\install.ps1（传递所有参数）
& $Installer @args
exit $LASTEXITCODE
