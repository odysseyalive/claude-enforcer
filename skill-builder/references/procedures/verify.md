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
| Self-heal observer | Grep SKILL.md for "Self-Heal Observer" | Present (WARN if absent and self-heal installed) |

### Step 3: Hook Validation

```bash
Glob: .claude/skills/**/hooks/*.sh
Read: .claude/settings.local.json → hooks section
```

For each hook script:
- Is it executable? (`ls -la` check)
- Is it wired in settings.local.json?

For each wired hook in settings.local.json:
- Does the script file exist?

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
| Hooks wired | [N]/[N] [PASS/FAIL] |
| Hooks executable | [N]/[N] [PASS/FAIL] |
| Agents referenced | [N]/[N] [PASS/FAIL] |
| Agent Teams enabled | [PASS/FAIL/N/A] |
| Research assistant in teams | [N]/[N] [PASS/WARN/N/A] |

Overall: [PASS / PASS with warnings / FAIL]
```

**If any FAIL:** List each failure with the skill name and specific issue.
**If WARN (self-heal observer missing):** Note: "Run `/skill-builder self-heal` or `optimize --execute` to embed missing observers."
**If all PASS:** Report clean health.
