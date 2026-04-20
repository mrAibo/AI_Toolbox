# generate-client-files.ps1 — Windows wrapper around the Python3 generator.
# Usage: powershell -ExecutionPolicy Bypass -File .agent/scripts/generate-client-files.ps1 -Mode check|sync
param(
    [ValidateSet("check","sync")]
    [string]$Mode = "check"
)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
python3 "$ScriptDir\generate_client_files.py" "--$Mode"
exit $LASTEXITCODE
