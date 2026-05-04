@echo off
chcp 65001 >nul 2>&1
echo ============================================================
echo   Hermes Windows Deploy — Push to GitHub
echo ============================================================
echo.

cd /d "%~dp0"

:: 检查 git remote
git remote -v 2>nul | findstr "origin" >nul
if errorlevel 1 (
    echo [ERROR] git remote 未设置。请先运行:
    echo   git remote add origin https://github.com/lingxiansen2/hermes-windows-deploy.git
    pause
    exit /b 1
)

echo 正在推送到 GitHub...
echo.

git push -u origin master 2>&1

if errorlevel 1 (
    echo.
    echo [FAIL] 推送失败。请确认:
    echo   1. GitHub Token 是否有效
    echo   2. 仓库 https://github.com/lingxiansen2/hermes-windows-deploy 是否存在
    echo.
    echo 如果仓库不存在，先在 GitHub 网页上创建:
    echo   https://github.com/new
    echo   Repository name: hermes-windows-deploy
    echo   Public / Private 均可
    echo   不要勾选 Initialize with README
) else (
    echo.
    echo [OK] 推送成功!
    echo https://github.com/lingxiansen2/hermes-windows-deploy
)

pause
