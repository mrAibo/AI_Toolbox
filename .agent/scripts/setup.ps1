# AI Toolbox Setup Script - One-command setup with client selection
# Usage: powershell -ExecutionPolicy Bypass -File .agent/scripts/setup.ps1 [-Silent]
# No $ErrorActionPreference = "Stop" - must be resilient.

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
AI Toolbox Setup Script

Usage: pwsh .agent/scripts/setup.ps1 [-Silent] [-Help]

  -Silent  Non-interactive. Pick the first detected client without prompting.
  -Help    Show this message.
"@
    exit 0
}

# Detect interactive console. If stdin is redirected (no TTY), force silent.
$script:Interactive = -not [Console]::IsInputRedirected
if (-not $script:Interactive -and -not $Silent) {
    Write-Host "[INFO] No TTY detected on stdin - running in -Silent mode." -ForegroundColor Cyan
    Write-Host "       Hooks, rtk, Beads, and MCP install prompts will use defaults (yes)."
    $Silent = $true
}

# Read-with-default helper. In -Silent or non-interactive mode, returns the
# default without prompting. Otherwise tries Read-Host; on null, returns default.
function script:Get-PromptDefault {
    param([string]$Question, [string]$Default)
    if ($Silent) {
        Write-Host "  $Question $Default (auto)"
        return $Default
    }
    $answer = Read-Host "  $Question"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer
}

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
Set-Location $RepoRoot

Write-Host ""
Write-Host "?? AI Toolbox Setup" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------
# Step 1: Determine primary AI client
#
# Priority:
#   1. Explicit primary_client in .ai-toolbox/config.json  (always wins)
#   2. Autodetection via Get-Command / path heuristics     (fallback)
#   3. Interactive selection when multiple detected         (last resort)
#   4. User's choice is written back to config so (1) applies next time
# ---------------------------------------------------------------

# --- Priority 1: Check for explicit override in central config ---
$ConfigPrimary = ""
if (Test-Path ".ai-toolbox/config.json") {
  try {
    $AiConfig = Get-Content ".ai-toolbox/config.json" -Raw | ConvertFrom-Json
    if ($AiConfig.primary_client) {
      $ConfigPrimary = $AiConfig.primary_client.Trim()
    }
  } catch { }
}

