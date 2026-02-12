## CLAUDE.md Optimization Procedure

CLAUDE.md loads into EVERY conversation. Keep it lean — move domain-specific content to skills.

### What MUST Stay in CLAUDE.md

| Content | Why |
|---------|-----|
| Build commands | Needed for any dev work |
| Project structure | Universal orientation |
| Tech stack | Framework context |
| Path aliases | Import resolution |
| Skills reference table | Discovery/navigation |
| Universal rules | Apply to ALL tasks |

### What Should Move to Skills

| Content | Move To |
|---------|---------|
| API integration rules | `/api-name` skill |
| Domain-specific workflows | Domain skill |
| ID/account tables | `skill/reference.md` |
| Vendor-specific instructions | Vendor skill |
| Complex procedures | Dedicated skill |

### CLAUDE.md Optimization Workflow

When asked to optimize CLAUDE.md:

**Step 1: Analyze current CLAUDE.md**
```bash
wc -l CLAUDE.md  # Line count
```

**Step 2: Identify extraction candidates**

Scan for:
- Sections with domain-specific rules (API integrations, budgeting, etc.)
- Inline tables with IDs/accounts
- Procedures longer than 10 lines
- Rules that only apply to specific tasks

**Step 3: For each extraction candidate**

1. Create skill if doesn't exist:
   ```
   .claude/skills/[domain]/
   ├── SKILL.md
   └── reference.md
   ```

2. Move directives (verbatim) to skill's `## Directives` section

3. Move reference tables to `reference.md`

4. Replace CLAUDE.md section with skill pointer:
   ```markdown
   ### [Domain] Integration

   See `/domain` skill for rules and workflows.
   ```

**Step 4: Verify skills table is updated**

Ensure extracted skills appear in the Skills Reference table.

**Step 5: Report savings**
```
## CLAUDE.md Optimization Report

Before: [X] lines
After: [Y] lines
Savings: [Z] lines ([%]%)

Extracted to skills:
- /skill-1: [description]
- /skill-2: [description]
```

### Target CLAUDE.md Structure

After optimization, CLAUDE.md should be ~100-150 lines:

```markdown
# CLAUDE.md

## Commands
[3-5 essential commands]

## Architecture
[Brief project structure - 20 lines max]

## Tech Stack
[One-liner per technology]

## Skills Reference
[Table pointing to skills]

## Important Rules
[Only rules that apply to EVERY task]

## Self-Improvement Protocol
[Meta-rules for learning]
```
