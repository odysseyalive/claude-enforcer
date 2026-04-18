# Shell Safety Audit Patterns

Detection patterns for the audit and lint workflows. Each pattern names the rule it enforces, the regex/grep used to detect it, the severity, and whether the patch is mechanical (auto-applicable) or judgment (flag-only).

---

## P1. Bare relative path in JSON hook command (R1)

**Where to look:** `.claude/settings*.json`, any JSON file with a `"command":` field for shell hook entries.

**Detection:** parse JSON; for each `command` value of a `type: "command"` hook, check if the trimmed string starts with `.` (relative) or with a literal path that does not start with `"$` or with `/`.

```python
# Pseudocode
def is_bare_relative(cmd):
    s = cmd.strip()
    if s.startswith('"$'):    # already quoted-and-anchored; safe
        return False
    if s.startswith('/'):     # absolute literal; safe (but discouraged)
        return False
    if s.startswith('.'):     # bare relative; UNSAFE
        return True
    return False
```

**Severity:** HARD
**Patch:** mechanical. Rewrite `<path>` → `"$CLAUDE_PROJECT_DIR/<path>"`. JSON-encoded as `"\"$CLAUDE_PROJECT_DIR/<path>\""`.

**Auto-fix script outline:**
```python
import json, sys
path = sys.argv[1]
with open(path) as f: d = json.load(f)
for evt, blocks in d.get("hooks", {}).items():
    for block in blocks:
        for h in block.get("hooks", []):
            if h.get("type") == "command":
                c = h["command"].strip()
                if c.startswith("."):
                    h["command"] = f'"$CLAUDE_PROJECT_DIR/{c}"'
with open(path + ".bak", "w") as f: json.dump(d, f, indent=2)  # backup
with open(path, "w") as f: json.dump(d, f, indent=2)
```

---

## P2. Unquoted variable expansion in shell (R2)

**Where to look:** `.sh` script bodies; multi-line bash inside heredocs.

**Detection:** grep for `$VAR` or `${VAR}` patterns NOT enclosed in double quotes, where the expansion is followed by `/` (suggesting a path).

```bash
# Catches: $VAR/foo, ${VAR}/foo (unquoted)
# Misses (correctly): "$VAR/foo", '$VAR/foo'
grep -nE '(^|[^"'\''])\$\{?[A-Z_][A-Z0-9_]*\}?/' file.sh
```

**Severity:** HARD when the variable likely holds a path (CLAUDE_PROJECT_DIR, HOME, PWD, *_DIR, *_PATH, *_ROOT). SOFT otherwise.

**Patch:** mechanical for HARD cases. Wrap the expansion: `$VAR/foo` → `"$VAR/foo"`. Preserve any surrounding quoting context.

---

## P3. Missing ERR trap in hook script (R3)

**Where to look:** `.sh` files under `*/hooks/` directories.

**Detection:** read the file; check whether any line matches `^trap .* ERR\b`.

```bash
if ! grep -qE '^trap .* ERR\b' "$file"; then
  echo "MISSING ERR TRAP: $file"
fi
```

**Severity:** SOFT
**Patch:** judgment. Adding a trap to existing scripts can change observable behavior (e.g., a script that intentionally exits non-zero on a code path now emits a systemMessage first). Flag and recommend manual addition using template T1/T2 from `templates.md`.

---

## P4. `set -e` in hook script (R4)

**Where to look:** `.sh` files under `*/hooks/`.

**Detection:**
```bash
grep -nE '^[[:space:]]*set\s+(-e|-eu|-eo)' file.sh
```

**Severity:** HARD
**Patch:** judgment. Removing `set -e` may unmask errors that were previously silenced by abort. Flag with the recommendation: replace `set -e` with explicit `||` / `&&` / `if` guards on each fallible command. Do not auto-strip.

---

## P5. Naked stdin read (R5)

**Where to look:** `.sh` files in any context that consumes stdin (hooks, filters).

**Detection:**
```bash
grep -nE 'INPUT=\$\(cat\)\s*$' file.sh   # no 2>/dev/null, no || exit
```

**Severity:** SOFT
**Patch:** mechanical. Rewrite `INPUT=$(cat)` → `INPUT=$(cat 2>/dev/null) || exit 0`.

---

## P6. `jq` invocation without dependency check (R6)

**Where to look:** `.sh` files.

**Detection:**
```bash
grep -nE '\bjq\b' file.sh | grep -v 'command -v jq'
```

**Severity:** SOFT
**Patch:** judgment. Replacing `jq` with inline Python is mechanical for simple field extractions but trickier for complex queries. Flag with recommendation; offer template R5's Python form as a candidate replacement.

---

## P7. `grep -P` (PCRE, GNU-only flag) (R6)

**Where to look:** `.sh`, JSON shell command strings.

**Detection:**
```bash
grep -nE '\bgrep\s+(-[a-zA-Z]*P|-P\b)' file.sh
```

**Severity:** SOFT
**Patch:** judgment. PCRE features sometimes have no ERE equivalent. Flag and let the author convert.

---

## P8. Unsuppressed grep stderr (R7)

**Where to look:** `.sh`.

**Detection:**
```bash
grep -nE '\bgrep\b[^|]*' file.sh | grep -v '2>/dev/null'
```

(Crude — produces false positives. Refine per use.)

**Severity:** SOFT
**Patch:** mechanical when the line is a single grep without further pipeline. Append `2>/dev/null` before the closing of the conditional.

---

## P9. Path with literal space in JSON command (R2 + R8)

**Where to look:** `.claude/settings*.json`.

**Detection:** parse JSON; for each `command` value, if the decoded shell command contains an unquoted space inside what looks like a path token, flag.

**Severity:** HARD
**Patch:** judgment. Could be a literal path with space that needs quoting, or an intentional command-with-arguments. Flag with the surrounding context for review.

---

## P10. Inline Python with mixed indentation (R9)

**Where to look:** `.sh`, JSON shell command strings.

**Detection:** find `python3 -c '...'` blocks; inside the quoted block, check that all lines are either at depth 0 or consistently indented under a `try:`, `def:`, etc.

**Severity:** SOFT
**Patch:** judgment. Indentation rewrites are risky. Flag with line numbers.

---

## Severity Aggregation Rule

When reporting findings:
- **HARD findings auto-fix in `--execute` mode**, with a backup file (`[name].bak`) created before each rewrite. Validate after rewrite (JSON parses, shebang intact, file not zero bytes).
- **SOFT findings always require human review.** Display in the report with line numbers and recommended fix; never patch automatically.
- If a single file has both, do the HARD patches and leave a marker comment near the SOFT findings.

---

## Output Format

Audit output is grouped by file:

```
=== <file> ===
HARD findings (auto-fixable):
  L23: P1 — bare relative path in command. Recommended: wrap in $CLAUDE_PROJECT_DIR.

SOFT findings (review needed):
  L45: P3 — missing ERR trap. Recommended: add trap from shell-safety/templates.md T1.
  L67: P4 — set -e present. Recommended: replace with explicit guards.

Summary: 1 HARD, 2 SOFT
```

Lint output is single-line per file:
```
<file>: 3 findings (1 H, 2 S)
```
