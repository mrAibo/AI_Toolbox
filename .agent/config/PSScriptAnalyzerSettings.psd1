# PSScriptAnalyzer settings — AI_Toolbox
# Loaded by the CI step: Invoke-ScriptAnalyzer -Settings <this file>
# To run locally:
#   pwsh -Command "Invoke-ScriptAnalyzer -Path .agent/scripts -Settings .agent/config/PSScriptAnalyzerSettings.psd1 -Recurse"

@{
    IncludeDefaultRules = $true

    Severity = @('Error', 'Warning')

    ExcludeRules = @(
        # Hook scripts write to stdout using Write-Host so that Claude Code can
        # read their output via the hook protocol. This is intentional.
        'PSAvoidUsingWriteHost',

        # These are standalone scripts, not exported cmdlets. ShouldProcess /
        # WhatIf support is not applicable.
        'PSUseShouldProcessForStateChangingFunctions',

        # Hook parameters follow the Claude Code call convention. Some
        # parameters may be unused when the script only handles a subset of
        # hook events.
        'PSReviewUnusedParameter',

        # Hook scripts intentionally use empty catch blocks to swallow all
        # exceptions. Hooks must never throw — a failure would abort the AI
        # session. Adding Write-Error inside catch would change the stdout
        # protocol that Claude Code reads.
        'PSAvoidUsingEmptyCatchBlock',

        # PSScriptAnalyzer does not track variable assignments made inside
        # ForEach-Object / Where-Object script blocks, producing false positives
        # (e.g. $hasStats assigned inside ForEach-Object and read outside).
        # Hook scripts also intentionally compute named intermediates for
        # readability even when the value flows to a single consumer.
        'PSUseDeclaredVarsMoreThanAssignments'
    )
}
