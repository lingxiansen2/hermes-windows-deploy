@echo off
setlocal EnableExtensions
cd /d "%~dp0"
echo ============================================================
echo   Hermes Windows Deploy - Push to GitHub
echo ============================================================
echo.
git remote -v 2>nul | findstr "origin" >nul
if errorlevel 1 (
    echo [ERROR] git remote origin was not found.
    echo   git remote add origin https://github.com/lingxiansen2/hermes-windows-deploy.git
    pause
    exit /b 1
)
echo Pushing to GitHub...
git push -u origin master
if errorlevel 1 (
    echo.
    echo [FAIL] Push failed. Check GitHub authentication and repository permissions.
) else (
    echo.
    echo [OK] Push complete.
    echo https://github.com/lingxiansen2/hermes-windows-deploy
)
pause
