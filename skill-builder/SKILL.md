---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new [name], optimize [skill], agents [skill], hooks [skill]"
allowed-tools: Read, Glob, Grep, Write, Edit, TaskCreate, TaskUpdate, TaskList, TaskGet
---

# Skill Builder

## Quick Commands

| Command | Action |
|---------|--------|
| `/skill-builder` | Full audit: runs optimize + agents + hooks in display mode for all skills |
| `/skill-builder audit` | Same as above |
| `/skill-builder skills` | List all local skills available in this project |
| `/skill-builder list [skill]` | Show all modes/options for a skill in a table |
| `/skill-builder new [name]` | Create a new skill from template |
| `/skill-builder optimize [skill]` | Display optimization plan for a skill (add `--execute` to apply) |
| `/skill-builder agents [skill]` | Display agent opportunities for a skill (add `--execute` to create) |
| `/skill-builder hooks [skill]` | Display hooks inventory + opportunities (add `--execute` to create) |
| `/skill-builder dev [command]` | Run any command with skill-builder itself included |

---

## The `skills` Command

**List all local skills available in this project.**

When invoked with `/skill-builder skills`:

1. Glob for all `.claude/skills/*/SKILL.md` files
2. Read each skill's frontmatter to extract name and description
3. Output a table of all available skills

### Output Format

```
| Skill | Description |
|-------|-------------|
| /deploy | Deploy application to staging or production |
| /api-client | API client integration and authentication |
| /db-migrate | Database migration management |
...
```

### Implementation

```bash
# Find all skills
.claude/skills/*/SKILL.md
```

For each skill file:
1. Read the frontmatter
2. Extract `name` and `description` fields
3. Format as table row: `| /[name] | [description] |`

Sort alphabetically by skill name.

---

## The `list` Mode Requirement

**Every skill with multiple modes MUST support a `list` mode.**

When a user runs `/skill-name list`, output a clean table showing all available modes:

```
| Mode | Command | Purpose |
|------|---------|---------|
| **mode1** | `/skill-name mode1 [args]` | Brief description of what this mode does |
| **mode2** | `/skill-name mode2 [args]` | Brief description of what this mode does |
```

### Why This Matters

The `description:` field in frontmatter is limited to one line and gets truncated. Users need a way to discover all available options without reading the full SKILL.md.

### Implementation

Skills with modes should include a `## Usage` section near the top:

```markdown
## Usage

```
/skill-name [mode] [args]
```

### Modes

| Mode | Command | Description |
|------|---------|-------------|
| `mode1` | `/skill-name mode1 [args]` | What mode1 does |
| `mode2` | `/skill-name mode2 [args]` | What mode2 does |

Default mode is `[default]` if not specified.
```

### Handling `/skill-name list`

When invoked with `list` as the first argument:
1. Read the skill's SKILL.md
2. Find the Modes table
3. Output the table directly to the user

**This is a reserved mode name.** Skills should not use `list` for other purposes.

### Audit Check

When auditing skills, verify:
- Does the skill have multiple modes? → Must have a Modes table
- Is the Modes table in a consistent format? → Command + Description columns
- Does the description mention `list` if applicable? → Add to frontmatter

---

## Self-Exclusion Rule

**The skill-builder skill MUST be excluded from all actions (audit, optimize, agents, hooks, skills list) unless the command is prefixed with `dev`.**

- `/skill-builder audit` → audits all skills EXCEPT skill-builder
- `/skill-builder optimize some-skill` → works normally
- `/skill-builder optimize skill-builder` → REFUSED. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev optimize skill-builder`"
- `/skill-builder dev audit` → includes skill-builder in the audit
- `/skill-builder dev optimize skill-builder` → allowed

**Detection:** If the first argument after the command is `dev`, strip it and proceed with self-inclusion enabled. Otherwise, skip any skill whose name is `skill-builder` when iterating skills, and refuse if `skill-builder` is explicitly named as a target.

---

## Display/Execute Mode Convention

**All sub-commands (`optimize`, `agents`, `hooks`) operate in two modes:**

| Mode | Behavior | Flag |
|------|----------|------|
| **Display** (default) | Read-only plan of what would change | *(none)* |
| **Execute** | Apply changes to files | `--execute` |

### Rules

1. **Default is always display mode.** Running `/skill-builder optimize my-skill` shows what *would* change without modifying anything.
2. **`--execute` triggers modifications.** Running `/skill-builder optimize my-skill --execute` applies the changes.
3. **Audit always calls sub-commands in display mode**, then offers the user a choice of which to execute.
4. **Execution requires a task plan.** When `--execute` is invoked, the command MUST:
   - First produce a numbered task list using TaskCreate — one task per discrete action
   - Execute each task sequentially, marking progress via TaskUpdate
   - This ensures context can be refreshed mid-execution without losing track, no tasks get forgotten during long context windows, and the user can see progress and resume if interrupted

---

## Audit Command

**When invoked without arguments or with `audit`, run the full audit as an orchestrator.**

### Step 1: Gather Metrics

```
Files to scan:
- CLAUDE.md
- .claude/rules/*.md (if exists)
- .claude/skills/*/SKILL.md
```

### Step 2: CLAUDE.md & Rules Analysis

```markdown
## CLAUDE.md
- **Lines:** [X] (target: < 150)
- **Extraction candidates:** [list sections that could move to skills]

