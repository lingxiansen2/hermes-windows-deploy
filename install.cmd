@echo off
:: =============================================================================
:: Hermes Agent 一键安装 — Windows 入口
:: 双击此文件即可开始安装。无 PowerShell 基础要求。
:: =============================================================================

echo.
echo   Hermes Agent 一键安装程序
echo   正在启动 Windows 安装向导...
echo.

:: 检查 windows\install.cmd 是否存在
if not exist "%~dp0windows\install.cmd" (
    echo   [ERROR] 找不到 windows\install.cmd
    echo   请解压完整的安装包后再运行本脚本。
    echo   安装包下载：https://github.com/lingxiansen2/hermes-windows-deploy/releases
    echo.
    pause
    exit /b 1
)

:: 委托到 windows\install.cmd（传递所有参数）
call "%~dp0windows\install.cmd" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   安装失败，错误码：%ERRORLEVEL%
    echo   请截图上述输出并提交 issue：
    echo     https://github.com/lingxiansen2/hermes-windows-deploy/issues
    echo.
    pause
    exit /b %ERRORLEVEL%
)

pause
