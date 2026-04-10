# AI Toolbox Setup Script — One-command setup with client selection
# Usage: powershell -ExecutionPolicy Bypass -File .agent/scripts/setup.ps1
# No $ErrorActionPreference = "Stop" — must be resilient.

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
Set-Location $RepoRoot

Write-Host ""
Write-Host "?? AI Toolbox Setup" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------
# Step 1: Detect installed AI clients
# ---------------------------------------------------------------
Write-Host "?? Scanning for installed AI clients..." -ForegroundColor Yellow

$Clients = @()
$ClientNames = @()

# Check Claude Code
if (Get-Command claude -ErrorAction SilentlyContinue) {
  try { $ver = (claude --version 2>$null) } catch { $ver = "installed" }
  $Clients += "claude"
  $ClientNames += "Claude Code ($ver)"
  Write-Host "  ? Claude Code ($ver)" -ForegroundColor Green
}

# Check Qwen Code
if (Get-Command qwen -ErrorAction SilentlyContinue) {
  try { $ver = (qwen --version 2>$null) } catch { $ver = "installed" }
  $Clients += "qwen"
  $ClientNames += "Qwen Code ($ver)"
  Write-Host "  ? Qwen Code ($ver)" -ForegroundColor Green
}

# Check Gemini CLI
if (Get-Command gemini -ErrorAction SilentlyContinue) {
  try { $ver = (gemini --version 2>$null) } catch { $ver = "installed" }
  $Clients += "gemini"
  $ClientNames += "Gemini CLI ($ver)"
  Write-Host "  ? Gemini CLI ($ver)" -ForegroundColor Green
}

# Check Aider
if (Get-Command aider -ErrorAction SilentlyContinue) {
  try { $ver = (aider --version 2>$null) } catch { $ver = "installed" }
  $Clients += "aider"
  $ClientNames += "Aider ($ver)"
  Write-Host "  ? Aider ($ver)" -ForegroundColor Green
}

# GUI-based clients (detect via install paths — unreliable, user can override)

# Cursor: common install locations
$CursorFound = (Get-Command cursor -ErrorAction SilentlyContinue) -or
    (Test-Path "$env:LOCALAPPDATA\Programs\cursor") -or
    (Test-Path "$env:LOCALAPPDATA\Programs\Cursor") -or
    (Test-Path "$env:USERPROFILE\.cursor") -or
    (Test-Path "$env:USERPROFILE\AppData\Local\Programs\Cursor")
if ($CursorFound) {
  $Clients += "cursor"
  $ClientNames += "Cursor (GUI)"
  Write-Host "  ? Cursor (GUI)" -ForegroundColor Green
}

# Cline/RooCode: VS Code extension — check extension storage + data dirs
$ClineFound = (Get-Command cline -ErrorAction SilentlyContinue) -or
    (Test-Path "$env:USERPROFILE\.cline") -or
    (Test-Path "$env:USERPROFILE\.roocode") -or
    ((Test-Path "$env:USERPROFILE\.vscode\extensions") -and (Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Filter "*cline*" -ErrorAction SilentlyContinue).Count -gt 0) -or
    ((Test-Path "$env:USERPROFILE\.vscode\extensions") -and (Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Filter "*roo*" -ErrorAction SilentlyContinue).Count -gt 0)
if ($ClineFound) {
  $Clients += "cline"
  $ClientNames += "Cline / RooCode (VS Code extension)"
  Write-Host "  ? Cline / RooCode (VS Code extension)" -ForegroundColor Green
}

# Windsurf: IDE — check common install locations
$WindsurfFound = (Get-Command windsurf -ErrorAction SilentlyContinue) -or
    (Test-Path "$env:LOCALAPPDATA\Programs\windsurf") -or
    (Test-Path "$env:LOCALAPPDATA\Programs\Windsurf") -or
    (Test-Path "$env:USERPROFILE\.windsurf") -or
    (Test-Path "$env:ProgramFiles\Windsurf")
if ($WindsurfFound) {
  $Clients += "windsurf"
  $ClientNames += "Windsurf (GUI)"
  Write-Host "  ? Windsurf (GUI)" -ForegroundColor Green
}

