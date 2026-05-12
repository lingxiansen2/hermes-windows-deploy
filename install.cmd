@echo off
:: =============================================================================
:: Hermes Agent One-Click Installer - Windows Entry Point
:: Double-click this file to begin. No PowerShell knowledge needed.
:: =============================================================================

echo.
echo   Hermes Agent Installer
echo   Starting Windows setup...
echo.

:: Check if windows\install.cmd exists
if not exist "%~dp0windows\install.cmd" (
    echo   [ERROR] windows\install.cmd not found
    echo   Please extract the full package before running.
    echo   Download: https://github.com/lingxiansen2/hermes-windows-deploy/releases
    echo.
    pause
    exit /b 1
)

:: Delegate to windows\install.cmd (pass all arguments through)
call "%~dp0windows\install.cmd" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   Install failed, exit code: %ERRORLEVEL%
    echo   Please screenshot the output above and submit an issue:
    echo     https://github.com/lingxiansen2/hermes-windows-deploy/issues
    echo.
    pause
    exit /b %ERRORLEVEL%
)

pause
