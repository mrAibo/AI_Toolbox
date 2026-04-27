"""
Regression tests for client config templates.

Each template under .agent/templates/clients/ is parsed and shape-checked
to prevent silent breakage like the v1.5.2 Codex bug where `[model]` was
accidentally a sub-table instead of a top-level string.

Run: python3 -m pytest tests/test_client_templates.py -v
"""
from __future__ import annotations

import json
import tomllib
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TEMPLATES = REPO_ROOT / ".agent" / "templates" / "clients"


class CodexConfigTemplateTest(unittest.TestCase):
    """Codex CLI reads <repo>/.codex/config.toml. Top-level keys must be
    strings; the `model` field in particular must NOT be a sub-table."""

    @classmethod
    def setUpClass(cls) -> None:
        path = TEMPLATES / ".codex-config.toml"
        with path.open("rb") as f:
            cls.data = tomllib.load(f)
        cls.path = path

    def test_no_model_subtable(self) -> None:
        """Regression: a `[model]` table broke Codex with
        'invalid type: map, expected a string in `model`'."""
        self.assertFalse(
            isinstance(self.data.get("model"), dict),
            f"{self.path} has a [model] sub-table; Codex expects "
            f"`model` to be a top-level string or absent.",
        )

    def test_top_level_strings(self) -> None:
        """approval_policy and sandbox_mode are top-level strings, not
        sections — they must appear before any [section] header."""
        for key in ("approval_policy", "sandbox_mode"):
            self.assertIn(key, self.data, f"missing top-level key: {key}")
            self.assertIsInstance(
                self.data[key], str, f"{key} must be a top-level string"
            )

    def test_features_table(self) -> None:
        self.assertIn("features", self.data)
        self.assertIsInstance(self.data["features"], dict)
        self.assertTrue(self.data["features"].get("codex_hooks"))

    def test_mcp_servers_present(self) -> None:
        """We ship four AI-Toolbox-recommended MCP servers."""
        mcps = self.data.get("mcp_servers", {})
        expected = {"context7", "sequential_thinking", "filesystem", "fetch"}
        self.assertEqual(
            set(mcps.keys()), expected,
            f"mcp_servers drift: {set(mcps.keys()) ^ expected}",
        )
        for name, spec in mcps.items():
            self.assertIn("command", spec, f"mcp_servers.{name} missing command")
            self.assertIn("args", spec, f"mcp_servers.{name} missing args")
            self.assertIsInstance(spec["args"], list)


class CodexHooksTemplateTest(unittest.TestCase):
    """.codex-hooks.json must be a valid Codex hooks file with all the
    AI Toolbox event handlers wired in."""

    @classmethod
    def setUpClass(cls) -> None:
        path = TEMPLATES / ".codex-hooks.json"
        with path.open(encoding="utf-8") as f:
            cls.data = json.load(f)

    def test_required_events_wired(self) -> None:
        hooks = self.data.get("hooks", {})
        for event in ("SessionStart", "PreToolUse", "PostToolUse", "Stop"):
            self.assertIn(event, hooks, f"missing hook event: {event}")
            self.assertIsInstance(hooks[event], list)
            self.assertGreater(len(hooks[event]), 0)


if __name__ == "__main__":
    unittest.main()
