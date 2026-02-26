---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new, optimize, agents, hooks, verify, inline, ledger"
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
| `/skill-builder ledger` | Awareness Ledger: create institutional memory for a project |
| `/skill-builder self-heal` | Install the Self-Heal companion skill |
| `/skill-builder dev [command]` | Run any command with skill-builder itself included |

---

## Directives

> **"When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY, in order to provide additional input in decision making."**

*— Added 2026-02-22, source: user directive*

> **"Each agent being created by this system always has to have an appropriate persona that is not being used anywhere else."**

*— Added 2026-02-22, source: user directive*

> **"When deploying a Team, one of the team member's persona is a research assistant who will always use the preferred web search and page fetch tools to research the issue online. Other team members may also make requests from the research assistant to help augment the outcome."**

*— Added 2026-02-23, source: user directive*

---

## The `update` Command

**Re-run the installer to update skill-builder to the latest version.**

When invoked with `/skill-builder update`:

1. Execute the installer script:
   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
   ```
2. Report the result to the user
3. Tell the user: **"Restart Claude Code to load the updated skill."** The current session still has the old skill loaded in memory, so start a new conversation. Once you're back, run `/skill-builder audit` — updates often add new recommendations that apply to your existing skills.

---

## The `skills` Command

**List all local skills available in this project.**

Globs for all `.claude/skills/*/SKILL.md`, reads frontmatter, outputs a table of skill names and descriptions.

**Grounding:** Read [references/procedures/skills.md](references/procedures/skills.md) before executing.

---

## The `list` Mode Requirement

**Every skill with multiple modes MUST support a `list` mode.** This is a reserved mode name.

When invoked with `list`, read the skill's SKILL.md, find the Modes table, and output it directly. When auditing, verify multi-mode skills have a Modes table in consistent format.

**Grounding:** Read [references/procedures/list.md](references/procedures/list.md) before executing.

---

## The `verify` Command

**Non-destructive health check for the entire skill system. Headless-compatible.**

Scans all skills, validates frontmatter, line counts, hook wiring, and agent references. Outputs a pass/fail summary. Never modifies files.

**Headless usage:** `claude -p "/skill-builder verify"` — suitable for CI, pre-commit, or batch checks.

**Grounding:** Read [references/procedures/verify.md](references/procedures/verify.md) before executing.

---

## Self-Exclusion Rule

**The skill-builder skill MUST be excluded from all actions (audit, optimize, agents, hooks, skills list) unless the command is prefixed with `dev`.**

- `/skill-builder audit` → audits all skills EXCEPT skill-builder
- `/skill-builder optimize some-skill` → works normally
- `/skill-builder optimize skill-builder` → REFUSED. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev optimize skill-builder`"
- `/skill-builder dev audit` → includes skill-builder in the audit
- `/skill-builder dev optimize skill-builder` → allowed

**Detection:** If the first argument after the command is `dev`, strip it and proceed with self-inclusion enabled. Otherwise, skip any skill whose name is `skill-builder` when iterating skills, and refuse if `skill-builder` is explicitly named as a target.

**Self-heal exception:** `/skill-builder self-heal` installs self-heal and is not subject to exclusion — this is installation, not analysis. However, self-heal integration embedded in other skills IS subject to self-exclusion — skill-builder does not embed self-heal awareness into itself.

**Post-dev check:** After any `dev` command that modifies skill-builder files, verify that the `install` script still covers all files. Glob `skill-builder/**/*.md`, compare against the files downloaded in the installer's loop, and flag any new/renamed/removed files that the installer doesn't handle. This prevents drift between the repo and what users receive on install.

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

**Grounding:** Read [references/procedures/audit.md](references/procedures/audit.md) before executing.

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

When a user gives you a rule, store it verbatim in a `## Directives` section with exact wording, source, and date. Place at TOP of skill file. NEVER summarize or reword. Enforce with hooks when possible.

**Grounding:** Read [references/templates.md](references/templates.md) § "SKILL.md Template" and [references/procedures/directives.md](references/procedures/directives.md) for format and workflow.

---

## Enforcement Mechanisms

See [references/enforcement.md](references/enforcement.md) for hook JSON examples, permission patterns, subagent YAML, and context mutability theory.

---

## Optimize Command

**Restructure a specific skill for optimal context efficiency.**

Reads the skill's SKILL.md, runs a per-skill audit checklist (frontmatter, directives, reference material, enforcement, line count), identifies optimization targets, and lists proposed changes. In execute mode, generates a task list and applies changes sequentially.

**Reference splitting:** When a skill's `reference.md` exceeds 100 lines with 3+ h2 sections (each >20 lines), the optimizer proposes splitting into a `references/` directory with domain-specific files. Each split file becomes an **enforcement boundary** — hooks and agents can attach per-file, enabling granular drift resistance. See [references/procedures/optimize.md](references/procedures/optimize.md) § "Evaluate Reference Splitting" for thresholds and enforcement priority heuristics.

**Grounding:** Read [references/procedures/optimize.md](references/procedures/optimize.md) before executing. Also consult `references/optimization-examples.md` and `references/templates.md`.

---

## Optimize claude.md Command

**When invoked with `optimize claude.md`, run the CLAUDE.md Optimization Procedure directly.**

This is a standalone command that targets CLAUDE.md itself rather than a skill. It analyzes CLAUDE.md for extraction candidates, proposes new skills, and in execute mode creates them. This is equivalent to what the audit does in bootstrap mode, but can be run explicitly at any time — even when skills already exist.

**Grounding:** Read [references/procedures/claude-md.md](references/procedures/claude-md.md) before executing.

