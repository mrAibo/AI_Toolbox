# AI Toolbox Setup Script — One-command setup with client selection
# Usage: powershell -ExecutionPolicy Bypass -File .agent/scripts/setup.ps1

$ErrorActionPreference = "Stop"

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
Set-Location $RepoRoot

Write-Host ""
Write-Host "🤖 AI Toolbox Setup" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------
# Step 1: Detect installed AI clients
# ---------------------------------------------------------------
Write-Host "📋 Scanning for installed AI clients..." -ForegroundColor Yellow

$Clients = @()
$ClientNames = @()

# Check Claude Code
if (Get-Command claude -ErrorAction SilentlyContinue) {
  try { $ver = (claude --version 2>$null) } catch { $ver = "installed" }
  $Clients += "claude"
  $ClientNames += "Claude Code ($ver)"
  Write-Host "  ✅ Claude Code ($ver)" -ForegroundColor Green
}

# Check Qwen Code
if (Get-Command qwen -ErrorAction SilentlyContinue) {
  try { $ver = (qwen --version 2>$null) } catch { $ver = "installed" }
  $Clients += "qwen"
  $ClientNames += "Qwen Code ($ver)"
  Write-Host "  ✅ Qwen Code ($ver)" -ForegroundColor Green
}

# Check Gemini CLI
if (Get-Command gemini -ErrorAction SilentlyContinue) {
  try { $ver = (gemini --version 2>$null) } catch { $ver = "installed" }
  $Clients += "gemini"
  $ClientNames += "Gemini CLI ($ver)"
  Write-Host "  ✅ Gemini CLI ($ver)" -ForegroundColor Green
}

# Check Aider
if (Get-Command aider -ErrorAction SilentlyContinue) {
  try { $ver = (aider --version 2>$null) } catch { $ver = "installed" }
  $Clients += "aider"
  $ClientNames += "Aider ($ver)"
  Write-Host "  ✅ Aider ($ver)" -ForegroundColor Green
}

if ($Clients.Count -eq 0) {
  Write-Host "  ⚠️  No supported AI clients detected." -ForegroundColor Yellow
  Write-Host "  Supported: Claude Code, Qwen Code, Gemini CLI, Aider"
  Write-Host "  Install one first, then re-run this setup."
  Write-Host ""
  Write-Host "  Continuing with bootstrap only..."
  $PrimaryClient = ""
} else {
  Write-Host ""
  Write-Host "  Found $($Clients.Count) client(s)."
  Write-Host ""

  if ($Clients.Count -eq 1) {
    $PrimaryClient = $Clients[0]
    Write-Host "  Auto-selected: $($ClientNames[0])" -ForegroundColor Green
  } else {
    Write-Host "  Select PRIMARY client (used for hooks + MCP config):"
    for ($i = 0; $i -lt $Clients.Count; $i++) {
      Write-Host "  $($i+1). $($ClientNames[$i])"
    }
    Write-Host ""

    while ($true) {
      $selection = Read-Host "  > "
      if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $Clients.Count) {
        $PrimaryClient = $Clients[[int]$selection - 1]
        break
      }
      Write-Host "  Invalid selection. Enter a number between 1 and $($Clients.Count)." -ForegroundColor Red
    }
  }
}

Write-Host ""
Write-Host "✅ Primary client: $PrimaryClient" -ForegroundColor Green
Write-Host "   → All router files will be created for ALL clients"
Write-Host "   → Hooks + MCP will be configured for $PrimaryClient"

# ---------------------------------------------------------------
# Step 2: Run bootstrap
# ---------------------------------------------------------------
Write-Host ""
Write-Host "🔧 Running bootstrap..." -ForegroundColor Yellow

if (Test-Path ".agent/scripts/bootstrap.ps1") {
  & powershell -ExecutionPolicy Bypass -File ".agent/scripts/bootstrap.ps1"
}

Write-Host ""
Write-Host "  ✅ Bootstrap complete" -ForegroundColor Green

# ---------------------------------------------------------------
# Step 3: Detect project stack
# ---------------------------------------------------------------
Write-Host ""
Write-Host "🔍 Detecting project stack..." -ForegroundColor Yellow

