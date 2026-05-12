# =============================================================================
# Hermes Agent One-Click Install - PowerShell entry (alternative)
# Double-click install.cmd is preferred. Run this directly in PowerShell if needed.
# =============================================================================

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Installer = Join-Path $ScriptDir "windows\install.ps1"

if (-not (Test-Path $Installer)) {
    Write-Host "  [ERROR] windows\install.ps1 not found" -ForegroundColor Red
    Write-Host "  Please extract the full package before running." -ForegroundColor Red
    Write-Host "  Download: https://github.com/lingxiansen2/hermes-windows-deploy/releases" -ForegroundColor Gray
    pause
    exit 1
}

& $Installer @args
exit $LASTEXITCODE
