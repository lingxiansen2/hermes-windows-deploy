# =============================================================================
# Hermes Agent Installer — Windows (Offline-First)
# =============================================================================
# Usage:
#   .\install.ps1
#   .\install.ps1 -SkipSetup          skip interactive setup wizard
#   .\install.ps1 -HermesHome "D:\hermes"   custom data directory
# =============================================================================
# All Python dependencies are pre-bundled as wheels. No network needed.
# Falls back to online install only if local wheels are incompatible.
# =============================================================================

param(
    [switch]$SkipSetup,
    [string]$HermesHome = "$env:LOCALAPPDATA\hermes",
    [string]$InstallDir = "$env:LOCALAPPDATA\hermes\hermes-agent"
)

$ErrorActionPreference = "Stop"

# ── Constants ──────────────────────────────────────────────────────────────
$PYTHON_MIN_MAJOR = 3
$PYTHON_MIN_MINOR = 11
$PYTHON_INSTALL_FALLBACK = "3.12"

# ── Output helpers ─────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "  │    Hermes Agent  Windows Installer             │" -ForegroundColor Magenta
    Write-Host "  │    by Nous Research  /  v0.12.0                │" -ForegroundColor Magenta
    Write-Host "  └────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
}
function info    { param($m); Write-Host "  → $m" -ForegroundColor Cyan }
function success { param($m); Write-Host "  ✓ $m" -ForegroundColor Green }
function warn    { param($m); Write-Host "  ⚠ $m" -ForegroundColor Yellow }
function err     { param($m); Write-Host "  ✗ $m" -ForegroundColor Red }
function hr      { Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray }

# ── Locate bundled resources ───────────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$PkgRoot    = Split-Path $ScriptDir -Parent
$VendorDir  = Join-Path $PkgRoot "vendor\hermes-agent"
$WheelsDir  = Join-Path $PkgRoot "wheels"
$UvExe      = Join-Path $PkgRoot "uv.exe"

if (-not (Test-Path $VendorDir)) {
    err "vendor\hermes-agent not found"
    err "Please extract the full package before running this script."
    err "Expected: $VendorDir"
    pause
    exit 1
}

$OfflineAvailable = (Test-Path $UvExe) -and (Test-Path $WheelsDir)
$WheelCount = 0
if ($OfflineAvailable) {
    $WheelCount = (Get-ChildItem "$WheelsDir\*.whl" -ErrorAction SilentlyContinue).Count
}

Write-Banner
info "Source:       $VendorDir"
info "Install to:   $InstallDir"
info "Data dir:     $HermesHome"
if ($OfflineAvailable) {
    success "Offline mode — $WheelCount wheels bundled, no network needed"
} else {
    warn "Offline bundle not found, will download dependencies from PyPI"
}
hr

# ── Step 1: Use bundled uv or find system uv ───────────────────────────────
$UvCmd = $null

# Priority: bundled uv.exe > system PATH uv > install from network
if (Test-Path $UvExe) {
    $UvCmd = $UvExe
    info "Using bundled uv.exe"
} else {
    info "Checking for uv..."
    foreach ($p in @("uv", "$env:USERPROFILE\.local\bin\uv.exe", "$env:USERPROFILE\.cargo\bin\uv.exe")) {
        if ($p -eq "uv") {
            if (Get-Command uv -ErrorAction SilentlyContinue) { $UvCmd = "uv"; break }
        } elseif (Test-Path $p) {
            $UvCmd = $p; break
        }
    }
    if (-not $UvCmd) {
        info "uv not found, installing..."
        try {
            powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex" 2>&1 | Out-Null
            $env:Path = [Environment]::GetEnvironmentVariable("Path","User") + ";" + [Environment]::GetEnvironmentVariable("Path","Machine")
            foreach ($p in @("$env:USERPROFILE\.local\bin\uv.exe","$env:USERPROFILE\.cargo\bin\uv.exe")) {
                if (Test-Path $p) { $UvCmd = $p; break }
            }
            if (-not $UvCmd -and (Get-Command uv -ErrorAction SilentlyContinue)) { $UvCmd = "uv" }
        } catch {}
    }
}

if (-not $UvCmd) {
    err "uv not available. Please install manually: https://docs.astral.sh/uv/"
    pause; exit 1
}
success "uv ready: $UvCmd"

# ── Step 2: Ensure Python >= 3.11 ──────────────────────────────────────────
# When offline wheels are bundled, prefer Python 3.12 (matching wheel ABI)
info "Checking Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR..."
$PythonOk = $false
$FoundPyVersion = $null
$OfflineTarget = "3.12"  # wheels are built for this version on CI

function Test-PythonVersion {
    param([string]$VersionStr)
    if ($VersionStr -match '(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        return ($major -gt $PYTHON_MIN_MAJOR) -or `
               ($major -eq $PYTHON_MIN_MAJOR -and $minor -ge $PYTHON_MIN_MINOR)
    }
    return $false
}