## Rules Files
- **Found:** [count] files in .claude/rules/
- **Should convert to skills:** [yes/no with reasoning]
```

### Step 3: Skills Summary Table

```markdown
## Skills Summary
| Skill | Lines | Description | Directives | Reference Inline | Hooks | Status |
|-------|-------|-------------|------------|------------------|-------|--------|
| /skill-1 | X | single/multi | Y | Z tables | yes/no | OK/NEEDS WORK |

**Description column:** Flag `multi` if uses `|` or `>` syntax (needs optimization to single line)
```

### Step 4: Run Sub-Commands in Display Mode

For each skill found:
1. Run **optimize** in display mode → collect optimization findings
2. Run **agents** in display mode → collect agent opportunities
3. Run **hooks** in display mode → collect hooks inventory and opportunities

### Step 5: Aggregate Report

Combine all sub-command outputs into a single report:

```markdown
# Skill System Audit Report

## CLAUDE.md
[from Step 2]

## Rules Files
[from Step 2]

## Skills Summary
[from Step 3]

## Optimization Findings
[aggregated from optimize display mode per skill]

## Agent Opportunities
| Skill | Agent Type | Purpose | Priority |
|-------|------------|---------|----------|
| /skill-1 | id-lookup | Enforce grounding for IDs | High |
[from agents display mode per skill]

## Hooks Status
[aggregated from hooks display mode]

## Directives Inventory
[List all directives found across all skills - ensures nothing is lost]

## Priority Fixes
1. [Most impactful optimization]
2. [Second priority]
3. [Third priority]
```

### Step 6: Offer Execution

After presenting the report, ask:
> "Which sub-commands should I execute?"
> 1. `optimize --execute` for [skill(s)]
> 2. `agents --execute` for [skill(s)]
> 3. `hooks --execute` for [skill(s)]
> 4. All of the above for [skill]
> 5. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress.

---

## Core Principles

**IMPORTANT: Never break anything.**

Optimization is RESTRUCTURING, not REWRITING. The skill must behave identically after optimization.

**YOU MUST:**

1. **MOVE content, don't rewrite it** — Copy verbatim to new location
2. **PRESERVE all directives exactly** — User's words are sacred
3. **KEEP all workflows intact** — Same steps, same order, same logic
4. **TEST nothing changes** — After optimization, skill works identically

**What optimization IS:**
- Moving reference tables to `reference.md`
- Moving IDs/accounts to `reference.md`
- Adding grounding requirements
- Creating enforcement hooks
- Splitting into SKILL.md + reference.md

**What optimization is NOT:**
- Rewriting instructions "for clarity"
- Condensing workflows "for brevity"
- Changing step order "for efficiency"
- Removing "redundant" content
- Summarizing user directives

**The test:** If the original author reviewed the optimized skill, they should say "this does exactly what mine did, just organized differently."

---

**Directives are sacred.**

When a user says "Never use Uncategorized accounts" — those exact words stay in the skill, verbatim, forever.

**YOU MUST distinguish between:**

| Content Type | Can Compress? | Where It Lives |
|--------------|---------------|----------------|
| **Directives** (user's exact rules) | NEVER | Top of SKILL.md, verbatim |
| **Reference** (IDs, tables, theory) | YES | Separate reference.md |
| **Machinery** (hooks, agents, chains) | YES | settings.json, hooks/, agents |

---

## The Sacred Directive Pattern

When a user gives you a rule, store it verbatim in a `## Directives` section:

```markdown
## Directives

> **NEVER assign a transaction or expense to Uncategorized or Other Expenses.**
> Every transaction must go to a specific, meaningful expense category.
> If a transaction doesn't clearly match a known category, stop and ask.

*— Added 2026-01-15, source: user instruction*
```

**Rules for directives:**
1. Quote the user's exact words
2. Add source and date
3. Place at TOP of skill file
4. NEVER summarize or reword for brevity
5. Enforce with hooks when possible

---

## Enforcement Mechanisms

See [references/enforcement.md](references/enforcement.md) for hook JSON examples, permission patterns, subagent YAML, and context mutability theory.

---

## Optimize Command

**Restructure a specific skill for optimal context efficiency.**