---

## Optimization Targets

See [references/optimization-examples.md](references/optimization-examples.md) for the full table of what can/can't be moved and a before/after example.

---

## Agents Command

**Analyze and create agents for a skill.**

Reads the skill's SKILL.md, evaluates 5 agent types (ID Lookup, Validator, Evaluation, Matcher, Voice Validator) against it, and reports which would help and why. Routes each recommendation to either **individual agents** (isolated evaluation with independent opinions) or **agent teams** (collaborative execution with shared task lists). Every agent gets a unique persona — no exceptions.

**Mandatory research assistant in teams:** When routing recommends an agent team, a research assistant teammate is always included. This teammate uses WebSearch, WebFetch, and Jina MCP tools to gather online information, and other teammates can send research requests to it. The research assistant is mandatory infrastructure and is not counted against the agent panel's recommendations.

**Mandatory agent situations:** When the analysis identifies non-obvious decisions where guessing is involved, agents are flagged as mandatory per directive. The report includes a "Mandatory Agent Situations" section listing these.

**Grounding:** Read [references/procedures/agents.md](references/procedures/agents.md) before executing. Also consult `references/agents.md` — especially § "Persona Assignment," § "Individual Agents vs. Agent Teams," and § "When Agents Are Mandatory."

---

## Hooks Command

**Inventory existing hooks and identify new enforcement opportunities.**

Scans for hook scripts and wiring in settings.local.json, validates existing hooks (wired, matcher, exit codes, stdin, permissions, stderr, scoping), identifies new opportunities from directive patterns, and generates a report. In execute mode, creates scripts and wires them. Style/content hooks must self-scope to skip `.claude/` infrastructure files.

**Grounding:** Read [references/procedures/hooks.md](references/procedures/hooks.md) before executing. Also consult `references/enforcement.md`.

---

## Skill File Structure & Templates

See [references/templates.md](references/templates.md) for directory layout, SKILL.md template, and frontmatter requirements with YAML examples.

---

## Adding Directives to Existing Skills

Extract exact wording verbatim, add to Directives section with date and source, then chain into a scoped review for enforcement opportunities.

**Grounding:** Read [references/procedures/directives.md](references/procedures/directives.md) for the full workflow and examples.

---

## Inline Directive Capture

**Quick-add a directive to a skill without running a full audit cycle.**

When invoked with `/skill-builder inline [skill] [directive text]`, reads the target SKILL.md, adds the directive verbatim to the `## Directives` section with date/source, and suggests enforcement if the directive is programmable. Supports mid-session learning.

**Grounding:** Read [references/procedures/inline.md](references/procedures/inline.md) before executing.

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

**Grounding:** Read [references/procedures/new.md](references/procedures/new.md) before executing.

---

## Ledger Command

**Create an Awareness Ledger companion skill for institutional memory.**

When invoked with `/skill-builder ledger`:

1. Validate the project (CLAUDE.md must exist, awareness-ledger must not already exist)
2. Create the awareness-ledger skill structure (SKILL.md, references, agents, hooks, ledger directories)
3. Seed the ledger by scanning git history, CLAUDE.md, and TODO/FIXME comments for initial records
4. Report what was created
5. Chain into a scoped mini-audit: run optimize, agents, and hooks in display mode for the new skill

Use `--execute` to create files. Default is display mode (shows what would be created). Use `--no-chain` to skip the post-action review.

**Grounding:** Read [references/procedures/ledger.md](references/procedures/ledger.md) before executing. Also consult `references/ledger-templates.md` for record type templates, agent definitions, hook script, and consultation protocol.

---

## Self-Heal Command

**Install the Self-Heal companion skill — ambient friction detection and surgical skill correction.**

When invoked with `/skill-builder self-heal`:

Installs a companion skill that embeds friction-detection awareness into all skills. During live sessions, each skill quietly watches for signals that its own instructions caused a misrepresentation or unnecessary friction. At natural task resolution, if a fixable source is found in the skill's instructions, self-heal proposes a surgical update — showing an exact before/after diff — and asks for approval before changing anything.

Use `--execute` to create files. Default is display mode.

**Grounding:** Read [references/procedures/self-heal.md](references/procedures/self-heal.md) before executing.

---

## CLAUDE.md Optimization

CLAUDE.md loads into EVERY conversation. Keep it lean. Move domain-specific content to skills.

**Grounding:** Read [references/procedures/claude-md.md](references/procedures/claude-md.md) for the full workflow, extraction rules, and target structure.

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
- [references/agents-personas.md](references/agents-personas.md) — Persona assignment rules, selection heuristic, research backing
- [references/agents-teams.md](references/agents-teams.md) — Individual vs. team routing, invocation patterns, mandatory agent situations
- [references/templates.md](references/templates.md) — Skill directory layout, SKILL.md template, frontmatter
- [references/optimization-examples.md](references/optimization-examples.md) — Before/after examples, optimization targets
- [references/portability.md](references/portability.md) — Install instructions, rule-to-skill conversion
- [references/patterns.md](references/patterns.md) — Lessons learned
- [references/ledger-templates.md](references/ledger-templates.md) — Awareness Ledger record templates, agent definitions, consultation protocol
- [references/procedures/self-heal.md](references/procedures/self-heal.md) — Self-Heal companion skill installation procedure
- [references/self-heal-templates.md](references/self-heal-templates.md) — Friction detection instructions, diff format, update protocol templates
- [references/procedures/](references/procedures/) — Per-command procedure files (audit, verify, optimize, agents, hooks, new, inline, ledger, etc.)
