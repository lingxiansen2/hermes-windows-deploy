@echo off
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
echo.
echo ============================================================
echo   Hermes Windows Deploy Setup
echo   AI Agent + launcher + skills
echo ============================================================
echo.
echo This setup will:
echo   1. Check Python, Git, and Node.js
echo   2. Create a local Python virtual environment
echo   3. Install Hermes Agent from bundled source
echo   4. Prepare .hermes config and optional skills
echo   5. Register the Start Menu launcher
echo.
pause
echo.
echo [1/5] Checking prerequisites...
echo.
call :detect_python
if not defined PYTHON_CMD (
    echo [WARN] Python 3.11+ was not found.
    echo        setup.bat will try to install Python 3.12 with winget.
    where winget >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] winget was not found.
        echo         Install Python 3.12 from https://python.org, then run setup.bat again.
        pause
        exit /b 1
    )
    winget install --id Python.Python.3.12 -e --scope user --accept-package-agreements --accept-source-agreements
    if errorlevel 1 (
        echo [ERROR] winget failed to install Python 3.12.
        echo         Install Python 3.12 manually from https://python.org, then run setup.bat again.
        pause
        exit /b 1
    )
    call :detect_python
)
if not defined PYTHON_CMD (
    echo [ERROR] Python 3.12 was installed but is not visible in this terminal yet.
    echo         Close this window, open a new cmd window, and run setup.bat again.
    pause
    exit /b 1
)
for /f "tokens=2" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo   [OK] Python %%v
if defined PYTHON_UNTESTED (
    echo [WARN] This Python version is newer than the tested range 3.11/3.12.
    echo        Setup will continue, but if dependency installation fails, install Python 3.12 and rerun setup.
)
where git >nul 2>&1
if errorlevel 1 (
    echo [WARN] Git was not found. Direct archive install will still be attempted.
) else (
    for /f "tokens=3" %%v in ('git --version 2^>^&1') do echo   [OK] Git %%v
)
set "HAS_NODE="
node --version >nul 2>&1 && set "HAS_NODE=1"
if not defined HAS_NODE if exist "C:\Program Files\nodejs\node.exe" set "HAS_NODE=1"
if defined HAS_NODE (
    echo   [OK] Node.js found
) else (
    echo [WARN] Node.js was not found. Some web or MCP workflows may need it.
)
if not exist "%SCRIPT_DIR%.env" (
    echo.
    echo [WARN] .env was not found. Creating it from .env.example.
    if exist "%SCRIPT_DIR%.env.example" (
        copy /Y "%SCRIPT_DIR%.env.example" "%SCRIPT_DIR%.env" >nul
        echo        Edit .env and fill in your API keys before using Hermes.
    ) else (
        echo [ERROR] .env.example was not found.
        pause
        exit /b 1
    )
)
findstr /i /c:"CHANGE_ME" "%SCRIPT_DIR%.env" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo [ERROR] .env still contains CHANGE_ME placeholders.
    echo         Fill in DEEPSEEK_API_KEY and any optional keys, then run setup.bat again.
    start notepad "%SCRIPT_DIR%.env"
    pause
    exit /b 1
)
echo.
echo [2/5] Creating Python virtual environment...
set "VENV_DIR=%SCRIPT_DIR%.venv"
if exist "%VENV_DIR%\Scripts\python.exe" (
    echo   [OK] Virtual environment already exists.
) else (
    %PYTHON_CMD% -m venv "%VENV_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment.
        pause
        exit /b 1
    )
    echo   [OK] Created %VENV_DIR%
)
set "PYTHON=%VENV_DIR%\Scripts\python.exe"
set "PIP=%VENV_DIR%\Scripts\pip.exe"
"%PYTHON%" -c "import sys; raise SystemExit(0 if sys.version_info >= (3,11) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Existing virtual environment uses Python older than 3.11.
    "%PYTHON%" --version
    echo         Delete the .venv directory and rerun setup.bat with Python 3.11 or newer.
    pause
    exit /b 1
)
"%PYTHON%" -c "import sys; raise SystemExit(0 if sys.version_info[:2] <= (3,12) else 1)" >nul 2>&1
if errorlevel 1 (
    echo [WARN] Existing virtual environment uses a newer untested Python version.
    "%PYTHON%" --version
)
"%PYTHON%" -m pip install --upgrade pip
if errorlevel 1 echo [WARN] Failed to upgrade pip. Continuing with existing pip.
echo.
echo [3/5] Installing Hermes Agent from bundled source...
set "HERMES_SOURCE=%SCRIPT_DIR%vendor\hermes-agent"
if not exist "%HERMES_SOURCE%\pyproject.toml" (
    echo [ERROR] Bundled Hermes source was not found: %HERMES_SOURCE%
    echo         Download the full repository archive, not a partial file copy.
    pause
    exit /b 1
)
"%PYTHON%" -m pip install "%HERMES_SOURCE%"
if errorlevel 1 (
    echo [ERROR] Failed to install Hermes Agent from bundled source.
    echo         Check Python, pip output, and the local vendor\hermes-agent folder.
    pause
    exit /b 1
)
echo   [OK] Hermes Agent installed
set "HERMES_EXE=%VENV_DIR%\Scripts\hermes.exe"
if not exist "%HERMES_EXE%" (
    echo [ERROR] hermes.exe was not found after installation.
    pause
    exit /b 1
)
echo.
echo [4/5] Preparing Hermes config...
set "HERMES_HOME=%SCRIPT_DIR%.hermes"
if not exist "%HERMES_HOME%\" mkdir "%HERMES_HOME%"
copy /Y "%SCRIPT_DIR%config.yaml" "%HERMES_HOME%\config.yaml" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy config.yaml.
    pause
    exit /b 1
)
echo   [OK] config.yaml copied
copy /Y "%SCRIPT_DIR%.env" "%HERMES_HOME%\.env" >nul
if errorlevel 1 (echo [WARN] Failed to copy .env into .hermes.) else (echo   [OK] .env copied)
for %%d in (sessions skills logs cron memories) do if not exist "%HERMES_HOME%\%%d" mkdir "%HERMES_HOME%\%%d"
echo   [OK] Hermes home prepared
echo.
echo [5/5] Installing optional skills and launcher shortcut...
if exist "%SCRIPT_DIR%install_skills.bat" (
    call "%SCRIPT_DIR%install_skills.bat"
) else (
    echo [WARN] install_skills.bat was not found. Skipping skills.
)
if exist "%SCRIPT_DIR%launcher\install_shortcut.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%launcher\install_shortcut.ps1"
    if errorlevel 1 (
        echo [WARN] Failed to create Start Menu shortcut. You can run launcher\install_shortcut.ps1 manually.
    ) else (
        echo   [OK] Start Menu shortcut created
    )
) else (
    echo [WARN] launcher\install_shortcut.ps1 was not found. Skipping shortcut.
)
echo.
echo ============================================================
echo   Setup complete
echo ============================================================
echo.
echo Launch options:
echo   1. Press Win and search for "Hermes"
echo   2. Run launcher\launcher.bat
echo   3. Run "%HERMES_EXE%"
echo.
echo Useful check:
echo   "%HERMES_EXE%" doctor
echo.
pause
:detect_python
set "PYTHON_CMD="
set "PYTHON_UNTESTED="
py -3.12 --version >nul 2>&1 && set "PYTHON_CMD=py -3.12"
if not defined PYTHON_CMD py -3.11 --version >nul 2>&1 && set "PYTHON_CMD=py -3.11"
if defined PYTHON_CMD exit /b 0
python --version >nul 2>&1 && python -c "import sys; raise SystemExit(0 if sys.version_info >= (3,11) else 1)" >nul 2>&1 && set "PYTHON_CMD=python"
if defined PYTHON_CMD python -c "import sys; raise SystemExit(0 if sys.version_info[:2] <= (3,12) else 1)" >nul 2>&1 || set "PYTHON_UNTESTED=1"
if defined PYTHON_CMD exit /b 0
python3 --version >nul 2>&1 && python3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3,11) else 1)" >nul 2>&1 && set "PYTHON_CMD=python3"
if defined PYTHON_CMD python3 -c "import sys; raise SystemExit(0 if sys.version_info[:2] <= (3,12) else 1)" >nul 2>&1 || set "PYTHON_UNTESTED=1"
if defined PYTHON_CMD exit /b 0
py --version >nul 2>&1 && py -c "import sys; raise SystemExit(0 if sys.version_info >= (3,11) else 1)" >nul 2>&1 && set "PYTHON_CMD=py"
if defined PYTHON_CMD py -c "import sys; raise SystemExit(0 if sys.version_info[:2] <= (3,12) else 1)" >nul 2>&1 || set "PYTHON_UNTESTED=1"
exit /b 0
