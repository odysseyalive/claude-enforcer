## Verify Command Procedure

**Non-destructive health check. Never modifies files.**

### Step 1: Discover Skills

**Preflight — self-exclusion.** Detect invocation form:
- Invoked as `/skill-builder dev verify …` → include `skill-builder` in the skill set
- Otherwise → exclude `skill-builder` from the glob result

Apply this filter to every step below that iterates skills. See SKILL.md § Self-Exclusion Rule.

```bash
Glob: .claude/skills/*/SKILL.md  (exclude skill-builder unless dev prefix)
```

### Step 2: Per-Skill Validation

For each skill found:

| Check | How | Pass Condition |
|-------|-----|----------------|
| Frontmatter exists | Look for `---` delimiters at top of file | Present |
| `name` matches folder | Compare `name:` field to parent directory name | Match |
| Single-line description | Check `description:` doesn't use `\|` or `>` YAML syntax | Single line |
| `allowed-tools` present | Check frontmatter field exists | Present |
| Line count | Count lines in SKILL.md (exclude reference files) | < 150 |
| Modes table | If skill has 2+ modes, check for Modes table | Present if needed |

### Step 2b: Directive Checksum Validation

For each skill found in Step 1, check for directive protection:

```bash
# For each skill at .claude/skills/[name]/SKILL.md
# Check: .claude/skills/[name]/.directives.sha
```

**If `.directives.sha` exists:**
1. Extract all `<!-- origin: user ... immutable: true -->` blocks from the skill's SKILL.md
2. Compute SHA-256 checksums using the same normalization as `generate-checksums.sh` (strip markers, trim whitespace, collapse blank lines)
3. Compare against stored checksums in `.directives.sha`
4. **Match** → PASS
5. **Mismatch** → FAIL — "Directive fingerprint mismatch: directives may have been modified since last checksum. Run `/skill-builder checksums [skill] --execute` to investigate."

**If `.directives.sha` does not exist but skill has `<!-- origin: user ... immutable: true -->` blocks:**
- WARN — "Directives found without checksum protection. Run `/skill-builder checksums [skill] --execute` to generate."

**If skill has no immutable directive blocks:**
- PASS (N/A) — no directives to fingerprint.

### Step 3: Hook Validation

```bash
Glob: .claude/skills/**/hooks/*.sh
Glob: .claude/hooks/*.sh
Read: .claude/settings.local.json → hooks section
```

For each hook script:
- Is it executable? (`ls -la` check)
- Is it wired in settings.local.json?

For each wired hook in settings.local.json:
- Does the script file exist?
- **Shell-safety lint:** Run `/skill-builder shell-safety lint .claude/settings.local.json` and `/skill-builder shell-safety lint .claude/skills/*/hooks/*.sh`. Surface any HARD findings as FAIL and SOFT findings as WARN. (Shell-safety ships as a skill-builder subcommand — its rule set is always available without a separate install.)

### Step 3a: Code-eval Enforcement Status

If `.claude/skills/code-evaluator/SKILL.md` exists, report whether the always-on
enforcement hooks (`/skill-builder code-eval enforce`) are wired — a legibility
check so a dormant backstop is never mistaken for live coverage:

```bash
Read: .claude/settings.local.json → hooks section
Glob: .claude/skills/code-evaluator/hooks/code-eval-*.{sh,ps1}
```

- All three entries (before-write PreToolUse, at-write PostToolUse, commit-gate
  PreToolUse Bash) wired AND their script files exist → check for drift: read
  `recorded` = the `# code-eval-enforce-version: N` header in
  `code-eval-prewrite.sh` (absent → `0`) vs `shipped` = the
  `<!-- code-eval-enforce-version: N -->` anchor in the skill-builder install's
  `references/procedures/code-eval.md`.
  - `recorded >= shipped` → **WIRED** (scripts v[recorded], current).
  - `recorded < shipped` → **WIRED-STALE** — note: "wired enforce hooks predate the
    current procedure (v[recorded] → v[shipped]); re-run `/skill-builder code-eval
    enforce --execute` to refresh the host backstop."
- Some or none wired → **UNWIRED** — note: "Code-eval enforcement not wired (only
  the in-skill CODE-EVAL-EMBED gate is active). Run `/skill-builder code-eval enforce`
  for the host backstop." Honest-scope reminder: Bash-written code is caught only at
  the commit gate.
- `code-evaluator` not installed → N/A (skip silently).

### Step 3b: Team Validation

```bash
Read: .claude/settings.local.json → env → CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
Grep: .claude/skills/**/SKILL.md AND BOTH agent-file forms — .claude/skills/**/agents/*.md (flat) and .claude/skills/**/agents/*/AGENT.md (subdir) — for "agent team", "TeamCreate", "Spawn teammates". Union the two globs so team patterns declared in either agent form are detected.
```

Determine whether any skill uses team patterns (grep matches above). Then check the env var.

| Scenario | Result |
|----------|--------|
| Env var missing, no skill uses teams | PASS (N/A) |
| Env var missing, a skill uses teams | FAIL |
| Env var present, teams have research assistant | PASS |
| Env var present, team missing research assistant | WARN |

