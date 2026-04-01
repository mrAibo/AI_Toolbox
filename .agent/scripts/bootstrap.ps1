$ErrorActionPreference = "Stop"

Write-Host "[bootstrap] preparing AI Toolbox structure..."

$dirs = @(
  ".agent/rules",
  ".agent/memory",
  ".agent/templates",
  ".agent/scripts",
  "docs",
  "examples",
  "prompts"
)

foreach ($dir in $dirs) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$files = @(
  "README.md",
  "AGENT.md",
  ".agent/memory/architecture-decisions.md",
  ".agent/memory/integration-contracts.md",
  ".agent/memory/session-handover.md",
  ".agent/memory/runbook.md",
  ".agent/memory/current-task.md",
  ".agent/rules/stack-rules.md",
  ".agent/rules/testing-rules.md",
  ".agent/rules/safety-rules.md"
)

foreach ($file in $files) {
  if (-not (Test-Path $file)) {
    New-Item -ItemType File -Path $file | Out-Null
  }
}

Write-Host "[bootstrap] creating AI auto-discovery router files..."
$RouterContent = @"
# AI Toolbox Workflow

Please refer strictly to [AGENT.md](AGENT.md) for the universal project guidelines, rules, and memory contracts. 
Do not begin any work or code without reading and following the Boot Sequence in AGENT.md!
"@

$AgentFiles = @("CLAUDE.md", "GEMINI.md", ".clinerules", ".cursorrules", ".windsurfrules")
foreach ($AgentFile in $AgentFiles) {
    Set-Content -Path $AgentFile -Value $RouterContent
}

if ((Test-Path ".git") -and -not (Test-Path ".git/hooks/pre-commit")) {
    Write-Host "[bootstrap] Installing Git pre-commit safeguards..."
    $HookContent = @"
#!/bin/bash
# AI Toolbox Pre-commit hook

HANDOVER_FILE=".agent/memory/session-handover.md"

if [ -f "`$HANDOVER_FILE" ]; then
    if [ ! -s "`$HANDOVER_FILE" ]; then
        echo "🚨 AI Toolbox Block: session-handover.md is empty!"
        echo "Please update handover notes before committing your work to preserve context."
        exit 1
    fi
fi
exit 0
"@
    Set-Content -Path ".git/hooks/pre-commit" -Value $HookContent -Encoding utf8
}

Write-Host "[bootstrap] structure ready"
