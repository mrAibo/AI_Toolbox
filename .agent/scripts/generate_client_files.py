#!/usr/bin/env python3
"""
generate-client-files.py
Read .ai-toolbox/config.json and sync template-backed client files.

Usage:
  python3 .agent/scripts/generate-client-files.py --check   # dry-run: show status
  python3 .agent/scripts/generate-client-files.py --sync    # install missing files

Exit codes: 0 = all OK (or all synced), 1 = missing files (--check), 2 = config error
"""
import json
import shutil
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent          # scripts/ -> .agent/ -> repo root
CONFIG_PATH = REPO_ROOT / ".ai-toolbox" / "config.json"

_VALID_TIERS = {"basic", "standard", "full"}


def validate_config(config: dict) -> list[str]:
    """Validate .ai-toolbox/config.json structure. Return list of error messages."""
    errors: list[str] = []

    for key in ("_meta", "clients", "tiers"):
        if key not in config:
            errors.append(f"Missing required top-level key: {key!r}")

    if "clients" not in config:
        return errors

    known_clients: set[str] = set(config["clients"])

    primary = config.get("primary_client")
    if primary is not None:
        if not isinstance(primary, str):
            errors.append("primary_client must be a string or null")
        elif primary not in known_clients:
            errors.append(
                f"primary_client {primary!r} is not a known client "
                f"(known: {sorted(known_clients)})"
            )

    for name, client in config["clients"].items():
        if "tier" not in client:
            errors.append(f"client {name!r} missing required key: 'tier'")
        elif client["tier"] not in _VALID_TIERS:
            errors.append(
                f"client {name!r} has invalid tier {client['tier']!r} "
                f"(must be one of: {sorted(_VALID_TIERS)})"
            )

    return errors


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        print(f"ERROR: config not found at {CONFIG_PATH.relative_to(REPO_ROOT)}", file=sys.stderr)
        sys.exit(2)
    with open(CONFIG_PATH, encoding="utf-8") as fh:
        return json.load(fh)


def _is_empty(path: Path) -> bool:
    return not path.exists() or path.stat().st_size == 0


def collect_mappings(config: dict) -> list[dict]:
    """Return all (source, target) file mappings that have a template source."""
    mappings = []
    for client_name, client in config.get("clients", {}).items():
        # router_file
        if client.get("router_file") and client.get("template_router"):
            mappings.append({
                "client": client_name,
                "type": "router",
                "source": client["template_router"],
                "target": client["router_file"],
            })
        # config_file
        if client.get("config_file") and client.get("template_config"):
            mappings.append({
                "client": client_name,
                "type": "config",
                "source": client["template_config"],
                "target": client["config_file"],
            })
        # extra_files with a source
        for ef in client.get("extra_files", []):
            if ef.get("source") and ef.get("target"):
                mappings.append({
                    "client": client_name,
                    "type": "extra",
                    "source": ef["source"],
                    "target": ef["target"],
                })
    return mappings


def check(mappings: list[dict]) -> bool:
    """Print status for each mapping. Return True if all are OK."""
    all_ok = True
    for m in mappings:
        src = REPO_ROOT / m["source"]
        tgt = REPO_ROOT / m["target"]
        src_ok = src.exists() and src.stat().st_size > 0

        if not src_ok:
            print(f"  [NO_TEMPLATE]  {m['client']}: {m['target']!s:<30}  (template missing: {m['source']})")
        elif not _is_empty(tgt):
            print(f"  [OK]           {m['client']}: {m['target']}")
        else:
            print(f"  [MISSING]      {m['client']}: {m['target']!s:<30}  (run --sync to install)")
            all_ok = False
    return all_ok


def sync(mappings: list[dict]) -> None:
    """Copy each template to its target when the target is missing/empty."""
    for m in mappings:
        src = REPO_ROOT / m["source"]
        tgt = REPO_ROOT / m["target"]
        if not (src.exists() and src.stat().st_size > 0):
            print(f"  [SKIP]    {m['client']}: template not found — {m['source']}")
            continue
        if not _is_empty(tgt):
            print(f"  [EXISTS]  {m['client']}: {m['target']} — already present, skipping")
            continue
        tgt.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, tgt)
        print(f"  [SYNCED]  {m['client']}: {m['source']} -> {m['target']}")


def main() -> None:
    args = set(sys.argv[1:])
    if not args or (args - {"--check", "--sync"}):
        print("Usage: generate-client-files.py --check | --sync")
        sys.exit(2)

    config = load_config()
    config_errors = validate_config(config)
    if config_errors:
        for e in config_errors:
            print(f"  CONFIG ERROR: {e}", file=sys.stderr)
        sys.exit(2)
    mappings = collect_mappings(config)

    if "--check" in args:
        print(f"Checking {len(mappings)} template-backed file(s) against {CONFIG_PATH.relative_to(REPO_ROOT)}:\n")
        ok = check(mappings)
        if not ok:
            sys.exit(1)
    else:
        print(f"Syncing {len(mappings)} template-backed file(s) from {CONFIG_PATH.relative_to(REPO_ROOT)}:\n")
        sync(mappings)


if __name__ == "__main__":
    main()
