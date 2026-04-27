# ai-toolbox.ps1 - Unified entry point for AI Toolbox commands (Windows parity).
#
# Thin dispatcher: every subcommand routes to a script under .agent/scripts/.
# The interface mirrors the bash sibling exactly.
#
# Subcommands and forwarding map:
#   doctor    [-Json|-Explain]        -> .agent/scripts/doctor.ps1
#   sync      [-Json]                 -> .agent/scripts/sync-task.ps1
#   setup     [-Silent]               -> .agent/scripts/setup.ps1
#   bootstrap [-DryRun]               -> .agent/scripts/bootstrap.ps1
#   validate  [-Json]                 -> .agent/scripts/validate-toolbox-config.sh (via bash)
#   migrate   [-Target X] [-DryRun]   -> .agent/scripts/migrate.ps1
#   context   build|show              -> (Phase C - not yet implemented)
#   simulate  -Intent X               -> (Phase C - not yet implemented)
#   stats     [-Json]                 -> (Phase C - not yet implemented)
#
# Exit codes match the underlying script. Dispatcher itself:
#   2  = unknown subcommand
#   60 = missing implementation

[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'
$ShimDir = Split-Path -Parent $PSCommandPath
$ScriptsDir = Join-Path $ShimDir '.agent/scripts'
$ConfigFile = Join-Path $ShimDir '.ai-toolbox/config.json'

function Show-Help {
    $script = Get-Content -Path $PSCommandPath
    foreach ($line in $script) {
        if ($line -match '^# ' -or $line -match '^#$') {
            ($line -replace '^# ?','')
        } else {
            break
        }
    }
}

function Show-Version {
    if (Test-Path $ConfigFile) {
        try {
            $cfg = Get-Content $ConfigFile -Raw -Encoding utf8 | ConvertFrom-Json
            $v = if ($cfg.toolbox_version) { $cfg.toolbox_version } else { 'unknown' }
            Write-Output "ai-toolbox $v"
        } catch {
            Write-Output 'ai-toolbox (config unreadable)'
        }
    } else {
        Write-Output 'ai-toolbox (no config)'
    }
}

function Invoke-Implementation {
    param(
        [string]$Path,
        [string[]]$Forward = @()
    )
    if (-not (Test-Path $Path)) {
        Write-Host "ai-toolbox: missing implementation: $Path" -ForegroundColor Red
        exit 60
    }
    if ($Path -match '\.ps1$') {
        & pwsh -ExecutionPolicy Bypass -File $Path @Forward
    } elseif ($Path -match '\.sh$') {
        & bash $Path @Forward
    } else {
        Write-Error "ai-toolbox: cannot dispatch unknown extension: $Path"
        exit 60
    }
    exit $LASTEXITCODE
}

function Show-PhaseCStub {
    param([string]$Cmd)
    Write-Host @"
ai-toolbox: '$Cmd' is reserved for Phase C and not yet implemented.

The interface is stable; the implementation lands in a future milestone:
  - context  build|show     (heuristic file selector + bundle viewer)
  - simulate -Intent X      (dry-run pipeline showing what would be done)
  - stats    [-Json]        (audit-log analyzer)

Use -Help to see the commands available today.
"@ -ForegroundColor Yellow
    exit 60
}

# ---- Dispatch --------------------------------------------------------------
if (-not $Command) {
    Show-Help
    exit 0
}

switch ($Command.ToLowerInvariant()) {
    { @('-h', '--help', 'help') -contains $_ } { Show-Help; break }
    { @('-v', '--version', 'version') -contains $_ } { Show-Version; break }

    'doctor'    { Invoke-Implementation (Join-Path $ScriptsDir 'doctor.ps1')    $Args }
    'sync'      { Invoke-Implementation (Join-Path $ScriptsDir 'sync-task.ps1') $Args }
    'setup'     { Invoke-Implementation (Join-Path $ScriptsDir 'setup.ps1')     $Args }
    'bootstrap' { Invoke-Implementation (Join-Path $ScriptsDir 'bootstrap.ps1') $Args }
    'validate'  {
        # Validate has no .ps1 — call the .sh via bash for parity.
        Invoke-Implementation (Join-Path $ScriptsDir 'validate-toolbox-config.sh') $Args
    }
    'migrate'   { Invoke-Implementation (Join-Path $ScriptsDir 'migrate.ps1')   $Args }

    'context'   { Show-PhaseCStub 'context' }
    'simulate'  { Show-PhaseCStub 'simulate' }
    'stats'     { Show-PhaseCStub 'stats' }

    default {
        Write-Host "ai-toolbox: unknown subcommand: $Command" -ForegroundColor Red
        Write-Host "Run 'ai-toolbox.ps1 help' for available commands." -ForegroundColor Yellow
        exit 2
    }
}