if ($ConfigPrimary) {
  Write-Host "  [CONFIG] Explicit primary_client in .ai-toolbox/config.json: $ConfigPrimary" -ForegroundColor Cyan
  Write-Host "           (Autodetection skipped. Edit primary_client in .ai-toolbox/config.json to change.)"
  $PrimaryClient = $ConfigPrimary
  Write-Host ""
  Write-Host "[OK] Primary client (from config): $PrimaryClient" -ForegroundColor Green
  Write-Host "   -> All router files will be created for ALL clients"
  Write-Host "   -> Hooks + MCP will be configured for $PrimaryClient"
} else {
  # --- Priority 2: Autodetect ---
  Write-Host "[SCAN] Scanning for installed AI clients..." -ForegroundColor Yellow

  $Clients = @()
  $ClientNames = @()

  # Check Claude Code
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    try { $ver = (claude --version 2>$null) } catch { $ver = "installed" }
    $Clients += "claude"
    $ClientNames += "Claude Code ($ver)"
    Write-Host "  [OK] Claude Code ($ver)" -ForegroundColor Green
  }

  # Check Qwen Code
  if (Get-Command qwen -ErrorAction SilentlyContinue) {
    try { $ver = (qwen --version 2>$null) } catch { $ver = "installed" }
    $Clients += "qwen"
    $ClientNames += "Qwen Code ($ver)"
    Write-Host "  [OK] Qwen Code ($ver)" -ForegroundColor Green
  }

  # Check Gemini CLI
  if (Get-Command gemini -ErrorAction SilentlyContinue) {
    try { $ver = (gemini --version 2>$null) } catch { $ver = "installed" }
    $Clients += "gemini"
    $ClientNames += "Gemini CLI ($ver)"
    Write-Host "  [OK] Gemini CLI ($ver)" -ForegroundColor Green
  }

  # Check Aider
  if (Get-Command aider -ErrorAction SilentlyContinue) {
    try { $ver = (aider --version 2>$null) } catch { $ver = "installed" }
    $Clients += "aider"
    $ClientNames += "Aider ($ver)"
    Write-Host "  [OK] Aider ($ver)" -ForegroundColor Green
  }

  # Check Codex CLI (binary or local .codex/ workspace or user-global config)
  $CodexFound = (Get-Command codex -ErrorAction SilentlyContinue) -or
      (Test-Path ".codex") -or
      (Test-Path "$env:USERPROFILE\.codex")
  if ($CodexFound) {
    try { $ver = (codex --version 2>$null) } catch { $ver = "installed" }
    if (-not $ver) { $ver = "installed" }
    $Clients += "codex"
    $ClientNames += "Codex CLI ($ver)"
    Write-Host "  [OK] Codex CLI ($ver)" -ForegroundColor Green
  }

  # GUI-based clients: check command + common install paths

  # Cursor
  $CursorFound = (Get-Command cursor -ErrorAction SilentlyContinue) -or
      (Test-Path "$env:LOCALAPPDATA\Programs\cursor") -or
      (Test-Path "$env:LOCALAPPDATA\Programs\Cursor") -or
      (Test-Path "$env:USERPROFILE\.cursor") -or
      (Test-Path "$env:USERPROFILE\AppData\Local\Programs\Cursor")
  if ($CursorFound) {
    $Clients += "cursor"
    $ClientNames += "Cursor (GUI)"
    Write-Host "  [OK] Cursor (GUI)" -ForegroundColor Green
  }

  # Cline/RooCode: command, config dirs, VS Code extension directory
  $ClineFound = (Get-Command cline -ErrorAction SilentlyContinue) -or
      (Test-Path "$env:USERPROFILE\.cline") -or
      (Test-Path "$env:USERPROFILE\.roocode") -or
      ((Test-Path "$env:USERPROFILE\.vscode\extensions") -and (Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Filter "*cline*" -ErrorAction SilentlyContinue).Count -gt 0) -or
      ((Test-Path "$env:USERPROFILE\.vscode\extensions") -and (Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Filter "*roo*" -ErrorAction SilentlyContinue).Count -gt 0)
  if ($ClineFound) {
    $Clients += "cline"
    $ClientNames += "Cline / RooCode (VS Code extension)"
    Write-Host "  [OK] Cline / RooCode (VS Code extension)" -ForegroundColor Green
  }

  # Windsurf
  $WindsurfFound = (Get-Command windsurf -ErrorAction SilentlyContinue) -or
      (Test-Path "$env:LOCALAPPDATA\Programs\windsurf") -or
      (Test-Path "$env:LOCALAPPDATA\Programs\Windsurf") -or
      (Test-Path "$env:USERPROFILE\.windsurf") -or
      (Test-Path "$env:ProgramFiles\Windsurf")
  if ($WindsurfFound) {
    $Clients += "windsurf"
    $ClientNames += "Windsurf (GUI)"
    Write-Host "  [OK] Windsurf (GUI)" -ForegroundColor Green
  }

  # OpenCode
  $OpenCodeFound = (Get-Command opencode -ErrorAction SilentlyContinue) -or
      (Test-Path "opencode.json") -or (Test-Path "opencode.jsonc")
  if ($OpenCodeFound) {
    try { $ver = (opencode --version 2>$null) } catch { $ver = "installed" }
    $Clients += "opencode"
    $ClientNames += "OpenCode ($ver)"
    Write-Host "  [OK] OpenCode ($ver)" -ForegroundColor Green
  }

  if ($Clients.Count -eq 0) {
    Write-Host "  [WARN]  No supported AI clients detected." -ForegroundColor Yellow
    Write-Host "  Supported: Claude Code, Qwen Code, Gemini CLI, Aider, Cursor, Cline, Windsurf"
    Write-Host "  Install one first, then re-run this setup."
    Write-Host "  Or set primary_client in .ai-toolbox/config.json to bypass autodetection."
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
    } elseif ($Silent) {
      $PrimaryClient = $Clients[0]
      Write-Host "  -Silent - auto-selected first client: $($ClientNames[0])" -ForegroundColor Green
    } else {
      # --- Priority 3: Interactive selection ---
      Write-Host "  Select PRIMARY client (used for hooks + MCP config):"
      for ($i = 0; $i -lt $Clients.Count; $i++) {
        Write-Host "  $($i+1). $($ClientNames[$i])"
      }
      Write-Host ""

      # Bounded retry. Fail-closed after 5 invalid attempts so we never spin.
      $attempts = 0
      $PrimaryClient = $null
      while ($attempts -lt 5) {
        $selection = Read-Host "  > "
        if ($null -eq $selection) {
          Write-Host "  [WARN] stdin closed before a selection was made." -ForegroundColor Yellow
          Write-Host "         Set primary_client in .ai-toolbox/config.json or re-run with -Silent."
          exit 65
        }
        if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $Clients.Count) {
          $PrimaryClient = $Clients[[int]$selection - 1]
          break
        }
        $attempts++
        Write-Host "  Invalid selection. Enter a number between 1 and $($Clients.Count). ($($5 - $attempts) attempt(s) left)" -ForegroundColor Red
      }
      if (-not $PrimaryClient) {
        Write-Host "  [WARN] Too many invalid attempts. Aborting." -ForegroundColor Yellow
        Write-Host "         Set primary_client in .ai-toolbox/config.json or re-run with -Silent."
        exit 65
      }
    }
  }

  # --- Priority 4: Persist choice back to config (so next run uses Priority 1) ---
  if ($PrimaryClient -and (Test-Path ".ai-toolbox/config.json")) {
    try {
      $AiConfig = Get-Content ".ai-toolbox/config.json" -Raw | ConvertFrom-Json
      $AiConfig | Add-Member -MemberType NoteProperty -Name "primary_client" -Value $PrimaryClient -Force
      $AiConfig | ConvertTo-Json -Depth 10 | Set-Content ".ai-toolbox/config.json" -Encoding utf8
      Write-Host "  [SAVE] Saved primary_client=$PrimaryClient to .ai-toolbox/config.json" -ForegroundColor Cyan
    } catch {
      Write-Host "  [NOTE] Could not persist primary client to config: $_" -ForegroundColor Yellow
    }
  }

  Write-Host ""
  Write-Host "[OK] Primary client: $PrimaryClient" -ForegroundColor Green
  Write-Host "   -> All router files will be created for ALL clients"
  Write-Host "   -> Hooks + MCP will be configured for $PrimaryClient"
}

