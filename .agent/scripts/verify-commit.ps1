# AI Toolbox Commit Verification (POWERSHELL)
# Runs lightweight checks on staged changes to preserve project quality.

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
$RepoRootResolved = [System.IO.Path]::GetFullPath($RepoRoot)
$Errors = 0

# ---------------------------------------------------------------
# Check 1: Tier Badge on Router Files
# If a router file is staged, it must contain a "-- Tier:" badge.
# ---------------------------------------------------------------
$RouterFiles = @(
    "CLAUDE.md", "QWEN.md", "GEMINI.md", "CONVENTIONS.md",
    ".cursorrules", ".clinerules", ".windsurfrules",
    "CODERULES.md", "OPENCODERULES.md"
)

$StagedFiles = git diff --cached --name-only 2>$null

foreach ($File in $RouterFiles) {
    # Only check if this file is in the staged changes
    if ($StagedFiles -contains $File) {
        $FullPath = Join-Path $RepoRoot $File
    $PathResolved = [System.IO.Path]::GetFullPath($FullPath)
    if (-not $PathResolved.StartsWith($RepoRootResolved)) { continue }
        if (Test-Path $FullPath) {
            $Content = Get-Content $FullPath -Raw
            if ($Content -notmatch "-- Tier:") {
                Write-Host "[WARN] AI Toolbox: $File is missing the '-- Tier: X' badge."
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
$ADRFileResolved = [System.IO.Path]::GetFullPath($ADRFile)

if ((Test-Path $ADRFileResolved) -and ((Get-Item $ADRFileResolved).Length -gt 0)) {
    $Content = Get-Content $ADRFileResolved -Raw
    if ($Content -notmatch "(?m)^### ADR-") {
        Write-Host "[WARN] AI Toolbox Note: architecture-decisions.md exists but contains no ADR entries."
        Write-Host "   Use the '### ADR-XXXX' format to document architectural decisions."
        # Note: Warning only, not a block — does not increment $Errors
    }
}

# ---------------------------------------------------------------
# Check 3: Secret Patterns in Staged Diffs (not entire files)
# Scans only newly added lines in staged text files for secrets.
# Blocks the commit if secrets are detected.
# Bypass: $env:SKIP_SECRET_SCAN = 'true'
# ---------------------------------------------------------------
$SkipSecretScan = ($env:SKIP_SECRET_SCAN -eq 'true')

if ($SkipSecretScan) {
    Write-Host "[INFO] AI Toolbox: Secret scanning skipped via SKIP_SECRET_SCAN."
} else {
    $SecretFiles = [System.Collections.Generic.List[string]]::new()
    $HardBlockedFiles = [System.Collections.Generic.List[string]]::new()

    foreach ($File in $StagedFiles) {
        $Basename = [System.IO.Path]::GetFileName($File)
        $FullPath = Join-Path $RepoRoot $File
        $PathResolved = [System.IO.Path]::GetFullPath($FullPath)
        if (-not $PathResolved.StartsWith($RepoRootResolved)) { continue }

        # Hard block: sensitive file types regardless of content
        if ($Basename -match '^\.env$|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$') {
            $HardBlockedFiles.Add($File) | Out-Null
            continue
        }

        # Skip deleted files
        if (-not (Test-Path $FullPath)) { continue }

        # Scan only newly added lines (lines starting with + in the diff)
        $DiffLines = git diff --cached $File 2>$null
        if (-not $DiffLines) { continue }
        $Additions = $DiffLines | Where-Object { $_ -match '^\+' -and $_ -notmatch '^\+\+\+' }
        if (-not $Additions) { continue }

        # Filter out common false positives (empty values, placeholders)
        $RealAdditions = $Additions | Where-Object {
            $_ -notmatch '[=:]\s*(""|null|undefined|PLACEHOLDER|YOUR_.*_HERE|change.?me|todo)'
        }
        if (-not $RealAdditions) { continue }

        $RealText = $RealAdditions -join "`n"

        if ($RealText -match '(?i)(password|passwd|pwd|api[_-]?key|secret|token|auth[_-]?key|connection[_-]?string|database[_-]?url)\s*[=:]\s*["\x27]?\S{8,}') {
            $SecretFiles.Add($File) | Out-Null
        } elseif ($RealText -match 'BEGIN\s+(RSA|DSA|EC|OPENSSH)\s+PRIVATE\s+KEY') {
            $SecretFiles.Add($File) | Out-Null
        }
    }

    if ($HardBlockedFiles.Count -gt 0) {
        Write-Host "[FAIL] AI Toolbox: Sensitive file types must never be committed: $($HardBlockedFiles -join ', ')"
        Write-Host "       Remove these files and use .env.example or placeholder files instead."
        $Errors++
    }

    if ($SecretFiles.Count -gt 0) {
        Write-Host "[FAIL] AI Toolbox: Potential secrets detected in: $($SecretFiles -join ', ')"
        Write-Host "       This commit is blocked to prevent accidental secret exposure."
        Write-Host "       Verify these are not accidental credentials."
        Write-Host "       If they are intentional test fixtures, bypass with:"
        Write-Host "         `$env:SKIP_SECRET_SCAN = 'true'; git commit -m 'your message'"
        $Errors++
    }
}

# ---------------------------------------------------------------
# Check 4: Broken References in Modified .md Files
# Only check files that are staged for commit.
# ---------------------------------------------------------------
$StagedMD = $StagedFiles | Where-Object { $_ -match '\.md$' }

foreach ($File in $StagedMD) {
    $FullPath = Join-Path $RepoRoot $File
    $PathResolved = [System.IO.Path]::GetFullPath($FullPath)
    if (-not $PathResolved.StartsWith($RepoRootResolved)) { continue }
    if (Test-Path $FullPath) {
        $Content = Get-Content $FullPath -Raw
        # Find all markdown links [text](path)
        $LinkMatches = [regex]::Matches($Content, '\[([^\]]+)\]\(([^)]+)\)')
        foreach ($Match in $LinkMatches) {
            $Target = $Match.Groups[2].Value -split '#' | Select-Object -First 1
            # Skip external links, anchors, and root-relative paths
            if ($Target -match '^https?://|^mailto:|^#|^/') { continue }
            # Resolve relative to the file's directory
            $Dir = Split-Path $FullPath -Parent
            $Resolved = Join-Path $Dir $Target
            # Normalize path
            $Resolved = [System.IO.Path]::GetFullPath($Resolved)
            if (-not (Test-Path $Resolved)) {
                Write-Host "[WARN]  AI Toolbox Note: $File ? broken link to '$Target'"
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
    Write-Host "[FAIL] AI Toolbox: $Errors error(s) found. Commit blocked."
    exit 1
}

exit 0

