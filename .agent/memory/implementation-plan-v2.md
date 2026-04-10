# AI Toolbox 2.0: Implementierungsplan

**Datum:** 2026-04-09
**Strategie:** Option A + B parallel — aktuelle Struktur beibehalten UND npm-Paket erstellen

---

## Vision

**AI Toolbox 2.0** = Best of Both Worlds:
- **Framework Repo** (aktuell): Vollständige Quellcodesammlung für Entwickler, die alles verstehen und anpassen wollen
- **npm Package** (`ai-toolbox-init`): Ein-Zeichen-Installation für schnelle Projekt-Initialisierung

```bash
# Heute:
git clone https://github.com/mrAibo/AI_Toolbox.git my-project
cd my-project
bash .agent/scripts/bootstrap.sh

# Zukünftig:
npx ai-toolbox-init my-project
# oder
npm create ai-toolbox my-project
```

---

## Phase 1: npm Package `ai-toolbox-init` (~300 Zeilen)

### 1.1 Paket-Struktur

```
packages/ai-toolbox-init/
├── package.json          # npm-Paket-Metadaten
├── bin/
│   └── init.js           # CLI-Entry-Point (#!/usr/bin/env node)
├── src/
│   ├── detector.js       # Erkennt installierte AI Clients
│   ├── bootstrapper.js   # Führt Bootstrap-Logik aus
│   ├── config-generator.js # Generiert Client-spezifische Configs
│   └── validator.js      # Validiert Installation
├── templates/            # Symlinks auf .agent/templates/
│   ├── clients/
│   ├── mcp/
│   └── ...
└── README.md
```

### 1.2 `package.json`

```json
{
  "name": "ai-toolbox-init",
  "version": "1.0.0",
  "description": "Initialize AI Toolbox in any project — one command, all AI clients",
  "bin": {
    "ai-toolbox-init": "bin/init.js",
    "ai-toolbox": "bin/init.js"
  },
  "scripts": {
    "test": "node --test src/**/*.test.js",
    "lint": "eslint src/",
    "prepublishOnly": "npm test"
  },
  "keywords": ["ai", "toolbox", "codex", "opencode", "qwen", "claude", "agent"],
  "license": "MIT",
  "engines": { "node": ">=18" }
}
```

### 1.3 CLI-Interface

```bash
# Interaktiv mit Client-Auswahl
npx ai-toolbox-init

# Direkt mit Optionen
npx ai-toolbox-init --client qwen --rtk --beads --mcp developer

# In bestehendem Projekt
cd my-project && npx ai-toolbox-init --no-prompt

# Neues Projekt mit AI Toolbox
npm create ai-toolbox my-project -- --client codex
```

### 1.4 `bin/init.js` (Auszug)

```javascript
#!/usr/bin/env node
const { detectClients } = require('../src/detector');
const { runBootstrap } = require('../src/bootstrapper');
const { generateConfigs } = require('../src/config-generator');

async function main() {
  const projectDir = process.argv[2] || process.cwd();
  const clients = await detectClients(projectDir);
  
  console.log(`🤖 Detected AI clients: ${clients.join(', ') || 'none'}`);
  
  const selectedClients = await promptClients(clients);
  const installRtk = await promptInstall('rtk', 'Token optimization (60-90% savings)');
  const installBeads = await promptInstall('beads', 'Task tracking across sessions');
  const mcpProfile = await promptMcpProfile();
  
  await runBootstrap(projectDir, selectedClients);
  await generateConfigs(projectDir, selectedClients, { rtk: installRtk, beads: installBeads, mcp: mcpProfile });
  
  console.log('✅ AI Toolbox initialized successfully!');
  console.log(`📚 Docs: https://github.com/mrAibo/AI_Toolbox`);
}

main().catch(console.error);
```

### 1.5 `src/detector.js`

```javascript
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const CLIENTS = {
  'qwen':     { cmd: 'qwen --version', file: '.qwen/settings.json' },
  'codex':    { cmd: 'codex --version', file: '.codex/config.toml' },
  'opencode': { cmd: 'opencode --version', file: 'opencode.json' },
  'claude':   { cmd: 'claude --version', file: '.claude/settings.json' },
  'cursor':   { cmd: null, file: '.cursorrules' },
  'aider':    { cmd: 'aider --version', file: '.aider.conf.yml' },
};

async function detectClients(projectDir) {
  const found = [];
  for (const [name, config] of Object.entries(CLIENTS)) {
    if (config.cmd) {
      try {
        execSync(config.cmd, { stdio: 'ignore' });
        found.push(name);
      } catch { /* not installed */ }
    }
    if (fs.existsSync(path.join(projectDir, config.file))) {
      if (!found.includes(name)) found.push(name);
    }
  }
  return found;
}