# Collects manual steps the user must complete after setup
$NextSteps = @()

# ---------------------------------------------------------------
# Step 2: Run bootstrap
# ---------------------------------------------------------------
Write-Host ""
$InstallHooks = Get-PromptDefault "  Install Git commit hooks (TDD enforcement + secret scan)? [Y/n]" "Y"
if ($InstallHooks -match '^[Nn]') {
  $env:AITB_INSTALL_GIT_HOOKS = "false"
  Write-Host "  Git hooks skipped (run bootstrap.ps1 manually to install later)" -ForegroundColor Yellow
} else {
  $env:AITB_INSTALL_GIT_HOOKS = "true"
}

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
  $installRtk = Get-PromptDefault "  Install rtk (token optimization, 60-90% less tokens)? [Y/n]" "Y"
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

      $initRtk = Get-PromptDefault "  Configure rtk hooks for $PrimaryClient? [Y/n]" "Y"
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
  $initRtk = Get-PromptDefault "  Configure rtk hooks for $PrimaryClient? [Y/n]" "Y"
  if ([string]::IsNullOrWhiteSpace($initRtk)) { $initRtk = "y" }
  if ($initRtk -match '^[Yy]$') {
    Write-Host "  ? Configuring hooks: rtk init -g"
    rtk init -g
  }
}

# ---------------------------------------------------------------
# Step 5: Offer to install Beads
# ---------------------------------------------------------------

# Find bd.exe including GOPATH/bin even if not yet in session PATH
function Find-BdExe {
  $cmd = Get-Command bd.exe -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  try {
    $gopath = (go env GOPATH 2>$null).Trim()
    if ($gopath) {
      $candidate = Join-Path $gopath "bin\bd.exe"
      if (Test-Path $candidate) { return $candidate }
    }
  } catch { }
  return $null
}

# Add a directory to the current session PATH and permanently to user PATH
function Add-ToPath {
  param([string]$Dir)
  if (-not $Dir -or -not (Test-Path $Dir)) { return }
  if ($env:PATH -notmatch [regex]::Escape($Dir)) {
    $env:PATH += ";$Dir"
  }
  $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
  if ($userPath -notmatch [regex]::Escape($Dir)) {
    [System.Environment]::SetEnvironmentVariable("PATH", $userPath + ";" + $Dir, "User")
    Write-Host "  [FIX] Added $Dir to user PATH (restart terminal to take effect)" -ForegroundColor Cyan
  }
}

