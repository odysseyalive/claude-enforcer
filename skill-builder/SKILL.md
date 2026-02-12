---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new, optimize, agents, hooks, verify, inline"
allowed-tools: Read, Glob, Grep, Write, Edit, TaskCreate, TaskUpdate, TaskList, TaskGet
---

# Skill Builder

## Quick Commands

| Command | Action |
|---------|--------|
| `/skill-builder` | Full audit: runs optimize + agents + hooks in display mode for all skills |
| `/skill-builder audit` | Same as above |
| `/skill-builder audit --quick` | Lightweight audit: frontmatter + line counts + priority fixes only |
| `/skill-builder skills` | List all local skills available in this project |
| `/skill-builder list [skill]` | Show all modes/options for a skill in a table |
| `/skill-builder new [name]` | Create a new skill from template, then review for optimization/enforcement |
| `/skill-builder optimize [skill]` | Display optimization plan for a skill (add `--execute` to apply) |
| `/skill-builder agents [skill]` | Display agent opportunities for a skill (add `--execute` to create) |
| `/skill-builder hooks [skill]` | Display hooks inventory + opportunities (add `--execute` to create) |
| `/skill-builder optimize claude.md` | Optimize CLAUDE.md by extracting domain content into skills |
| `/skill-builder update` | Re-run the installer to update skill-builder to the latest version |
| `/skill-builder verify` | Health check: validate all skills, hooks, and wiring (headless-compatible) |
| `/skill-builder inline [skill] [directive]` | Quick-add a directive to a skill, then review for optimization/enforcement |
| `/skill-builder dev [command]` | Run any command with skill-builder itself included |

---

## The `update` Command

**Re-run the installer to update skill-builder to the latest version.**

When invoked with `/skill-builder update`:

1. Execute the installer script:
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
   ```
2. Report the result to the user

This fetches and runs the latest installer from the repository, which will update all skill-builder files to the current version.

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

## The `verify` Command

**Non-destructive health check for the entire skill system. Headless-compatible.**

When invoked with `/skill-builder verify`:

1. **Scan all skills** — glob `.claude/skills/*/SKILL.md`
2. **For each skill, validate:**
   - Frontmatter exists with `---` delimiters
   - `name` matches folder name
   - `description` is single-line (no `|` or `>` syntax)
   - `allowed-tools` is present
   - Line count is under 150 (excluding reference files)
   - If skill has modes, a Modes table exists
3. **Validate hooks:**
   - All `.sh` files in `hooks/` are executable (`chmod +x`)
   - All hook scripts are wired in `.claude/settings.local.json`
   - All wired hooks point to scripts that exist
4. **Validate agents:**
   - All `.md` files in `agents/` have valid frontmatter
   - Agent files are referenced in parent SKILL.md
5. **Output a pass/fail summary:**

```
## Skill System Health Check

| Check | Status |
|-------|--------|
| Skills found | 5 |
| Frontmatter valid | 5/5 PASS |
| Line targets met | 4/5 WARN (/budget: 172 lines) |
| Hooks wired | 3/3 PASS |
| Hooks executable | 3/3 PASS |
| Agents referenced | 2/2 PASS |

Overall: PASS (1 warning)
```

6. **Exit behavior:** If all checks pass, report PASS. If any FAIL, list failures. This command never modifies files — it only reads and reports.

**Headless usage:** `claude -p "/skill-builder verify"` — suitable for CI, pre-commit, or batch checks.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Verify Command Procedure" before executing.

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
5. **Scope discipline during execution.** Execute ONLY the tasks in the task list. Do not add bonus tasks, expand scope, or create deliverables not in the original plan. If execution reveals a new opportunity, note it in the completion report — do not act on it. The task list is the contract.
6. **Post-action chaining.** Any action that modifies a skill (`new`, `inline`, adding directives) automatically chains into a scoped mini-audit for the affected skill — running optimize, agents, and hooks in display mode, then offering execution choices. Use `--no-chain` to suppress.

---

## Audit Command

**When invoked without arguments or with `audit`, run the full audit as an orchestrator.**

Gathers metrics from CLAUDE.md, rules files, and all skills. Runs optimize + agents + hooks in display mode for each skill. Aggregates into a single report with priority fixes. Offers execution choices.

**Bootstrap mode:** If no skills are found (no `.claude/skills/*/SKILL.md` files exist), the audit switches to bootstrap mode. Instead of reporting "no skills found," it runs the CLAUDE.md Optimization Procedure as its primary action — analyzing CLAUDE.md for extraction candidates, proposing new skills to create, and offering to execute the extraction. This is the expected first-run experience for new installations.

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

## Optimize claude.md Command

**When invoked with `optimize claude.md`, run the CLAUDE.md Optimization Procedure directly.**

This is a standalone command that targets CLAUDE.md itself rather than a skill. It analyzes CLAUDE.md for extraction candidates, proposes new skills, and in execute mode creates them. This is equivalent to what the audit does in bootstrap mode, but can be run explicitly at any time — even when skills already exist.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "CLAUDE.md Optimization Procedure" before executing.

---

## Optimization Targets

See [references/optimization-examples.md](references/optimization-examples.md) for the full table of what can/can't be moved and a before/after example.

---

## Agents Command

**Analyze and create agents for a skill.**

Reads the skill's SKILL.md, evaluates 5 agent types (ID Lookup, Validator, Evaluation, Matcher, Voice Validator) against it, and reports which would help and why. In execute mode, creates agent files from templates.

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

Extract exact wording verbatim, add to Directives section with date and source, then chain into a scoped review for enforcement opportunities.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Adding Directives Procedure" for the full workflow and examples.

---

## Inline Directive Capture

**Quick-add a directive to a skill, then run a scoped review for optimization and enforcement opportunities.**

When invoked with `/skill-builder inline [skill] [directive text]`:

1. Read the target skill's SKILL.md
2. Add the directive verbatim to the `## Directives` section (create the section if it doesn't exist)
3. Add date and source attribution
4. Report what was added
5. Chain into a scoped mini-audit: run optimize, agents, and hooks in display mode for the affected skill, then offer execution choices

