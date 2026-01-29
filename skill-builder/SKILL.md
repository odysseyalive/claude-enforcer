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
   - First produce a numbered task list using TaskCreate, one task per discrete action
   - Execute each task sequentially, marking progress via TaskUpdate
   - This ensures context can be refreshed mid-execution without losing track, no tasks get forgotten during long context windows, and the user can see progress and resume if interrupted

---

## Audit Command

**When invoked without arguments or with `audit`, run the full audit as an orchestrator.**

Gathers metrics from CLAUDE.md, rules files, and all skills. Runs optimize + agents + hooks in display mode for each skill. Aggregates into a single report with priority fixes. Offers execution choices.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Audit Command Procedure" before executing.

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
- Reorganizing workflow structure that enforces directives (see enforcement.md § "Behavior Preservation")

**The test:** If the original author reviewed the optimized skill, they should say "this does exactly what mine did, just organized differently."

---

**Directives are sacred.**

When a user says "Never use Uncategorized accounts," those exact words stay in the skill, verbatim, forever.

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

Reads the skill's SKILL.md, runs a per-skill audit checklist (frontmatter, directives, reference material, enforcement, line count), identifies optimization targets, and lists proposed changes. In execute mode, generates a task list and applies changes sequentially.

**Reference splitting:** When a skill's `reference.md` exceeds 100 lines with 3+ h2 sections (each >20 lines), the optimizer proposes splitting into a `references/` directory with domain-specific files. Each split file becomes an **enforcement boundary** — hooks and agents can attach per-file, enabling granular drift resistance. See `references/procedures.md` § "Evaluate Reference Splitting" for thresholds and enforcement priority heuristics.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Optimize Command Procedure" before executing. Also consult `references/optimization-examples.md` and `references/templates.md`.

---

## Optimization Targets

See [references/optimization-examples.md](references/optimization-examples.md) for the full table of what can/can't be moved and a before/after example.

---

## Agents Command

**Analyze and create agents for a skill.**

Reads the skill's SKILL.md, evaluates 4 agent types (ID Lookup, Validator, Evaluation, Matcher) against it, and reports which would help and why. In execute mode, creates agent files from templates.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Agents Command Procedure" before executing. Also consult `references/agents.md`.

---

## Hooks Command

**Inventory existing hooks and identify new enforcement opportunities.**

Scans for hook scripts and wiring in settings.local.json, validates existing hooks (wired, matcher, exit codes, stdin, permissions, stderr, scoping), identifies new opportunities from directive patterns, and generates a report. In execute mode, creates scripts and wires them. Style/content hooks must self-scope to skip `.claude/` infrastructure files.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Hooks Command Procedure" before executing. Also consult `references/enforcement.md`.

---

## Skill File Structure & Templates

See [references/templates.md](references/templates.md) for directory layout, SKILL.md template, and frontmatter requirements with YAML examples.

---

## Adding Directives to Existing Skills

Extract exact wording verbatim, add to Directives section with date and source, create enforcement hook if possible, test and wire.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Adding Directives Procedure" for the full workflow and examples.

---

## CLAUDE.md Optimization

CLAUDE.md loads into EVERY conversation. Keep it lean. Move domain-specific content to skills.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "CLAUDE.md Optimization Procedure" for the full workflow, extraction rules, and target structure.

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
- [references/procedures.md](references/procedures.md) — Detailed step-by-step procedures for all commands