module.exports = { detectClients, CLIENTS };
```

### 1.6 `src/bootstrapper.js`

```javascript
const { execSync } = require('child_process');
const path = require('path');

async function runBootstrap(projectDir, clients) {
  const bootstrapSh = path.join(projectDir, '.agent/scripts/bootstrap.sh');
  const bootstrapPs1 = path.join(projectDir, '.agent/scripts/bootstrap.ps1');
  
  // Prefer platform-native bootstrap
  const isWindows = process.platform === 'win32';
  const bootstrap = isWindows ? bootstrapPs1 : bootstrapSh;
  
  try {
    if (isWindows) {
      execSync(`powershell -ExecutionPolicy Bypass -File "${bootstrap}"`, { 
        cwd: projectDir, stdio: 'inherit' 
      });
    } else {
      execSync(`bash "${bootstrap}"`, { 
        cwd: projectDir, stdio: 'inherit' 
      });
    }
  } catch (err) {
    console.error('❌ Bootstrap failed:', err.message);
    process.exit(1);
  }
}

module.exports = { runBootstrap };
```

### 1.7 `src/config-generator.js`

```javascript
const fs = require('fs');
const path = require('path');

const MCP_PROFILES = {
  minimal: ['context7', 'sequential-thinking'],
  developer: ['context7', 'sequential-thinking', 'filesystem', 'fetch'],
  full: ['context7', 'sequential-thinking', 'filesystem', 'fetch', 'github', 'memory'],
};

async function generateConfigs(projectDir, clients, options) {
  const templatesDir = path.join(projectDir, '.agent/templates/clients');
  
  for (const client of clients) {
    const configFile = `${client}-config.json`;
    const templatePath = path.join(templatesDir, configFile);
    
    if (fs.existsSync(templatePath)) {
      const destPath = getDestPath(client, projectDir);
      if (!fs.existsSync(destPath)) {
        fs.copyFileSync(templatePath, destPath);
        console.log(`  ✅ Created ${path.relative(projectDir, destPath)}`);
      }
    }
  }
  
  // Install rtk if requested
  if (options.rtk) {
    console.log('  📦 Installing rtk...');
    try {
      execSync('cargo install --git https://github.com/rtk-ai/rtk --version 0.35.0', { stdio: 'inherit' });
      execSync('rtk init -g', { stdio: 'inherit' });
    } catch { console.error('  ⚠️ rtk installation failed — install Rust first'); }
  }
  
  // Install Beads if requested
  if (options.beads) {
    console.log('  📦 Installing Beads...');
    try {
      execSync('go install github.com/steveyegge/beads/cmd/bd@v0.63.3', { stdio: 'inherit' });
    } catch { console.error('  ⚠️ Beads installation failed — install Go first'); }
  }
}

function getDestPath(client, projectDir) {
  const mapping = {
    'qwen':     '.qwen/settings.json',
    'codex':    '.codex/config.toml',
    'opencode': 'opencode.json',
    'claude':   '.claude/settings.json',
  };
  return path.join(projectDir, mapping[client] || `${client}-config.json`);
}

module.exports = { generateConfigs, MCP_PROFILES };
```

---

## Phase 2: CI/CD + Release-Pipeline (~200 Zeilen)

### 2.1 Semantic Versioning

```bash
# Release-Prozess
git tag v1.0.0
git push origin v1.0.0
# GitHub Actions erstellt automatisch:
#   1. npm publish (ai-toolbox-init)
#   2. GitHub Release mit Changelog
#   3. Git Tag
```

### 2.2 GitHub Actions: `release.yml`

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          registry-url: 'https://registry.npmjs.org'
      
      - name: Build package
        working-directory: packages/ai-toolbox-init
        run: npm ci && npm test
      
      - name: Publish to npm
        working-directory: packages/ai-toolbox-init
        run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

### 2.3 Changelog-Automatisierung

Conventional Commits + automatischer Changelog:
```bash
# Commit-Format
feat: add OpenCode CLI integration
fix: resolve critical code injection
docs: update setup instructions

# Changelog wird automatisch generiert aus Commit-Messages
```

---

## Phase 3: Qualitätssicherung (~250 Zeilen)

### 3.1 Funktionale Hook-Tests

```javascript
// packages/ai-toolbox-init/src/__tests__/hooks.test.js
import { test } from 'node:test';
import assert from 'node:assert';
import { execSync } from 'child_process';

