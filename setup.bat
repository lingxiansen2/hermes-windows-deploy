@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

echo.
echo ============================================================
echo    Hermes Windows 一键部署
echo    AI Agent + 联网搜索 + 编程 Skills
echo ============================================================
echo.
echo 此脚本将自动完成:
echo   1. 检查环境 (Python, Git, Node.js)
echo   2. 安装 Hermes Agent
echo   3. 部署配置文件和 Skills
echo   4. 设置可视化启动器
echo.
echo 预计耗时: 3-5 分钟
echo.
pause

:: =============================================================
:: Step 1: 环境检查
:: =============================================================
echo.
echo [1/5] 检查环境...
echo.

:: --- Python ---
set "PYTHON_CMD="
python --version >nul 2>&1 && set "PYTHON_CMD=python"
if not defined PYTHON_CMD python3 --version >nul 2>&1 && set "PYTHON_CMD=python3"
if not defined PYTHON_CMD py --version >nul 2>&1 && set "PYTHON_CMD=py"

if not defined PYTHON_CMD (
    echo [ERROR] Python 未安装。请从 https://python.org 下载安装。
    echo         安装时务必勾选 "Add Python to PATH"。
    pause
    exit /b 1
)
for /f "tokens=2" %%v in ('%PYTHON_CMD% --version 2^>^&1') do echo   [OK] Python %%v

:: --- Git ---
where git >nul 2>&1
if errorlevel 1 (
    echo [WARN] Git 未安装，部分功能可能不可用。
    echo        从 https://git-scm.com 下载安装。
) else (
    for /f "tokens=3" %%v in ('git --version 2^>^&1') do echo   [OK] Git %%v
)

:: --- Node.js (optional) ---
set "HAS_NODE="
node --version >nul 2>&1 && set "HAS_NODE=1"
if not defined HAS_NODE (
    if exist "C:\Program Files\nodejs\node.exe" set "HAS_NODE=1"
)
if defined HAS_NODE (
    echo   [OK] Node.js 已安装
) else (
    echo [WARN] Node.js 未安装，浏览器自动化不可用（可选）。
    echo        从 https://nodejs.org 下载安装。
)

:: --- .env 检查 ---
if not exist "%SCRIPT_DIR%.env" (
    echo.
    echo [WARN] .env 文件不存在，正在从模板创建...
    if exist "%SCRIPT_DIR%.env.example" (
        copy /Y "%SCRIPT_DIR%.env.example" "%SCRIPT_DIR%.env" >nul 2>&1
        echo        已创建 .env，请用记事本编辑填入你的 API Key:
        echo        notepad "%SCRIPT_DIR%.env"
    ) else (
        echo   [ERROR] .env.example 模板文件缺失！
    )
)

:: 检查 .env 中的 Key
if exist "%SCRIPT_DIR%.env" (
    findstr /c:"sk-你的" "%SCRIPT_DIR%.env" >nul 2>&1
    if not errorlevel 1 (
        echo.
        echo ⚠  检测到 .env 中的 KEY 还是默认占位值！
        echo   请先编辑 .env 填入真实的 API Key，然后重新运行 setup.bat
        echo.
        echo   需要: DEEPSEEK_API_KEY, TAVILY_API_KEY
        echo   可选: GITHUB_TOKEN
        echo.
        start notepad "%SCRIPT_DIR%.env"
        pause
        exit /b 1
    )
)

:: =============================================================
:: Step 2: 创建 Python 虚拟环境
:: =============================================================
echo.
echo [2/5] 创建 Python 虚拟环境...

set "VENV_DIR=%SCRIPT_DIR%.venv"
if exist "%VENV_DIR%\Scripts\python.exe" (
    echo   [OK] 虚拟环境已存在，跳过创建。
) else (
    %PYTHON_CMD% -m venv "%VENV_DIR%" >nul 2>&1
    if errorlevel 1 (
        echo   [ERROR] 创建虚拟环境失败。请确认 Python 安装正确。
        pause
        exit /b 1
    )
    echo   [OK] 虚拟环境已创建: %VENV_DIR%
)

