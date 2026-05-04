@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\"
cd /d "%PROJECT_ROOT%"

:: 查找 Python
set "PYTHON="
python --version >nul 2>&1 && set "PYTHON=python"
if not defined PYTHON python3 --version >nul 2>&1 && set "PYTHON=python3"
if not defined PYTHON py --version >nul 2>&1 && set "PYTHON=py"

if not defined PYTHON (
    echo [ERROR] Python not found
    pause
    exit /b 1
)

start "" "%PYTHON%" "%SCRIPT_DIR%launcher.py"