For each skill that uses teams, verify its team definition includes a research assistant (grep for `research assistant`, `Research`, or a role explicitly designated as the research member).

### Step 4: Agent Validation

```bash
Glob BOTH agent-file forms and union the results:
- `.claude/skills/**/agents/*.md` (flat-file agents like `agents/failure-triage.md`)
- `.claude/skills/**/agents/*/AGENT.md` (subdirectory-form agents like `agents/optimize-diff-auditor/AGENT.md`)

Either glob alone silently misses half the agent population.
```

For each agent file:
- Does it have valid frontmatter?
- Is it referenced (by name or filename) in the parent SKILL.md?

### Step 4b: Fleet Registration & Contract Health (2-Brain Harness, 2026-06-06)

For each agent carrying `generated-by: skill-builder lane-excursion` (from the Step 4 union):

- **Registered?** A `.claude/agents/<name>.md` registration must resolve to it (dereference symlinks; a copy-fallback counts). Unregistered → **FAIL** — "minion unregistered: spawns fall to the degraded path (wrong-lane main-session execution). Re-register via `agents [skill] --execute`." *(Panel-measured precedent: a live fleet had 104 agent files with 2 registrations — the whole fleet was silently degraded.)*
- **Model pinned?** `model:` present while lanes are configured (per `references/model-lanes.md`). Missing → WARN with the Audit Agent Model-Assignment Gate fix path.
- **Contract stamped?** `contract-stamp:` present → recompute against the current skill workflow; mismatch → WARN `CONTRACT-DRIFT` ("skill changed under the minion — run `agents [skill]`"). Absent → WARN `UNSTAMPED`.
- **Orphaned?** `excursion-skill:` names a directory that no longer exists → WARN with the retirement path (marker-gated AUTO task in audit's execution phase; ✗ report item in no-VCS projects — audit.md § Step 4f.5-bis).

### Step 4c: Code-Evaluator Agent Registration (marker-neutral)

Independently of the lane-excursion fleet, the two `code-evaluator` agents must be spawnable via the Task tool, or the `code-eval enforce` Phase 1 hard block (and any `CODE-EVAL-EMBED` advisor spawn) cannot resolve. If `.claude/skills/code-evaluator/SKILL.md` exists, for each of `code-design-advisor` and `deadcode-gardener` confirm a `.claude/agents/<name>.md` registration resolves (deref symlinks; copy-fallback counts). Unregistered → **FAIL** — "code-evaluator agent <name> unregistered: the Phase 1 enforce hook's Task spawn cannot resolve. Re-register via `/skill-builder code-eval create` (idempotent repair) or `/skill-builder audit`." This check recomputes NO contract stamp and considers NO orphan retirement — these are the evaluator's own agents, not lane-excursion minions (DEC-2026-06-08). `code-evaluator` not installed → N/A (skip silently).

### Step 5: Summary Output

```
## Skill System Health Check

| Check | Status |
|-------|--------|
| Skills found | [N] |
| Frontmatter valid | [N]/[N] [PASS/FAIL] |
| Line targets met | [N]/[N] [PASS/WARN] (details if warn) |
| Directive checksums | [N]/[N] [PASS/WARN/FAIL] |
| Hooks wired | [N]/[N] [PASS/FAIL] |
| Hooks executable | [N]/[N] [PASS/FAIL] |
| Shell-safety lint (hooks/settings) | [N]/[N] [PASS/WARN/FAIL] |
| Code-eval enforcement | [WIRED/WIRED-STALE/UNWIRED/N/A] |
| Code-eval agents registered | [N]/[N] [PASS/FAIL/N/A] |
| Stale artifacts | [NONE/WARN — list] |
| Agents referenced | [N]/[N] [PASS/FAIL] |
| Minions registered (lane-excursion fleet) | [N]/[N] [PASS/FAIL/N/A] |
| Minion contracts current (stamp check) | [N]/[N] [PASS/WARN/N/A] |
| Agent Teams enabled | [PASS/FAIL/N/A] |
| Research assistant in teams | [N]/[N] [PASS/WARN/N/A] |

Overall: [PASS / PASS with warnings / FAIL]
```

**If any FAIL:** List each failure with the skill name and specific issue.
**If FAIL (directive checksum mismatch):** List each skill with mismatched fingerprint. This may indicate unauthorized directive modification.
**If WARN (no directive checksum):** Note: "WARN: Directives without checksum protection in [skill]. Run `/skill-builder checksums [skill] --execute`."
**If FAIL (shell-safety findings):** List each finding with file path, line number, and the rule it violates (e.g., R1 path resolution, R2 path-with-spaces). Remediation: `/skill-builder shell-safety audit [path] --execute` rewrites the mechanical (HARD) findings in place; SOFT findings need human review. Reason this matters: hook runner invokes commands via `/bin/sh -c`; unquoted relative or `$CLAUDE_PROJECT_DIR` paths fail silently on synced project roots and any non-project-root CWD.
**If all PASS:** Report clean health.
