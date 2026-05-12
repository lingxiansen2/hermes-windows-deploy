# =============================================================================
# Hermes Agent 安装脚本 — Windows
# =============================================================================
# 用法：
#   .\install.ps1
#   .\install.ps1 -SkipSetup          跳过交互式配置向导
#   .\install.ps1 -HermesHome "D:\hermes"   自定义数据目录
# =============================================================================

param(
    [switch]$SkipSetup,
    [string]$HermesHome = "$env:LOCALAPPDATA\hermes",
    [string]$InstallDir = "$env:LOCALAPPDATA\hermes\hermes-agent"
)

$ErrorActionPreference = "Stop"

# ── 常量 ──────────────────────────────────────────────────────────────────
$PYTHON_MIN_MAJOR = 3
$PYTHON_MIN_MINOR = 11
$PYTHON_INSTALL_FALLBACK = "3.12"   # 系统无合适版本时自动安装的版本

# ── 打印函数 ──────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  ┌────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "  │    Hermes Agent  Windows 安装程序              │" -ForegroundColor Magenta
    Write-Host "  │    by Nous Research  /  v0.12.0                │" -ForegroundColor Magenta
    Write-Host "  └────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
}
function info    { param($m); Write-Host "  → $m" -ForegroundColor Cyan }
function success { param($m); Write-Host "  ✓ $m" -ForegroundColor Green }
function warn    { param($m); Write-Host "  ⚠ $m" -ForegroundColor Yellow }
function err     { param($m); Write-Host "  ✗ $m" -ForegroundColor Red }
function hr      { Write-Host "  ─────────────────────────────────────────────────" -ForegroundColor DarkGray }

# ── 定位 vendor 目录 ──────────────────────────────────────────────────────
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$VendorDir  = Join-Path (Split-Path $ScriptDir -Parent) "vendor\hermes-agent"

if (-not (Test-Path $VendorDir)) {
    err "找不到 vendor\hermes-agent 目录"
    err "请解压完整的安装包后再运行本脚本。"
    err "预期路径：$VendorDir"
    pause
    exit 1
}

Write-Banner
info "源码路径：$VendorDir"
info "安装目标：$InstallDir"
info "数据目录：$HermesHome"
hr

# ── Step 1：安装 uv ────────────────────────────────────────────────────────
info "正在检查 uv..."
$UvCmd = $null

foreach ($p in @("uv", "$env:USERPROFILE\.local\bin\uv.exe", "$env:USERPROFILE\.cargo\bin\uv.exe")) {
    if ($p -eq "uv") {
        if (Get-Command uv -ErrorAction SilentlyContinue) { $UvCmd = "uv"; break }
    } elseif (Test-Path $p) {
        $UvCmd = $p; break
    }
}

if (-not $UvCmd) {
    info "uv 未找到，正在安装..."
    try {
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex" 2>&1 | Out-Null
        # 刷新 PATH 后再找一次
        $env:Path = [Environment]::GetEnvironmentVariable("Path","User") + ";" + [Environment]::GetEnvironmentVariable("Path","Machine")
        foreach ($p in @("$env:USERPROFILE\.local\bin\uv.exe","$env:USERPROFILE\.cargo\bin\uv.exe")) {
            if (Test-Path $p) { $UvCmd = $p; break }
        }
        if (-not $UvCmd -and (Get-Command uv -ErrorAction SilentlyContinue)) { $UvCmd = "uv" }
    } catch {}
}

if (-not $UvCmd) {
    err "uv 安装失败。请手动安装后重试：https://docs.astral.sh/uv/"
    pause; exit 1
}
success "uv 就绪：$UvCmd"

# ── Step 2：确保 Python >= 3.11 ──────────────────────────────────────────────
info "正在检查 Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR..."
$PythonOk = $false
$FoundPyVersion = $null

# 辅助函数：从 "Python 3.x.y" 提取 major.minor 并判断 >= 3.11
function Test-PythonVersion {
    param([string]$VersionStr)
    # 匹配 "3.xx" 或 "3.xx.yy" 等格式
    if ($VersionStr -match '(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        return ($major -gt $PYTHON_MIN_MAJOR) -or `
               ($major -eq $PYTHON_MIN_MAJOR -and $minor -ge $PYTHON_MIN_MINOR)
    }
    return $false
}

