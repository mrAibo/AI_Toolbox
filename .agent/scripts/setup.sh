#!/bin/bash
# AI Toolbox Setup Script — One-command setup with client selection
#
# Usage:
#   bash .agent/scripts/setup.sh [--silent|-s] [--help|-h]
#
#   --silent, -s    Non-interactive. Pick the first detected client without
#                   prompting; abort with code 65 if none is detected.
#   --help, -h      Show this message.

set -e

# ---- Argument parsing ----
SILENT=0
for _arg in "$@"; do
    case "$_arg" in
        --silent|-s) SILENT=1 ;;
        --help|-h)
            awk '
                NR == 1 { next }
                /^# / || /^#$/ { sub(/^# ?/, ""); print; next }
                { exit }
            ' "$0"
            exit 0
            ;;
    esac
done

# ---- Detect interactive stdin once. We use this to bail out of read loops
#      cleanly instead of spinning forever on a closed stdin (e.g. when
#      ai-toolbox is invoked from a non-TTY parent). ----
if [ -t 0 ]; then
    INTERACTIVE=1
else
    INTERACTIVE=0
    if [ "$SILENT" -eq 0 ]; then
        echo "ℹ️  No TTY detected on stdin — running in --silent mode." >&2
        echo "   Hooks, rtk, Beads, and MCP install prompts will use defaults (yes)." >&2
        SILENT=1
    fi
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# ---- Prompt helper. In SILENT mode, returns the default without reading.
#      Otherwise tries to read; on EOF, falls back to the default.
#
# Usage: _prompt VAR "Question text? [Y/n]" "Y"
_prompt() {
    local _varname="$1"; shift
    local _question="$1"; shift
    local _default="$1"; shift
    if [ "$SILENT" -eq 1 ]; then
        printf -v "$_varname" '%s' "$_default"
        echo "  ${_question} ${_default} (auto)"
        return 0
    fi
    local _answer
    if ! read -r -p "  ${_question} " _answer; then
        printf -v "$_varname" '%s' "$_default"
        return 0
    fi
    if [ -z "$_answer" ]; then
        _answer="$_default"
    fi
    printf -v "$_varname" '%s' "$_answer"
}

echo ""
echo "🤖 AI Toolbox Setup"
echo "==================="
echo ""

# ---------------------------------------------------------------
# Step 1: Determine primary AI client
#
# Priority:
#   1. Explicit primary_client in .ai-toolbox/config.json  (always wins)
#   2. Autodetection via command-v / path heuristics       (fallback)
#   3. Interactive selection when multiple detected         (last resort)
#   4. User's choice is written back to config so (1) applies next time
# ---------------------------------------------------------------

