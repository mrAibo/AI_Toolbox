# migrate.ps1 - Advance .ai-toolbox/config.json toolbox_version (Windows parity)
# See migrate.sh for full protocol.

[CmdletBinding()]
param(
    [string]$Target,
    [switch]$DryRun,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'

$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

$DefaultTarget = '1.5'
if (-not $Target) {
    $Target = if ($env:TOOLBOX_VERSION) { $env:TOOLBOX_VERSION } else { $DefaultTarget }
}

$ConfigFile = Join-Path $RepoRoot '.ai-toolbox/config.json'
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[migrate] FAIL - $ConfigFile not found" -ForegroundColor Red
    exit 60
}

# Read current version.
$Current = '1.4'
try {
    $cfg = Get-Content $ConfigFile -Raw -Encoding utf8 | ConvertFrom-Json
    if ($cfg.toolbox_version) { $Current = [string]$cfg.toolbox_version }
} catch {
    Write-Host "[migrate] FAIL - could not parse $ConfigFile" -ForegroundColor Red
    exit 10
}

Write-Host "[migrate] current=$Current  target=$Target"

if ($Current -eq $Target) {
    Write-Host "[migrate] config already at $Target - no migration needed"
    exit 0
}

# Refuse downgrade (lexicographic comparison is good enough for x.y schemes).
$versionsSorted = @($Current, $Target) | Sort-Object {[version]($_ + '.0')}
if ($versionsSorted[0] -ne $Current) {
    Write-Host "[migrate] FAIL - target $Target is lower than current $Current" -ForegroundColor Red
    exit 41
}

$MigrationsDir = Join-Path $RepoRoot '.agent/migrations'
if (-not (Test-Path $MigrationsDir)) {
    Write-Host "[migrate] FAIL - $MigrationsDir not found" -ForegroundColor Red
    exit 40
}

$Hop = $Current
$Applied = 0
while ($Hop -ne $Target) {
    $candidates = Get-ChildItem $MigrationsDir -Filter "$Hop-to-*.ps1" | Sort-Object Name
    if (-not $candidates) {
        # Fall back to .sh and run via bash if available (Linux/macOS containers).
        $candidates = Get-ChildItem $MigrationsDir -Filter "$Hop-to-*.sh" | Sort-Object Name
    }
    if (-not $candidates) {
        Write-Host "[migrate] FAIL - no migration script for $Hop -> $Target" -ForegroundColor Red
        exit 40
    }
    $Mig = $candidates[0]
    $Next = $Mig.BaseName -replace "^$Hop-to-",''

    Write-Host "[migrate] applying $Hop -> $Next"
    if ($DryRun) {
        Write-Host "[migrate]   DRY-RUN - would run: $($Mig.FullName)"
    } else {
        if ($Mig.Extension -eq '.ps1') {
            & pwsh -ExecutionPolicy Bypass -File $Mig.FullName -RepoRoot $RepoRoot
        } else {
            & bash $Mig.FullName $RepoRoot
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[migrate] FAIL - migration $Hop -> $Next exited $LASTEXITCODE" -ForegroundColor Red
            exit 40
        }
        $Applied++
    }

    $Hop = $Next
    if ($Applied -gt 50) {
        Write-Host '[migrate] FAIL - too many migration steps; aborting' -ForegroundColor Red
        exit 90
    }
}

if ($DryRun) {
    Write-Host '[migrate] DRY-RUN complete - no changes written'
} else {
    Write-Host "[migrate] OK - applied $Applied migration(s); now at $Target"
}
exit 0
