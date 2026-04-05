# AI Toolbox Commit Verification (POWERSHELL)
# Runs lightweight checks on staged changes to preserve project quality.

$RepoRoot = git rev-parse --show-toplevel
$Errors = 0

# ---------------------------------------------------------------
# Check 1: Tier Badge on Router Files
# If a router file is staged, it must contain a "-- Tier:" badge.
# ---------------------------------------------------------------
$RouterFiles = @(
    "CLAUDE.md", "QWEN.md", "GEMINI.md", "CONVENTIONS.md", "SKILL.md",
    ".cursorrules", ".clinerules", ".windsurfrules"
)

$StagedFiles = git diff --cached --name-only 2>$null

foreach ($File in $RouterFiles) {
    # Only check if this file is in the staged changes
    if ($StagedFiles -contains $File) {
        $FullPath = Join-Path $RepoRoot $File
        if (Test-Path $FullPath) {
            $Content = Get-Content $FullPath -Raw
            if ($Content -notmatch "-- Tier:") {
                Write-Host "🚨 AI Toolbox Warning: $File is missing the '-- Tier: X' badge."
                Write-Host "   Every router file must declare its tier (Full, Standard, or Basic)."
                $Errors++
            }
        }
    }
}

# ---------------------------------------------------------------
# Check 2: ADR Format (existing check, relaxed)
# If architecture-decisions.md is non-empty, it should have ADR entries.
# ---------------------------------------------------------------
$ADRFile = Join-Path $RepoRoot ".agent/memory/architecture-decisions.md"

if ((Test-Path $ADRFile) -and ((Get-Item $ADRFile).Length -gt 0)) {
    $Content = Get-Content $ADRFile -Raw
    if ($Content -notmatch "^### ADR-") {
        Write-Host "⚠️  AI Toolbox Note: architecture-decisions.md exists but contains no ADR entries."
        Write-Host "   Use the '### ADR-XXXX' format to document architectural decisions."
        # Note: Warning only, not a block — does not increment $Errors
    }
}

# ---------------------------------------------------------------
# Check 3: Broken References in Modified .md Files
# Only check files that are staged for commit.
# ---------------------------------------------------------------
$StagedMD = $StagedFiles | Where-Object { $_ -match '\.md$' }

foreach ($File in $StagedMD) {
    $FullPath = Join-Path $RepoRoot $File
    if (Test-Path $FullPath) {
        $Content = Get-Content $FullPath -Raw
        # Find all markdown links [text](path)
        $Matches = [regex]::Matches($Content, '\[([^\]]+)\]\(([^)]+)\)')
        foreach ($Match in $Matches) {
            $Target = $Match.Groups[2].Value -split '#' | Select-Object -First 1
            # Skip external links and anchors
            if ($Target -match '^https?://|^mailto:|^/') { continue }
            # Resolve relative to the file's directory
            $Dir = Split-Path $FullPath -Parent
            $Resolved = Join-Path $Dir $Target
            # Normalize path
            $Resolved = [System.IO.Path]::GetFullPath($Resolved)
            if (-not (Test-Path $Resolved)) {
                Write-Host "⚠️  AI Toolbox Note: $File → broken link to '$Target'"
                # Note: Warning only, does not block commit
            }
        }
    }
}

# ---------------------------------------------------------------
# Result
# ---------------------------------------------------------------
if ($Errors -gt 0) {
    Write-Host ""
    Write-Host "❌ AI Toolbox: $Errors error(s) found. Commit blocked."
    exit 1
}

exit 0