# --- Priority 1: Check for explicit override in central config ---
CONFIG_PRIMARY=""
if [ -f ".ai-toolbox/config.json" ] && command -v python3 &>/dev/null; then
  CONFIG_PRIMARY=$(python3 -c "
import json, sys
try:
    with open('.ai-toolbox/config.json') as f:
        data = json.load(f)
    pc = (data.get('primary_client') or '').strip()
    print(pc)
except Exception:
    print('')
" 2>/dev/null || echo "")
fi

if [ -n "$CONFIG_PRIMARY" ]; then
  echo "  📌 Explicit primary_client in .ai-toolbox/config.json: $CONFIG_PRIMARY"
  echo "     (Autodetection skipped. Edit primary_client in .ai-toolbox/config.json to change.)"
  PRIMARY_CLIENT="$CONFIG_PRIMARY"
  echo ""
  echo "✅ Primary client (from config): $PRIMARY_CLIENT"
  echo "   → All router files will be created for ALL clients"
  echo "   → Hooks + MCP will be configured for $PRIMARY_CLIENT"
else
  # --- Priority 2: Autodetect ---
  echo "📋 Scanning for installed AI clients..."

  CLIENTS=()
  CLIENT_NAMES=()

  # Check Claude Code
  if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
    CLIENTS+=("claude")
    CLIENT_NAMES+=("Claude Code ($CLAUDE_VERSION)")
    echo "  ✅ Claude Code ($CLAUDE_VERSION)"
  fi

  # Check Qwen Code
  if command -v qwen &> /dev/null; then
    QWEN_VERSION=$(qwen --version 2>/dev/null || echo "installed")
    CLIENTS+=("qwen")
    CLIENT_NAMES+=("Qwen Code ($QWEN_VERSION)")
    echo "  ✅ Qwen Code ($QWEN_VERSION)"
  fi

  # Check Gemini CLI
  if command -v gemini &> /dev/null; then
    GEMINI_VERSION=$(gemini --version 2>/dev/null || echo "installed")
    CLIENTS+=("gemini")
    CLIENT_NAMES+=("Gemini CLI ($GEMINI_VERSION)")
    echo "  ✅ Gemini CLI ($GEMINI_VERSION)"
  fi

  # Check Aider
  if command -v aider &> /dev/null; then
    AIDER_VERSION=$(aider --version 2>/dev/null || echo "installed")
    CLIENTS+=("aider")
    CLIENT_NAMES+=("Aider ($AIDER_VERSION)")
    echo "  ✅ Aider ($AIDER_VERSION)"
  fi

  # Check Codex CLI (binary or local .codex/ workspace)
  if command -v codex &> /dev/null || [ -d ".codex" ] || [ -d "$HOME/.codex" ]; then
    CODEX_VERSION=$(codex --version 2>/dev/null || echo "installed")
    CLIENTS+=("codex")
    CLIENT_NAMES+=("Codex CLI ($CODEX_VERSION)")
    echo "  ✅ Codex CLI ($CODEX_VERSION)"
  fi

  # GUI-based clients (no CLI binary — detect via common install paths)
  if command -v cursor &> /dev/null || [ -d "$HOME/.cursor" ] || [ -d "$HOME/.config/cursor" ]; then
    CLIENTS+=("cursor")
    CLIENT_NAMES+=("Cursor (GUI)")
    echo "  ✅ Cursor (GUI)"
  fi

  # Cline / RooCode: check command, config dirs, and VS Code extension directory (parity with .ps1)
  _cline_ext_found=false
  if [ -d "$HOME/.vscode/extensions" ]; then
    if find "$HOME/.vscode/extensions" -maxdepth 1 \( -iname "*cline*" -o -iname "*roo*" \) 2>/dev/null | grep -q .; then
      _cline_ext_found=true
    fi
  fi
  if command -v cline &> /dev/null || [ -d "$HOME/.cline" ] || [ -d "$HOME/.config/cline" ] || [ -d "$HOME/.roocode" ] || [ "$_cline_ext_found" = true ]; then
    CLIENTS+=("cline")
    CLIENT_NAMES+=("Cline / RooCode (VS Code extension)")
    echo "  ✅ Cline / RooCode (VS Code extension)"
  fi

  if command -v windsurf &> /dev/null || [ -d "$HOME/.windsurf" ] || [ -d "$HOME/.config/windsurf" ]; then
    CLIENTS+=("windsurf")
    CLIENT_NAMES+=("Windsurf (GUI)")
    echo "  ✅ Windsurf (GUI)"
  fi

  # Check OpenCode
  if command -v opencode &> /dev/null || [ -f "opencode.json" ] || [ -f "opencode.jsonc" ]; then
    OPENCODE_VERSION=$(opencode --version 2>/dev/null || echo "installed")
    CLIENTS+=("opencode")
    CLIENT_NAMES+=("OpenCode ($OPENCODE_VERSION)")
    echo "  ✅ OpenCode ($OPENCODE_VERSION)"
  fi

  # If no clients found, show message
  if [ ${#CLIENTS[@]} -eq 0 ]; then
    echo "  ⚠️  No supported AI clients detected."
    echo "  Supported: Claude Code, Qwen Code, Gemini CLI, Aider, Cursor, Cline, Windsurf"
    echo "  Install one first, then re-run this setup."
    echo "  Or set primary_client in .ai-toolbox/config.json to bypass autodetection."
    echo ""
    echo "  Continuing with bootstrap only..."
    PRIMARY_CLIENT=""
  else
    echo ""
    echo "  Found ${#CLIENTS[@]} client(s)."
    echo ""

    # If only one client, auto-select
    if [ ${#CLIENTS[@]} -eq 1 ]; then
      PRIMARY_CLIENT="${CLIENTS[0]}"
      echo "  Auto-selected: ${CLIENT_NAMES[0]}"
    elif [ "$SILENT" -eq 1 ] || [ "$INTERACTIVE" -eq 0 ]; then
      # Non-interactive: pick the first detected client. The choice is
      # persisted to config below, so a re-run can adjust if needed.
      PRIMARY_CLIENT="${CLIENTS[0]}"
      if [ "$SILENT" -eq 1 ]; then
        echo "  --silent — auto-selected first client: ${CLIENT_NAMES[0]}"
      else
        echo "  Non-interactive (no TTY) — auto-selected first client: ${CLIENT_NAMES[0]}"
        echo "  To choose a different one, edit primary_client in .ai-toolbox/config.json"
        echo "  or re-run interactively."
      fi
    else
      # --- Priority 3: Interactive selection ---
      echo "  Select PRIMARY client (used for hooks + MCP config):"
      for i in "${!CLIENTS[@]}"; do
        echo "  $((i+1)). ${CLIENT_NAMES[$i]}"
      done
      echo ""

      # Bounded retry loop. Each iteration MUST either succeed or break out
      # — never silently spin if stdin is closed or the user keeps entering
      # garbage. Fail closed after 5 invalid attempts.
      attempts=0
      while [ "$attempts" -lt 5 ]; do
        if ! read -r -p "  > " selection; then
          echo "  ⚠️  stdin closed before a selection was made." >&2
          echo "     Set primary_client in .ai-toolbox/config.json or re-run with --silent." >&2
          exit 65
        fi
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#CLIENTS[@]}" ]; then
          PRIMARY_CLIENT="${CLIENTS[$((selection-1))]}"
          break
        fi
        attempts=$((attempts+1))
        echo "  Invalid selection. Enter a number between 1 and ${#CLIENTS[@]}. ($((5-attempts)) attempt(s) left)"
      done
      if [ -z "${PRIMARY_CLIENT:-}" ]; then
        echo "  ⚠️  Too many invalid attempts. Aborting." >&2
        echo "     Set primary_client in .ai-toolbox/config.json or re-run with --silent." >&2
        exit 65
      fi
    fi
  fi

  # --- Priority 4: Persist choice back to config (so next run uses Priority 1) ---
  if [ -n "$PRIMARY_CLIENT" ] && [ -f ".ai-toolbox/config.json" ] && command -v python3 &>/dev/null; then
    PYTHONIOENCODING=utf-8 python3 -c "
import json
try:
    with open('.ai-toolbox/config.json', encoding='utf-8') as f:
        data = json.load(f)
    data['primary_client'] = '$PRIMARY_CLIENT'
    with open('.ai-toolbox/config.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
        f.write('\n')
    print('  Saved primary_client=$PRIMARY_CLIENT to .ai-toolbox/config.json')
except Exception as e:
    print('  Note: Could not persist primary client to config: ' + str(e))
" 2>/dev/null || true
  fi

  echo ""
  echo "✅ Primary client: $PRIMARY_CLIENT"
  echo "   → All router files will be created for ALL clients"
  echo "   → Hooks + MCP will be configured for $PRIMARY_CLIENT"
fi

# Collects manual steps the user must complete after setup
NEXT_STEPS=()

# ---------------------------------------------------------------
# Step 2: Run bootstrap
# ---------------------------------------------------------------
echo ""
_prompt install_hooks "Install Git commit hooks (TDD enforcement + secret scan)? [Y/n]" "Y"
install_hooks=${install_hooks:-y}
if [[ "$install_hooks" =~ ^[Nn]$ ]]; then
  export AITB_INSTALL_GIT_HOOKS=false
  echo "  ⏭️  Git hooks skipped (run bootstrap.sh manually to install later)"
else
  export AITB_INSTALL_GIT_HOOKS=true
fi

echo ""
echo "🔧 Running bootstrap..."

if [ -f ".agent/scripts/bootstrap.sh" ]; then
  bash .agent/scripts/bootstrap.sh
fi

echo ""
echo "  ✅ Bootstrap complete"

# ---------------------------------------------------------------
# Step 3: Detect project stack
# ---------------------------------------------------------------
echo ""
echo "🔍 Detecting project stack..."

STACK=""
if [ -f "package.json" ]; then
  STACK="Node.js/TypeScript"
  echo "  ✅ Detected: $STACK (package.json found)"
elif [ -f "Cargo.toml" ]; then
  STACK="Rust"
  echo "  ✅ Detected: $STACK (Cargo.toml found)"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
  STACK="Python"
  echo "  ✅ Detected: $STACK (Python project files found)"
elif [ -f "go.mod" ]; then
  STACK="Go"
  echo "  ✅ Detected: $STACK (go.mod found)"
elif [ -f "pom.xml" ]; then
  STACK="Java/Maven"
  echo "  ✅ Detected: $STACK (pom.xml found)"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  STACK="Java/Gradle"
  echo "  ✅ Detected: $STACK (Gradle files found)"
else
  echo "  ⚠️  No recognized project stack detected."
  echo "  Stack rules will use generic settings."
fi

# ---------------------------------------------------------------
# Step 4: Offer to install rtk
# ---------------------------------------------------------------
echo ""
echo "📦 Optional tools:"
echo ""

if ! command -v rtk &> /dev/null; then
  _prompt install_rtk "Install rtk (token optimization, 60-90% less tokens)? [Y/n]" "Y"
  install_rtk=${install_rtk:-y}

  if [[ "$install_rtk" =~ ^[Yy]$ ]]; then
    if command -v cargo &> /dev/null; then
      echo "  ✅ Installing: cargo install rtk --version 0.35.0"
      cargo install rtk --version 0.35.0 --locked
      echo "  ✅ rtk installed"

      _prompt init_rtk "Configure rtk hooks for $PRIMARY_CLIENT? [Y/n]" "Y"
      init_rtk=${init_rtk:-y}
      if [[ "$init_rtk" =~ ^[Yy]$ ]]; then
        echo "  ✅ Configuring hooks: rtk init -g"
        rtk init -g 2>/dev/null || true
      fi
    else
      echo "  ⚠️  cargo not found. Install Rust first: https://rustup.rs/"
    fi
  fi
else
  echo "  ✅ rtk already installed ($(rtk --version 2>/dev/null || echo "installed"))"
  _prompt init_rtk "Configure rtk hooks for $PRIMARY_CLIENT? [Y/n]" "Y"
  init_rtk=${init_rtk:-y}
  if [[ "$init_rtk" =~ ^[Yy]$ ]]; then
    echo "  ✅ Configuring hooks: rtk init -g"
    rtk init -g 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------
# Step 5: Offer to install Beads
# ---------------------------------------------------------------

# Ensure GOPATH/bin is in PATH for this session (needed right after go install)
_ensure_gopath_bin() {
  local gopath
  gopath=$(go env GOPATH 2>/dev/null || true)
  if [ -n "$gopath" ] && [ -d "$gopath/bin" ]; then
    case ":$PATH:" in
      *":$gopath/bin:"*) ;;
      *) export PATH="$PATH:$gopath/bin" ;;
    esac
  fi
}

# Find bd binary including GOPATH/bin even if not yet in PATH
_find_bd() {
  command -v bd 2>/dev/null && return
  command -v bd.exe 2>/dev/null && return
  local gopath
  gopath=$(go env GOPATH 2>/dev/null || true)
  [ -n "$gopath" ] && [ -x "$gopath/bin/bd" ]   && echo "$gopath/bin/bd"   && return
  [ -n "$gopath" ] && [ -x "$gopath/bin/bd.exe" ] && echo "$gopath/bin/bd.exe" && return
}

BD_CMD=$(_find_bd)
if [ -z "$BD_CMD" ]; then
  echo ""
  _prompt install_beads "Install Beads (task tracking)? [Y/n]" "Y"
  install_beads=${install_beads:-y}

  if [[ "$install_beads" =~ ^[Yy]$ ]]; then
    if command -v go &> /dev/null; then
      echo "  ✅ Installing: go install github.com/steveyegge/beads/cmd/bd@v0.63.3"
      go install github.com/steveyegge/beads/cmd/bd@v0.63.3
      if [ $? -eq 0 ]; then
        echo "  ✅ Beads installed"
        _ensure_gopath_bin
        BD_CMD=$(_find_bd)
        if [ -n "$BD_CMD" ]; then
          echo "  ✅ Initializing: bd init"
          "$BD_CMD" init 2>&1 || {
            echo "  ⚠️  bd init failed — run manually: bd init"
            NEXT_STEPS+=("Run in this directory: bd init")
          }
        else
          echo "  ⚠️  bd not found after install — open a new terminal and run: bd init"
          NEXT_STEPS+=("Open a new terminal and run: bd init")
        fi
      else
        echo "  ❌ Beads installation failed"
        NEXT_STEPS+=("Retry: go install github.com/steveyegge/beads/cmd/bd@v0.63.3")
      fi
    else
      echo "  ⚠️  go not found. Install Go first: https://go.dev/dl/"
      NEXT_STEPS+=("Install Go (https://go.dev/dl/), then: go install github.com/steveyegge/beads/cmd/bd@v0.63.3 && bd init")
    fi
  fi
else
  echo "  ✅ Beads already installed ($("$BD_CMD" version 2>/dev/null || echo "installed"))"
fi

# ---------------------------------------------------------------
# Step 6: Offer to configure MCP
# ---------------------------------------------------------------
if [ -n "$PRIMARY_CLIENT" ]; then
  echo ""
  _prompt install_mcp "🌐 Configure MCP servers for $PRIMARY_CLIENT? [Y/n]" "Y"
  install_mcp=${install_mcp:-y}

  if [[ "$install_mcp" =~ ^[Yy]$ ]]; then
    case "$PRIMARY_CLIENT" in
      claude)
        echo "  ✅ context7"
        claude mcp add context7 npx -y @upstash/context7-mcp@1.2.0 2>/dev/null || echo "  ⚠️  Failed to add context7 (may already exist)"

        echo "  ✅ sequential-thinking"
        claude mcp add sequential-thinking npx -y @modelcontextprotocol/server-sequential-thinking@0.1.0 2>/dev/null || echo "  ⚠️  Failed to add sequential-thinking (may already exist)"
        ;;
      qwen|aider|cursor|cline|windsurf|gemini)
        # For other clients, we provide the config file
        MCP_FILE=""
        case "$PRIMARY_CLIENT" in
          qwen) MCP_FILE="mcp-qwen.json" ;;
          aider) MCP_FILE="mcp-aider.yml" ;;
          *) MCP_FILE="mcp-configs.json" ;;
        esac

        if [ -f ".agent/templates/mcp/$MCP_FILE" ]; then
          _prompt copy_mcp "Copy config file to root for easy access? [Y/n]" "Y"
          copy_mcp=${copy_mcp:-y}
          if [[ "$copy_mcp" =~ ^[Yy]$ ]]; then
            cp ".agent/templates/mcp/$MCP_FILE" "./$MCP_FILE"
            echo "  ✅ Copied to ./$MCP_FILE — add this to your $PRIMARY_CLIENT MCP settings"
          fi
        else
          echo "  ⚠️  Config file not found."
        fi
        ;;
    esac
  fi