# 策略 1：用 uv python list 动态发现所有已安装版本，选最高的 >= 3.11
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
                success "Python 已找到（通过 uv）：$(& $p --version 2>$null)"
            }
        }
    }
} catch {}

# 策略 2：尝试系统 PATH 中的 python / python3 / py
if (-not $PythonOk) {
    foreach ($cmd in @("python", "python3")) {
        try {
            $ver = & $cmd --version 2>$null
            if ($ver -and (Test-PythonVersion $ver)) {
                # 提取 major.minor 用于 venv
                if ($ver -match '(\d+\.\d+)') { $FoundPyVersion = $Matches[1] }
                $PythonOk = $true
                success "Python 已找到（系统）：$ver"
                break
            } elseif ($ver) {
                warn "发现 $ver，但版本低于 $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR，跳过"
            }
        } catch {}
    }
}

# 策略 3：Windows py launcher（支持 py -3.xx）
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
                success "Python 已找到（py launcher）：$bestVer"
            }
        }
    } catch {}
}

# 策略 4：以上全部失败，通过 uv 自动安装
if (-not $PythonOk) {
    info "未找到 Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR，通过 uv 安装 $PYTHON_INSTALL_FALLBACK..."
    try {
        & $UvCmd python install $PYTHON_INSTALL_FALLBACK 2>&1 | Out-Null
        $p = & $UvCmd python find $PYTHON_INSTALL_FALLBACK 2>$null
        if ($p) {
            $PythonOk = $true
            $FoundPyVersion = $PYTHON_INSTALL_FALLBACK
            success "Python 安装完成：$(& $p --version 2>$null)"
        }
    } catch {}
}

if (-not $PythonOk) {
    err "Python >= $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR 安装失败。"
    info "请手动安装 Python 3.12 或更高版本："
    info "  winget install Python.Python.3.12"
    info "  或从 https://python.org 下载"
    pause; exit 1
}

# ── Step 3：复制源码到安装目录 ────────────────────────────────────────────
info "正在部署程序文件..."
$parent = Split-Path $InstallDir -Parent
if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
if (Test-Path $InstallDir)    { Remove-Item -Recurse -Force $InstallDir }
Copy-Item -Recurse -Path $VendorDir -Destination $InstallDir
success "程序文件已部署到：$InstallDir"

# ── Step 4：创建虚拟环境 ────────────────────────────────────────────────────
info "正在创建 Python 虚拟环境..."
Push-Location $InstallDir
if (Test-Path "venv") { Remove-Item -Recurse -Force "venv" }
& $UvCmd venv venv --python $FoundPyVersion
success "虚拟环境就绪"

# ── Step 5：安装 Python 依赖（仅核心，不含 skills/RL）────────────────────────
info "正在安装 Python 依赖（首次可能需要几分钟）..."
info "  下方会显示下载进度，请耐心等待"
$env:VIRTUAL_ENV = "$InstallDir\venv"

# 只安装核心依赖，跳过 rl / optional-skills 等重型 extras
# 三层降级：完整 → 去掉 pty（避免 pywinpty 需要 MSVC 编译工具）→ 裸装
$installed = $false
foreach ($spec in @(".[messaging,mcp,pty,honcho,cron,cli]", ".[messaging,mcp,honcho,cron,cli]", ".")) {
    Write-Host ""
    info "  尝试安装: hermes-agent$spec"
    # 直接运行 uv，不隐藏任何输出 —— 用户能看到进度条
    & $UvCmd pip install -e $spec
    if ($LASTEXITCODE -eq 0) {
        $installed = $true
        break
    } else {
        warn "    $spec 安装失败 (exit code: $LASTEXITCODE)，尝试备选方案..."
    }
}

if (-not $installed) {
    Write-Host ""
    err "依赖安装失败，请检查网络连接后重试。"
    info "常见原因："
    info "  1. 网络不通 — 检查是否能访问 https://pypi.org"
    info "  2. 代理/防火墙 — 尝试关闭系统代理或设置 pip 源为国内镜像"
    info "  3. 磁盘空间不足 — 需要约 500 MB 空闲空间"
    info "  4. 手动重试：进入 %InstallDir% 目录运行: uv pip install -e ."
    Pop-Location; pause; exit 1
}
success "Python 依赖安装完成"
Pop-Location

