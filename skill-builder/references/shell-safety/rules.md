# Shell Safety Rules

The canonical pitfall list. Each rule has rationale (why it bites), the bad pattern, and the safe pattern. Audit detection patterns and write templates derive from these rules.

---

## R1. Path resolution: never assume CWD

**Why it bites:** Shell hook subsystems and tool runners often invoke commands from a CWD that is not the project root. A bare relative path like `.claude/skills/x/hooks/y.sh` resolves correctly only when CWD happens to be the project root. When it isn't, `/bin/sh` reports `No such file or directory` and the hook fails silently with a "non-blocking status code." The bug is invisible until something else surfaces the error stream.

**Bad:**
```json
{ "command": ".claude/skills/x/hooks/y.sh" }
```

**Good:**
```json
{ "command": "\"$CLAUDE_PROJECT_DIR/.claude/skills/x/hooks/y.sh\"" }
```

The `$CLAUDE_PROJECT_DIR` env var is set by the hook subsystem and resolves to the project root. The escaped double quotes around the expansion handle R2 (paths with spaces) at the same time.

**Same rule for scripts launched outside hooks:** absolute paths or paths anchored to a known env var. Never `./foo` or `cd somewhere && ./foo` unless the script itself first sets a known root.

---

## R2. Path-with-spaces: quote every variable that holds a path

**Why it bites:** When `$VAR` expands to `/Users/me/My Drive/project`, an unquoted use splits at the space. The shell sees two tokens, treats the first as the command, and fails with `/My: No such file or directory`. Common on iCloud Drive, Google Drive (Insync/rclone mounts), OneDrive, and any user folder named with a space.

**Bad:**
```bash
cd $PROJECT_DIR
$CLAUDE_PROJECT_DIR/scripts/build.sh
```

**Good:**
```bash
cd "$PROJECT_DIR"
"$CLAUDE_PROJECT_DIR/scripts/build.sh"
```

**For JSON-embedded commands** (settings.json), the outer JSON-string quotes are not the same as shell quotes. Embed shell-level double quotes by escaping them inside the JSON value:

```json
{ "command": "\"$CLAUDE_PROJECT_DIR/scripts/build.sh\"" }
```

The unquoted form is never acceptable, even on a system where the current path happens to have no spaces. Environments move; the script should not break when they do.

---

## R3. Crash visibility: every hook script needs an ERR trap

**Why it bites:** When a hook script crashes (syntax error, missing dependency, unhandled exit), the hook subsystem reports a generic "non-blocking status code" with no diagnostic. The script's actual error message is lost. ERR traps capture the failure to a sentinel file or stderr so the cause is recoverable.

**Bad:**
```bash
#!/bin/bash
INPUT=$(cat)
# ... if anything below crashes, you get nothing useful
```

**Good (script-body):**
```bash
#!/bin/bash
trap 'echo "{\"systemMessage\":\"hook-name.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR
INPUT=$(cat 2>/dev/null) || exit 0
# ... rest of script
```

The trap catches uncaught failures, emits a structured message the hook subsystem can surface, and exits cleanly so a buggy hook doesn't block the user's tool call.

---

## R4. `set -e` is a foot-gun in hook scripts

**Why it bites:** `set -e` causes the script to exit immediately on any non-zero return. This bypasses the ERR trap's emit step (the trap fires, but `exit 0` inside the trap may not run before `set -e` propagates). It also makes legitimate non-zero returns (e.g., `grep -q` returning 1 when no match) abort the script. In hooks, this turns an advisory check into a fatal crash.

**Bad:**
```bash
#!/bin/bash
set -e
INPUT=$(cat)
echo "$INPUT" | grep -q "pattern"  # exits the script if no match!
echo "found pattern"
```

**Good:**
```bash
#!/bin/bash
trap '...' ERR
INPUT=$(cat 2>/dev/null) || exit 0
if echo "$INPUT" | grep -q "pattern" 2>/dev/null; then
  echo "found pattern"
fi
```

Use explicit conditionals (`if`, `||`, `&&`) instead of `set -e`. Each fallible step makes its own decision about what to do on failure.

---

## R5. Stdin parsing: treat input as untrusted

**Why it bites:** Hook stdin is a JSON document, but the script may be invoked in contexts where stdin is empty, malformed, or redirected from elsewhere. A naked `INPUT=$(cat)` blocks forever if no stdin is open, and a downstream `echo "$INPUT" | jq ...` crashes when `jq` is missing or the input isn't JSON.

**Bad:**
```bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path')
```

