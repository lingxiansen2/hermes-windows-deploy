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

# ── Step 1b: Copy portable Git ──────────────────────────────────────────────
$GitSrc  = Join-Path $PkgRoot "git"
$GitDest = "$HermesHome\git"
if (Test-Path $GitSrc) {
    info "Copying portable Git..."
    if (Test-Path $GitDest) { Remove-Item -Recurse -Force $GitDest }
    Copy-Item -Recurse -Path $GitSrc -Destination $GitDest
    success "Git copied to $GitDest"
} else {
    warn "Portable Git not found in package (git/ missing), skipping"
}

# ── Step 2: Verify hermes launcher ─────────────────────────────────────────
$hermesCmd = "$PythonDest\Scripts\hermes.cmd"
if (-not (Test-Path $hermesCmd)) {
    err "hermes.cmd not found after copy"
    err "Expected: $hermesCmd"
    pause
    exit 1
}
success "hermes launcher ready"

# ── Step 3: Configure PATH ─────────────────────────────────────────────────
info "Configuring environment..."
$hermesBin = "$PythonDest\Scripts"
$gitBin    = "$GitDest\bin"

# Add to current session
$env:Path = "$hermesBin;$gitBin;$env:Path"
$env:HERMES_HOME = $HermesHome

# Add to user PATH (persistent)
$curPath = [Environment]::GetEnvironmentVariable("Path", "User")
foreach ($bin in @($hermesBin, $gitBin)) {
    if ((Test-Path $bin) -and ($curPath -notlike "*$bin*")) {
        $curPath = "$bin;$curPath"
        success "Added to user PATH: $bin"
    }
}
[Environment]::SetEnvironmentVariable("Path", $curPath, "User")

# Set HERMES_HOME
[Environment]::SetEnvironmentVariable("HERMES_HOME", $HermesHome, "User")
$env:HERMES_HOME = $HermesHome
success "HERMES_HOME = $HermesHome"

# Set HERMES_GIT_BASH_PATH (for shell commands)
$bashExe = "$GitDest\bin\bash.exe"
if (Test-Path $bashExe) {
    [Environment]::SetEnvironmentVariable("HERMES_GIT_BASH_PATH", $bashExe, "User")
    $env:HERMES_GIT_BASH_PATH = $bashExe
    success "Git bash: $bashExe"
}
# ── Step 4: Initialize data directories ────────────────────────────────────
info "Creating data directories..."
foreach ($sub in @("sessions", "logs", "memories", "cron", "hooks")) {
    New-Item -ItemType Directory -Force -Path "$HermesHome\$sub" | Out-Null
}

# ── Step 5: Create default config and .env (API Key) ───────────────────────
$configPath = "$HermesHome\config.yaml"
if (-not (Test-Path $configPath)) {
    $configTmpl = Join-Path $PkgRoot "config.yaml"
    if (Test-Path $configTmpl) {
        Copy-Item $configTmpl $configPath
        success "Config copied to $configPath"
    }
}

$envPath = "$HermesHome\.env"
$envIsNew = $false
if (-not (Test-Path $envPath)) {
    $tmpl = Join-Path $PkgRoot ".env.example"
    if (Test-Path $tmpl) {
        Copy-Item $tmpl $envPath
    } else {
        $defaultEnv = @(
            "# Hermes Agent API Keys",
            "# Fill in at least one provider's key below.",
            "# DeepSeek: https://platform.deepseek.com/api_keys",
            "",
            "DEEPSEEK_API_KEY=sk-CHANGE_ME"
        )
        [System.IO.File]::WriteAllLines($envPath, $defaultEnv, [System.Text.UTF8Encoding]::new($false))
    }
    $envIsNew = $true
} else {
    info ".env already exists, preserving"
}

# Local launcher for custom install locations where the user's PATH has not
# refreshed yet. This keeps `D:\path\to\hermes\hermes.cmd` usable immediately.
$localCmd = "$HermesHome\hermes.cmd"
@(
    '@echo off',
    'set "HERMES_HOME=%~dp0"',
    'set "HERMES_GIT_BASH_PATH=%~dp0git\bin\bash.exe"',
    'set "PYTHONIOENCODING=utf-8"',
    '"%~dp0python\Scripts\hermes.cmd" %*'
) | Set-Content -Path $localCmd -Encoding ASCII
success "Local launcher: $localCmd"

# If the installer was launched elevated, the copied tree can otherwise remain
# unwritable from a normal terminal. Grant the invoking user modify rights.
try {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    & icacls $HermesHome /grant "${currentUser}:(OI)(CI)M" /T /Q | Out-Null
} catch {
    warn "Could not update install directory permissions: $($_.Exception.Message)"
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