### Display Mode (default)

When running `/skill-builder optimize [skill]`:

1. **Read the skill's SKILL.md** and any associated files
2. **Run per-skill audit checklist:**

```
## Audit: /skill-name

**Frontmatter:**
- Has YAML frontmatter: [yes/no]
- name matches folder: [yes/no]
- description is single line: [yes/no] ← CRITICAL (multi-line gets truncated)
- Has modes/subcommands: [yes/no]
- Modes listed in description: [yes/no/N/A]

**Modes/List Support:**
- Has multiple modes: [yes/no]
- Has Modes table: [yes/no/N/A]
- Table format correct (Mode | Command | Description): [yes/no/N/A]
- Supports `/skill-name list`: [yes/no/N/A]

**Directives found:** [count]
- Are they verbatim user rules? [yes/no]
- Are they at the top? [yes/no]

**Reference material inline:** [count] tables/lists
- Should move to reference.md? [yes/no]

**Enforcement:**
- allowed-tools: [current]
- hooks: [present/missing]
- agents: [present/missing]
- Directives enforceable by hooks? [yes/no/partial]

**Line count:** [X] (target: < 150 excluding reference.md)
```

3. **Identify optimization targets** per `references/optimization-examples.md`
4. **List proposed changes** (what would move to reference.md, frontmatter fixes, etc.)

```markdown
### Proposed Changes
1. [e.g., Move accounts table (lines 45-80) to reference.md]
2. [e.g., Fix frontmatter description to single line]
3. [e.g., Add grounding requirement for reference.md]

**Estimated result:** [X] → [Y] lines
```

### Execute Mode (`--execute`)

When running `/skill-builder optimize [skill] --execute`:

1. Run display mode analysis first
2. **Generate task list from findings** using TaskCreate — one task per discrete action (e.g., "Move accounts table to reference.md", "Fix frontmatter description to single line")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. Report before/after line counts

**Grounding:** `references/optimization-examples.md`, `references/templates.md`

---

## Optimization Targets

See [references/optimization-examples.md](references/optimization-examples.md) for the full table of what can/can't be moved and a before/after example.

---

## Agents Command

**Analyze and create agents for a skill.**

### Display Mode (default)

When running `/skill-builder agents [skill]`:

1. **Read the skill's SKILL.md** — understand its directives, workflows, and enforcement gaps
2. **Read `references/agents.md`** — load the 4 agent templates and opportunity detection table
3. **Evaluate each agent type** against the skill:

| Agent Type | Trigger Condition | Applies? |
|------------|-------------------|----------|
| **ID Lookup** | Skill references IDs, accounts, or external identifiers that must be validated | [yes/no + reasoning] |
| **Validator** | Skill has pre-flight checks or complex validation rules | [yes/no + reasoning] |
| **Evaluation** | Skill produces output that needs quality assessment | [yes/no + reasoning] |
| **Matcher** | Skill requires matching inputs to categories or patterns | [yes/no + reasoning] |

4. **Report which agents would help and why:**

```markdown
## Agent Opportunities for /skill-name

| Agent Type | Recommended | Purpose | Priority |
|------------|-------------|---------|----------|
| ID Lookup | Yes | Validate account IDs against reference.md | High |
| Validator | No | No complex validation rules found | — |
| Evaluation | Yes | Assess output quality for reports | Medium |
| Matcher | No | No pattern matching needed | — |

### Recommended Agents
1. **ID Lookup Agent** — [specific purpose for this skill]
2. **Evaluation Agent** — [specific purpose for this skill]
```

### Execute Mode (`--execute`)

When running `/skill-builder agents [skill] --execute`:

1. Run display mode analysis first
2. **Generate task list from findings** using TaskCreate — one task per agent to create (e.g., "Create ID Lookup agent for /budget", "Create Validator agent for /deploy")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. Each task: create the agent file in `.claude/skills/[skill]/agents/`, following templates from `references/agents.md`

**Grounding:** `references/agents.md`

---

## Hooks Command

**Inventory existing hooks and identify new enforcement opportunities.**

When running `/skill-builder hooks` (all skills) or `/skill-builder hooks [skill]` (specific skill):

### Display Mode (default)

#### Step 1: Inventory Existing Hooks

Scan for hook scripts and their wiring:

```
1. Glob for .claude/skills/**/hooks/*.sh
2. Read .claude/settings.local.json → hooks section
3. Cross-reference: which scripts are wired, which are orphaned
```

#### Step 2: Validate Existing Hooks

For each hook script found:

| Check | What to Verify |
|-------|----------------|
| **Wired** | Listed in settings.local.json `hooks` section |
| **Matcher** | Correct tool matcher (Bash, Edit, etc.) |
| **Exit codes** | Uses `exit 2` to block, `exit 0` to allow |
| **Reads stdin** | Captures `INPUT=$(cat)` for tool input |
| **Permission** | Script is executable (`chmod +x`) |
| **Error output** | Writes block reason to stderr (`>&2`) |