fi

# ---------------------------------------------------------------
# Step 7: Register hooks for ALL detected clients
# ---------------------------------------------------------------
echo ""
echo "🔗 Registering AI Toolbox hooks for all detected clients..."

for i in "${!CLIENTS[@]}"; do
  client="${CLIENTS[$i]}"
  echo ""
  echo "  → ${CLIENT_NAMES[$i]}:"

  case "$client" in
    claude)
      if [ -f ".agent/templates/clients/.claude.json" ]; then
        cp .agent/templates/clients/.claude.json .claude.json
        echo "    ✅ .claude.json hooks installed"
      else
        echo "    ⚠️  .claude.json template not found"
      fi
      ;;
    qwen)
      mkdir -p .qwen
      cat > .qwen/hooks.sh << 'QWENEOF'
#!/bin/bash
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
case "$QWEN_HOOK_TYPE" in
  pre-command) bash "$REPO_ROOT/.agent/scripts/hook-pre-command.sh" "$QWEN_COMMAND" ;;
  post-command) bash "$REPO_ROOT/.agent/scripts/hook-stop.sh" ;;
  session-start) bash "$REPO_ROOT/.agent/scripts/sync-task.sh" && cat "$REPO_ROOT/.agent/memory/current-task.md" 2>/dev/null ;;
