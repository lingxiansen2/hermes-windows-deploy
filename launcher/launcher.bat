@echo off
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\"
cd /d "%PROJECT_ROOT%"
set "PYTHON="
if exist "%PROJECT_ROOT%.venv\Scripts\python.exe" set "PYTHON=%PROJECT_ROOT%.venv\Scripts\python.exe"
if not defined PYTHON python --version >nul 2>&1 && set "PYTHON=python"
if not defined PYTHON python3 --version >nul 2>&1 && set "PYTHON=python3"
if not defined PYTHON py --version >nul 2>&1 && set "PYTHON=py"
if not defined PYTHON (
    echo [ERROR] Python not found. Run setup.bat first.
    pause
    exit /b 1
)
start "Hermes Launcher" "%PYTHON%" "%SCRIPT_DIR%launcher.py"
