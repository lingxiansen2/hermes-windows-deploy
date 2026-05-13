@echo off
setlocal EnableExtensions
set "ROOT=%~dp0..\..\"
set "HERMES_CMD="
if exist "%ROOT%.venv\Scripts\hermes.exe" set "HERMES_CMD=%ROOT%.venv\Scripts\hermes.exe"
if not defined HERMES_CMD where hermes >nul 2>&1 && set "HERMES_CMD=hermes"
if not defined HERMES_CMD (
    echo   [WARN] hermes command was not found. Run setup.bat first.
    exit /b 1
)
echo   Installing optional Hermes skills...
echo   [1/3] Basic utility skills
"%HERMES_CMD%" skills install --yes blackbox 2>nul && echo     [OK] blackbox || echo     [SKIP] blackbox
echo   [2/3] Developer workflow skills
"%HERMES_CMD%" skills install --yes docker-management 2>nul && echo     [OK] docker-management || echo     [SKIP] docker-management
"%HERMES_CMD%" skills install --yes fastmcp 2>nul && echo     [OK] fastmcp || echo     [SKIP] fastmcp
"%HERMES_CMD%" skills install --yes duckduckgo-search 2>nul && echo     [OK] duckduckgo-search || echo     [SKIP] duckduckgo-search
echo   [3/3] Research and coding skills
"%HERMES_CMD%" skills install --yes gitnexus-explorer 2>nul && echo     [OK] gitnexus-explorer || echo     [SKIP] gitnexus-explorer
"%HERMES_CMD%" skills install --yes chroma 2>nul && echo     [OK] chroma || echo     [SKIP] chroma
"%HERMES_CMD%" skills install --yes faiss 2>nul && echo     [OK] faiss || echo     [SKIP] faiss
"%HERMES_CMD%" skills install --yes scrapling 2>nul && echo     [OK] scrapling || echo     [SKIP] scrapling
"%HERMES_CMD%" skills install --yes guidance 2>nul && echo     [OK] guidance || echo     [SKIP] guidance
"%HERMES_CMD%" skills install --yes instructor 2>nul && echo     [OK] instructor || echo     [SKIP] instructor
"%HERMES_CMD%" skills install --yes one-three-one-rule 2>nul && echo     [OK] one-three-one-rule || echo     [SKIP] one-three-one-rule
"%HERMES_CMD%" skills install --yes concept-diagrams 2>nul && echo     [OK] concept-diagrams || echo     [SKIP] concept-diagrams
echo   Skill installation step complete.
