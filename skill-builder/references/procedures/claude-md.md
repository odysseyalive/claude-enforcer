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
| Project Memory (if ledger exists) | Ledger consultation + capture in every conversation |

### What Should Move to Skills

| Content | Move To |
|---------|---------|
| API integration rules | `/api-name` skill |
| Domain-specific workflows | Domain skill |
| ID/account tables | `skill/reference.md` |
| Vendor-specific instructions | Vendor skill |
| Complex procedures | Dedicated skill |

### What Should Move to Rules (`.claude/rules/`)

Rules are modular instruction files that load automatically. Use them for content that:
- Applies globally but isn't domain-specific enough for a skill
- Benefits from path-scoping (only load for matching file types)
- Doesn't need invocation — just passive guidance

| Content | Move To | Path Scope |
|---------|---------|------------|
| TypeScript conventions | `.claude/rules/typescript.md` | `paths: "**/*.ts"` |
| Testing standards | `.claude/rules/testing.md` | `paths: "**/*.test.*"` |
| Code review guidelines | `.claude/rules/review.md` | *(none — always load)* |
| Security requirements | `.claude/rules/security.md` | *(none — always load)* |
| Component patterns | `.claude/rules/components.md` | `paths: "**/components/**"` |

### Decision Framework: Rules vs Skills vs CLAUDE.md

| Question | If Yes → | If No → |
|----------|----------|---------|
| Does it apply to EVERY task? | CLAUDE.md | ↓ |
| Is it invoked on-demand with arguments? | Skill | ↓ |
| Does it only apply to specific file types? | Rule with `paths:` | ↓ |
| Is it passive guidance (no workflow)? | Rule | Skill |
| Does it have complex workflows or agents? | Skill | Rule |

**Context cost comparison:**
- CLAUDE.md: Always loaded (~100% of sessions)
- Rules without `paths:`: Always loaded
- Rules with `paths:`: Only loaded when matching files touched
- Skills: Only loaded when invoked

**Prefer path-scoped rules** for language-specific or directory-specific guidance — they reduce context cost significantly.

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

**Step 3: For each extraction candidate, decide: Rule or Skill?**

Use the decision framework above. Then:

**If extracting to a Rule:**

1. Create the rule file:
   ```
   .claude/rules/[topic].md
   ```

2. Add frontmatter with optional path scope:
   ```yaml
   ---
   description: "Brief description of what this rule covers"
   paths: "**/*.ts"  # Optional — only load for matching files
   ---
   ```

3. Move content (verbatim) to the rule file

4. Remove the section from CLAUDE.md (rules load automatically)

**If extracting to a Skill:**

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

**Step 4b: Ensure Project Memory section**

If `.claude/skills/awareness-ledger/` exists and has records:
- Check if CLAUDE.md already has a Project Memory section (grep for "awareness ledger" or "ledger/index.md")
- If missing, add the CLAUDE.md Integration Line from `references/ledger-templates.md` § "CLAUDE.md Integration Line"
- If present, leave it untouched — it is a structural section that must not be extracted to a skill
- This section must survive optimization. It provides baseline ledger awareness (both consultation and capture) in every conversation, regardless of which skills are loaded.

**Step 5: Report savings**
```
## CLAUDE.md Optimization Report

Before: [X] lines
After: [Y] lines
Savings: [Z] lines ([%]%)

Extracted to rules:
- .claude/rules/[topic].md (paths: [scope]) — [description]

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

## Project Memory
[Awareness ledger integration — if ledger is installed with records.
 See references/ledger-templates.md § "CLAUDE.md Integration Line" for template.]

## Self-Improvement Protocol
[Meta-rules for learning]
```