esac
QWENEOF
      chmod +x .qwen/hooks.sh
      echo "    ✅ .qwen/hooks.sh created"
      ;;
    cursor)
      mkdir -p .cursor
      cat > .cursor/hooks.json << 'CURSOREOF'
{"pre-command":"bash .agent/scripts/hook-pre-command.sh \"$COMMAND\"","post-command":"bash .agent/scripts/hook-stop.sh","session-start":"bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md"}
CURSOREOF
      echo "    ✅ .cursor/hooks.json created"
      ;;
    cline|roocode)
      mkdir -p .cline
      cat > .cline/hooks.json << 'CLINEEOF'
{"pre-command":"bash .agent/scripts/hook-pre-command.sh \"$COMMAND\"","post-command":"bash .agent/scripts/hook-stop.sh","session-start":"bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md"}
CLINEEOF
      echo "    ✅ .cline/hooks.json created"
      ;;
    windsurf)
      mkdir -p .windsurf
      cat > .windsurf/hooks.json << 'WSEOF'
{"pre-command":"bash .agent/scripts/hook-pre-command.sh \"$COMMAND\"","post-command":"bash .agent/scripts/hook-stop.sh","session-start":"bash .agent/scripts/sync-task.sh && cat .agent/memory/current-task.md"}
WSEOF
      echo "    ✅ .windsurf/hooks.json created"
      ;;
    opencode)
      if [ -f "opencode.json" ] || [ -f "opencode.jsonc" ]; then
        echo "    ✅ opencode.json already configured (created by bootstrap)"
      elif [ -f ".agent/templates/clients/opencode-config.json" ]; then
        cp .agent/templates/clients/opencode-config.json opencode.json
        echo "    ✅ opencode.json created with AI Toolbox configuration"
      else
        echo "    ⚠️  opencode-config.json template not found"
      fi
      ;;
    gemini|aider)
      echo "    ℹ️  Basic Tier — hooks not supported (soft reminders only)"
      ;;
  esac
