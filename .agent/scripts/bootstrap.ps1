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
  ".agent/rules/stack-rules.md",
  ".agent/rules/testing-rules.md",
  ".agent/rules/safety-rules.md"
)

foreach ($file in $files) {
  if (-not (Test-Path $file)) {
    New-Item -ItemType File -Path $file | Out-Null
  }
}

Write-Host "[bootstrap] structure ready"
