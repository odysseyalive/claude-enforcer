# Shell Safety Templates

Scaffolds for the most common shell shapes. Each one bakes in the safe defaults from `rules.md` so the author doesn't have to remember every rule on every write.

---

## T1. Hook script body (advisory)

For hooks that emit a reminder via `additionalContext` and never block. Most content/style guards are this shape.

```bash
#!/bin/bash
# Hook: <one-line purpose>
# Skill: /<skill-name>
# Rule reference: shell-safety R3, R4, R5, R7

trap 'echo "{\"systemMessage\":\"<hook-name>.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR

INPUT=$(cat 2>/dev/null) || exit 0

# Extract file_path from tool input (skip if you don't need it)
FILE_PATH=$(echo "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass' 2>/dev/null)

# Scope check: skip skill infrastructure
if echo "$FILE_PATH" | grep -q '\.claude/' 2>/dev/null; then
  exit 0
fi

# Domain check: only fire for files in scope
if ! echo "$FILE_PATH" | grep -qE '<your-path-pattern>' 2>/dev/null; then
  exit 0
fi

# Emit advisory reminder
echo '{"additionalContext":"<your reminder text here>"}'
exit 0
```

**Always exits 0.** Does not block. Reminder is injected via `additionalContext`.

---

## T2. Hook script body (blocking)

For hooks that prevent forbidden actions. Use when violation is unambiguous and damage is hard to undo (R10).

```bash
#!/bin/bash
# Hook: <one-line purpose>
# Skill: /<skill-name>
# Rule reference: shell-safety R3, R5, R7, R10

trap 'echo "{\"systemMessage\":\"<hook-name>.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR

INPUT=$(cat 2>/dev/null) || exit 0

# Extract the field you want to inspect (Bash command, Edit content, etc.)
TARGET=$(echo "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    # adjust the path for your tool: command, file_path, content, etc.
    print(d.get("tool_input", {}).get("command", ""))
except Exception:
    pass' 2>/dev/null)

# Block on forbidden pattern
if echo "$TARGET" | grep -qE '<forbidden-pattern>' 2>/dev/null; then
  echo "BLOCKED: <reason> per /<skill> directive" >&2
  exit 2
fi

exit 0
```

**Exits 2 on violation** (blocks the tool). Reason goes to stderr so the user sees it. Always exits 0 on no-match.

---

## T3. settings.json hook entry (command type)

For wiring an on-disk script into the hook subsystem.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR/.claude/skills/<skill-name>/hooks/<hook-name>.sh\""
          }
        ]
      }
    ]
  }
}
```

**Key invariants** (R1 + R2 + R8):
- Path uses `$CLAUDE_PROJECT_DIR`, not bare relative
- Whole expansion wrapped in escaped double quotes (`"\"$CLAUDE_PROJECT_DIR/...\""`)
- This keeps the path intact when expanded into a directory containing whitespace

---

## T4. Frontmatter hook entry (prompt type)

Embedded in a skill's SKILL.md frontmatter. Fires only while the skill is loaded.

```yaml
---
name: my-skill
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: prompt
          prompt: "<what to check>: $ARGUMENTS. If <violation>, DENY with explanation. Otherwise APPROVE."
          if: "Edit(content/**/*.mdx)"
          statusMessage: "<status text>..."
---
```

**Key invariants:**
- `if:` field for scoping — declarative, no shell parsing
- `$ARGUMENTS` placeholder is replaced with the hook input JSON
- No file paths in command strings means R1/R2/R8 do not apply

---

## T5. Frontmatter hook entry (PostCompact reminder)

Re-injects critical rules after context compaction. Pure echo, no script needed.

```yaml
hooks:
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: <critical rules here>\"}'"
          statusMessage: "Re-injecting <skill> awareness..."
```

The single-quote bash string contains the JSON. Escape `"` inside as `\"`.

---

## T6. Standalone utility script (not a hook)

For scripts run from the command line or by other automation (not the hook subsystem).

```bash
#!/bin/bash
# <Script purpose>
# Rule reference: shell-safety R1, R2, R6

set -u  # Catch unset vars; do NOT use set -e (R4)

# Resolve script directory portably (no realpath dependency, R6)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# All paths anchored to SCRIPT_DIR or absolute (R1)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Quote every variable expansion (R2)
cd "$PROJECT_ROOT" || { echo "Cannot cd to $PROJECT_ROOT" >&2; exit 1; }

# ... rest of script logic
```

`set -u` is safer than `set -e` — it catches typos in variable names without aborting on every non-zero return.

---

## Picking the right template

| Situation | Template |
|-----------|----------|
| Advisory reminder hook | T1 |
| Blocking hook (forbidden pattern) | T2 |
| Wiring a script into settings.json | T3 |
| Semantic check via prompt hook | T4 |
| Drift-resistance reminder | T5 |
| Stand-alone utility script | T6 |
