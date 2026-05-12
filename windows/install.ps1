# =============================================================================
# Hermes Agent Installer — Windows (Portable Python)
# =============================================================================
# A complete Python 3.12 + all dependencies is bundled as python/.
# No Python detection, no pip install, no network, no compilation.
# Just copy files, set PATH, fill API key, done.
# =============================================================================

param(
    [switch]$SkipSetup,
    [string]$HermesHome = "$env:LOCALAPPDATA\hermes",
    [switch]$KeepSource = $false
)

$ErrorActionPreference = "Stop"

# ── Output helpers ─────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "  │    Hermes Agent  Windows Installer             │" -ForegroundColor Magenta
    Write-Host "  │    Portable Python 3.12  /  v0.12.0            │" -ForegroundColor Magenta
    Write-Host "  └────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
}
function info    { param($m); Write-Host "  -> $m" -ForegroundColor Cyan }
function success { param($m); Write-Host "  OK $m" -ForegroundColor Green }
function warn    { param($m); Write-Host "  !! $m" -ForegroundColor Yellow }
function err     { param($m); Write-Host "  XX $m" -ForegroundColor Red }
function hr      { Write-Host "  -------------------------------------------------" -ForegroundColor DarkGray }

# ── Locate bundled Python ──────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PkgRoot   = Split-Path $ScriptDir -Parent
$PythonSrc = Join-Path $PkgRoot "python"
$PythonExe = Join-Path $PythonSrc "python.exe"

if (-not (Test-Path $PythonExe)) {
    err "python\python.exe not found"
    err "Please extract the full package before running."
    err "Expected: $PythonExe"
    pause
    exit 1
}

Write-Banner
info "Portable Python: $PythonSrc"
info "Install to:      $HermesHome"
hr

# ── Step 1: Copy portable Python ───────────────────────────────────────────
$PythonDest = "$HermesHome\python"
info "Copying portable Python..."

$parent = Split-Path $HermesHome -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }

if (Test-Path $PythonDest) {
    info "Removing previous installation..."
    Remove-Item -Recurse -Force $PythonDest
}

Copy-Item -Recurse -Path $PythonSrc -Destination $PythonDest
success "Python copied to $PythonDest"

# ── Step 2: Verify hermes command ──────────────────────────────────────────
$hermesExe = "$PythonDest\Scripts\hermes.exe"
if (-not (Test-Path $hermesExe)) {
    err "hermes.exe not found after copy"
    err "Expected: $hermesExe"
    pause
    exit 1
}
success "hermes.exe ready"

# ── Step 3: Configure PATH ─────────────────────────────────────────────────
info "Configuring environment..."
$hermesBin = "$PythonDest\Scripts"

# Add to current session
$env:Path = "$hermesBin;$env:Path"
$env:HERMES_HOME = $HermesHome

# Add to user PATH (persistent)
$curPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($curPath -notlike "*$hermesBin*") {
    [Environment]::SetEnvironmentVariable("Path", "$hermesBin;$curPath", "User")
    success "Added to user PATH: $hermesBin"
} else {
    info "PATH already includes hermes"
}

# Set HERMES_HOME
$curHome = [Environment]::GetEnvironmentVariable("HERMES_HOME", "User")
if ($curHome -ne $HermesHome) {
    [Environment]::SetEnvironmentVariable("HERMES_HOME", $HermesHome, "User")
    success "HERMES_HOME = $HermesHome"
}

# ── Step 4: Initialize data directories ────────────────────────────────────
info "Creating data directories..."
foreach ($sub in @("sessions", "logs", "memories", "cron", "hooks")) {
    New-Item -ItemType Directory -Force -Path "$HermesHome\$sub" | Out-Null
}

# ── Step 5: Create .env (API Key) ──────────────────────────────────────────
$envPath = "$HermesHome\.env"
$envIsNew = $false
if (-not (Test-Path $envPath)) {
    $tmpl = Join-Path $PkgRoot ".env.example"
    if (Test-Path $tmpl) {
        Copy-Item $tmpl $envPath
    } else {
        @"
# Hermes Agent API Keys
# Fill in at least one provider's key below.
# DeepSeek (recommended): https://platform.deepseek.com/api_keys

DEEPSEEK_API_KEY=sk-CHANGE_ME
"@ | Out-File -Encoding utf8 $envPath
    }
    $envIsNew = $true
} else {
    info ".env already exists, preserving"
}

# ── Step 6: API Key prompt ─────────────────────────────────────────────────
if ($envIsNew -and -not $SkipSetup) {
    hr
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  Opening API Key config — fill in your key!  ║" -ForegroundColor Yellow
    Write-Host "  ║  Replace sk-CHANGE_ME with your real key     ║" -ForegroundColor Yellow
    Write-Host "  ║  Save and close the window to continue       ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    info "Press any key to open $envPath ..."
    pause | Out-Null
    Start-Process notepad $envPath
    Write-Host ""
    success "API Key config opened — fill in and save"
}

# ── Done ───────────────────────────────────────────────────────────────────
hr
Write-Host ""
Write-Host "  ====== Installation Complete ======" -ForegroundColor Green
Write-Host ""
Write-Host "  Files:" -ForegroundColor Gray
Write-Host "    Python + hermes:  $PythonDest" -ForegroundColor Gray
Write-Host "    API Key config:   $envPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Fill in your API Key in:" -ForegroundColor White
Write-Host "       $envPath" -ForegroundColor Green
Write-Host "    2. Restart terminal, then run:" -ForegroundColor White
Write-Host "       hermes" -ForegroundColor Green
Write-Host ""
Write-Host "  Optional: hermes setup  — configure models/terminal/tools" -ForegroundColor Gray
Write-Host ""
hr