# ── Step 6：配置 PATH 与环境变量 ────────────────────────────────────────────
info "正在配置环境变量..."
$hermesBin = "$InstallDir\venv\Scripts"

$curPath = [Environment]::GetEnvironmentVariable("Path","User")
if ($curPath -notlike "*$hermesBin*") {
    [Environment]::SetEnvironmentVariable("Path","$hermesBin;$curPath","User")
    success "已将 $hermesBin 加入用户 PATH"
} else {
    info "PATH 已包含 hermes 目录，无需修改"
}

$curHome = [Environment]::GetEnvironmentVariable("HERMES_HOME","User")
if ($curHome -ne $HermesHome) {
    [Environment]::SetEnvironmentVariable("HERMES_HOME",$HermesHome,"User")
    success "已设置 HERMES_HOME = $HermesHome"
}
$env:HERMES_HOME = $HermesHome
$env:Path = "$hermesBin;$env:Path"

# ── Step 7：初始化数据目录（最小化，不同步 skills）─────────────────────────
info "正在初始化数据目录..."
foreach ($sub in @("sessions","logs","memories","cron","hooks")) {
    New-Item -ItemType Directory -Force -Path "$HermesHome\$sub" | Out-Null
}

# .env（首次创建模板，已有则保留）
$envPath = "$HermesHome\.env"
$envIsNew = $false
if (-not (Test-Path $envPath)) {
    $tmpl = "$InstallDir\.env.example"
    if (Test-Path $tmpl) { Copy-Item $tmpl $envPath }
    else { New-Item -ItemType File -Force -Path $envPath | Out-Null }
    $envIsNew = $true
} else {
    info ".env 已存在，保留原文件"
}

# config.yaml
$cfgPath = "$HermesHome\config.yaml"
if (-not (Test-Path $cfgPath)) {
    $tmpl = "$InstallDir\cli-config.yaml.example"
    if (Test-Path $tmpl) {
        Copy-Item $tmpl $cfgPath
        success "已创建 $cfgPath"
    }
} else {
    info "config.yaml 已存在，保留原文件"
}

success "数据目录就绪：$HermesHome"

# ── Step 8：API Key 配置 ────────────────────────────────────────────────────
if ($envIsNew -and -not $SkipSetup) {
    hr
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  即将打开 API Key 配置文件，请立即填写！    ║" -ForegroundColor Yellow
    Write-Host "  ║  把 sk-CHANGE_ME 替换为你的真实 Key        ║" -ForegroundColor Yellow
    Write-Host "  ║  保存并关闭窗口即可                         ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    info "按任意键打开 $envPath ..."
    pause | Out-Null
    Start-Process notepad $envPath
    Write-Host ""
    info "填写 API Key 后保存关闭，然后重启终端运行 hermes 即可"
    success "已创建 $envPath"
} elseif (-not $envIsNew) {
    info "API Key 配置文件已存在：$envPath"
}

# ── 完成 ────────────────────────────────────────────────────────────────────
hr
Write-Host ""
Write-Host "  ✓ 安装完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  文件位置：" -ForegroundColor Gray
Write-Host "    数据目录  $HermesHome"
Write-Host "    API Key   $HermesHome\.env"
Write-Host "    程序目录  $InstallDir"
Write-Host ""
Write-Host "  ⚡ 下一步（必须）：" -ForegroundColor Yellow
Write-Host "    1. 如果还没填写 API Key，编辑：" -ForegroundColor White
Write-Host "       $HermesHome\.env" -ForegroundColor Green
Write-Host "    2. 重启终端，运行：" -ForegroundColor White
Write-Host "       hermes" -ForegroundColor Green
Write-Host ""
Write-Host "  可选：hermes setup  配置模型/终端/工具等高级设置" -ForegroundColor Gray
Write-Host ""
Write-Host "  Skills 安装（可选，安装后再按需添加）：" -ForegroundColor Gray
Write-Host "    hermes skills   ← 浏览可用 Skills" -ForegroundColor DarkGray
Write-Host ""
hr