test('hook-pre-command-qwen.sh produces valid JSON on empty input', () => {
  const output = execSync('echo "" | bash .agent/scripts/hook-pre-command-qwen.sh');
  const result = JSON.parse(output.toString());
  assert.strictEqual(result.decision, 'allow');
});

test('hook-pre-command-qwen.sh blocks heavy commands without rtk', () => {
  const input = JSON.stringify({
    tool_name: 'bash',
    tool_input: { command: 'npm run build' }
  });
  const output = execSync(`echo '${input}' | bash .agent/scripts/hook-pre-command-qwen.sh`);
  const result = JSON.parse(output.toString());
  assert.strictEqual(result.decision, 'ask');
});

test('hook-post-tool-qwen.sh detects secrets in test file', () => {
  // Create test file with fake secret
  execSync('echo "password = \\"test12345678\\"" > /tmp/test-secret.txt');
  const input = JSON.stringify({
    tool_name: 'write_file',
    tool_input: { file_path: '/tmp/test-secret.txt' }
  });
  const output = execSync(`echo '${input}' | bash .agent/scripts/hook-post-tool-qwen.sh`);
  const result = JSON.parse(output.toString());
  assert.ok(result.hookSpecificOutput.additionalContext.includes('secret'));
  execSync('rm /tmp/test-secret.txt');
});
```

### 3.2 Integrationstest

```bash
#!/bin/bash
# tests/integration/quick-init.sh
set -e

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Initialize AI Toolbox
npx ai-toolbox-init --no-prompt --client qwen --rtk --beads

# Verify structure
test -d ".agent" || exit 1
test -f "AGENT.md" || exit 1
test -f ".qwen/settings.json" || exit 1

# Verify hooks are configured
grep -q "pre-command" .qwen/settings.json || exit 1

echo "✅ Quick init test passed"
rm -rf "$TEMP_DIR"
```

### 3.3 CI-Erweiterung

```yaml
# .github/workflows/ci.yml — neue Steps
      - name: Install PowerShell
        run: sudo apt install powershell -y
      
      - name: Run integration tests
        run: bash tests/integration/quick-init.sh
      
      - name: Hook JSON validation
        run: |
          for script in .agent/scripts/hook-*-qwen.sh; do
            echo '{}' | bash "$script" | jq . > /dev/null || exit 1
          done
```

---

## Phase 4: Plugin-System (Zukunft, optional)

### 4.1 OpenCode Plugin

```json
// opencode.json
{
  "plugins": ["@ai-toolbox/opencode@1.0.0"]
}
```

### 4.2 Codex CLI Plugin

```toml
# .codex/config.toml
[plugins]
packages = ["@ai-toolbox/codex@1.0.0"]
```

---

## Aufwandsschätzung

| Phase | Dateien | Zeilen | Aufwand |
|---|---|---|---|
| **Phase 1: npm Package** | 6 | ~300 | 2-3 Stunden |
| **Phase 2: CI/CD + Release** | 3 | ~200 | 1-2 Stunden |
| **Phase 3: Qualitätssicherung** | 5 | ~250 | 2-3 Stunden |
| **Phase 4: Plugin-System** | 4 | ~400 | 4-6 Stunden |
| **Total** | **18** | **~1,150** | **9-14 Stunden** |

---

## Timeline-Empfehlung

| Woche | Phase | Deliverables |
|---|---|---|
| **1** | Phase 1 + 2 | `ai-toolbox-init` npm-Paket, Release-Pipeline |
| **2** | Phase 3 | Funktionale Tests, Integrationstests, CI-Erweiterung |
| **3** | Phase 4 | OpenCode Plugin, Codex Plugin |

---

## Risiken & Gegenmaßnahmen

| Risiko | Auswirkung | Gegenmaßnahme |
|---|---|---|
| npm-Paket wird nicht aktualisiert | Users installieren veraltete Version | Automatische Release-Pipeline via Git Tags |
| Bootstrap-Skripte ändern sich | npm-Paket kopiert alte Templates | npm-Paket referenziert Templates dynamisch aus Framework Repo |
| Clients ändern ihre Config-Formate | Generierte Configs funktionieren nicht | Regelmäßige Validierung in CI |
| Node.js < 18 auf alten Systemen | npm-Paket funktioniert nicht | `engines` field + Fallback auf git clone |

---

## Nächste Schritte

1. **Entscheidung:** Plan genehmigt? Scope anpassen?
2. **Phase 1 starten:** npm-Paket-Struktur erstellen
3. **Testing:** Erste funktionale Tests für Hooks schreiben
4. **Release:** Erstes `ai-toolbox-init@1.0.0` veröffentlichen
