## Checksums Command Procedure

**Generate or verify directive checksums for skill files. Also generates the `protect-directives` and `unique-persona` command hooks if not present.**

No scripts are shipped — they are generated on the target system adapted to the available toolchain.

When running `/skill-builder checksums` (all skills) or `/skill-builder checksums [skill]` (specific skill):

### Display Mode (default)

#### Step 1: Discover Skills with Directives

**Preflight — self-exclusion.** Detect invocation form:
- Invoked as `/skill-builder dev checksums …` → skill-builder may be targeted or iterated normally
- Invoked as `/skill-builder checksums skill-builder` → REFUSE. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev checksums skill-builder`". Do not proceed.
- Invoked as `/skill-builder checksums` (all skills, no target) → exclude `skill-builder` from the glob result

See SKILL.md § Self-Exclusion Rule.

```bash
Glob: .claude/skills/*/SKILL.md  (exclude skill-builder unless dev prefix)
```

For each skill, check for `<!-- origin: user ... immutable: true -->` blocks.

#### Step 2: Show Current State

For each skill with directives:

| Skill | Directives | Sidecar Exists | Rows / Blocks | Status |
|-------|-----------|----------------|---------------|--------|
| skill-name | N | Yes/No | R / B | PASS/FAIL/PARTIAL/UNREADABLE/N/A |

Parse sidecar rows with the § Canonical Sidecar Parse Regex below. Never re-derive a stricter regex from the format template: doing so reproduces the exact blind spot this report exists to surface, and the resulting "R of B protected" line will understate coverage while looking authoritative.

- **Sidecar exists:** `.directives.sha` file present next to SKILL.md
- **Rows / Blocks:** parsed sidecar rows (R) against immutable blocks found in SKILL.md (B). `R < B` means unprotected directives
- **PASS:** `R == B`, every row parses, every hash matches
- **FAIL:** at least one parsed row's hash differs from the recomputed block
- **PARTIAL:** `R < B` (some directives have no sidecar row) or one or more rows are malformed
- **UNREADABLE:** the sidecar has content but zero rows parse. Treat as UNPROTECTED, never as PASS
- **N/A:** No sidecar exists (checksums not yet generated)

Also check for enforcement hooks:

| Hook | Exists | Wired |
|------|--------|-------|
| protect-directives | Yes/No | Yes/No |
| unique-persona | Yes/No | Yes/No |

#### Step 3: Report

```markdown
# Directive Checksums Report

## Status

| Skill | Directives | Protected | Status |
|-------|-----------|-----------|--------|
| [name] | [N] | Yes/No | [PASS/FAIL/PARTIAL/UNREADABLE/UNPROTECTED] |

## Enforcement Hooks
| Hook | Status |
|------|--------|
| protect-directives | [present/missing] |
| unique-persona | [present/missing] |

## Actions Needed
- [List skills needing checksum generation]
- [List skills with mismatched checksums]
- [List skills with PARTIAL coverage: R < B, naming the unprotected directive indices]
- [List skills with UNREADABLE sidecars]
- [List hooks that need generating]
```

### Execute Mode (`--execute`)

1. Run display mode analysis first (Steps 1-3)
2. **Generate sidecar files** — For each skill with directives and no sidecar (or mismatched checksums), generate `.directives.sha` inline:
   - Read the SKILL.md
   - Strip YAML frontmatter (everything between the first two `---` lines) before scanning — this prevents matching marker references inside hook prompt strings
   - Extract all `<!-- origin: user | ... immutable: true -->` ... `<!-- /origin -->` blocks. **Canonical extraction regex (order-insensitive, must match the shipped hook exactly):** `<!-- origin: user[^>]*immutable: true[^>]*-->\n(.*?)\n<!-- /origin -->` with DOTALL. The trailing `[^>]*` before `-->` is load-bearing: `immutable: true` may appear in any token position within the marker (`added: … | immutable: true` OR `immutable: true | added: …`), and the generator and the `protect-directives` hook MUST use the identical regex or position-based (`directive:N`) comparison drifts. Still requires literal `origin: user` and literal `immutable: true` (excludes `immutable: false`)
   - For each block: normalize (strip markers, trim trailing whitespace per line, collapse 3+ blank lines to 2), compute SHA-256
   - **Hashes MUST come from an executed host command, never from model output.** Run `python3 -c` with `hashlib`, or `shasum -a 256`, or PowerShell `Get-FileHash`, over the normalized block bytes and copy the command's actual output. A plausible-looking 64-hex string that no command produced is a FABRICATED hash: it makes the sidecar a permanent false baseline that mismatches forever, or worse, matches nothing and reads as absent. If no hashing command is available on the host, write NO sidecar and report the toolchain gap. (Incident precedent: the 2026-07-28d fabricated-hash sidecar.)
   - Write sidecar in the format specified below, obeying § Sidecar File Format's preview rules literally
2-bis. **Read-back self-verification (MANDATORY, blocks success).** A generator that emits a sidecar its own reader cannot parse is the failure class this step exists to prevent. Immediately after writing, re-read the file from disk and assert all four:
   - **(a) Every data row parses** under the § Canonical Sidecar Parse Regex below. Any non-blank, non-`#` line that does not match is a FAILURE.
   - **(b) Row count equals block count.** `directive:N` values must be exactly `1..len(blocks)` with no gaps and no duplicates. Fewer rows than blocks means unprotected directives that the hook will silently never examine.
   - **(c) Every hash re-verifies.** Recompute each block's SHA-256 from the file and compare against the row just written. This catches a fabricated or mis-copied hash at generation time rather than months later.
   - **(d) Every preview ends in the literal `...`** per the format rules.
   On ANY failure: report the specific rows and the assertion that failed, and do NOT report the sidecar as generated. Do not "fix up" the row by hand and move on; a hand-repaired sidecar is regenerated (and re-broken) by the next run, so correct the generation step itself.
3. **Generate `protect-directives` hook** (if not present) — Create `.claude/skills/skill-builder/hooks/protect-directives.sh` following the spec below. Make executable. Wire in `settings.local.json` under **PostToolUse** for Edit and Write (the shipped hook is an advisory post-edit drift check; see its spec below for why PreToolUse wiring silently defeats it).
4. **Generate `unique-persona` hook** (if not present) — Create `.claude/skills/skill-builder/hooks/unique-persona.sh` following the spec below. Make executable. Wire in `settings.local.json` under PreToolUse for Write and Edit.
4-bis. **Windows wiring (OS-appropriate variant).** Read the `Platform:` line from the session environment context. IF the platform is `windows`/`win32` → wire the PowerShell companions instead of the `.sh` scripts: the installer already ships `protect-directives.ps1` and `unique-persona.ps1` alongside the bash originals (2026-06-06 extension of the 2026-05-11 hooks-in-source exception), so do NOT generate new hook code — wire the existing files with a command of the form `powershell -NoProfile -ExecutionPolicy Bypass -File "$CLAUDE_PROJECT_DIR/.claude/skills/skill-builder/hooks/<name>.ps1"`. No executable bit is needed for `.ps1` files. On bash platforms (`linux`, `darwin`, Windows with Git Bash as the shell tool) wire the `.sh` variants per steps 3 and 4. Never wire both variants for the same hook on one host.
5. Report generated checksums with directive previews

### Sidecar File Format (`.directives.sha`)

```
# Directive checksums - generated by skill-builder
# Do not edit manually. Regenerate with: /skill-builder checksums [skill]
# Last generated: YYYY-MM-DD
sha256:<hash>  directive:1  "<preview>..."
sha256:<hash>  directive:2  "<preview>..."
```

**Row rules (normative, not illustrative).** The template above is a shape, not a spec. These rules are the spec, and the generator MUST follow each one literally:

1. **Separators:** two spaces between the three columns. One `sha256:` row per immutable block, in document order, numbered from 1 with no gaps.
2. **Hash:** exactly 64 lowercase hex chars, produced by an executed command (see Execute Mode step 2).
3. **Preview construction, in this order:**
   a. Take the block's normalized text.
   b. **Flatten every newline and tab to a single space, then collapse runs of whitespace to one space, then trim.** The preview is a single-line display string; a raw newline inside it splits the row and makes it unparseable.
   c. Replace every `"` with `'`. A double quote inside the preview breaks the quoted column.
   d. Take the first 50 characters of the result. If the text is shorter than 50 characters, take all of it. **Never truncate at a newline** (step b already removed them).
4. **The trailing `...` is MANDATORY and unconditional.** It is part of the row grammar, not an ellipsis meaning "text was cut." Append the literal three dots **even when the preview is shorter than 50 characters and nothing was truncated.** This is the exact defect that shipped: a short first line yielded a row with no `...`, the parser's regex required it, and the row was silently skipped while the hook reported clean.
5. **Preview content is display-only.** It is never compared, never hashed, and never used to locate a block. Block identity is positional (`directive:N`). A preview that reads oddly is cosmetic; a preview that breaks the row grammar is a protection outage.

### Canonical Sidecar Parse Regex

Every reader of a `.directives.sha` (the `protect-directives` hooks, `verify` Step 2b, `audit` Step 4b-bis, and the display mode above) MUST use this one regex. Do not re-derive a stricter one from the format template.

```
^sha256:([0-9a-f]{64})\s+directive:(\d+)\s+"(.*)"\s*$
```

- The preview group is **greedy to the final quote on the line** and does **not** require the trailing `...`. Strip a trailing `...` from group 3 for display if present.
- **Rationale:** the reader must stay liberal so that already-generated legacy rows (written before rule 4 above existed, therefore missing the `...`) still verify their hashes. A reader that demands the `...` converts a generator bug into a protection outage on every sidecar already on disk. The generator is strict; the reader is liberal; the mismatch is reported, not silently absorbed.
- **A non-blank, non-`#` line that does not match this regex is a finding, never a skip.** See the hook spec's Malformed-row handling below.

### Hook Generation Specifications

The specs below describe the bash variants. The shipped PowerShell companions (`protect-directives.ps1`, `unique-persona.ps1`) implement the same logic, normalization, and exit semantics for Windows hosts and are fetched by the installer — they are wired (per step 4-bis), never regenerated here.

#### protect-directives.sh

**Purpose:** **PostToolUse** hook on Edit/Write. Advisory drift check: reports when a SKILL.md's immutable directive blocks no longer match their `.directives.sha` baseline.

**Wiring event: PostToolUse, not PreToolUse.** The shipped hook reads the target file **from disk** after the tool has run. Wired under PreToolUse it would hash the *pre-edit* file, which trivially matches its own baseline, so the check passes on every edit and protection is silently zero. This is not a preference; PreToolUse wiring defeats the shipped implementation entirely. (Earlier revisions of this spec described a PreToolUse blocking variant that reconstructed post-edit content from `old_string`/`new_string`. That variant was never what shipped. The spec now documents the shipped hook.)

**Location:** `.claude/skills/skill-builder/hooks/protect-directives.sh`

**Matcher:** `Edit|Write`

**Logic:**
1. Read JSON from stdin. Extract `file_path`.
2. If file path does not end with `SKILL.md` → exit 0 (not our concern)
3. Look for `.directives.sha` sidecar next to the target SKILL.md. If absent → exit 0 (first-time pass)
4. Read the target file from disk (post-edit state). If unreadable → report the read failure; never pass silently.
5. Strip YAML frontmatter (regex: `^---\n.*?\n---\n` with DOTALL)
6. Extract all `<!-- origin: user | ... immutable: true -->` blocks from the body — order-insensitive, using the canonical regex `<!-- origin: user[^>]*immutable: true[^>]*-->\n(.*?)\n<!-- /origin -->` (DOTALL); identical to the sidecar generator above so position-based comparison aligns
7. Normalize each block (same as sidecar generation: trim, collapse blank lines)
8. Compute SHA-256 of each block
9. Parse sidecar rows with the § Canonical Sidecar Parse Regex. Compare hashes positionally by `directive:N`
10. Report all four finding classes below via `additionalContext`. If there are no findings, print nothing
11. Always `exit 0`

**Four finding classes — every one of them reports; none is a silent skip:**

| Class | Condition | Why it must be loud |
|-------|-----------|---------------------|
| **DRIFT** | Row parses, hash differs from the recomputed block | The original purpose of the hook |
| **MISSING BLOCK** | `directive:N` in the sidecar exceeds the block count in the file | A protected directive was deleted |
| **MALFORMED ROW** | A non-blank, non-`#` line does not match the canonical regex | A row the reader cannot interpret is an unverified directive. Silently skipping it is how a sidecar becomes decorative |
| **UNPROTECTED BLOCK** | The file has a block at index N with no corresponding sidecar row | **Coverage.** Iterating only sidecar rows means blocks past the last row are never examined, and the hook prints nothing about them. A sidecar with 1 row against a file with 12 blocks reports clean on 11 unexamined directives |

**Sidecar-unreadable special case:** if the sidecar has at least one non-blank, non-`#` line but **zero** rows parse, emit a single explicit `SIDECAR UNREADABLE` advisory naming the file, instead of a per-row list. This is the state that must never again present as clean.

**Fail-open, not fail-silent.** The hook exits 0 unconditionally, including on internal error: a hook bug must never block the user's work, and a PostToolUse exit 2 cannot undo an edit that already happened. "Fail loudly" here means the `additionalContext` advisory channel fires. What is forbidden is the combination the shipped hook had: an empty parse result producing an empty report that reads as a pass. Blanket `except: exit 0` / `catch { exit 0 }` handlers are permitted only where they cannot swallow a finding; any handler wrapping the parse or compare stage must emit an advisory before exiting.

**Toolchain adaptation:**
- Prefer `python3` for JSON parsing and multiline regex (most portable for this use case)
- If python3 unavailable, degrade gracefully: exit 0 with warning to stderr
- Use `grep -oP` for file_path extraction from JSON stdin (works on GNU grep; for BSD, adapt to `sed`)

**Exit codes:** 0 always (advisory hook). Findings surface through `additionalContext`, never through the exit code.

#### unique-persona.sh

**Purpose:** PreToolUse hook on Write/Edit. Blocks creation of agents with duplicate personas.

**Location:** `.claude/skills/skill-builder/hooks/unique-persona.sh`

**Matcher:** `Write|Edit`

**Logic:**
1. Read JSON from stdin. Extract `file_path`.
2. If file path is not an agent file (does NOT match `*/agents/*.md` for flat-file agents OR `*/agents/*/AGENT.md` for subdirectory-form agents) → exit 0 (not our concern). Both forms are valid agent locations; filtering only on `AGENT.md` silently skips flat-file agent writes.
3. Extract `persona:` field from the JSON content (look for the YAML frontmatter field within the raw JSON — appears as literal text)
4. If no persona found → exit 0 (allow). This naturally handles non-agent markdown that happens to live under `agents/` (e.g. supporting notes) — files without a `persona:` field exit here.
5. Find all existing agent files in BOTH forms: `.claude/skills/*/agents/*.md` (flat) AND `.claude/skills/*/agents/*/AGENT.md` (subdir). Union the two — checking only one form silently misses persona collisions from the other half of the population.
6. For each (excluding the file being written): extract `persona:` field
7. Case-insensitive comparison. If match → exit 2 with stderr: "BLOCKED: Persona '[X]' already in use by [agent] in [file]."
8. If unique → exit 0

**Toolchain adaptation:**
- Pure bash with `grep` and `find` — no python3 required
- Use `tr '[:upper:]' '[:lower:]'` for case normalization
- Skip files that lack a `persona:` field

**Exit codes:** 0 = allow, 2 = block

### Override Path

To legitimately change a directive:
1. Delete the `.directives.sha` sidecar file (deliberate act)
2. Edit the directive in SKILL.md
3. Run `/skill-builder checksums [skill] --execute` to regenerate

The friction is the feature: accidental directive alteration is surfaced immediately after the edit, in the same turn, while the change is still trivially revertible. (`protect-directives` is advisory by design and never blocks a write; `unique-persona` is the blocking PreToolUse member of the pair.)

**Grounding:** `references/enforcement.md` § "Hook Handler Types"
