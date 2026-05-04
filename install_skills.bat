@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion

echo   ─── 安装编程 Skills ───

:: 查找 hermes 命令
set "HERMES_CMD="
if exist "%~dp0.venv\Scripts\hermes.exe" set "HERMES_CMD=%~dp0.venv\Scripts\hermes.exe"
if not defined HERMES_CMD where hermes >nul 2>&1 && set "HERMES_CMD=hermes"

if not defined HERMES_CMD (
    echo   [WARN] hermes 命令未找到，请先运行 setup.bat
    exit /b 1
)

set "SKIP_ERROR=0"

:: 代码委托与代理
echo   [1/3] 安装代码委托与审查 Skills...
"%HERMES_CMD%" skills install --yes blackbox 2>nul       && echo     [OK] blackbox       || echo     [SKIP] blackbox

:: 开发工具链
echo   [2/3] 安装开发工具 Skills...
"%HERMES_CMD%" skills install --yes docker-management 2>nul  && echo     [OK] docker-management  || echo     [SKIP] docker-management
"%HERMES_CMD%" skills install --yes fastmcp 2>nul           && echo     [OK] fastmcp         || echo     [SKIP] fastmcp
"%HERMES_CMD%" skills install --yes duckduckgo-search 2>nul && echo     [OK] duckduckgo-search || echo     [SKIP] duckduckgo-search

:: 代码库分析与搜索
echo   [3/3] 安装代码分析与结构化 Skills...
"%HERMES_CMD%" skills install --yes gitnexus-explorer 2>nul && echo     [OK] gitnexus-explorer || echo     [SKIP] gitnexus-explorer
"%HERMES_CMD%" skills install --yes chroma 2>nul             && echo     [OK] chroma         || echo     [SKIP] chroma
"%HERMES_CMD%" skills install --yes faiss 2>nul              && echo     [OK] faiss          || echo     [SKIP] faiss
"%HERMES_CMD%" skills install --yes scrapling 2>nul          && echo     [OK] scrapling      || echo     [SKIP] scrapling
"%HERMES_CMD%" skills install --yes guidance 2>nul           && echo     [OK] guidance       || echo     [SKIP] guidance
"%HERMES_CMD%" skills install --yes instructor 2>nul         && echo     [OK] instructor     || echo     [SKIP] instructor
"%HERMES_CMD%" skills install --yes one-three-one-rule 2>nul && echo     [OK] one-three-one-rule || echo     [SKIP] one-three-one-rule
"%HERMES_CMD%" skills install --yes concept-diagrams 2>nul   && echo     [OK] concept-diagrams || echo     [SKIP] concept-diagrams

echo   ─── 完成 ───