# Ensure dolt.exe is reachable — check common Windows install paths
function Test-DoltInPath {
  if (Get-Command dolt -ErrorAction SilentlyContinue) { return $true }
  $candidates = @(
    "C:\Program Files\Dolt\bin",
    "C:\Program Files (x86)\Dolt\bin",
    "$env:LOCALAPPDATA\Programs\Dolt\bin"
  )
  foreach ($dir in $candidates) {
    if (Test-Path (Join-Path $dir "dolt.exe")) {
      Add-ToPath -Dir $dir
      Write-Host "  [FIX] dolt found at $dir — added to PATH" -ForegroundColor Cyan
      return $true
    }
  }
  return $false
}

# Run bd init — try embedded first, fall back to --server mode
function Invoke-BdInit {
  param([string]$BdPath)
  $out = & $BdPath init 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] Beads initialized" -ForegroundColor Green
    return $true
  }
  # CGO/embedded not available — try server mode
  if (Test-DoltInPath) {
    $out2 = & $BdPath init --server 2>&1
    if ($LASTEXITCODE -eq 0) {
      Write-Host "  [OK] Beads initialized (server mode)" -ForegroundColor Green
      return $true
    }
    Write-Host "  [ERROR] bd init --server failed: $out2" -ForegroundColor Red
    $script:NextSteps += "Run manually in this directory: bd init --server"
    return $false
  }
  Write-Host "  [WARN] dolt not found — install dolt then run: bd init --server" -ForegroundColor Yellow
  $script:NextSteps += "Install dolt (winget install DoltHub.Dolt), open a new terminal, then run: bd init --server"
  return $false
}

# Remove stale npm bd shim if present (points to a non-existent
# @beads/bd npm package). Beads is a Go binary — `go install …/bd@…` —
# never an npm package. Old setups sometimes leave a broken shim in
# %APPDATA%\npm that PowerShell picks up before ~/go/bin/bd.exe.
#
# We check ALL extensions: PowerShell prefers bd.ps1, cmd.exe prefers
# bd.cmd, bare bd is a fallback. The previous version of this block
# only checked the bare path and missed the .ps1 variant entirely.
function Remove-NpmBdShim {
  $npmDir = Join-Path $env:APPDATA "npm"
  if (-not (Test-Path $npmDir)) { return }
  $candidates = @('bd', 'bd.ps1', 'bd.cmd', 'bd.exe') |
    ForEach-Object { Join-Path $npmDir $_ } |
    Where-Object { Test-Path $_ }
  if (-not $candidates) { return }
  # Confirm at least one looks like the broken @beads/bd shim before
  # we touch anything — never delete a shim we didn't recognize.
  $broken = $false
  foreach ($c in $candidates) {
    $body = Get-Content $c -Raw -ErrorAction SilentlyContinue
    if ($body -match 'bd\.js' -or $body -match 'node_modules.*beads') {
      $broken = $true; break
    }
  }
  if (-not $broken) { return }
  foreach ($c in $candidates) {
    Remove-Item $c -Force -ErrorAction SilentlyContinue
  }
  $names = ($candidates | ForEach-Object { Split-Path -Leaf $_ }) -join ', '
  Write-Host "  [FIX] Removed stale npm bd shim ($names)" -ForegroundColor Cyan
}
Remove-NpmBdShim

$BdPath = Find-BdExe
if (-not $BdPath) {
  Write-Host ""
  $installBeads = Get-PromptDefault "  Install Beads (task tracking)? [Y/n]" "Y"
  if ([string]::IsNullOrWhiteSpace($installBeads)) { $installBeads = "y" }

  if ($installBeads -match '^[Yy]$') {
    if (Get-Command go -ErrorAction SilentlyContinue) {
      Write-Host "  [INFO] Installing: go install github.com/steveyegge/beads/cmd/bd@v0.63.3"
      go install github.com/steveyegge/beads/cmd/bd@v0.63.3
      if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Beads installed" -ForegroundColor Green
        # Ensure GOPATH/bin is reachable in this session and permanently
        try {
          $GoBin = Join-Path (go env GOPATH).Trim() "bin"
          Add-ToPath -Dir $GoBin
        } catch { }
        $BdPath = Find-BdExe
        if ($BdPath) {
          Write-Host "  [INFO] Initializing Beads..."
          Invoke-BdInit -BdPath $BdPath | Out-Null
        } else {
          Write-Host "  [WARN] bd.exe not found after install — PATH may need a terminal restart" -ForegroundColor Yellow
          $NextSteps += "Open a new terminal and run: bd init --server"
        }
      } else {
        Write-Host "  [ERROR] Beads installation failed" -ForegroundColor Red
        $NextSteps += "Retry: go install github.com/steveyegge/beads/cmd/bd@v0.63.3"
      }
    } else {
      Write-Host "  [WARN]  go not found. Install Go first: https://go.dev/dl/" -ForegroundColor Yellow
      $NextSteps += "Install Go (https://go.dev/dl/), then: go install github.com/steveyegge/beads/cmd/bd@v0.63.3 && bd init --server"
    }
  }
} else {
  try { $ver = (& $BdPath --version 2>$null).Trim() } catch { $ver = "installed" }
  Write-Host "  [INFO] Beads already installed ($ver)" -ForegroundColor Green
  $initBd = Get-PromptDefault "  Initialize Beads task tracker for this project? [Y/n]" "Y"
  if ([string]::IsNullOrWhiteSpace($initBd)) { $initBd = "y" }
  if ($initBd -match '^[Yy]$') {
    Write-Host "  [INFO] Initializing Beads..."
    Invoke-BdInit -BdPath $BdPath | Out-Null
  }
}

