---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new, optimize, agents, hooks, verify, inline, ledger, cascade, checksums, convert"
when_to_use: "When creating, auditing, or optimizing Claude Code skills, or when working with SKILL.md files, hooks, or agents"
argument-hint: "[command] [skill] [--execute]"
version: "1.5"
minimum-effort-level: high
allowed-tools: Read, Glob, Grep, Write, Edit, TaskCreate, TaskUpdate, TaskList, TaskGet
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "\"$CLAUDE_PROJECT_DIR/.claude/skills/skill-builder/hooks/check-persona-uniqueness.sh\""
          if: "Write(**/AGENT.md)|Edit(**/AGENT.md)"
          statusMessage: "Checking persona uniqueness..."
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "\"$CLAUDE_PROJECT_DIR/.claude/skills/skill-builder/hooks/verify-directive-integrity.sh\""
          if: "Edit(**/SKILL.md)|Write(**/SKILL.md)"
          statusMessage: "Verifying directive integrity..."
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: Directives are sacred. Never reword, paraphrase, or summarize text between <!-- origin: user | immutable: true --> markers. Optimization is restructuring, not rewriting. Move content — never rewrite it.\"}'"
          statusMessage: "Re-injecting directive awareness..."
---

# Skill Builder

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Quick Commands

| Command | Action |
|---------|--------|
| `/skill-builder` | Full audit: runs optimize + agents + hooks in display mode for all skills |
| `/skill-builder audit` | Same as above |
| `/skill-builder audit --quick` | Lightweight audit: frontmatter + line counts + priority fixes only |
| `/skill-builder cascade [skill]` | Validation cascade analysis: detect over-validation suppressing output |
| `/skill-builder dev [command]` | Run any command with skill-builder itself included |
<!-- /origin -->

---

<!-- origin: user | added: 2026-02-22 | immutable: true -->
## Directives

> **"When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY, in order to provide additional input in decision making."**

*— Added 2026-02-22, source: user directive*

> **"Each agent being created by this system always has to have an appropriate persona that is not being used anywhere else."**

*— Added 2026-02-22, source: user directive*

> **"When deploying a Team, one of the team member's persona is a research assistant who will research the issue using read-only reference tools. Other team members may also make requests from the research assistant to help augment the outcome."**

*— Added 2026-02-23, source: user directive (tool specifics in references/agents-teams.md)*
<!-- /origin -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY, in order to provide additional input in decision making." -->
CHECKPOINT — Non-Obvious Decision Gate:
1. Before committing to any classification, structural change, or content-removal decision that depends on interpretation, list the decision's alternatives in one sentence each.
2. IF exactly one alternative matches a concrete, measurable criterion (ID match, regex match, frontmatter field present/absent, file exists/absent) → CONTINUE without an agent.
3. IF two or more alternatives are plausible AND the selection requires judgment on wording, scope, priority, or fit → STOP. Spawn at least one agent via the Task tool (or an agent panel per the relevant procedure — e.g., optimize.md § 4b, § 5b) to supply independent input.
4. Read the agent findings. Where agents agree → proceed with the agreed alternative. Where agents disagree → default to the safer/conservative alternative.
5. IF an agent was required but skipped → STOP. Report to user: "Agent consultation skipped for a non-obvious decision. Respawn with agent input before proceeding."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "Each agent being created by this system always has to have an appropriate persona that is not being used anywhere else." -->
CHECKPOINT — Persona Assignment Gate:
1. Before writing or editing any AGENT.md file, extract the proposed persona string from the agent frontmatter.
2. Read references/agents-personas.md § "Persona assignment rules" to confirm the persona fits the agent's stated role (task, scope, perspective).
3. Glob .claude/skills/*/agents/*/AGENT.md and read each file's persona field.
4. IF the proposed persona string matches any existing persona verbatim OR paraphrases one already in use (same core identity, different words) → STOP. Report: "Persona conflicts with [path]: '[existing persona]'. Choose a different persona."
5. IF no duplicate AND the persona fits the role (step 2 passed) → CONTINUE to write the AGENT.md.
6. The Write/Edit PreToolUse hook declared in this SKILL.md frontmatter performs the uniqueness check at tool-call time as a deterministic backstop; the steps above must run during authorship so the hook is never the first signal.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When deploying a Team, one of the team member's persona is a research assistant who will research the issue using read-only reference tools. Other team members may also make requests from the research assistant to help augment the outcome." -->
CHECKPOINT — Team Research Assistant Gate:
1. Detect team deployment: the procedure invokes TeamCreate, uses language like "Spawn teammates", or explicitly assembles multiple parallel agents under one task.
2. IF detected → read references/agents-teams.md § "Individual vs. team routing" for the allowed research-assistant tool list (read-only reference tools).
3. Enumerate the planned team members and their personas. IF none are labeled as the research assistant → STOP. Add a research-assistant team member with the read-only reference toolset from step 2 before spawning.
4. IF a research assistant is present → confirm its allowed-tools contains ONLY read-only reference tools. Strip any write or side-effect tools from the research assistant before spawn.
5. After spawn, surface to other team members: "Research assistant '[persona]' is available for read-only reference queries. Route lookups through the assistant rather than duplicating research."
6. IF a team is deployed without a research assistant (step 3 skipped) → STOP. Report: "Team deployment blocked — no research assistant in team composition."
<!-- END ENFORCEMENT ANNOTATION -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Commands