if ($Clients.Count -eq 0) {
  Write-Host "  [WARN]  No supported AI clients detected." -ForegroundColor Yellow
  Write-Host "  Supported: Claude Code, Qwen Code, Gemini CLI, Aider, Cursor, Cline, Windsurf"
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
Write-Host "? Primary client: $PrimaryClient" -ForegroundColor Green
Write-Host "   ? All router files will be created for ALL clients"
Write-Host "   ? Hooks + MCP will be configured for $PrimaryClient"

# ---------------------------------------------------------------
# Step 2: Run bootstrap
# ---------------------------------------------------------------
Write-Host ""
Write-Host "[TOOLS] Running bootstrap..." -ForegroundColor Yellow

if (Test-Path ".agent/scripts/bootstrap.ps1") {
  & ".agent/scripts/bootstrap.ps1"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "  [WARN]  Bootstrap exited with code $LASTEXITCODE" -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "  ? Bootstrap complete" -ForegroundColor Green

# ---------------------------------------------------------------
# Step 3: Detect project stack
# ---------------------------------------------------------------
Write-Host ""
Write-Host "?? Detecting project stack..." -ForegroundColor Yellow

$Stack = ""
if (Test-Path "package.json") {
  $Stack = "Node.js/TypeScript"
  Write-Host "  ? Detected: $Stack (package.json found)" -ForegroundColor Green
} elseif (Test-Path "Cargo.toml") {
  $Stack = "Rust"
  Write-Host "  ? Detected: $Stack (Cargo.toml found)" -ForegroundColor Green
} elseif ((Test-Path "pyproject.toml") -or (Test-Path "setup.py") -or (Test-Path "requirements.txt")) {
  $Stack = "Python"
  Write-Host "  ? Detected: $Stack (Python project files found)" -ForegroundColor Green
} elseif (Test-Path "go.mod") {
  $Stack = "Go"
  Write-Host "  ? Detected: $Stack (go.mod found)" -ForegroundColor Green
} elseif (Test-Path "pom.xml") {
  $Stack = "Java/Maven"
  Write-Host "  ? Detected: $Stack (pom.xml found)" -ForegroundColor Green
} elseif ((Test-Path "build.gradle") -or (Test-Path "build.gradle.kts")) {
  $Stack = "Java/Gradle"
  Write-Host "  ? Detected: $Stack (Gradle files found)" -ForegroundColor Green
} else {
  Write-Host "  [WARN]  No recognized project stack detected." -ForegroundColor Yellow
  Write-Host "  Stack rules will use generic settings."
}

# ---------------------------------------------------------------
# Step 4: Offer to install rtk
# ---------------------------------------------------------------
Write-Host ""
Write-Host "?? Optional tools:" -ForegroundColor Yellow
Write-Host ""

if (-not (Get-Command rtk -ErrorAction SilentlyContinue)) {
  $installRtk = Read-Host "  Install rtk (token optimization, 60-90% less tokens)? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($installRtk)) { $installRtk = "y" }

  if ($installRtk -match '^[Yy]$') {
    if (Get-Command cargo -ErrorAction SilentlyContinue) {
      Write-Host "  ? Installing: cargo install rtk --version 0.35.0"
      cargo install rtk --version 0.35.0
      if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] rtk installed" -ForegroundColor Green
      } else {
        Write-Host "  [ERROR] rtk installation failed" -ForegroundColor Red
      }

      $initRtk = Read-Host "  Configure rtk hooks for $PrimaryClient? [Y/n] "
      if ([string]::IsNullOrWhiteSpace($initRtk)) { $initRtk = "y" }
      if ($initRtk -match '^[Yy]$') {
        Write-Host "  ? Configuring hooks: rtk init -g"
        rtk init -g
        if ($LASTEXITCODE -eq 0) {
          Write-Host "  [OK] rtk hooks configured" -ForegroundColor Green
        } else {
          Write-Host "  [ERROR] rtk hook configuration failed" -ForegroundColor Red
        }
      }
    } else {
      Write-Host "  [WARN]  cargo not found. Install Rust first: https://rustup.rs/" -ForegroundColor Yellow
    }
  }
} else {
  try { $ver = (rtk --version 2>$null) } catch { $ver = "installed" }
  Write-Host "  ? rtk already installed ($ver)" -ForegroundColor Green
  $initRtk = Read-Host "  Configure rtk hooks for $PrimaryClient? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($initRtk)) { $initRtk = "y" }
  if ($initRtk -match '^[Yy]$') {
    Write-Host "  ? Configuring hooks: rtk init -g"
    rtk init -g
  }
}

