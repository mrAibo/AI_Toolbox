"""
Regression test for the Remove-NpmBdShim function in setup.ps1.

Beads is a Go binary; setups that previously installed a (non-existent)
@beads/bd npm package leave a broken shim under %APPDATA%\\npm. The
function is supposed to detect and remove all four extension variants
(bd, bd.ps1, bd.cmd, bd.exe) — only when the shim content actually
references @beads/bd, never blindly.

Skipped on systems without pwsh (most CI Linux runners install pwsh).
"""
from __future__ import annotations

import re
import shutil
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

REPO = Path(__file__).resolve().parent.parent
SETUP_PS1 = REPO / ".agent" / "scripts" / "setup.ps1"
HAS_PWSH = shutil.which("pwsh") is not None


def _extract_function(source: str, name: str) -> str:
    """Return just the named function definition. Brace-counts to find end."""
    m = re.search(rf"function {re.escape(name)}\s*\{{", source)
    if not m:
        raise AssertionError(f"function {name} not found in setup.ps1")
    start = m.start()
    depth = 0
    i = m.end() - 1  # position at opening brace
    while i < len(source):
        ch = source[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return source[start:i + 1]
        i += 1
    raise AssertionError(f"function {name} brace mismatch")


@unittest.skipUnless(HAS_PWSH, "pwsh not available on this runner")
class NpmBdShimCleanupTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.func_src = _extract_function(
            SETUP_PS1.read_text(encoding="utf-8"),
            "Remove-NpmBdShim",
        )

    def _run(self, fake_appdata: Path) -> subprocess.CompletedProcess:
        # On Windows + Git Bash, /tmp/xxx paths confuse pwsh (it treats
        # them as Windows-relative without a drive letter). Resolve to
        # absolute Windows paths before handing them to pwsh.
        def _winpath(p: Path) -> str:
            try:
                return subprocess.check_output(
                    ["cygpath", "-w", str(p)], text=True
                ).strip()
            except (FileNotFoundError, subprocess.CalledProcessError):
                return str(p)

        win_appdata = _winpath(fake_appdata)
        script_path = fake_appdata / "_runner.ps1"
        script_path.write_text(
            f'$env:APPDATA = "{win_appdata}"\n'
            f"{self.func_src}\n"
            f"Remove-NpmBdShim\n",
            encoding="utf-8",
        )
        # Use -File rather than stdin: pwsh's stdin parser mangles
        # multi-line script blocks containing pipelines.
        return subprocess.run(
            ["pwsh", "-NoProfile", "-NonInteractive", "-File",
             _winpath(script_path)],
            capture_output=True,
            text=True,
        )

    def test_removes_all_broken_shim_variants(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            npm = tmp / "npm"
            npm.mkdir()
            broken = r"require('node_modules\@beads\bd\bin\bd.js')"
            for name in ("bd", "bd.ps1", "bd.cmd", "bd.exe"):
                (npm / name).write_text(broken, encoding="utf-8")
            result = self._run(tmp)
            self.assertEqual(result.returncode, 0, result.stderr)
            for name in ("bd", "bd.ps1", "bd.cmd", "bd.exe"):
                self.assertFalse(
                    (npm / name).exists(),
                    f"{name} should have been removed",
                )
            self.assertIn("Removed stale npm bd shim", result.stdout)

    def test_removes_only_ps1_when_only_ps1_present(self) -> None:
        """The original bug: only bd.ps1 existed, the old code missed it."""
        with TemporaryDirectory() as td:
            tmp = Path(td)
            npm = tmp / "npm"
            npm.mkdir()
            (npm / "bd.ps1").write_text(
                r"node 'C:\path\to\node_modules\@beads\bd\bin\bd.js' $args",
                encoding="utf-8",
            )
            result = self._run(tmp)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse((npm / "bd.ps1").exists())

    def test_leaves_unrecognized_shim_alone(self) -> None:
        """Never delete a shim we don't recognize — paranoia is correct."""
        with TemporaryDirectory() as td:
            tmp = Path(td)
            npm = tmp / "npm"
            npm.mkdir()
            (npm / "bd.ps1").write_text(
                "echo 'this is some other bd tool'", encoding="utf-8"
            )
            result = self._run(tmp)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(
                (npm / "bd.ps1").exists(),
                "must not delete shims we don't recognize",
            )

    def test_no_npm_dir_is_a_no_op(self) -> None:
        with TemporaryDirectory() as td:
            result = self._run(Path(td))
            self.assertEqual(result.returncode, 0, result.stderr)
            # No output expected when there's nothing to do
            self.assertNotIn("Removed", result.stdout)

    def test_empty_npm_dir_is_a_no_op(self) -> None:
        with TemporaryDirectory() as td:
            tmp = Path(td)
            (tmp / "npm").mkdir()
            result = self._run(tmp)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn("Removed", result.stdout)


if __name__ == "__main__":
    unittest.main()
