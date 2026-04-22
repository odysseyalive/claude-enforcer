#!/bin/bash
# Hook: advisory drift check on SKILL.md directive blocks via .directives.sha sidecar
# Skill: /skill-builder
# Rule reference: shell-safety R3, R5, R7
# Replaces the former type:agent PostToolUse check. Detects byte-level drift in
# sacred blocks. Does NOT cover workflow-step reordering or moved-vs-rewritten
# analysis of modifiable content — those are handled post-execute by the
# optimize-diff-auditor agent (which itself runs only when the mechanical
# precheck is inconclusive).

trap 'echo "{\"systemMessage\":\"verify-directive-integrity.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR

INPUT=$(cat 2>/dev/null) || exit 0

FILE_PATH=$(echo "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass' 2>/dev/null)

# Only inspect SKILL.md files
case "$FILE_PATH" in
  */SKILL.md) ;;
  *) exit 0 ;;
esac

# Sidecar sits next to the SKILL.md
SKILL_DIR=$(dirname "$FILE_PATH")
SIDECAR="$SKILL_DIR/.directives.sha"

if [ ! -f "$SIDECAR" ]; then
    # No sidecar configured — no protection to verify. First-time pass.
    exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
    # File missing post-tool-use — nothing to verify
    exit 0
fi

# Compare sidecar entries against current file contents using the same
# normalization as /skill-builder checksums.
REPORT=$(python3 << PYEOF 2>/dev/null
import hashlib, re, sys

sidecar_path = "$SIDECAR"
file_path = "$FILE_PATH"

try:
    with open(file_path) as f:
        content = f.read()
except Exception:
    sys.exit(0)

# Strip YAML frontmatter
stripped = re.sub(r'^---\n.*?\n---\n', '', content, count=1, flags=re.DOTALL)

# Extract sacred blocks in order
blocks = re.findall(
    r'<!-- origin: user[^>]*immutable: true -->\n(.*?)\n<!-- /origin -->',
    stripped, flags=re.DOTALL
)

def normalize(text):
    lines = [ln.rstrip() for ln in text.split('\n')]
    out, blanks = [], 0
    for ln in lines:
        if ln == '':
            blanks += 1
            if blanks <= 2:
                out.append(ln)
        else:
            blanks = 0
            out.append(ln)
    return '\n'.join(out)

# Parse sidecar entries: sha256:<hash>  directive:<N>  "<preview>..."
expected = {}
try:
    with open(sidecar_path) as sc:
        for line in sc:
            m = re.match(r'sha256:([0-9a-f]{64})\s+directive:(\d+)\s+"(.*?)\.\.\."', line)
            if m:
                expected[int(m.group(2))] = (m.group(1), m.group(3))
except Exception:
    sys.exit(0)

violations = []
for n, (expected_sha, preview) in expected.items():
    if n > len(blocks):
        violations.append(f'directive:{n} (preview: "{preview}...") — block no longer present in file')
        continue
    actual_sha = hashlib.sha256(normalize(blocks[n - 1]).encode('utf-8')).hexdigest()
    if actual_sha != expected_sha:
        violations.append(f'directive:{n} (preview: "{preview}...") — sidecar expected sha256:{expected_sha[:12]}..., current sha256:{actual_sha[:12]}...')

if violations:
    msg = "DIRECTIVE DRIFT DETECTED in " + file_path + ":\n  - " + "\n  - ".join(violations) + "\nSacred-block content has changed against its .directives.sha sidecar. If this was intentional, regenerate the sidecar via /skill-builder checksums --execute. If not, revert the change."
    print(msg)
PYEOF
)

if [ -n "$REPORT" ]; then
    # Surface advisory via additionalContext so Claude sees the drift notice
    # Escape double quotes and newlines for JSON
    ESCAPED=$(printf '%s' "$REPORT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null)
    if [ -n "$ESCAPED" ]; then
        echo "{\"additionalContext\":${ESCAPED}}"
    fi
fi

exit 0