done

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
echo ""
echo "==================================="
echo "✅ Setup complete!"
echo "==================================="
echo ""

if [ -n "$PRIMARY_CLIENT" ]; then
  echo "  Primary client: $PRIMARY_CLIENT  ✅"
else
  echo "  Primary client: none detected  ⚠️"
fi
echo "  Router files:   8 created"
if [ -n "$STACK" ]; then
  echo "  Project stack:  $STACK  ✅"
fi

if command -v rtk &>/dev/null; then
  echo "  rtk:            ✅ installed"
else
  echo "  rtk:            ⚠️  not installed"
  NEXT_STEPS+=("Install rtk: cargo install rtk --version 0.35.0  (needs Rust: https://rustup.rs/)")
fi

BD_CMD=$(_find_bd)
if [ -n "$BD_CMD" ]; then
  echo "  Beads:          ✅ installed + initialized"
else
  echo "  Beads:          ⚠️  not installed"
  if ! printf '%s\n' "${NEXT_STEPS[@]}" | grep -q "beads"; then
    NEXT_STEPS+=("Install Beads: go install github.com/steveyegge/beads/cmd/bd@v0.63.3  (needs Go: https://go.dev/dl/)")
  fi
fi

# ---------------------------------------------------------------
# Next Steps (only shown if something requires manual action)
# ---------------------------------------------------------------
if [ ${#NEXT_STEPS[@]} -gt 0 ]; then
  echo ""
  echo "  *** ACTION REQUIRED — complete these steps manually: ***"
  n=1
  for step in "${NEXT_STEPS[@]}"; do
    echo "  $n. $step"
    n=$((n+1))
  done
  echo ""
  echo "  After completing the steps above, re-run setup.sh to verify."
else
  echo ""
  echo "  🚀 Next: Open your AI client in this directory and start working!"
fi
echo ""

