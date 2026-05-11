@echo off
chcp 65001 >nul 2>&1
:: =============================================================================
:: Hermes Agent 安装脚本 — Windows CMD 入口
:: 双击此文件即可启动安装，无需手动打开 PowerShell
:: =============================================================================

echo.
echo   Hermes Agent Windows 安装程序
echo   正在启动 PowerShell...
echo.

:: 确认 install.ps1 在同目录
if not exist "%~dp0install.ps1" (
    echo   [错误] 找不到 install.ps1
    echo   请确保 install.cmd 和 install.ps1 在同一文件夹中。
    echo.
    pause
    exit /b 1
)

powershell -ExecutionPolicy ByPass -NoProfile -File "%~dp0install.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   安装失败，错误代码：%ERRORLEVEL%
    echo   请以管理员身份重试，或直接运行：
    echo     powershell -ExecutionPolicy ByPass -File "%~dp0install.ps1"
    echo.
    pause
    exit /b %ERRORLEVEL%
)

pause