All commands operate in display mode by default. Add `--execute` to apply changes.
Before executing any command, read its procedure file from `references/procedures/`.

| Command | Procedure | Summary |
|---------|-----------|---------|
| `audit` | [audit.md](references/procedures/audit.md) | Full system audit |
| `audit --quick` | [audit.md](references/procedures/audit.md) | Lightweight: frontmatter + line counts |
| `cascade [skill]` | [cascade.md](references/procedures/cascade.md) | Validation cascade analysis (diagnostic only) |
| `convert [skill]` | [convert.md](references/procedures/convert.md) | Convert 4.6-era skill to 4.7-compatible (annotations + explicit steps) |
| `optimize [skill]` | [optimize.md](references/procedures/optimize.md) | Restructure for context efficiency |
| `optimize claude.md` | [claude-md.md](references/procedures/claude-md.md) | Extract domain content to skills |
| `agents [skill]` | [agents.md](references/procedures/agents.md) | Analyze/create agents |
| `hooks [skill]` | [hooks.md](references/procedures/hooks.md) | Inventory/create hooks |
| `new [name]` | [new.md](references/procedures/new.md) | Create skill from template |
| `inline [skill] [directive]` | [inline.md](references/procedures/inline.md) | Quick-add directive |
| `skills` | [skills.md](references/procedures/skills.md) | List local skills |
| `list [skill]` | [list.md](references/procedures/list.md) | Show modes/options |
| `verify` | [verify.md](references/procedures/verify.md) | Health check (headless-compatible) |
| `ledger` | [ledger.md](references/procedures/ledger.md) | Create Awareness Ledger |
| `checksums [skill]` | [checksums.md](references/procedures/checksums.md) | Generate/verify directive checksums |
| `shell-safety [mode] [path]` | [shell-safety.md](references/procedures/shell-safety.md) | Write / audit / lint shell code and JSON-embedded shell for pitfalls |
| `update` | *(inline below)* | Update to latest version |
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `update` Command

Re-run the installer to update skill-builder to the latest version.

1. Run the installer directly via Bash: `bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"`
2. Tell the user: **"Restart Claude Code to load the updated skill."** The current session still has the old skill loaded in memory, so start a new conversation. Once you're back, run `/skill-builder audit` — updates often add new recommendations that apply to your existing skills.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `convert` Command

Convert existing Opus 4.6-era skills to Opus 4.7-compatible execution. User directives stay verbatim and receive enforcement annotations (machine-generated CHECKPOINT blocks beneath the sacred block); skill-builder machinery (workflow steps, grounding statements) is rewritten in-place for literal execution.

- Display mode (default): `/skill-builder convert [skill]` — report what would change
- Execute mode: `/skill-builder convert [skill] --execute` — apply changes
- Batch display: `/skill-builder convert --all` — summary across all skills
- Batch execute: `/skill-builder convert --all --execute` — convert every skill in sequence (one task per skill; the task list survives context compaction)

High-risk command — defaults to display mode, requires `--execute` to modify files.

**Grounding:** Read [references/procedures/convert.md](references/procedures/convert.md) for the full procedure, [references/templates.md](references/templates.md) § "Enforcement Annotation Template" for the annotation format, and [references/enforcement.md](references/enforcement.md) § "Opus 4.7 Behavioral Contract" for the literal-execution model.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `shell-safety` Command

Write, audit, and lint shell code (scripts, hook commands, JSON-embedded shell strings) against the canonical pitfall rule set. Used internally by `hooks` and `verify`, and available for direct user invocation.

