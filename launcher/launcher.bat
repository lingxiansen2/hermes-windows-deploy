@echo off
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%..\"

:: Auto-detect work environment
::   Deploy: %LOCALAPPDATA%\hermes
::   Dev:    project root
set "HERMES_HOME=%LOCALAPPDATA%\hermes"
if exist "%PROJECT_ROOT%.hermes" set "HERMES_HOME=%PROJECT_ROOT%.hermes"
if exist "%PROJECT_ROOT%.hermes-win" set "HERMES_HOME=%PROJECT_ROOT%.hermes-win"

:: Find Python
set "PYTHON="
if exist "%HERMES_HOME%\hermes-agent\venv\Scripts\python.exe" (
    set "PYTHON=%HERMES_HOME%\hermes-agent\venv\Scripts\python.exe"
) else if exist "%PROJECT_ROOT%.venv\Scripts\python.exe" (
    set "PYTHON=%PROJECT_ROOT%.venv\Scripts\python.exe"
) else if exist "%PROJECT_ROOT%.venv-hermes-win\Scripts\python.exe" (
    set "PYTHON=%PROJECT_ROOT%.venv-hermes-win\Scripts\python.exe"
)
if not defined PYTHON python --version >nul 2>&1 && set "PYTHON=python"
if not defined PYTHON python3 --version >nul 2>&1 && set "PYTHON=python3"
if not defined PYTHON py --version >nul 2>&1 && set "PYTHON=py"

if not defined PYTHON (
    echo [ERROR] Python not found.
    echo         Run windows\install.ps1 or windows\install-extended.ps1 first.
    pause
    exit /b 1
)

:: Pick launcher (GUI exe first, then Python fallback)
set "EXE_PATH="
if exist "%HERMES_HOME%\launcher\Hermes.exe" (
    set "EXE_PATH=%HERMES_HOME%\launcher\Hermes.exe"
) else if exist "%SCRIPT_DIR%Hermes.exe" (
    set "EXE_PATH=%SCRIPT_DIR%Hermes.exe"
)

if defined EXE_PATH (
    echo Starting Hermes GUI Launcher...
    start "" "%EXE_PATH%"
    exit /b 0
)

:: Fallback: Python deploy launcher
if exist "%SCRIPT_DIR%launcher_deploy.py" (
    echo Starting Hermes Launcher (Python)...
    start "Hermes Launcher" "%PYTHON%" "%SCRIPT_DIR%launcher_deploy.py"
    exit /b 0
)

:: Final fallback: legacy launcher
if exist "%SCRIPT_DIR%launcher.py" (
    echo Starting Hermes Launcher (legacy)...
    start "Hermes Launcher" "%PYTHON%" "%SCRIPT_DIR%launcher.py"
    exit /b 0
)

echo [ERROR] No launcher found.
echo         Looking for: launcher\Hermes.exe or launcher\launcher_deploy.py
pause
exit /b 1