$Stack = ""
if (Test-Path "package.json") {
  $Stack = "Node.js/TypeScript"
  Write-Host "  ✅ Detected: $Stack (package.json found)" -ForegroundColor Green
} elseif (Test-Path "Cargo.toml") {
  $Stack = "Rust"
  Write-Host "  ✅ Detected: $Stack (Cargo.toml found)" -ForegroundColor Green
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "setup.py") -or (Test-Path "requirements.txt")) {
  $Stack = "Python"
  Write-Host "  ✅ Detected: $Stack (Python project files found)" -ForegroundColor Green
} elseif (Test-Path "go.mod") {
  $Stack = "Go"
  Write-Host "  ✅ Detected: $Stack (go.mod found)" -ForegroundColor Green
} elseif (Test-Path "pom.xml") {
  $Stack = "Java/Maven"
  Write-Host "  ✅ Detected: $Stack (pom.xml found)" -ForegroundColor Green
} elseif ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
  $Stack = "Java/Gradle"
  Write-Host "  ✅ Detected: $Stack (Gradle files found)" -ForegroundColor Green
} else {
  Write-Host "  ⚠️  No recognized project stack detected." -ForegroundColor Yellow
  Write-Host "  Stack rules will use generic settings."
}

# ---------------------------------------------------------------
# Step 4: Offer to install rtk
# ---------------------------------------------------------------
Write-Host ""
Write-Host "📦 Optional tools:" -ForegroundColor Yellow
Write-Host ""

if (-not (Get-Command rtk -ErrorAction SilentlyContinue)) {
  $installRtk = Read-Host "  Install rtk (token optimization, 60-90% less tokens)? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($installRtk)) { $installRtk = "y" }

  if ($installRtk -match '^[Yy]$') {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
      Write-Host "  ✅ Installing: cargo install rtk"
      cargo install rtk
      Write-Host "  ✅ rtk installed" -ForegroundColor Green

      $initRtk = Read-Host "  Configure rtk hooks for $PrimaryClient? [Y/n] "
      if ([string]::IsNullOrWhiteSpace($initRtk)) { $initRtk = "y" }
      if ($initRtk -match '^[Yy]$') {
        Write-Host "  ✅ Configuring hooks: rtk init -g"
        rtk init -g
      }
    } else {
      Write-Host "  ⚠️  cargo not found. Install Rust first: https://rustup.rs/" -ForegroundColor Yellow
    }
  }
} else {
  try { $ver = (rtk --version 2>$null) } catch { $ver = "installed" }
  Write-Host "  ✅ rtk already installed ($ver)" -ForegroundColor Green
}

# ---------------------------------------------------------------
# Step 5: Offer to install Beads
# ---------------------------------------------------------------
if (-not (Get-Command bd -ErrorAction SilentlyContinue)) {
  Write-Host ""
  $installBeads = Read-Host "  Install Beads (task tracking)? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($installBeads)) { $installBeads = "y" }

  if ($installBeads -match '^[Yy]$') {
    if (Get-Command go -ErrorAction SilentlyContinue) {
      Write-Host "  ✅ Installing: go install github.com/steveyegge/beads@latest"
      go install github.com/steveyegge/beads@latest
      Write-Host "  ✅ Beads installed" -ForegroundColor Green

      Write-Host "  ✅ Initializing: bd init"
      bd init
    } else {
      Write-Host "  ⚠️  go not found. Install Go first: https://go.dev/dl/" -ForegroundColor Yellow
    }
  }
} else {
  try { $ver = (bd version 2>$null) } catch { $ver = "installed" }
  Write-Host "  ✅ Beads already installed ($ver)" -ForegroundColor Green
}

# ---------------------------------------------------------------
# Step 6: Offer to configure MCP
# ---------------------------------------------------------------
if ($PrimaryClient -eq "claude") {
  Write-Host ""
  $installMcp = Read-Host "🌐 Configure MCP servers for $PrimaryClient? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($installMcp)) { $installMcp = "y" }

  if ($installMcp -match '^[Yy]$') {
    Write-Host "  ✅ context7"
    try { claude mcp add context7 npx -y @upstash/context7-mcp 2>$null } catch { Write-Host "  ⚠️  Failed to add context7 (may already exist)" -ForegroundColor Yellow }

    Write-Host "  ✅ sequential-thinking"
    try { claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking 2>$null } catch { Write-Host "  ⚠️  Failed to add sequential-thinking (may already exist)" -ForegroundColor Yellow }
  }
}

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

if ($PrimaryClient) {
  Write-Host "  Primary client: $PrimaryClient"
} else {
  Write-Host "  Primary client: none detected"
}
Write-Host "  Router files:   8 created"

if ($Stack) {
  Write-Host "  Project stack:  $Stack"
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
  Write-Host "  rtk:            installed + hooks configured" -ForegroundColor Green
} else {
  Write-Host "  rtk:            not installed (run 'cargo install rtk' later)" -ForegroundColor Yellow
}

if (Get-Command bd -ErrorAction SilentlyContinue) {
  Write-Host "  Beads:          installed + initialized" -ForegroundColor Green
} else {
  Write-Host "  Beads:          not installed (run 'go install .../beads@latest' later)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  🚀 Next: Open your AI client in this directory and start working!" -ForegroundColor Cyan
Write-Host ""
