"""
Regression test for the multi_client gating in bootstrap.sh (v1.5.5+).

multi_client=true (default) keeps the legacy behavior — generate router
files for every supported client. multi_client=false + primary_client=X
generates ONLY X's files, keeping the project root tidy.

Skipped on Windows-only Python where bash isn't installed.
"""
from __future__ import annotations

import json
import shutil
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

REPO = Path(__file__).resolve().parent.parent
HAS_BASH = shutil.which("bash") is not None

# Map: which top-level files belong to which client (client-id from
# .ai-toolbox/config.json clients{}). Drives the assertions below.
CLIENT_FILES = {
    "claude-code":  {"CLAUDE.md"},
    "qwen-code":    {"QWEN.md"},
    "gemini-cli":   {"GEMINI.md"},
    "antigravity":  {"SKILL.md"},
    "pi":           {"PI.md"},
    "cursor":       {".cursorrules"},
    "cline":        {".clinerules"},
    "windsurf":     {".windsurfrules"},
    "aider":        {"CONVENTIONS.md"},
}
ALL_CLIENT_FILES = set().union(*CLIENT_FILES.values())


def _make_sandbox(td: Path, *, multi_client: bool, primary: str | None) -> Path:
    """Copy .agent and .ai-toolbox into a fresh sandbox + adjust config.
    Also seed an empty AGENT.md with plugin markers so render-plugins
    (called at the end of bootstrap) doesn't crash in dry-run mode where
    `touch AGENT.md` is a no-op."""
    shutil.copytree(REPO / ".agent", td / ".agent")
    shutil.copytree(REPO / ".ai-toolbox", td / ".ai-toolbox")
    (td / "AGENT.md").write_text(
        "# Sandbox AGENT.md\n\n"
        "<!-- AI_TOOLBOX_PLUGINS:START -->\n"
        "<!-- AI_TOOLBOX_PLUGINS:END -->\n",
        encoding="utf-8",
    )
    cfg_path = td / ".ai-toolbox" / "config.json"
    cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
    cfg["multi_client"] = multi_client
    cfg["primary_client"] = primary
    cfg_path.write_text(json.dumps(cfg, indent=2) + "\n", encoding="utf-8")
    return td


def _dry_run_writes(sandbox: Path) -> set[str]:
    """Run bootstrap.sh --dry-run in the sandbox, return the set of files
    it WOULD write at the project root level."""
    result = subprocess.run(
        ["bash", ".agent/scripts/bootstrap.sh", "--dry-run"],
        cwd=sandbox,
        capture_output=True,
        text=True,
        timeout=60,
    )
    if result.returncode != 0:
        raise AssertionError(
            f"bootstrap exited {result.returncode}\n"
            f"STDOUT:\n{result.stdout}\nSTDERR:\n{result.stderr}"
        )
    writes: set[str] = set()
    for line in result.stdout.splitlines():
        # Match `[DRY-RUN] write FILE (N bytes)` from _dr_writeto …
        if line.startswith("[DRY-RUN] write "):
            tail = line[len("[DRY-RUN] write "):]
            writes.add(tail.split(" ", 1)[0])
        # … and `[DRY-RUN] cp SRC DEST` from the cp-template path.
        elif line.startswith("[DRY-RUN] cp "):
            parts = line[len("[DRY-RUN] cp "):].split()
            if len(parts) >= 2:
                writes.add(parts[-1])
    return writes


@unittest.skipUnless(HAS_BASH, "bash not available on this runner")
class BootstrapMultiClientTest(unittest.TestCase):

    def test_multi_client_true_generates_all_routers(self) -> None:
        """Default behavior: every client's router file appears in the
        write set."""
        with TemporaryDirectory() as td:
            sb = _make_sandbox(Path(td), multi_client=True, primary=None)
            writes = _dry_run_writes(sb)
            for f in ALL_CLIENT_FILES:
                self.assertIn(
                    f, writes,
                    f"multi_client=true should generate {f}; writes={sorted(writes)}",
                )

    def test_single_client_generates_only_primary(self) -> None:
        """multi_client=false + primary=cursor → only .cursorrules at root."""
        with TemporaryDirectory() as td:
            sb = _make_sandbox(Path(td), multi_client=False, primary="cursor")
            writes = _dry_run_writes(sb)
            self.assertIn(".cursorrules", writes)
            for f in ALL_CLIENT_FILES - CLIENT_FILES["cursor"]:
                self.assertNotIn(
                    f, writes,
                    f"single-client mode should NOT generate {f}; writes={sorted(writes)}",
                )

    def test_single_client_claude_only(self) -> None:
        with TemporaryDirectory() as td:
            sb = _make_sandbox(Path(td), multi_client=False, primary="claude-code")
            writes = _dry_run_writes(sb)
            self.assertIn("CLAUDE.md", writes)
            for f in ALL_CLIENT_FILES - CLIENT_FILES["claude-code"]:
                self.assertNotIn(f, writes,
                                 f"unexpected write {f}; writes={sorted(writes)}")

    def test_no_primary_falls_back_to_multi_client(self) -> None:
        """Defensive: multi_client=false + primary=null → still generate
        all (we don't know what to keep)."""
        with TemporaryDirectory() as td:
            sb = _make_sandbox(Path(td), multi_client=False, primary=None)
            writes = _dry_run_writes(sb)
            for f in ALL_CLIENT_FILES:
                self.assertIn(f, writes,
                              f"fallback mode should generate {f}")


if __name__ == "__main__":
    unittest.main()
