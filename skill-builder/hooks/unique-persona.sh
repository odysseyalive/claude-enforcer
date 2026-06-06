#!/bin/bash
# Hook: unique-persona — block persona duplication across agent files.
#       Covers both flat-file agents (agents/<name>.md) and subdir-form
#       agents (agents/<name>/AGENT.md). Exact-match fast path.
#       Runs PreToolUse on Edit|Write.
# Skill: /skill-builder
# Rule reference: shell-safety R3, R5, R7, R10
#
# Paraphrase / near-duplicate detection lives in
#   /skill-builder agents --deliberate
# rather than firing on every edit. This hook is the deterministic backstop
# for the user directive: "Each agent being created by this system always has
# to have an appropriate persona that is not being used anywhere else."

trap 'echo "{\"systemMessage\":\"unique-persona.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR

INPUT=$(cat 2>/dev/null) || exit 0

FILE_PATH=$(echo "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass' 2>/dev/null)

# Only inspect agent files. Agents live in two valid forms:
#   - flat-file:   <skill>/agents/<name>.md
#   - subdir form: <skill>/agents/<name>/AGENT.md
# Filtering only on */AGENT.md silently skips flat-file agent writes.
# The trailing persona-extraction check exits early on files that happen
# to live under agents/ but lack a persona: field (e.g. supporting notes).
case "$FILE_PATH" in
  */agents/*.md) ;;
  *) exit 0 ;;
esac

# Extract proposed persona from the tool input. For Write, look in content.
# For Edit, look in new_string. If the change doesn't touch the persona line,
# the existing on-disk value is unchanged and no check is needed.
PROPOSED_PERSONA=$(echo "$INPUT" | python3 -c 'import json,re,sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {})
    payload = ti.get("content") or ti.get("new_string") or ""
    m = re.search(r"^persona:\s*(.+?)\s*$", payload, flags=re.MULTILINE)
    if m:
        val = m.group(1).strip()
        if len(val) >= 2 and val[0] == val[-1] and val[0] in (chr(34), chr(39)):
            val = val[1:-1]
        print(val)
except Exception:
    pass' 2>/dev/null)

if [ -z "$PROPOSED_PERSONA" ]; then
    # No persona line in the change — nothing to check
    exit 0
fi

# Normalize for comparison: lowercase, collapse whitespace, trim punctuation
normalize() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ' | sed 's/[[:punct:]]//g' | sed 's/^ *//;s/ *$//'
}

NORM_PROPOSED=$(normalize "$PROPOSED_PERSONA")

# Locate the project root (prefer $CLAUDE_PROJECT_DIR, fall back to pwd)
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"

# Scan every other agent file for an exact normalized match. Three forms:
#   - flat-file:   .claude/skills/<skill>/agents/<name>.md
#   - subdir form: .claude/skills/<skill>/agents/<name>/AGENT.md
#   - registered:  .claude/agents/<name>.md (often a symlink back into a skill form)
# Symlinks are dereferenced and deduped by resolved path so a registration
# symlink never double-counts (or false-conflicts with) its own target.
CONFLICT_FILE=""
CONFLICT_PERSONA=""
EDIT_REAL=$(readlink -f -- "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
SEEN=""
while IFS= read -r -d '' f; do
    REAL=$(readlink -f -- "$f" 2>/dev/null || echo "$f")
    # Skip the file being edited (by resolved path)
    if [ "$REAL" = "$EDIT_REAL" ]; then
        continue
    fi
    # Dedupe resolved targets (registration symlink + its target = one agent)
    case "$SEEN" in
      *"|$REAL|"*) continue ;;
    esac
    SEEN="$SEEN|$REAL|"
    EXISTING=$(grep -m1 -E '^persona:' "$REAL" 2>/dev/null | sed -E 's/^persona:[[:space:]]*//' | sed -E 's/^[\"'"'"']//; s/[\"'"'"']$//')
    if [ -z "$EXISTING" ]; then
        continue
    fi
    NORM_EXISTING=$(normalize "$EXISTING")
    if [ "$NORM_PROPOSED" = "$NORM_EXISTING" ]; then
        CONFLICT_FILE="$f"
        CONFLICT_PERSONA="$EXISTING"
        break
    fi
done < <({ find "$ROOT/.claude/skills" -path '*/agents/*' -name '*.md' -print0 2>/dev/null; find "$ROOT/.claude/agents" -maxdepth 1 -name '*.md' -print0 2>/dev/null; })

if [ -n "$CONFLICT_FILE" ]; then
    echo "BLOCKED: persona '${PROPOSED_PERSONA}' conflicts with ${CONFLICT_FILE}: '${CONFLICT_PERSONA}'. Choose a different persona." >&2
    exit 2
fi

exit 0
