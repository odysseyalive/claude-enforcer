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

Overall: [PASS / PASS with warnings / FAIL]
```

**If any FAIL:** List each failure with the skill name and specific issue.
**If all PASS:** Report clean health.