set "PYTHON=%VENV_DIR%\Scripts\python.exe"
set "PIP=%VENV_DIR%\Scripts\pip.exe"

:: 升级 pip
"%PIP%" install --upgrade pip >nul 2>&1

:: =============================================================
:: Step 3: 安装 Hermes Agent
:: =============================================================
echo.
echo [3/5] 安装 Hermes Agent...

"%PIP%" install hermes-agent >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Hermes Agent 安装失败。请检查网络连接后重试。
    pause
    exit /b 1
)
echo   [OK] Hermes Agent 已安装

:: 验证安装
set "HERMES_EXE=%VENV_DIR%\Scripts\hermes.exe"
if not exist "%HERMES_EXE%" (
    echo   [WARN] hermes.exe 未找到，尝试通过 pip 查找...
    "%PYTHON%" -c "import hermes_cli; print('OK')" >nul 2>&1
    if errorlevel 1 (
        echo   [ERROR] Hermes Agent 安装验证失败。
        pause
        exit /b 1
    )
    echo   [OK] Hermes Python 包已验证
)

:: =============================================================
:: Step 4: 部署配置
:: =============================================================
echo.
echo [4/5] 部署配置文件...

:: Hermes home
set "HERMES_HOME=%SCRIPT_DIR%.hermes"
if not exist "%HERMES_HOME%\" mkdir "%HERMES_HOME%" >nul 2>&1

:: 复制配置
copy /Y "%SCRIPT_DIR%config.yaml" "%HERMES_HOME%\config.yaml" >nul 2>&1
echo   [OK] config.yaml 已部署

:: 复制 .env
if exist "%SCRIPT_DIR%.env" (
    copy /Y "%SCRIPT_DIR%.env" "%HERMES_HOME%\.env" >nul 2>&1
    echo   [OK] .env 已部署
)

:: 创建必要的目录
mkdir "%HERMES_HOME%\sessions" >nul 2>&1
mkdir "%HERMES_HOME%\skills" >nul 2>&1
mkdir "%HERMES_HOME%\logs" >nul 2>&1
mkdir "%HERMES_HOME%\cron" >nul 2>&1
mkdir "%HERMES_HOME%\memories" >nul 2>&1
echo   [OK] 目录结构已创建

:: 设置环境变量
set "HERMES_HOME=%HERMES_HOME%"

:: =============================================================
:: Step 5: 安装 Skills + 启动器
:: =============================================================
echo.
echo [5/5] 安装编程 Skills 和启动器...

:: 安装 Skills
if exist "%SCRIPT_DIR%install_skills.bat" (
    call "%SCRIPT_DIR%install_skills.bat"
) else (
    echo   [WARN] install_skills.bat 未找到，跳过 Skills 安装。
    echo         你可以稍后手动运行: hermes skills install --yes blackbox
)

:: 安装启动器到开始菜单
if exist "%SCRIPT_DIR%launcher\install_shortcut.ps1" (
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%launcher\install_shortcut.ps1" 2>nul
    if not errorlevel 1 (
        echo   [OK] 启动器已注册到开始菜单（Win 键搜索 "Hermes"）
    ) else (
        echo   [WARN] 开始菜单注册失败，你可以手动运行 launcher\install_shortcut.ps1
    )
)

:: =============================================================
:: 完成
:: =============================================================
echo.
echo ============================================================
echo   安装完成！
echo ============================================================
echo.
echo 启动方式:
echo   1. Win 键搜索 "Hermes" → 点击图标
echo   2. 双击 launcher\launcher.bat
echo   3. 命令行: "%HERMES_EXE%"
echo.
echo 下一步:
echo   - 确保 .env 中的 API Key 已正确填写
echo   - 运行 health check: "%HERMES_EXE%" doctor
echo   - 开始使用: "%HERMES_EXE%"
echo.
echo 工作目录: %SCRIPT_DIR%
echo Hermes 配置: %HERMES_HOME%
echo.
pause