# Strategy 0 (offline): if wheels are bundled, prefer Python 3.12 exactly
if ($OfflineAvailable) {
    try {
        $p = & $UvCmd python find $OfflineTarget 2>$null
        if ($p) {
            $PythonOk = $true
            $FoundPyVersion = $OfflineTarget
            success "Python found (offline target): $(& $p --version 2>$null)"
        }
    } catch {}
}

# Strategy 1: uv python list — discover all installed versions, pick highest >= 3.11
if (-not $PythonOk) {
try {
    $uvList = & $UvCmd python list --only-installed 2>$null
    if ($uvList) {
        $bestVer = $null; $bestMajor = 0; $bestMinor = 0
        foreach ($line in $uvList) {
            if ($line -match 'cpython-(\d+)\.(\d+)') {
                $maj = [int]$Matches[1]; $min = [int]$Matches[2]
                $meetsMin = ($maj -gt $PYTHON_MIN_MAJOR) -or `
                            ($maj -eq $PYTHON_MIN_MAJOR -and $min -ge $PYTHON_MIN_MINOR)
                if ($meetsMin -and (($maj -gt $bestMajor) -or ($maj -eq $bestMajor -and $min -gt $bestMinor))) {
                    $bestMajor = $maj; $bestMinor = $min
                    $bestVer = "$maj.$min"
                }
            }
        }
        if ($bestVer) {
            $p = & $UvCmd python find $bestVer 2>$null
            if ($p) {
                $PythonOk = $true
                $FoundPyVersion = $bestVer
                success "Python found (via uv): $(& $p --version 2>$null)"
            }
        }
    }
} catch {}
}

# Strategy 2: system PATH python / python3
if (-not $PythonOk) {
    foreach ($cmd in @("python", "python3")) {
        try {
            $ver = & $cmd --version 2>$null
            if ($ver -and (Test-PythonVersion $ver)) {
                if ($ver -match '(\d+\.\d+)') { $FoundPyVersion = $Matches[1] }
                $PythonOk = $true
                success "Python found (system): $ver"
                break
            } elseif ($ver) {
                warn "Found $ver, below $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR, skipping"
            }
        } catch {}
    }
}

# Strategy 3: Windows py launcher (py -3.xx)
if (-not $PythonOk -and (Get-Command py -ErrorAction SilentlyContinue)) {
    try {
        $pyList = py --list 2>$null
        if ($pyList) {
            $bestVer = $null; $bestMajor = 0; $bestMinor = 0
            foreach ($line in $pyList) {
                if ($line -match '(\d+)\.(\d+)') {
                    $maj = [int]$Matches[1]; $min = [int]$Matches[2]
                    $meetsMin = ($maj -gt $PYTHON_MIN_MAJOR) -or `
                                ($maj -eq $PYTHON_MIN_MAJOR -and $min -ge $PYTHON_MIN_MINOR)
                    if ($meetsMin -and (($maj -gt $bestMajor) -or ($maj -eq $bestMajor -and $min -gt $bestMinor))) {
                        $bestMajor = $maj; $bestMinor = $min
                        $bestVer = "$maj.$min"
                    }
                }
            }
            if ($bestVer) {
                $FoundPyVersion = $bestVer
                $PythonOk = $true
                success "Python found (py launcher): $bestVer"
            }
        }
    } catch {}
}

# Strategy 4: auto-install via uv
if (-not $PythonOk) {
    info "Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR not found, installing $PYTHON_INSTALL_FALLBACK via uv..."
    try {
        & $UvCmd python install $PYTHON_INSTALL_FALLBACK 2>&1 | Out-Null
        $p = & $UvCmd python find $PYTHON_INSTALL_FALLBACK 2>$null
        if ($p) {
            $PythonOk = $true
            $FoundPyVersion = $PYTHON_INSTALL_FALLBACK
            success "Python installed: $(& $p --version 2>$null)"
        }
    } catch {}
}

if (-not $PythonOk) {
    err "Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR could not be installed."
    info "Please install Python 3.12+ manually:"
    info "  winget install Python.Python.3.12"
    info "  or download from https://python.org"
    pause; exit 1
}

# ── Step 3: Copy source to install directory ───────────────────────────────
info "Deploying program files..."
$parent = Split-Path $InstallDir -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
if (Test-Path $InstallDir)    { Remove-Item -Recurse -Force $InstallDir }
Copy-Item -Recurse -Path $VendorDir -Destination $InstallDir
success "Files deployed to: $InstallDir"

# ── Step 4: Create virtual environment ─────────────────────────────────────
info "Creating Python virtual environment..."
Push-Location $InstallDir
if (Test-Path "venv") { Remove-Item -Recurse -Force "venv" }
& $UvCmd venv venv --python $FoundPyVersion
success "Virtual environment ready"

# ── Step 5: Install Python dependencies (offline-first) ────────────────────
$env:VIRTUAL_ENV = "$InstallDir\venv"

# Offline mode: install from bundled wheels (no network)
# Falls back to online install only if wheels are incompatible
$installed = $false
$triedOffline = $false

