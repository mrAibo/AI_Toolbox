#!/bin/bash
# hook-pre-compact-qwen.sh - Qwen Code PreCompact hook for Unix/Linux/macOS
# Injects important architecture context before compaction.
# Reads from stdin (Qwen JSON protocol), outputs decision JSON.

INPUT=$(cat 2>/dev/null)
if [ -z "$INPUT" ]; then
    echo '{"decision":"allow","reason":"No input received"}'
    exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
export HOOK_REPO_ROOT="$REPO_ROOT"

python3 << 'PYEOF'
import json, os

repo_root = os.environ.get('HOOK_REPO_ROOT', '.')
adr_file = os.path.join(repo_root, '.agent', 'memory', 'architecture-decisions.md')
task_file = os.path.join(repo_root, '.agent', 'memory', 'current-task.md')

context_parts = []

# Current task summary
try:
    with open(task_file) as f:
        lines = [f.readline() for _ in range(5)]
        task_summary = ' '.join(l.strip() for l in lines if l.strip())
        if task_summary:
            context_parts.append(f"### Current Task: {task_summary}")
except Exception:
    pass

# Latest ADR
try:
    with open(adr_file) as f:
        content = f.read()
        adrs = [a for a in content.split('### ADR-') if a.strip()]
        if adrs:
            latest = adrs[-1][:500]  # Cap at 500 chars
            context_parts.append(f"### Latest Architecture Decision: ### ADR-{latest}")
except Exception:
    pass

context_parts.append("## Key Rules\n- Use rtk for heavy commands\n- Update .agent/memory/ files when state changes\n- Follow .agent/rules/*.md")

context = '\n\n'.join(context_parts)

print(json.dumps({
    'decision': 'allow',
    'reason': 'Architecture context injected',
    'hookSpecificOutput': {
        'hookEventName': 'PreCompact',
        'additionalContext': f'## AI Toolbox Architecture Context (survives compaction)\n\n{context}'
    }
}))
PYEOF
exit 0
