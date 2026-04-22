#!/bin/bash
# Hook: block persona duplication across AGENT.md files (exact-match fast path)
# Skill: /skill-builder
# Rule reference: shell-safety R3, R5, R7, R10
# Replaces the former type:agent PreToolUse check. Paraphrase detection lives in
# /skill-builder agents --deliberate rather than firing on every edit.

trap 'echo "{\"systemMessage\":\"check-persona-uniqueness.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR

INPUT=$(cat 2>/dev/null) || exit 0

FILE_PATH=$(echo "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass' 2>/dev/null)

# Only inspect AGENT.md files
case "$FILE_PATH" in
  */AGENT.md) ;;
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

# Scan every other AGENT.md for an exact normalized match
CONFLICT_FILE=""
CONFLICT_PERSONA=""
while IFS= read -r -d '' f; do
    # Skip the file being edited
    if [ "$f" = "$FILE_PATH" ]; then
        continue
    fi
    EXISTING=$(grep -m1 -E '^persona:' "$f" 2>/dev/null | sed -E 's/^persona:[[:space:]]*//' | sed -E 's/^[\"'"'"']//; s/[\"'"'"']$//')
    if [ -z "$EXISTING" ]; then
        continue
    fi
    NORM_EXISTING=$(normalize "$EXISTING")
    if [ "$NORM_PROPOSED" = "$NORM_EXISTING" ]; then
        CONFLICT_FILE="$f"
        CONFLICT_PERSONA="$EXISTING"
        break
    fi
done < <(find "$ROOT/.claude/skills" -name 'AGENT.md' -print0 2>/dev/null)

if [ -n "$CONFLICT_FILE" ]; then
    echo "BLOCKED: persona '${PROPOSED_PERSONA}' conflicts with ${CONFLICT_FILE}: '${CONFLICT_PERSONA}'. Choose a different persona." >&2
    exit 2
fi

exit 0
