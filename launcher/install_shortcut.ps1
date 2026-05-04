# Install Hermes Launcher to Windows Start Menu
# Run: powershell -ExecutionPolicy Bypass -File .\launcher\install_shortcut.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$launcherBat = Join-Path $scriptDir "launcher.bat"

if (-not (Test-Path $launcherBat)) {
    Write-Host "[ERROR] $launcherBat not found" -ForegroundColor Red
    exit 1
}

$startMenu = [Environment]::GetFolderPath("Programs")
$shortcutPath = Join-Path $startMenu "Hermes Agent Launcher.lnk"

$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $launcherBat
$Shortcut.WorkingDirectory = $projectRoot
$Shortcut.WindowStyle = 7
$Shortcut.Description = "Hermes Agent - AI Coding Assistant with web search & skills"

$Shortcut.Save()

Write-Host "[OK] Shortcut created: $shortcutPath" -ForegroundColor Green
Write-Host "Now press Win, type 'Hermes', and launch!" -ForegroundColor Yellow
