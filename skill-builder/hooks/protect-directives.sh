#!/bin/bash
# Hook: protect-directives — advisory drift check on SKILL.md directive blocks
#       via the .directives.sha sidecar. Runs PostToolUse on Edit|Write.
# Skill: /skill-builder
# Rule reference: shell-safety R3, R5, R7
#
# Detects byte-level drift in <!-- origin: user | immutable: true --> blocks.
# Does NOT cover workflow-step reordering or moved-vs-rewritten analysis of
# modifiable content — those live in the optimize-diff-auditor agent and only
# run when the mechanical precheck is inconclusive.
#
# Reports FIVE classes, none of which is ever a silent skip:
#   DRIFT              row parses, hash differs from the recomputed block
#   MISSING BLOCK      sidecar names a directive:N the file no longer has
#   MALFORMED ROW      a data line the canonical row regex cannot parse
#   UNPROTECTED BLOCK  a block in the file with no sidecar row (coverage gap)
#   SIDECAR UNREADABLE the sidecar has data lines but zero of them parse
#
# Fail-open but never fail-silent: this hook always exits 0 (a PostToolUse
# exit 2 cannot undo an edit that already happened, and a hook bug must never
# block the user's work), so "loud" means the additionalContext channel fires.
# An empty parse result must NEVER produce an empty report — that combination
# is what let a sidecar this reader could not read present as clean.
#
# Regenerate the sidecar after intentional directive changes:
#   /skill-builder checksums [skill] --execute
# (or /skill-builder checksums dev skill-builder --execute when targeting
# skill-builder itself).

trap 'echo "{\"systemMessage\":\"protect-directives.sh crashed (non-fatal) — directive protection was NOT verified for this edit\"}" 2>/dev/null; exit 0' ERR

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
#
# Paths are passed through the environment, NOT interpolated into the heredoc:
# the delimiter is quoted so the shell expands nothing inside the script. This
# keeps a path containing $ or " from breaking (or injecting into) the parser,
# and lets the regexes use $ freely.
PY_FAILED=0
REPORT=$(SIDECAR="$SIDECAR" FILE_PATH="$FILE_PATH" python3 << 'PYEOF' 2>/dev/null
import hashlib, os, re, sys

sidecar_path = os.environ.get("SIDECAR", "")
file_path = os.environ.get("FILE_PATH", "")

TAIL = ("\nSacred-block content is verified against its .directives.sha sidecar. "
        "If a change was intentional, regenerate via /skill-builder checksums --execute. "
        "If not, revert the change.")

try:
    with open(file_path) as f:
        content = f.read()
except Exception as exc:
    print("DIRECTIVE CHECK COULD NOT RUN for " + file_path +
          ": the file could not be read (" + exc.__class__.__name__ + "). "
          "Directive protection was NOT verified for this edit.")
    sys.exit(0)

# Strip YAML frontmatter
stripped = re.sub(r'^---\n.*?\n---\n', '', content, count=1, flags=re.DOTALL)

# Extract sacred blocks in order
blocks = re.findall(
    r'<!-- origin: user[^>]*immutable: true[^>]*-->\n(.*?)\n<!-- /origin -->',
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

# Canonical sidecar row regex (checksums.md § Canonical Sidecar Parse Regex).
# The preview group is greedy to the final quote and does NOT require the
# trailing "..." — legacy rows written before that suffix became mandatory
# must still verify their hashes rather than being skipped.
ROW_RE = re.compile(r'sha256:([0-9a-f]{64})\s+directive:(\d+)\s+"(.*)"\s*')

expected = {}
malformed = []
data_lines = 0
try:
    with open(sidecar_path) as sc:
        for lineno, raw in enumerate(sc, 1):
            line = raw.strip()
            if not line or line.startswith('#'):
                continue
            data_lines += 1
            m = ROW_RE.fullmatch(line)
            if not m:
                malformed.append((lineno, line[:70]))
                continue
            preview = m.group(3)
            if preview.endswith('...'):
                preview = preview[:-3]
            expected[int(m.group(2))] = (m.group(1), preview)
except Exception as exc:
    print("DIRECTIVE CHECK COULD NOT RUN for " + file_path +
          ": the sidecar " + sidecar_path + " could not be read (" +
          exc.__class__.__name__ + "). Directive protection was NOT verified "
          "for this edit.")
    sys.exit(0)

# A sidecar with data lines but nothing parseable is a protection outage, not
# a clean run. Report it as one finding instead of a per-row list.
if data_lines > 0 and not expected:
    print("SIDECAR UNREADABLE: " + sidecar_path + "\n  - " + str(data_lines) +
          " data line(s) present, 0 parsed by the canonical row regex.\n  - "
          "NONE of the " + str(len(blocks)) + " immutable block(s) in " +
          file_path + " were verified. This is an UNPROTECTED state, not a "
          "pass.\n  - Regenerate the sidecar: /skill-builder checksums "
          "--execute" + TAIL)
    sys.exit(0)

drift = []
for n in sorted(expected):
    expected_sha, preview = expected[n]
    if n > len(blocks):
        drift.append('directive:%d (preview: "%s...") — block no longer present in file' % (n, preview))
        continue
    actual_sha = hashlib.sha256(normalize(blocks[n - 1]).encode('utf-8')).hexdigest()
    if actual_sha != expected_sha:
        drift.append('directive:%d (preview: "%s...") — sidecar expected sha256:%s..., current sha256:%s...'
                     % (n, preview, expected_sha[:12], actual_sha[:12]))

# Coverage: blocks present in the file that no sidecar row covers are never
# examined by the loop above. Without this check the hook prints nothing about
# them and reads as clean.
unprotected = [i for i in range(1, len(blocks) + 1) if i not in expected]

sections = []
if drift:
    sections.append("DIRECTIVE DRIFT DETECTED in " + file_path + ":\n  - " + "\n  - ".join(drift))
if malformed:
    rows = ['line %d: %s' % (ln, txt) for ln, txt in malformed]
    sections.append("MALFORMED SIDECAR ROW(S) in " + sidecar_path +
                    " — these directives were NOT verified:\n  - " + "\n  - ".join(rows))
if unprotected:
    sections.append("UNPROTECTED DIRECTIVE BLOCK(S) in " + file_path +
                    " — present in the file, absent from " + sidecar_path +
                    ", therefore never checked: directive:" +
                    ", directive:".join(str(i) for i in unprotected) +
                    "\n  - Regenerate the sidecar to bring them under protection: "
                    "/skill-builder checksums --execute")

if sections:
    print("\n\n".join(sections) + TAIL)
PYEOF
) || PY_FAILED=1

if [ "$PY_FAILED" -ne 0 ]; then
    # The checker itself failed to run. Say so — an unreported failure is
    # indistinguishable from a clean pass, which is the bug class this hook
    # was hardened against.
    echo "{\"systemMessage\":\"protect-directives.sh: the drift check failed to execute (python3 error). Directive protection was NOT verified for this edit.\"}"
    exit 0
fi

if [ -n "$REPORT" ]; then
    # Surface advisory via additionalContext so Claude sees the drift notice
    ESCAPED=$(printf '%s' "$REPORT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null)
    if [ -n "$ESCAPED" ]; then
        echo "{\"additionalContext\":${ESCAPED}}"
    else
        # Escaping failed — emit a plain-text fallback rather than dropping a
        # real finding on the floor.
        echo "{\"systemMessage\":\"protect-directives.sh found directive-protection issues but could not encode the report. Run /skill-builder checksums --execute.\"}"
    fi
fi

exit 0