# ---------------------------------------------------------------
# Step 5: Offer to install Beads
# ---------------------------------------------------------------
if (-not (Get-Command bd.exe -ErrorAction SilentlyContinue)) {
  Write-Host ""
  $installBeads = Read-Host "  Install Beads (task tracking)? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($installBeads)) { $installBeads = "y" }

  if ($installBeads -match '^[Yy]$') {
    if (Get-Command go -ErrorAction SilentlyContinue) {
      Write-Host "  [INFO] Installing: go install github.com/steveyegge/beads@v0.63.3"
      go install github.com/steveyegge/beads@v0.63.3
      if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Beads installed" -ForegroundColor Green
      } else {
        Write-Host "  [ERROR] Beads installation failed" -ForegroundColor Red
      }

      Write-Host "  [INFO] Initializing: bd init"
      bd.exe init
    } else {
      Write-Host "  [WARN]  go not found. Install Go first: https://go.dev/dl/" -ForegroundColor Yellow
    }
  }
} else {
  try { $ver = (bd.exe version 2>$null) } catch { $ver = "installed" }
  Write-Host "  [INFO] Beads already installed ($ver)" -ForegroundColor Green
  $initBd = Read-Host "  Initialize Beads task tracker for this project? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($initBd)) { $initBd = "y" }
  if ($initBd -match '^[Yy]$') {
    Write-Host "  [INFO] Initializing: bd init"
    bd.exe init
  }
}

# ---------------------------------------------------------------
# Step 6: Offer to configure MCP
# ---------------------------------------------------------------
if ($PrimaryClient) {
  Write-Host ""
  $installMcp = Read-Host "?? Configure MCP servers for $PrimaryClient? [Y/n] "
  if ([string]::IsNullOrWhiteSpace($installMcp)) { $installMcp = "y" }

  if ($installMcp -match '^[Yy]$') {
    switch ($PrimaryClient) {
      "claude" {
        Write-Host "  ? context7"
        try { claude mcp add context7 npx -y @upstash/context7-mcp@1.2.0 2>$null } catch { Write-Host "  [WARN]  Failed to add context7 (may already exist)" -ForegroundColor Yellow }

        Write-Host "  ? sequential-thinking"
        try { claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking@0.1.0 2>$null } catch { Write-Host "  [WARN]  Failed to add sequential-thinking (may already exist)" -ForegroundColor Yellow }
      }
      "qwen" { $McpFile = "mcp-qwen.json" }
      "aider" { $McpFile = "mcp-aider.yml" }
      default { $McpFile = "mcp-configs.json" }
    }

    if ($McpFile -and (Test-Path ".agent/templates/mcp/$McpFile")) {
      $copyMcp = Read-Host "  Copy config file to root for easy access? [Y/n] "
      if ([string]::IsNullOrWhiteSpace($copyMcp)) { $copyMcp = "y" }
      if ($copyMcp -match '^[Yy]$') {
        Copy-Item ".agent/templates/mcp/$McpFile" "./$McpFile"
        Write-Host "  ? Copied to ./$McpFile — add this to your $PrimaryClient MCP settings" -ForegroundColor Green
      }
    } elseif ($McpFile) {
      Write-Host "  [WARN]  Config file not found." -ForegroundColor Yellow
    }
  }
}

# ---------------------------------------------------------------
# Step 7: Register hooks for ALL detected clients
# ---------------------------------------------------------------
Write-Host ""
Write-Host "?? Registering AI Toolbox hooks for all detected clients..." -ForegroundColor Cyan