#### Step 3: Identify New Opportunities

Scan each skill's SKILL.md for directive patterns that can be enforced with hooks:

| Directive Pattern | Hook Type | Example |
|-------------------|-----------|---------|
| "Never use X" / "Never assign to X" | **Grep-block** | Block forbidden IDs/values |
| "Always use script Y" | **Require-pattern** | Block direct API calls, require helper |
| "Never call Z directly" | **Grep-block** | Block forbidden endpoints |
| "Must include X" | **Require-pattern** | Ensure required fields present |
| "Never exceed N" | **Threshold** | Block values above limit |

**Skip these** (need agents, not hooks):
- "Choose the best X" → judgment call
- "If unclear, ask" → context-dependent
- "Match X to Y" → reasoning required

#### Step 4: Generate Report

```markdown
# Hooks Audit Report

## Existing Hooks

| Script | Skill | Matcher | Wired | Status |
|--------|-------|---------|-------|--------|
| no-uncategorized.sh | /budget | Bash | Yes | OK |
| validate-org-id.sh | /api-client | Bash | Yes | OK |
| orphaned-script.sh | /skill | — | No | ORPHANED |

## Wiring Issues
- [List any scripts not in settings.json]
- [List any settings.json entries pointing to missing scripts]

## New Opportunities

| Skill | Directive | Hook Type | Priority |
|-------|-----------|-----------|----------|
| /skill-name | "Never use Uncategorized" | Grep-block | High |

## Recommended Actions
1. [Wire orphaned script X]
2. [Create hook for directive Y in /skill-name]
3. [Fix exit code in script Z]
```

### Execute Mode (`--execute`)

When running `/skill-builder hooks [skill] --execute`:

1. Run display mode analysis first (Steps 1-4 above)
2. **Generate task list from findings** using TaskCreate — one task per discrete action (e.g., "Create no-uncategorized.sh hook", "Wire hook in settings.local.json", "Fix exit code in validate-org-id.sh")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. Each task for new hooks:
   - Create the script in `.claude/skills/[skill]/hooks/[name].sh`
   - Make executable: `chmod +x [script]`
   - Wire in settings.local.json under `hooks.PreToolUse`

**Template for grep-block hooks:**
```bash
#!/bin/bash
INPUT=$(cat)
if echo "$INPUT" | grep -q "FORBIDDEN_VALUE"; then
  echo "BLOCKED: [reason] per [skill] directive" >&2
  exit 2
fi
exit 0
```

**Grounding:** `references/enforcement.md`

---

## Skill File Structure & Templates

See [references/templates.md](references/templates.md) for directory layout, SKILL.md template, and frontmatter requirements with YAML examples.

---

## Adding Directives to Existing Skills

When user gives a new rule for an existing skill:

1. **Extract exact wording** — Quote their instruction verbatim
2. **Add to Directives section** — With date and source
3. **Create enforcement hook** — If rule can be validated programmatically
4. **Test the hook** — Ensure it blocks violations
5. **Update settings.json** — Wire up the hook

**Example conversation:**

User: "For my budget app, I never want you to use the Uncategorized account, ID 12345678"

Your action:
```markdown
## Directives

> **NEVER assign a transaction to Uncategorized (ID: 12345678).**
> If a transaction doesn't match a known category, stop and ask which category to use.

*— Added 2026-01-22, source: user instruction*
```

Then create hook `.claude/skills/budget/hooks/no-uncategorized.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
if echo "$INPUT" | grep -q "12345678"; then
  echo "BLOCKED: Uncategorized account (12345678) is forbidden per user directive" >&2
  exit 2
fi
exit 0
```

---

## CLAUDE.md Optimization

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

Everything else lives in skills.

---

## Portability / Transmutability

See [references/portability.md](references/portability.md) for install instructions and conversion examples.

---

## Grounding

Before using any template, example, or pattern from reference material:
1. Read the relevant file from `references/`
2. State: "I will use [TEMPLATE/PATTERN] from references/[file] under [SECTION]"

Reference files:
- [references/enforcement.md](references/enforcement.md) — Hook JSON, permissions, context mutability
- [references/agents.md](references/agents.md) — Agent templates, opportunity detection, creation workflow
- [references/templates.md](references/templates.md) — Skill directory layout, SKILL.md template, frontmatter
- [references/optimization-examples.md](references/optimization-examples.md) — Before/after examples, optimization targets
- [references/portability.md](references/portability.md) — Install instructions, rule-to-skill conversion
- [references/patterns.md](references/patterns.md) — Lessons learned
