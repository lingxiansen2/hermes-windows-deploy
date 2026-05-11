@echo off
:: =============================================================================
:: Hermes Agent Installer — Windows CMD Entry Point
:: Double-click this file to start installation. No PowerShell knowledge needed.
:: =============================================================================

echo.
echo   Hermes Agent Windows Installer
echo   Launching PowerShell...
echo.

:: Verify install.ps1 exists in same directory
if not exist "%~dp0install.ps1" (
    echo   [ERROR] install.ps1 not found
    echo   Make sure install.cmd and install.ps1 are in the same folder.
    echo.
    pause
    exit /b 1
)

powershell -ExecutionPolicy ByPass -NoProfile -File "%~dp0install.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo   Installation failed, error code: %ERRORLEVEL%
    echo   Try running as Administrator, or run directly:
    echo     powershell -ExecutionPolicy ByPass -File "%~dp0install.ps1"
    echo.
    pause
    exit /b %ERRORLEVEL%
)

pause
