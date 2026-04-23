# Diff Editing Rules

**Purpose:** Output tokens are 3-5x more expensive than input tokens. Never waste them rewriting entire files.

---

## Rules

1. **NEVER output full file contents** when making changes. This burns tokens and will be rejected.

2. **For single-line changes:** Use `sed -i`:
   ```bash
   sed -i 's/old_text/new_text/' path/to/file
   ```

3. **For multi-line changes:** Write a temporary Python script:
   ```python
   # /tmp/patch.py
   with open("path/to/file") as f:
       content = f.read()
   content = content.replace("old_exact_block", "new_exact_block")
   with open("path/to/file", "w") as f:
       f.write(content)
   ```

4. **For new files:** Use heredoc or `cat << 'EOF' > new_file`:
   ```bash
   cat << 'EOF' > path/to/new_file.py
   ... content ...
   EOF
   ```

5. **For complex changes:** Use a patch file or write a small bash/python script. Avoid complex regex replacements — LLMs are notoriously bad at escaping slashes and quotes in sed.

---

## Rationale

- Writing a 500-line file to change 3 lines costs ~500 output tokens unnecessarily
- A targeted `sed` or Python `.replace()` costs ~5-20 tokens
- Over multiple sessions, this saves thousands of tokens per task

---

## Exceptions

- Creating brand new files from scratch (acceptable)
- Files under 50 lines where the full output is shorter than a patch
- When explicitly asked by the user to output the full file

---

## Input Context Budget

Input tokens cost less than output tokens, but at agent scale they dominate total cost. Default to the minimum sufficient slice when gathering context:

| Situation | Preferred approach |
|-----------|-------------------|
| Bug in a known function | `git diff HEAD~1 -- <file>` + function body only |
| Understanding a module | File outline (signatures only), not full source |
| Log analysis | `rtk log <file>` (deduped) instead of `cat` |
| Large refactor | Full file read is acceptable — state why explicitly |
| API contract check | Read only the relevant type/interface definition |

**Default rule:** read the diff or the symbol, not the file.

**Escape hatch:** when the full file genuinely matters, say so explicitly before reading it — e.g. "Reading full file: needed to understand module-level side effects." This keeps full reads intentional rather than reflexive.