# ---------------------------------------------------------------
# Step 6: Offer to configure MCP
# ---------------------------------------------------------------
if ($PrimaryClient) {
  Write-Host ""
  $installMcp = Get-PromptDefault "?? Configure MCP servers for $PrimaryClient? [Y/n]" "Y"
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
      $copyMcp = Get-PromptDefault "  Copy config file to root for easy access? [Y/n]" "Y"
      if ([string]::IsNullOrWhiteSpace($copyMcp)) { $copyMcp = "y" }
      if ($copyMcp -match '^[Yy]$') {
        Copy-Item ".agent/templates/mcp/$McpFile" "./$McpFile"
        Write-Host "  ? Copied to ./$McpFile � add this to your $PrimaryClient MCP settings" -ForegroundColor Green
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
    "opencode" {
      if ((Test-Path "opencode.json") -or (Test-Path "opencode.jsonc")) {
        Write-Host "    [OK] opencode.json already configured (created by bootstrap)" -ForegroundColor Green
      } elseif (Test-Path ".agent/templates/clients/opencode-config.json") {
        Copy-Item ".agent/templates/clients/opencode-config.json" "opencode.json"
        Write-Host "    [OK] opencode.json created with AI Toolbox configuration" -ForegroundColor Green
      } else {
        Write-Host "    [WARN]  opencode-config.json template not found" -ForegroundColor Yellow
      }
    }
    "gemini" { Write-Host "    ??  Basic Tier� hooks not supported (soft reminders only)" -ForegroundColor Gray }
    "aider" { Write-Host "    ??  Basic Tier � hooks not supported (soft reminders only)" -ForegroundColor Gray }
  }
}

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host "[OK] Setup complete!" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""

if ($PrimaryClient) {
  Write-Host "  Primary client: $PrimaryClient" -ForegroundColor Green
} else {
  Write-Host "  Primary client: none detected" -ForegroundColor Yellow
}
Write-Host "  Router files:   8 created"

if ($Stack) {
  Write-Host "  Project stack:  $Stack" -ForegroundColor Green
}

$RtkOk = Get-Command rtk -ErrorAction SilentlyContinue
if ($RtkOk) {
  Write-Host "  rtk:            [OK] installed" -ForegroundColor Green
} else {
  Write-Host "  rtk:            [--] not installed" -ForegroundColor Yellow
  $NextSteps += "Install rtk: cargo install rtk --version 0.35.0  (needs Rust: https://rustup.rs/)"
}

$BdOk = Find-BdExe
if ($BdOk) {
  Write-Host "  Beads:          [OK] installed + initialized" -ForegroundColor Green
} else {
  Write-Host "  Beads:          [--] not installed" -ForegroundColor Yellow
  if (-not ($NextSteps -match "beads")) {
    $NextSteps += "Install Beads: go install github.com/steveyegge/beads/cmd/bd@v0.63.3  (needs Go: https://go.dev/dl/)"
  }
}

# ---------------------------------------------------------------
# Next Steps (only shown if something requires manual action)
# ---------------------------------------------------------------
if ($NextSteps.Count -gt 0) {
  Write-Host ""
  Write-Host "  *** ACTION REQUIRED — complete these steps manually: ***" -ForegroundColor Yellow
  $n = 1
  foreach ($step in $NextSteps) {
    Write-Host "  $n. $step" -ForegroundColor Yellow
    $n++
  }
  Write-Host ""
  Write-Host "  After completing the steps above, re-run setup.ps1 to verify." -ForegroundColor Cyan
} else {
  Write-Host ""
  Write-Host "  [NEXT] Open your AI client in this directory and start working!" -ForegroundColor Cyan
}
Write-Host ""