**Good:**
```bash
INPUT=$(cat 2>/dev/null) || exit 0
FILE=$(echo "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass' 2>/dev/null)
```

`python3` is more universally available than `jq`. The `try/except` returns empty on bad input rather than crashing. The `2>/dev/null || exit 0` on the `cat` lets the script no-op when stdin is closed.

---

## R6. Tool dependence: don't assume optional tools are present

**Why it bites:** `jq`, `gdate`, `ggrep`, GNU-specific flags (`grep -P`, `sed -i`) are not portable. A hook that works on the author's Linux box fails silently on a contributor's macOS install or a fresh CI image.

**Common offenders:**
| Tool / Flag | Portable alternative |
|-------------|---------------------|
| `jq` | `python3 -c 'import json,sys; ...'` |
| `grep -P` (PCRE) | `grep -E` (ERE) or escape sequences |
| `sed -i` | `sed -i.bak` (BSD-compatible, leaves backup) or write to tmp + mv |
| `date -d` (GNU) | Pure Python via `datetime` |
| `realpath` | Plain `cd "$dir" && pwd` or Python `pathlib` |

When a tool is required, check first:
```bash
if ! command -v jq >/dev/null 2>&1; then
  echo "jq not installed; skipping" >&2
  exit 0
fi
```

---

## R7. Grep: anchor what matters, swallow what doesn't

**Why it bites:** Unanchored patterns match more than intended. Missing `2>/dev/null` lets grep's stderr leak into hook output. `grep -q` followed by reliance on exit code without an ERR trap or guard turns a no-match into a script crash.

**Bad:**
```bash
if echo "$FILE" | grep -q '\.claude/'; then ...
```

**Good:**
```bash
if echo "$FILE" | grep -q '\.claude/' 2>/dev/null; then ...
```

The `2>/dev/null` keeps stderr clean. For paths, prefer anchoring (`grep -qE '^/abs/path/'`) when you mean "starts with."

---

## R8. JSON-embedded shell: quoting is layered

**Why it bites:** When a shell command lives inside a JSON string (settings.json hook commands, MCP tool definitions), there are two quoting contexts: the JSON string syntax and the shell parser that runs after the JSON is decoded. Forgetting either layer produces commands that look correct in the JSON but execute incorrectly.

**The two layers:**

1. **JSON layer** — backslash-escapes apply to the JSON parser. `\"` becomes a literal `"` in the decoded string. `\\` becomes a literal `\`.
2. **Shell layer** — what the shell sees after JSON decoding. Quotes here are real shell quotes.

**Reading rule:** decode the JSON string first; what's left is what the shell sees. Validate that.

**Common mistakes:**
- `"command": "$VAR/path"` → shell sees `$VAR/path` unquoted; breaks on spaces (R2)
- `"command": "\"$VAR/path\""` → shell sees `"$VAR/path"`; correct
- `"command": "/path with space/script.sh"` → shell sees the literal path unquoted; breaks (R2)

---

## R9. Heredoc and inline Python: indent and quoting cliffs

**Why it bites:** Embedding multi-line Python (or any language) inside a bash heredoc or `python3 -c '...'` requires getting both the bash quoting and the inner-language indentation right. A stray single quote inside the inner code closes the bash string. Indentation that looks fine in the editor breaks Python.

**Bad:**
```bash
python3 -c 'd = json.load(sys.stdin)
    print(d.get("x"))'
```

(Indented `print` is a Python `IndentationError` because there's no enclosing block.)

**Good:**
```bash
python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("x", ""))
except Exception:
    pass'
```

For longer scripts, write the helper to a `.py` file and call it. Inline Python should stay under ~10 lines.

---

## R10. The advisory vs blocking distinction

**Why it matters:** Hooks can either advise (exit 0 + emit reminder) or block (exit 2 + emit reason). Choosing wrong produces either nagging that gets ignored or unexpected hard stops that frustrate the user.

| Use blocking (exit 2) when | Use advisory (exit 0 + reminder) when |
|----------------------------|----------------------------------------|
| Violation is unambiguous (forbidden ID, banned keyword) | Rule has exceptions (mechanical edits, intentional overrides) |
| Damage is hard to undo | Damage is easy to revisit |
| User cannot legitimately want the action | User might legitimately bypass on judgment |

Mixing the two: a hook can advise on borderline cases and block on clear violations within the same script.

---

## Quick Decision Reference

When writing a hook command in JSON: **R1 + R2 + R8** apply.
When writing a hook script body: **R3 + R4 + R5 + R6 + R7** apply.
When writing inline Python in bash: **R9** applies.
When choosing the exit code: **R10** applies.