for ($i = 0; $i -lt $Clients.Count; $i++) {
  $client = $Clients[$i]
  Write-Host ""
  Write-Host "  ? $($ClientNames[$i]):" -ForegroundColor Yellow

  switch ($client) {
    "claude" {
      if (Test-Path ".agent/templates/clients/.claude.json") {
        Copy-Item ".agent/templates/clients/.claude.json" ".claude.json" -Force
        Write-Host "    ? .claude.json hooks installed" -ForegroundColor Green
      } else {
        Write-Host "    [WARN]  .claude.json template not found" -ForegroundColor Yellow
      }
    }
    "qwen" {
      New-Item -ItemType Directory -Force -Path ".qwen" | Out-Null
      @'
# Qwen Code hook wrapper (PowerShell)
$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
if ($env:QWEN_HOOK_TYPE -eq "pre-command") {
    & powershell -ExecutionPolicy Bypass -File "$RepoRoot/.agent/scripts/hook-pre-command.ps1" "$env:QWEN_COMMAND"
} elseif ($env:QWEN_HOOK_TYPE -eq "post-command") {
    & "$RepoRoot/.agent/scripts/hook-stop.ps1"
} elseif ($env:QWEN_HOOK_TYPE -eq "session-start") {
    & "$RepoRoot/.agent/scripts/sync-task.ps1"
    Get-Content "$RepoRoot/.agent/memory/current-task.md" 2>$null
}
'@ | Set-Content ".qwen/hooks.ps1" -Encoding utf8
      Write-Host "    ? .qwen/hooks.ps1 created" -ForegroundColor Green
    }
    "cursor" {
      New-Item -ItemType Directory -Force -Path ".cursor" | Out-Null
      @'
{"pre-command":"powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1","post-command":"powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1","session-start":"powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1"}
'@ | Set-Content ".cursor/hooks.json" -Encoding utf8
      Write-Host "    ? .cursor/hooks.json created" -ForegroundColor Green
    }
    "cline" {
      New-Item -ItemType Directory -Force -Path ".cline" | Out-Null
      @'
{"pre-command":"powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1","post-command":"powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1","session-start":"powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1"}
'@ | Set-Content ".cline/hooks.json" -Encoding utf8
      Write-Host "    ? .cline/hooks.json created" -ForegroundColor Green
    }
    "windsurf" {
      New-Item -ItemType Directory -Force -Path ".windsurf" | Out-Null
      @'
{"pre-command":"powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-pre-command.ps1","post-command":"powershell -ExecutionPolicy Bypass -File .agent/scripts/hook-stop.ps1","session-start":"powershell -ExecutionPolicy Bypass -File .agent/scripts/sync-task.ps1"}
'@ | Set-Content ".windsurf/hooks.json" -Encoding utf8
      Write-Host "    ? .windsurf/hooks.json created" -ForegroundColor Green
    }
    "gemini" { Write-Host "    ??  Basic Tier — hooks not supported (soft reminders only)" -ForegroundColor Gray }
    "aider" { Write-Host "    ??  Basic Tier — hooks not supported (soft reminders only)" -ForegroundColor Gray }
  }
}

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "? Setup complete!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

if ($PrimaryClient) {
  Write-Host "  Primary client: $PrimaryClient"
} else {
  Write-Host "  Primary client: none detected"
}
Write-Host "  Router files:   7 created"

if ($Stack) {
  Write-Host "  Project stack:  $Stack"
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
  Write-Host "  rtk:            installed + hooks configured" -ForegroundColor Green
} else {
  Write-Host "  rtk:            not installed (run 'cargo install rtk --version 0.35.0' later)" -ForegroundColor Yellow
}

if (Get-Command bd.exe -ErrorAction SilentlyContinue) {
  Write-Host "  Beads:          installed + initialized" -ForegroundColor Green
} else {
  Write-Host "  Beads:          not installed (run 'go install .../beads@latest' later)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  [NEXT] Next: Open your AI client in this directory and start working!" -ForegroundColor Cyan
Write-Host ""

