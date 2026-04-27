"""
Tests for .agent/scripts/render-plugins.py

Run: python3 -m pytest tests/test_render_plugins.py -v
  or: python3 -m unittest tests.test_render_plugins -v
"""
import json
import os
import subprocess
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / ".agent" / "scripts" / "render-plugins.py"
SCHEMA = REPO_ROOT / ".agent" / "schema" / "plugin-manifest.schema.json"


def _run(cwd: Path, *args: str) -> subprocess.CompletedProcess:
    """Invoke render-plugins.py in `cwd`. Return CompletedProcess."""
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        env=env,
    )


def _make_repo(tmp: Path, plugins: dict[str, dict]) -> None:
    """Create a minimal repo skeleton in `tmp` with the given plugins.

    `plugins` maps plugin name → manifest dict (without 'name' which is set
    automatically). Each plugin gets a stub rules.md.
    """
    (tmp / ".agent" / "scripts").mkdir(parents=True)
    # Symlink the script and schema into the temp repo so the script can find them.
    # On Windows fallback to copy (symlinks may need elevation).
    try:
        (tmp / ".agent" / "scripts" / "render-plugins.py").symlink_to(SCRIPT)
    except (OSError, NotImplementedError):
        import shutil
        shutil.copy(SCRIPT, tmp / ".agent" / "scripts" / "render-plugins.py")

    # AGENT.md with markers
    (tmp / "AGENT.md").write_text(
        "# Test\n\n"
        "<!-- AI_TOOLBOX_PLUGINS:START -->\n"
        "<!-- placeholder -->\n"
        "<!-- AI_TOOLBOX_PLUGINS:END -->\n",
        encoding="utf-8",
    )

    plugins_dir = tmp / ".agent" / "plugins"
    plugins_dir.mkdir()
    for name, manifest in plugins.items():
        pdir = plugins_dir / name
        pdir.mkdir()
        full = {"name": name, "version": "0.1.0", **manifest}
        (pdir / "manifest.json").write_text(json.dumps(full), encoding="utf-8")
        for rule in full.get("rules", ["rules.md"]):
            (pdir / rule).write_text(f"# {name}\n", encoding="utf-8")


class RenderPluginsTest(unittest.TestCase):
    def test_renders_block_for_two_plugins(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {
                "alpha": {"rules": ["rules.md"], "priority": 50},
                "beta":  {"rules": ["rules.md"], "priority": 200},
            })
            result = _run(tmp)
            self.assertEqual(result.returncode, 0, result.stderr)
            agent_md = (tmp / "AGENT.md").read_text(encoding="utf-8")
            self.assertIn("`alpha`", agent_md)
            self.assertIn("`beta`", agent_md)
            # Sort order: ascending priority → alpha (50) before beta (200).
            self.assertLess(agent_md.index("alpha"), agent_md.index("beta"))

    def test_idempotent_second_run(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {"only": {"rules": ["rules.md"]}})
            _run(tmp)  # first run mutates AGENT.md
            text_before = (tmp / "AGENT.md").read_text(encoding="utf-8")
            result = _run(tmp)  # second run is the no-op path
            self.assertEqual(result.returncode, 0)
            self.assertEqual(text_before, (tmp / "AGENT.md").read_text(encoding="utf-8"))
            self.assertIn("up to date", result.stdout)

    def test_check_mode_detects_drift(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {"only": {"rules": ["rules.md"]}})
            # AGENT.md still has placeholder; --check must detect drift
            result = _run(tmp, "--check")
            self.assertEqual(result.returncode, 1)
            self.assertIn("stale", result.stderr)

    def test_check_passes_after_render(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {"only": {"rules": ["rules.md"]}})
            _run(tmp)
            result = _run(tmp, "--check")
            self.assertEqual(result.returncode, 0)

    def test_dry_run_does_not_modify(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {"only": {"rules": ["rules.md"]}})
            text_before = (tmp / "AGENT.md").read_text(encoding="utf-8")
            result = _run(tmp, "--dry-run")
            self.assertEqual(result.returncode, 0)
            self.assertEqual(text_before, (tmp / "AGENT.md").read_text(encoding="utf-8"))
            self.assertIn("DRY-RUN", result.stdout)

    def test_conflict_resolution_fail(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {
                "alpha": {"rules": ["rules.md"], "conflict_resolution": "fail"},
                "beta":  {"rules": ["rules.md"]},
            })
            result = _run(tmp)
            self.assertEqual(result.returncode, 51, result.stderr)
            self.assertIn("PLUGIN_CONFLICT", result.stderr)

    def test_directory_name_must_match_manifest_name(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            (tmp / ".agent" / "scripts").mkdir(parents=True)
            try:
                (tmp / ".agent" / "scripts" / "render-plugins.py").symlink_to(SCRIPT)
            except (OSError, NotImplementedError):
                import shutil
                shutil.copy(SCRIPT, tmp / ".agent" / "scripts" / "render-plugins.py")
            (tmp / "AGENT.md").write_text(
                "<!-- AI_TOOLBOX_PLUGINS:START -->\n<!-- AI_TOOLBOX_PLUGINS:END -->\n",
                encoding="utf-8",
            )
            plugins_dir = tmp / ".agent" / "plugins" / "wrong-dir"
            plugins_dir.mkdir(parents=True)
            (plugins_dir / "manifest.json").write_text(
                json.dumps({"name": "different-name", "version": "0.1.0"}),
                encoding="utf-8",
            )
            result = _run(tmp)
            self.assertEqual(result.returncode, 50, result.stderr)
            self.assertIn("PLUGIN_ERROR", result.stderr)

    def test_no_plugins_emits_empty_note(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            _make_repo(tmp, {})
            result = _run(tmp)
            self.assertEqual(result.returncode, 0)
            agent_md = (tmp / "AGENT.md").read_text(encoding="utf-8")
            self.assertIn("No plugins installed", agent_md)


if __name__ == "__main__":
    unittest.main()
