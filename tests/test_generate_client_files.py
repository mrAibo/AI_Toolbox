"""
Tests for .agent/scripts/generate-client-files.py

Run: python3 -m pytest tests/ -v
  or: python3 -m unittest tests.test_generate_client_files -v
"""
import json
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

# Allow importing the generator without package overhead
SCRIPTS_DIR = Path(__file__).resolve().parent.parent / ".agent" / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))
import generate_client_files as gen  # noqa: E402


MINIMAL_CONFIG = {
    "clients": {
        "test-client": {
            "tier": "full",
            "router_file": "TEST.md",
            "template_router": "templates/TEST.md",
            "config_file": ".test.json",
            "template_config": "templates/.test.json",
            "hooks": True,
        },
        "no-template-client": {
            "tier": "standard",
            "router_file": ".norules",
            "template_router": None,
        },
        "extra-files-client": {
            "tier": "full",
            "extra_files": [
                {"source": "templates/extra.json", "target": "extra/config.json"},
                {"target": "no-source.json"},
            ],
        },
    }
}


class TestCollectMappings(unittest.TestCase):
    def test_router_and_config_with_templates(self):
        mappings = gen.collect_mappings(MINIMAL_CONFIG)
        targets = [m["target"] for m in mappings]
        self.assertIn("TEST.md", targets)
        self.assertIn(".test.json", targets)

    def test_null_template_excluded(self):
        mappings = gen.collect_mappings(MINIMAL_CONFIG)
        targets = [m["target"] for m in mappings]
        self.assertNotIn(".norules", targets)

    def test_extra_files_with_source_included(self):
        mappings = gen.collect_mappings(MINIMAL_CONFIG)
        targets = [m["target"] for m in mappings]
        self.assertIn("extra/config.json", targets)

    def test_extra_files_without_source_excluded(self):
        mappings = gen.collect_mappings(MINIMAL_CONFIG)
        targets = [m["target"] for m in mappings]
        self.assertNotIn("no-source.json", targets)

    def test_empty_clients(self):
        self.assertEqual(gen.collect_mappings({"clients": {}}), [])


class TestIsEmpty(unittest.TestCase):
    def test_nonexistent_path(self):
        self.assertTrue(gen._is_empty(Path("/nonexistent/path/file.txt")))

    def test_empty_file(self):
        with TemporaryDirectory() as tmp:
            f = Path(tmp) / "empty.txt"
            f.write_text("")
            self.assertTrue(gen._is_empty(f))

    def test_nonempty_file(self):
        with TemporaryDirectory() as tmp:
            f = Path(tmp) / "content.txt"
            f.write_text("hello")
            self.assertFalse(gen._is_empty(f))


class TestCheckAndSync(unittest.TestCase):
    def _make_repo(self, tmp: str):
        """Create a minimal fake repo with config + one template."""
        root = Path(tmp)
        # Config
        cfg_dir = root / ".ai-toolbox"
        cfg_dir.mkdir()
        (cfg_dir / "config.json").write_text(
            json.dumps({
                "clients": {
                    "aider": {
                        "router_file": "CONVENTIONS.md",
                        "template_router": ".agent/templates/clients/CONVENTIONS.md",
                    }
                }
            })
        )
        # Template
        tpl_dir = root / ".agent" / "templates" / "clients"
        tpl_dir.mkdir(parents=True)
        (tpl_dir / "CONVENTIONS.md").write_text("# Aider conventions\n")
        return root

    def test_check_reports_missing(self):
        with TemporaryDirectory() as tmp:
            root = self._make_repo(tmp)
            orig_root = gen.REPO_ROOT
            orig_config = gen.CONFIG_PATH
            try:
                gen.REPO_ROOT = root
                gen.CONFIG_PATH = root / ".ai-toolbox" / "config.json"
                config = gen.load_config()
                mappings = gen.collect_mappings(config)
                self.assertEqual(len(mappings), 1)
                self.assertEqual(mappings[0]["target"], "CONVENTIONS.md")
                # Target does not exist yet
                self.assertTrue(gen._is_empty(root / "CONVENTIONS.md"))
            finally:
                gen.REPO_ROOT = orig_root
                gen.CONFIG_PATH = orig_config

    def test_sync_creates_target_from_template(self):
        with TemporaryDirectory() as tmp:
            root = self._make_repo(tmp)
            orig_root = gen.REPO_ROOT
            orig_config = gen.CONFIG_PATH
            try:
                gen.REPO_ROOT = root
                gen.CONFIG_PATH = root / ".ai-toolbox" / "config.json"
                config = gen.load_config()
                mappings = gen.collect_mappings(config)
                gen.sync(mappings)
                target = root / "CONVENTIONS.md"
                self.assertTrue(target.exists())
                self.assertIn("Aider", target.read_text())
            finally:
                gen.REPO_ROOT = orig_root
                gen.CONFIG_PATH = orig_config

    def test_sync_skips_existing_nonempty_target(self):
        with TemporaryDirectory() as tmp:
            root = self._make_repo(tmp)
            orig_root = gen.REPO_ROOT
            orig_config = gen.CONFIG_PATH
            try:
                gen.REPO_ROOT = root
                gen.CONFIG_PATH = root / ".ai-toolbox" / "config.json"
                target = root / "CONVENTIONS.md"
                target.write_text("# Custom content\n")
                config = gen.load_config()
                mappings = gen.collect_mappings(config)
                gen.sync(mappings)
                # Must not overwrite existing content
                self.assertEqual(target.read_text(), "# Custom content\n")
            finally:
                gen.REPO_ROOT = orig_root
                gen.CONFIG_PATH = orig_config


if __name__ == "__main__":
    unittest.main()