- Write: `/skill-builder shell-safety write [target]` — generate a new script or JSON shell entry from a safe-default template
- Audit: `/skill-builder shell-safety audit [path]` — scan for pitfalls; with `--execute`, patch the mechanical-safe ones
- Lint: `/skill-builder shell-safety lint [file]` — read-only single-file check (exit 1 on findings, composes with `&&`)

**Grounding:** Read [references/procedures/shell-safety.md](references/procedures/shell-safety.md) for the full procedure, [references/shell-safety/rules.md](references/shell-safety/rules.md) for the pitfall catalog, [references/shell-safety/templates.md](references/shell-safety/templates.md) for safe scaffolds, and [references/shell-safety/audit-patterns.md](references/shell-safety/audit-patterns.md) for detection regexes.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Self-Exclusion Rule

**The skill-builder skill MUST be excluded from all actions (audit, optimize, agents, hooks, skills list) unless the command is prefixed with `dev`.**

- `/skill-builder audit` → audits all skills EXCEPT skill-builder
- `/skill-builder optimize some-skill` → works normally
- `/skill-builder optimize skill-builder` → REFUSED. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev optimize skill-builder`"
- `/skill-builder dev audit` → includes skill-builder in the audit
- `/skill-builder dev optimize skill-builder` → allowed

**Detection:** If the first argument after the command is `dev`, strip it and proceed with self-inclusion enabled. Otherwise, skip any skill whose name is `skill-builder` when iterating skills, and refuse if `skill-builder` is explicitly named as a target.

**CHECKPOINT — apply before dispatching to any procedure (Opus 4.7 literal-execution gate):**

1. Parse the invocation. Is the first positional argument the literal string `dev`?
   - YES → `dev_mode = true`; strip `dev` from the argument list; continue.
   - NO  → `dev_mode = false`.
2. Extract the first remaining positional argument as `first_arg`.
3. Define the known-command set: `{ audit, optimize, agents, hooks, new, inline, skills, list, verify, ledger, cascade, checksums, convert, shell-safety, update }`.
4. IF `first_arg` is empty (no arguments remaining) → dispatch to the default full-audit flow per § Quick Commands. Do NOT invoke the intent router. STOP this CHECKPOINT.
5. IF `first_arg` is in the known-command set → treat it as the command name. Determine whether a skill target was specified in the remaining arguments. CONTINUE to step 7.
6. IF `first_arg` is NOT in the known-command set AND the remaining argument string is non-empty →
   - STOP normal dispatch.
   - Ground on [references/procedures/intent-router.md](references/procedures/intent-router.md) (read-before-use).
   - Invoke the Intent Router procedure, passing the full remaining argument string (including `first_arg`) as the freeform intent, and `dev_mode` as context.
   - The router is responsible for either re-dispatching to a known command (in which case resume this CHECKPOINT at step 7 with the router's resolved command and target) or halting with an AskUserQuestion / explanatory message.
   - The router NEVER modifies files; all file-touching work happens in the re-dispatched command.
7. IF `dev_mode == false`:
   - IF the skill target is the literal string `skill-builder` → REFUSE and STOP. Print: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev [command] skill-builder`". Do not dispatch.
   - IF no target was specified (all-skills/iteration mode) → the skill set passed into the procedure MUST have `skill-builder` filtered out before any per-skill iteration begins.
8. IF `dev_mode == true` → skill-builder is included normally.
9. Dispatch to the procedure file.

This CHECKPOINT fires every invocation. Procedure files repeat it in their own preflight blocks for defense in depth — 4.7 executes each file literally, so both gates matter.

**Post-dev check:** After any `dev` command that modifies skill-builder files, verify that the `install` script still covers all files. Glob `skill-builder/**/*.md`, compare against the files downloaded in the installer's loop, and flag any new/renamed/removed files that the installer doesn't handle. This prevents drift between the repo and what users receive on install.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Display/Execute Mode Convention

**Commands are classified by risk level, which determines their default mode:**

| Risk | Commands | Default Mode |
|------|----------|-------------|
| **Low-risk** (additive, non-destructive) | `new`, `inline`, `skills`, `list`, `verify`, `ledger`, `checksums` | **Execute directly** |
| **High-risk** (restructuring, modifying) | `optimize`, `agents`, `hooks`, `audit`, `cascade`, `convert` | **Display mode** (requires `--execute`) |

| Mode | Behavior | Flag |
|------|----------|------|
| **Display** | Read-only plan of what would change | *(default for high-risk)* |
| **Execute** | Apply changes to files | `--execute` or *(default for low-risk)* |

