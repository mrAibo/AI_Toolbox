# Python / pip / venv Conventions

This plugin contributes Python-specific rules. They sit on top of the
universal toolbox rules; they don't replace them.

## Virtual environments

- **Always work inside a venv.** Never `pip install` against the system
  Python on shared machines.
- Prefer `python -m venv .venv` (stdlib) for projects without an
  established tool. For multi-version projects, `uv` and `poetry` are
  reasonable choices; pick one and stick with it.
- Add `.venv/`, `venv/`, `env/` to `.gitignore`.

## Dependency files

- For libraries: pin only what you must in `pyproject.toml` (`>= X` style),
  let consumers resolve.
- For applications: pin everything in a lockfile (`uv.lock`, `poetry.lock`,
  or compiled `requirements.txt` from `pip-tools`). Reproducibility beats
  freshness.
- Don't mix dependency managers — choose `pip + requirements.txt`,
  `uv`, or `poetry`. Mixing leads to drift.

## Type hints

- Public API surfaces: type-annotate. Internal helpers: inference is fine.
- Run `mypy` (or `pyright`) in CI; do not check in code that fails
  type-checking with the agreed strictness.
- Use `from __future__ import annotations` in any file that supports
  Python ≥ 3.10. It eliminates forward-reference quoting and aligns with
  PEP 563.

## Test layout

- Tests live in `tests/` at the repo root or alongside source as
  `test_<module>.py`. Pick one convention per project.
- Use `pytest`. The stdlib `unittest` is acceptable but more verbose.
- Run tests via `rtk pytest` to compress noisy output. CI: collect and
  report failures, do not dump full pass output.

## Imports

- Sort imports: stdlib → third-party → local, separated by blank lines.
- Use `ruff` or `isort` to enforce. One choice per project — don't
  configure both.
- Avoid `from X import *` outside `__init__.py` aggregations.

## Common pitfalls

- **Mutable default arguments** are a footgun. `def f(x=[])` shares the
  list across calls. Use `def f(x=None): if x is None: x = []`.
- **Truthiness on collections**: `if items` is fine, but `if items is not
  None` if you need to distinguish empty from missing.
- **`__init__.py` imports** that fail at import time make the entire
  package unimportable. Keep `__init__.py` minimal.
