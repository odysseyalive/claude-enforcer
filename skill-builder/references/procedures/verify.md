## Verify Command Procedure

**Non-destructive health check. Never modifies files.**

### Step 1: Discover Skills

```bash
Glob: .claude/skills/*/SKILL.md
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
- **Shell-safety lint:** If `shell-safety` is installed, run `/shell-safety lint .claude/settings.local.json` and `/shell-safety lint .claude/skills/*/hooks/*.sh`. Surface any HARD findings as FAIL and SOFT findings as WARN. Fallback when not installed: check that command strings referencing `$CLAUDE_PROJECT_DIR` are wrapped in escaped double quotes (`"\"$CLAUDE_PROJECT_DIR/...\""`) and that hook script bodies have ERR traps and no `set -e`. Recommend installing shell-safety for the full rule set.

### Step 3b: Team Validation

```bash
Read: .claude/settings.local.json → env → CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
Grep: .claude/skills/**/SKILL.md and .claude/skills/**/agents/*.md for "agent team", "TeamCreate", "Spawn teammates"
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
Glob: .claude/skills/**/agents/*.md
```

For each agent file:
- Does it have valid frontmatter?
- Is it referenced (by name or filename) in the parent SKILL.md?

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
| Stale artifacts | [NONE/WARN — list] |
| Agents referenced | [N]/[N] [PASS/FAIL] |
| Agent Teams enabled | [PASS/FAIL/N/A] |
| Research assistant in teams | [N]/[N] [PASS/WARN/N/A] |

Overall: [PASS / PASS with warnings / FAIL]
```

**If any FAIL:** List each failure with the skill name and specific issue.
**If FAIL (directive checksum mismatch):** List each skill with mismatched fingerprint. This may indicate unauthorized directive modification.
**If WARN (no directive checksum):** Note: "WARN: Directives without checksum protection in [skill]. Run `/skill-builder checksums [skill] --execute`."
**If FAIL (shell-safety findings):** List each finding with file path, line number, and the rule it violates (e.g., R1 path resolution, R2 path-with-spaces). Remediation: `/shell-safety audit [path] --execute` rewrites the mechanical (HARD) findings in place; SOFT findings need human review. Reason this matters: hook runner invokes commands via `/bin/sh -c`; unquoted relative or `$CLAUDE_PROJECT_DIR` paths fail silently on synced project roots and any non-project-root CWD.
**If all PASS:** Report clean health.
