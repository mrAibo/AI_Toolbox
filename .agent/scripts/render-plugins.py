#!/usr/bin/env python3
"""
render-plugins.py — enumerate .agent/plugins/*/manifest.json and update the
AI_TOOLBOX_PLUGINS region of AGENT.md.

Idempotent: writes only if content between markers would change. Returns
exit 0 if AGENT.md is now correct, regardless of whether a write happened.

Usage:
    python3 .agent/scripts/render-plugins.py [--dry-run] [--check]

  --dry-run  Print the would-be content; do not write.
  --check    Exit 1 if AGENT.md would change. Does not write. For CI.

Exit codes:
    0  AGENT.md already up to date or successfully updated
    1  --check failed (AGENT.md is stale)
   50  PLUGIN_ERROR (manifest invalid)
   51  PLUGIN_CONFLICT
   60  IO_ERROR
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

START = "<!-- AI_TOOLBOX_PLUGINS:START -->"
END = "<!-- AI_TOOLBOX_PLUGINS:END -->"
EMPTY_NOTE = (
    "<!-- No plugins installed. Run `ai-toolbox bootstrap` to populate this block. -->"
)


def find_repo_root(start: Path) -> Path:
    p = start.resolve()
    while p != p.parent:
        if (p / ".git").exists() or (p / "AGENT.md").exists():
            return p
        p = p.parent
    return start.resolve()


def load_manifests(plugins_dir: Path) -> list[dict[str, Any]]:
    """Return manifests sorted by ascending priority (default 100), then name."""
    manifests: list[dict[str, Any]] = []
    if not plugins_dir.is_dir():
        return manifests
    for plugin_dir in sorted(plugins_dir.iterdir()):
        if not plugin_dir.is_dir():
            continue
        manifest_path = plugin_dir / "manifest.json"
        if not manifest_path.is_file():
            continue
        try:
            with manifest_path.open(encoding="utf-8") as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            print(
                f"render-plugins: PLUGIN_ERROR in {manifest_path}: {e}",
                file=sys.stderr,
            )
            sys.exit(50)
        if not isinstance(data, dict) or "name" not in data:
            print(
                f"render-plugins: PLUGIN_ERROR — {manifest_path} missing 'name'",
                file=sys.stderr,
            )
            sys.exit(50)
        if data["name"] != plugin_dir.name:
            print(
                f"render-plugins: PLUGIN_ERROR — {manifest_path} name "
                f"{data['name']!r} != directory {plugin_dir.name!r}",
                file=sys.stderr,
            )
            sys.exit(50)
        data["_dir"] = plugin_dir
        manifests.append(data)
    manifests.sort(key=lambda m: (int(m.get("priority", 100)), m["name"]))
    return manifests


def detect_conflicts(manifests: list[dict[str, Any]]) -> list[str]:
    """Detect rule-filename overlaps among 'fail'-mode plugins."""
    rule_owners: dict[str, list[dict[str, Any]]] = {}
    for m in manifests:
        for rule in m.get("rules", []):
            rule_owners.setdefault(rule, []).append(m)
    conflicts = []
    for rule, owners in rule_owners.items():
        if len(owners) <= 1:
            continue
        if any(m.get("conflict_resolution") == "fail" for m in owners):
            names = [m["name"] for m in owners]
            conflicts.append(
                f"plugins {sorted(names)} all reference {rule!r} "
                f"and at least one declares conflict_resolution=fail"
            )
    return conflicts


def render_block(manifests: list[dict[str, Any]]) -> str:
    """Build the markdown content that goes between the markers."""
    if not manifests:
        return EMPTY_NOTE

    lines = [
        "**Active plugins** (sorted by priority ascending — see "
        "[.agent/plugins/README.md](.agent/plugins/README.md)):",
        "",
    ]
    for m in manifests:
        plugin_dir = m["_dir"]
        name = m["name"]
        version = m.get("version", "0.0.0")
        priority = m.get("priority", 100)
        desc = m.get("description", "")
        rule_files = m.get("rules", [])

        header = f"- **`{name}`** v{version} (priority {priority})"
        if desc:
            header += f" — {desc}"
        lines.append(header)

        for rule in rule_files:
            rel = (plugin_dir / rule).relative_to(plugin_dir.parent.parent.parent)
            rel_str = str(rel).replace("\\", "/")
            lines.append(f"  - [{rel_str}]({rel_str})")

    return "\n".join(lines)


def update_agent_md(agent_md: Path, new_block: str, *, dry_run: bool, check: bool) -> bool:
    """Replace the content between START and END markers. Returns True if changed."""
    if not agent_md.is_file():
        print(f"render-plugins: IO_ERROR — {agent_md} not found", file=sys.stderr)
        sys.exit(60)

    text = agent_md.read_text(encoding="utf-8")
    if START not in text or END not in text:
        print(
            f"render-plugins: IO_ERROR — markers {START} / {END} not found in {agent_md}",
            file=sys.stderr,
        )
        sys.exit(60)

    pre, _, rest = text.partition(START)
    _, _, post = rest.partition(END)

    new_section = f"{START}\n{new_block}\n{END}"
    new_text = f"{pre}{new_section}{post}"

    changed = new_text != text
    if changed:
        if dry_run or check:
            return True
        agent_md.write_text(new_text, encoding="utf-8")
    return changed


def main(argv: list[str]) -> int:
    dry_run = "--dry-run" in argv
    check = "--check" in argv

    repo_root = find_repo_root(Path.cwd())
    plugins_dir = repo_root / ".agent" / "plugins"
    agent_md = repo_root / "AGENT.md"

    manifests = load_manifests(plugins_dir)

    conflicts = detect_conflicts(manifests)
    if conflicts:
        for c in conflicts:
            print(f"render-plugins: PLUGIN_CONFLICT — {c}", file=sys.stderr)
        return 51

    block = render_block(manifests)
    changed = update_agent_md(agent_md, block, dry_run=dry_run, check=check)

    plural = "" if len(manifests) == 1 else "s"
    if check:
        if changed:
            print(
                f"[render-plugins] AGENT.md is stale — re-run bootstrap "
                f"({len(manifests)} plugin{plural})",
                file=sys.stderr,
            )
            return 1
        print(f"[render-plugins] AGENT.md up to date ({len(manifests)} plugin{plural})")
        return 0

    if dry_run:
        verb = "would update" if changed else "no change needed"
        print(f"[render-plugins] DRY-RUN — {verb} ({len(manifests)} plugin{plural})")
        if changed:
            print("---")
            print(f"{START}\n{block}\n{END}")
        return 0

    if changed:
        print(f"[render-plugins] Updated AGENT.md ({len(manifests)} plugin{plural})")
    else:
        print(f"[render-plugins] AGENT.md already up to date ({len(manifests)} plugin{plural})")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
