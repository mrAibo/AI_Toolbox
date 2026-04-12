#!/bin/bash
# AI Toolbox Setup Script — One-command setup with client selection
# Usage: bash .agent/scripts/setup.sh

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo ""
echo "🤖 AI Toolbox Setup"
echo "==================="
echo ""

# ---------------------------------------------------------------
# Step 1: Detect installed AI clients
# ---------------------------------------------------------------
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

# GUI-based clients (no CLI binary — detect via common install paths)
if command -v cursor &> /dev/null || [ -d "$HOME/.cursor" ] || [ -d "$HOME/.config/cursor" ] || [ -d "$LOCALAPPDATA/Programs/cursor" ] 2>/dev/null; then
  CLIENTS+=("cursor")
  CLIENT_NAMES+=("Cursor (GUI)")
  echo "  ✅ Cursor (GUI)"
fi

if command -v cline &> /dev/null || [ -d "$HOME/.cline" ] || [ -d "$HOME/.config/cline" ] || [ -d "$HOME/.roocode" ] 2>/dev/null; then
  CLIENTS+=("cline")
  CLIENT_NAMES+=("Cline / RooCode (VS Code extension)")
  echo "  ✅ Cline / RooCode (VS Code extension)"
fi

if command -v windsurf &> /dev/null || [ -d "$HOME/.windsurf" ] || [ -d "$HOME/.config/windsurf" ] 2>/dev/null; then
  CLIENTS+=("windsurf")
  CLIENT_NAMES+=("Windsurf (GUI)")
  echo "  ✅ Windsurf (GUI)"
fi

# If no clients found, show message
if [ ${#CLIENTS[@]} -eq 0 ]; then
  echo "  ⚠️  No supported AI clients detected."
  echo "  Supported: Claude Code, Qwen Code, Gemini CLI, Aider, Cursor, Cline, Windsurf"
  echo "  Install one first, then re-run this setup."
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
  else
    # Let user select
    echo "  Select PRIMARY client (used for hooks + MCP config):"
    for i in "${!CLIENTS[@]}"; do
      echo "  $((i+1)). ${CLIENT_NAMES[$i]}"
    done
    echo ""

    while true; do
      read -r -p "  > " selection
      if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#CLIENTS[@]}" ]; then
        PRIMARY_CLIENT="${CLIENTS[$((selection-1))]}"
        break
      fi
      echo "  Invalid selection. Enter a number between 1 and ${#CLIENTS[@]}."
    done
  fi
fi

echo ""
echo "✅ Primary client: $PRIMARY_CLIENT"
echo "   → All router files will be created for ALL clients"
echo "   → Hooks + MCP will be configured for $PRIMARY_CLIENT"

# ---------------------------------------------------------------
# Step 2: Run bootstrap
# ---------------------------------------------------------------
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
  read -r -p "  Install rtk (token optimization, 60-90% less tokens)? [Y/n] " install_rtk
  install_rtk=${install_rtk:-y}

  if [[ "$install_rtk" =~ ^[Yy]$ ]]; then
    if command -v cargo &> /dev/null; then
      echo "  ✅ Installing: cargo install rtk --version 0.35.0"
      cargo install rtk --version 0.35.0 --locked
      echo "  ✅ rtk installed"

      read -r -p "  Configure rtk hooks for $PRIMARY_CLIENT? [Y/n] " init_rtk
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
  read -r -p "  Configure rtk hooks for $PRIMARY_CLIENT? [Y/n] " init_rtk
  init_rtk=${init_rtk:-y}
  if [[ "$init_rtk" =~ ^[Yy]$ ]]; then
    echo "  ✅ Configuring hooks: rtk init -g"
    rtk init -g 2>/dev/null || true
  fi
fi

# ---------------------------------------------------------------
# Step 5: Offer to install Beads
# ---------------------------------------------------------------
if ! command -v bd &> /dev/null; then
  echo ""
  read -r -p "  Install Beads (task tracking)? [Y/n] " install_beads
  install_beads=${install_beads:-y}

  if [[ "$install_beads" =~ ^[Yy]$ ]]; then
    if command -v go &> /dev/null; then
      echo "  ✅ Installing: go install github.com/steveyegge/beads@v0.63.3"
      go install github.com/steveyegge/beads@v0.63.3
      echo "  ✅ Beads installed"

      echo "  ✅ Initializing: bd init"
      bd init
    else
      echo "  ⚠️  go not found. Install Go first: https://go.dev/dl/"
    fi
  fi
else
  echo "  ✅ Beads already installed ($(bd version 2>/dev/null || echo "installed"))"
fi

# ---------------------------------------------------------------
# Step 6: Offer to configure MCP
# ---------------------------------------------------------------
if [ -n "$PRIMARY_CLIENT" ]; then
  echo ""
  read -r -p "🌐 Configure MCP servers for $PRIMARY_CLIENT? [Y/n] " install_mcp
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
          read -r -p "  Copy config file to root for easy access? [Y/n] " copy_mcp
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
echo "  Primary client: ${PRIMARY_CLIENT:-none detected}"
echo "  Router files:   7 created"
if [ -n "$STACK" ]; then
  echo "  Project stack:  $STACK"
fi
if command -v rtk &> /dev/null; then
  echo "  rtk:            installed + hooks configured"
else
  echo "  rtk:            not installed (run 'cargo install rtk --version 0.35.0' later)"
fi
if command -v bd &> /dev/null; then
  echo "  Beads:          installed + initialized"
else
  echo "  Beads:          not installed (run 'go install .../beads@latest' later)"
fi

echo ""
echo "  🚀 Next: Open your AI client in this directory and start working!"
echo ""