### Rules

1. **Low-risk commands execute immediately.** `new`, `inline`, `skills`, `list`, `verify`, `ledger`, and `checksums` do their work directly without requiring `--execute`. They are additive or read-only — there is nothing to preview.
2. **High-risk commands default to display mode.** Running `/skill-builder optimize my-skill` shows what *would* change without modifying anything. Add `--execute` to apply.
3. **Audit always calls sub-commands in display mode**, then offers the user a choice of which to execute.
4. **Execution requires a task plan.** When a high-risk command runs with `--execute`, the command MUST:
   - First produce a numbered task list using TaskCreate, one task per discrete action
   - Execute each task sequentially, marking progress via TaskUpdate
   - This ensures context can be refreshed mid-execution without losing track, no tasks get forgotten during long context windows, and the user can see progress and resume if interrupted
5. **Scope discipline during execution.** Execute ONLY the tasks in the task list. Do not add bonus tasks, expand scope, or create deliverables not in the original plan. If execution reveals a new opportunity, note it in the completion report — do not act on it. The task list is the contract.
6. **Post-action chaining.** Any action that modifies a skill (`new`, `inline`, adding directives) automatically chains into a scoped mini-audit for the affected skill — running optimize, agents, and hooks in display mode, then offering execution choices. Use `--no-chain` to suppress.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Core Principles

**Read [references/principles.md](references/principles.md) before running any high-risk command** (`optimize`, `agents`, `hooks`, `audit`, `cascade`, `convert`). That file contains the full Core Principles, Sacred Directive Pattern, Output Discipline rules, and Grounding Protocol. It was split out of SKILL.md during the 4.7 upgrade to reduce always-loaded context weight.

**IMPORTANT: Never break anything.** Optimization is RESTRUCTURING, not REWRITING. MOVE content, don't rewrite it. PRESERVE all directives exactly. KEEP all workflows intact. If the original author reviewed the result, they should say "this does exactly what mine did, just organized differently."
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Grounding

Grounding protocol (read-before-use, state which pattern will be used) is documented in [references/principles.md](references/principles.md) § "Grounding Protocol".

Reference files:
- [references/principles.md](references/principles.md) — Core Principles, Sacred Directive Pattern, Output Discipline, Grounding Protocol (READ FIRST for high-risk commands)
- [references/enforcement.md](references/enforcement.md) — Hook JSON, permissions, context mutability, provenance permission model
- [references/agents.md](references/agents.md) — Agent templates, opportunity detection, creation workflow
- [references/agents-personas.md](references/agents-personas.md) — Persona assignment rules, selection heuristic, research backing
- [references/agents-teams.md](references/agents-teams.md) — Individual vs. team routing, invocation patterns, mandatory agent situations
- [references/templates.md](references/templates.md) — Skill directory layout, SKILL.md template, frontmatter
- [references/optimization-examples.md](references/optimization-examples.md) — Before/after examples, optimization targets
- [references/portability.md](references/portability.md) — Install instructions, rule-to-skill conversion
- [references/patterns.md](references/patterns.md) — Lessons learned
- [references/platform.md](references/platform.md) — Claude Code skill platform architecture, frontmatter fields, listing budget, invocation flow
- [references/token-efficiency.md](references/token-efficiency.md) — Token-intensive pattern catalog and Token Efficiency Scan rules (optimize step 4e)
- [references/temporal-validation.md](references/temporal-validation.md) — Temporal risk classification, phrase mappings, hook generation spec
- [references/ledger-templates.md](references/ledger-templates.md) — Awareness Ledger record templates, agent definitions, consultation protocol
- [references/procedures/](references/procedures/) — Per-command procedure files (audit, verify, optimize, agents, hooks, new, inline, ledger, cascade, checksums, shell-safety, etc.)
- [references/procedures/checksums.md](references/procedures/checksums.md) — Directive checksum generation spec (scripts generated at runtime, not shipped)
- [references/procedures/shell-safety.md](references/procedures/shell-safety.md) — Shell-safety subcommand procedure (write / audit / lint)
- [references/shell-safety/](references/shell-safety/) — Shell-safety rule set (rules.md, templates.md, audit-patterns.md) — the canonical pitfall catalog used by hooks, verify, and shell-safety
- [agents/optimize-diff-auditor/](agents/optimize-diff-auditor/) — Post-optimize semantic equivalence verification agent
<!-- /origin -->