Use `--no-chain` to skip the post-action review (e.g., `/skill-builder inline writing --no-chain Never use jargon`).

**Example:**
```
/skill-builder inline writing Never use the phrase "in conclusion" in any article.
```

Adds to `.claude/skills/writing/SKILL.md`:
```markdown
> **Never use the phrase "in conclusion" in any article.**

*— Added 2026-02-11, source: user instruction (inline)*
```

Then automatically reviews the skill for enforcement opportunities — the hooks display mode detects the "Never use" pattern and recommends a grep-block hook, the agents display mode evaluates whether a Voice Validator applies, etc.

**Why this exists:** Supports mid-session learning. When you notice a pattern violation during a writing or editing session, capture it immediately as a directive. The post-action chain ensures enforcement opportunities are surfaced automatically, without requiring a separate audit cycle.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "Inline Directive Procedure" before executing.

---

## New Command

**Create a new skill from template, then automatically review for optimization and enforcement opportunities.**

When invoked with `/skill-builder new [name]`:

1. Validate the skill name (lowercase alphanumeric + hyphens, must not already exist)
2. Detect domain — content-creation vs standard (based on name and user context)
3. Create skill files from template (SKILL.md + reference.md)
4. Report what was created
5. Chain into a scoped mini-audit: run optimize, agents, and hooks in display mode for the new skill, then offer execution choices

Use `--no-chain` to skip the post-action review (e.g., `/skill-builder new my-skill --no-chain`).

**Why this exists:** Creating a skill is just the first step. The post-action chain immediately surfaces what hooks could enforce its directives, what agents could validate its output, and what structural optimizations apply — without requiring the user to remember to run a separate audit.

**Grounding:** Read [references/procedures.md](references/procedures.md) § "New Command Procedure" before executing.

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