if ($OfflineAvailable -and $WheelCount -gt 0) {
    $triedOffline = $true
    foreach ($spec in @(".[messaging,mcp,pty,honcho,cron,cli]", ".[messaging,mcp,honcho,cron,cli]", ".")) {
        Write-Host ""
        info "  Installing from local wheels: hermes-agent$spec"
        & $UvCmd pip install -e $spec --no-index --find-links "$WheelsDir"
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
            success "Installed from local wheels (offline)"
            break
        } else {
            warn "    Offline install failed for $spec (exit: $LASTEXITCODE)"
        }
    }
}

# Online fallback: download from PyPI
if (-not $installed) {
    if ($triedOffline) {
        hr
        warn "Offline wheels incompatible with your Python version."
        info "  Your Python: $FoundPyVersion"
        info "  Wheels built for: Python 3.12"
        info "  Switching to online install (network required)..."
        hr
    } else {
        info "Installing dependencies from PyPI (network required)..."
        info "  Download progress will be shown below"
    }

    foreach ($spec in @(".[messaging,mcp,pty,honcho,cron,cli]", ".[messaging,mcp,honcho,cron,cli]", ".")) {
        Write-Host ""
        info "  Installing: hermes-agent$spec"
        & $UvCmd pip install -e $spec
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
            break
        } else {
            warn "    $spec failed (exit: $LASTEXITCODE), trying next option..."
        }
    }
}

if (-not $installed) {
    Write-Host ""
    err "Dependency installation failed."
    info "Common causes:"
    info "  1. No network — check internet access"
    info "  2. Proxy/firewall — try disabling proxy or using a mirror"
    info "  3. Disk full — need ~500 MB free space"
    info "  4. Manual: cd $InstallDir && uv pip install -e ."
    Pop-Location; pause; exit 1
}
success "Python dependencies installed"
Pop-Location

# ── Step 6: Configure PATH and environment variables ───────────────────────
info "Configuring environment variables..."
$hermesBin = "$InstallDir\venv\Scripts"

$curPath = [Environment]::GetEnvironmentVariable("Path","User")
if ($curPath -notlike "*$hermesBin*") {
    [Environment]::SetEnvironmentVariable("Path","$hermesBin;$curPath","User")
    success "Added $hermesBin to user PATH"
} else {
    info "PATH already includes hermes directory"
}

$curHome = [Environment]::GetEnvironmentVariable("HERMES_HOME","User")
if ($curHome -ne $HermesHome) {
    [Environment]::SetEnvironmentVariable("HERMES_HOME",$HermesHome,"User")
    success "Set HERMES_HOME = $HermesHome"
}
$env:HERMES_HOME = $HermesHome
$env:Path = "$hermesBin;$env:Path"

# ── Step 7: Initialize data directory ──────────────────────────────────────
info "Initializing data directory..."
foreach ($sub in @("sessions","logs","memories","cron","hooks")) {
    New-Item -ItemType Directory -Force -Path "$HermesHome\$sub" | Out-Null
}

# .env (create template on first run, preserve existing)
$envPath = "$HermesHome\.env"
$envIsNew = $false
if (-not (Test-Path $envPath)) {
    $tmpl = "$InstallDir\.env.example"
    if (Test-Path $tmpl) { Copy-Item $tmpl $envPath }
    else { New-Item -ItemType File -Force -Path $envPath | Out-Null }
    $envIsNew = $true
} else {
    info ".env already exists, preserving"
}

# config.yaml
$cfgPath = "$HermesHome\config.yaml"
if (-not (Test-Path $cfgPath)) {
    $tmpl = "$InstallDir\cli-config.yaml.example"
    if (Test-Path $tmpl) {
        Copy-Item $tmpl $cfgPath
        success "Created $cfgPath"
    }
} else {
    info "config.yaml already exists, preserving"
}

success "Data directory ready: $HermesHome"

# ── Step 8: API Key configuration ──────────────────────────────────────────
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
    info "After filling in your API Key, restart terminal and run: hermes"
    success "Created $envPath"
} elseif (-not $envIsNew) {
    info "API Key config already exists: $envPath"
}

# ── Done ───────────────────────────────────────────────────────────────────
hr
Write-Host ""
Write-Host "  ✓ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  File locations:" -ForegroundColor Gray
Write-Host "    Data dir   $HermesHome"
Write-Host "    API Key    $HermesHome\.env"
Write-Host "    Program    $InstallDir"
Write-Host ""
Write-Host "  Next steps (required):" -ForegroundColor Yellow
Write-Host "    1. If you haven't filled in your API Key, edit:" -ForegroundColor White
Write-Host "       $HermesHome\.env" -ForegroundColor Green
Write-Host "    2. Restart terminal, then run:" -ForegroundColor White
Write-Host "       hermes" -ForegroundColor Green
Write-Host ""
Write-Host "  Optional: hermes setup   configure models/terminal/tools" -ForegroundColor Gray
Write-Host ""
Write-Host "  Skills (install on demand after setup):" -ForegroundColor Gray
Write-Host "    hermes skills   ← browse available skills" -ForegroundColor DarkGray
Write-Host ""
hr
