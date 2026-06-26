# Claude Enforcer Commands

Every `/skill-builder` command, grouped by what it does. Each entry answers what the command does, when to reach for it, a concrete example, and where to find the full procedure inside the installed skill when you want the depth.

For the narrative framing of this tool, see [README.md](README.md). This file is the technical reference.

---

## Inspection & Diagnostics

Commands that read without modifying. Safe to run any time.

### `/skill-builder audit`

**What it does.** Full audit of CLAUDE.md, your rules, and every installed skill. Runs `optimize`, `agents`, and `hooks` in display mode, aggregates findings, flags priority fixes. As of the Opus 4.7 upgrade, the audit also runs a Token Efficiency Scan on each skill (see [Technical Background § Token Efficiency](#token-efficiency--strictness)). When model lanes are configured, every full interactive audit also re-confirms the Lane to Model mapping via a batched picker (options: `claude-opus-4-6`, `claude-opus-4-8`, and the latest released model discovered live by official ID), scans lane-declared skills for uncovered cross-lane excursion steps and legacy mid-workflow switch prompts, and flags any agent missing an explicit `model:` field. A confirmed remap rewrites the `model:` line of every generated lane-pinned agent.

**When to use.** Quarterly health check. After any Claude model update. Any time a project starts feeling "off" and you need a full picture of what's drifting.

**Example.**
```
/skill-builder audit
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/audit.md`

---

### `/skill-builder audit --quick`

**What it does.** Lightweight audit. Frontmatter validity, line counts, hook wiring, priority fixes only. No deep structural analysis. No agent panels. Completes fast.

**When to use.** Iterative work sessions where a full audit would slow you down.

**Example.**
```
/skill-builder audit --quick
```

**Under the hood.** Same procedure file as `audit`. The `--quick` flag branches early.

---

### `/skill-builder verify`

**What it does.** Non-destructive health check that validates every skill, hook, and wiring. Headless-compatible, meaning `claude -p "/skill-builder verify"` works from CI or a pre-commit script.

**When to use.** CI pipelines and pre-commit scripts, where you need a go/no-go without modifying anything.

**Example.**
```
/skill-builder verify
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/verify.md`

---

### `/skill-builder skills`

**What it does.** Lists every skill installed in the current project, with a one-line description of each.

**When to use.** When you don't remember what's already here. Useful in a new session, or when onboarding a collaborator to a project.

**Example.**
```
/skill-builder skills
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/skills.md`

---

### `/skill-builder list [skill]`

**What it does.** Shows all modes, subcommands, and options for a specific skill. Useful for skills with multi-mode entry points like `/awareness-ledger record|consult|review`.

**When to use.** Before invoking a skill you don't use often, to remind yourself what options exist.

**Example.**
```
/skill-builder list awareness-ledger
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/list.md`

---

### `/skill-builder cascade [skill]`

**What it does.** Analyzes a specific skill for validation cascade risk. Too many validators firing on the same action. Over-validation suppressing output. Diagnostic only. Does not modify anything.

**When to use.** When you suspect a skill is running "too heavy" and you want to see how many hooks and agents actually fire on a typical invocation.

**Example.**
```
/skill-builder cascade writing
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/cascade.md`

---

## Creating & Adding

Commands that produce new artifacts. Low-risk, additive only.

### `/skill-builder new [name]`

**What it does.** Creates a skill from scratch. Invoked either as `/skill-builder new [name]` with a skill name, or conversationally with a description like `/skill-builder I need a skill for deploying to production`. Drafts the frontmatter, directives, workflow, and reference structure based on what you describe. New skills default to `strictness: standard`.

**When to use.** Whenever a pattern is worth capturing as its own skill. If you find yourself giving the same instructions across sessions, that's a new skill waiting to happen.

**Example.**
```
/skill-builder new deploy
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/new.md`

---

### `/skill-builder inline [skill] [directive]`

**What it does.** Quick-adds a directive to an existing skill, verbatim, with date and source attribution. Does not modify directive wording. If the directive is mechanically enforceable (contains "never" or "always" with a specific value), skill-builder suggests a hook but does not create one unless you ask.

**When to use.** Mid-session capture. Claude drifts in a specific way, you see the pattern, you want to prevent it permanently without breaking the flow of what you're doing.

**Example.**
```
/skill-builder inline writing Never use the phrase "in conclusion" in any article.
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/inline.md`

---

### `/skill-builder ledger`

**What it does.** Creates the Awareness Ledger companion skill. The institutional-memory layer that records incidents, decisions, patterns, and flows for the project. Seeds the initial records by scanning git history, CLAUDE.md, and TODO/FIXME comments.

**When to use.** When a project is mature enough that conversations repeat ("didn't we already debug this?"), or when decisions made in one session need to survive into the next.

**Example.**
See what would be created.

```
/skill-builder ledger
```

Create it.

```
/skill-builder ledger --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/ledger.md`. See also [Technical Background § The Awareness Ledger](#the-awareness-ledger).

---

## Removing

Commands that delete skills and clean up after them. Destructive, so they default to display mode. Add `--execute` to apply.

### `/skill-builder strip [skill]`

**What it does.** Deletes a skill completely and removes every cross-reference to it from the rest of the project. Sweeps grounding links, slash-skill prose mentions, route catalog rows, `ROUTE-EMBED` blocks, hook bindings in `settings.local.json`, `Skill()` and `Read()` permission entries, AGENT.md grounding, hook script bodies, and dev-repo manifests like the installer. Auto-runs `route index --execute` after deletion so the catalog drops the target. Display mode by default. Add `--execute` to apply the plan.

**When to use.** When a skill is no longer earning its keep. The directive moved into another skill. The workflow stopped getting invoked. A refactor is absorbing one skill into another. The deprecation cycle is over and the leftover files just need to go.

**Example.**
Display mode shows the impact report.

```
/skill-builder strip my-old-skill
```

Apply the plan.

```
/skill-builder strip my-old-skill --execute
```

When the report flags BREAKING because other skills hard-depend on the target (workflow Reads, hook scripts, AGENT.md grounding), an additional confirmation flag is required.

```
/skill-builder strip my-old-skill --execute --confirm-breaking
```

**Stripping skill-builder is hard-refused.** Even with the `dev` prefix. The prefix permits self-modification, not self-deletion. To uninstall skill-builder, close the session, remove `.claude/skills/skill-builder/` manually, and rerun the installer if you want it back.

**Under the hood.** `.claude/skills/skill-builder/references/procedures/strip.md`. The procedure documents 15 detection patterns for cross-references, the dependent classification (HARD vs SOFT), and the strict task ordering that sweeps every reference before deleting the directory.

---

## Backup & Restore

Snapshot and recover the project's Claude configuration, so a clean uninstall of claude-enforcer is always reversible. The audit offers a backup right after the disclaimer (its Step 0.2 question), and both are also standalone commands. No script ships with either. They are markdown procedures that drive host-generated commands, cross-platform by reading the session `Platform:` line, using `zip`/`unzip` on Linux and macOS and `Compress-Archive`/`Expand-Archive` on Windows.

### `/skill-builder backup`

**What it does.** Zips `CLAUDE.md` and the `.claude/` directory into `.claude-backups/` at the repo root, a sibling of `.claude/` so the archive never swallows its own output. Keeps the last **3 rotating** snapshots plus one pinned **baseline**, the first-ever backup, which rotation never removes, preserving your original CLAUDE.md and skill set forever. Adds `.claude-backups/` to `.gitignore` only if a `.gitignore` already exists. The create is atomic (temp, verify, rename) so an interrupted run never leaves a poisoned snapshot. It also drops a host-generated restore kit (`RESTORE-README.md` plus `restore.sh`/`.ps1`) into `.claude-backups/`, so the baseline restores even after the skill is uninstalled. Low-risk and additive, writing only into `.claude-backups/`, so it executes immediately.

**When to use.** Before a risky change to your Claude config. Before uninstalling claude-enforcer. The audit also offers it at Step 0.2 and runs it first in its execution phase, so the snapshot captures true pre-audit state.

**Example.**
```
/skill-builder backup
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/backup.md`

---

### `/skill-builder restore [snapshot]`

**What it does.** Restores `CLAUDE.md` and `.claude/` from a chosen snapshot, either the baseline, a rotating snapshot, or a pre-restore safety snapshot. The destructive mirror of `backup`: it overwrites the live tree, so it defaults to display mode, listing the available snapshots and a blast-radius diff. Add `--execute` plus a confirmation to apply. Before overwriting anything it takes an automatic pre-restore snapshot (its own undo, exempt from rotation), checks VCS state the way audit does, and verifies the source archive's integrity before trusting it. The audit **never** auto-fires restore. Recovery is always a deliberate, separate act.

**When to use.** To roll back a Claude config you regret. To perform a clean uninstall of claude-enforcer by restoring the baseline, returning the project to its original CLAUDE.md and skill set.

**Example.**
Display mode lists snapshots and the diff.

```
/skill-builder restore
```

Apply a chosen snapshot.

```
/skill-builder restore baseline --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/restore.md`

---

## Restructuring & Enforcement

Commands that reshape existing skills or add enforcement machinery. High-risk, so they default to display mode. Add `--execute` to apply.

### `/skill-builder optimize [skill]`

**What it does.** Restructures a skill for context efficiency. Moves reference tables to `reference.md`, splits oversized SKILL.md files into `references/` directories, adds grounding links, classifies directives as HARD or SOFT for 4.7 enforcement annotations. The Token Efficiency Scan (step 4e) also runs, flagging agent hooks that could downshift, `xhigh` effort levels that aren't justified, and always-spawned validators that could gate on a precheck.

**When to use.** When a skill has grown past 150 lines. When SKILL.md is carrying machinery that doesn't belong there. When an audit flags it. When you want to see what could be trimmed without actually trimming.

**Example.**
Display mode.

```
/skill-builder optimize writing
```

Apply changes.

```
/skill-builder optimize writing --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/optimize.md` plus `.claude/skills/skill-builder/references/token-efficiency.md` for the scan rules.

---

### `/skill-builder agents [skill]`

**What it does.** Analyzes a skill's directives and suggests where agents could help. Individual agents (independent perspectives for evaluation) versus agent teams (coordinated implementation across files). Each agent suggestion includes a distinct persona per the cross-skill uniqueness rule. For skills with a declared model lane, it also detects cross-lane excursion steps (research inside a creative skill, prose inside a coding skill) and designs bespoke lane-pinned excursion agents: subagents whose `model:` frontmatter carries the other lane's full model ID, so the step runs on the right model without prompting a mid-workflow `/model` switch. Every agent it creates or modifies during an audit gets an explicit `model:` per the user's lane choices.

**When to use.** When a skill's directives involve judgment or cross-file validation that hooks can't mechanically catch. When you want to know whether a skill should spawn validators, and what kind.

**Example.**
Display mode.

```
/skill-builder agents edit
```

Create the agent files.

```
/skill-builder agents edit --execute
```

Include agent panels for ambiguity review.

```
/skill-builder agents edit --deliberate
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/agents.md`. See [Technical Background § Individual Agents vs Agent Teams](#individual-agents-vs-agent-teams).

---

### `/skill-builder hooks [skill]`

**What it does.** Inventories existing hooks for a skill and identifies new opportunities. For each directive, decides whether the right enforcement is a command hook (grep-block, require-pattern, threshold), a prompt hook (semantic check), or an agent hook (multi-file analysis). Delegates shell-level pitfall checks to the `shell-safety` subcommand.

**When to use.** When a skill has directives that should be mechanically enforced but aren't yet. When an audit flags "directives could be enforced by hooks" for a particular skill.

**Example.**
Display mode.

```
/skill-builder hooks deploy
```

Create and wire the hooks.

```
/skill-builder hooks deploy --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/hooks.md`

---

### `/skill-builder checksums [skill]`

**What it does.** Generates or verifies the `.directives.sha` sidecar for a skill. The sidecar hashes each sacred directive block, so any drift in user-directive wording gets caught by the `verify-directive-integrity.sh` hook that runs on every SKILL.md edit.

**When to use.** After creating or modifying a skill's directives, to seal the sidecar. After any `optimize --execute` or `convert --execute` run, to refresh the sidecar since the surrounding structure may have changed.

**Example.**
Check whether the sidecar matches.

```
/skill-builder checksums voice
```

Generate or refresh the sidecar.

```
/skill-builder checksums voice --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/checksums.md`

---

### `/skill-builder local-mode`

**What it does.** Audits the project for local LLM compatibility. Classifies every skill as Ready (under 100 lines, no agent spawning), Needs Trimming (over 100 lines), or Incompatible (spawns agents or depends on subprocesses, so disabled in local mode), checks CLAUDE.md against a 100-line limit, and reports whether the local-mode infrastructure (`.claude/skills/local/` plus the `detect-local-mode.sh` SessionStart hook) is installed. With `--execute`, builds a task list to optimize oversized skills (each optimization still presented for approval), flag CLAUDE.md for manual trimming, and install the missing local infrastructure.

**When to use.** Before pointing a project at a local model (Ollama or similar) with a small context window, or any time you want to know how much of your skill system would survive off the frontier models.

**Example.**
```
/skill-builder local-mode
```

Apply the setup.

```
/skill-builder local-mode --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/local-mode.md`

---

## Upgrading to Opus 4.7

Commands specific to the 4.6 to 4.7 migration. These recalibrate skills for Opus 4.7's literal execution style. Display mode by default for all three.

### `/skill-builder convert [skill]`

**What it does.** Converts a single skill from 4.6-era inference-friendly phrasing to 4.7-compatible literal execution. User directives stay verbatim. Sacred as always. Each SOFT directive gets an enforcement annotation (a numbered CHECKPOINT block beneath it), workflow steps get rewritten for explicit execution, a `minimum-effort-level` lands in frontmatter, and a Phase 0 assessment gets added where vague input enters.

**When to use.** After updating Claude Code to a version that uses Opus 4.7. On any skill that was authored against 4.6 behaviors. When an audit flags "needs convert" on a specific skill.

**Example.**
Display mode.

```
/skill-builder convert voice
```

Apply changes.

```
/skill-builder convert voice --execute
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/convert.md`

---

### `/skill-builder convert --all`

**What it does.** Batch display mode. Runs the conversion analysis on every skill in the project (except skill-builder itself) and produces a summary table showing which skills need converting. No files modified.

**When to use.** After upgrading to a Claude Code on Opus 4.7. Gives you a full map of conversion work before you commit to any of it.

**Example.**
```
/skill-builder convert --all
```

**Under the hood.** Same procedure file as `convert`, batch display section.

---

### `/skill-builder convert --all --execute`

**What it does.** Batch execute mode. Converts every skill in the project sequentially. Generates a thin top-level plan (the discovered skill list) plus a TaskCreate task list with one task per skill. Each task invokes the per-skill conversion, which manages its own inner task list. The batch task list persists through context compaction, so a long run can resume where it left off.

**When to use.** When you've reviewed the `--all` summary and want to convert every flagged skill in one run. Safer than running `--execute` on each skill manually, because the task list keeps track even if the session hits context limits.

**Example.**
```
/skill-builder convert --all --execute
```

**Under the hood.** Same procedure file as `convert`, batch-execute section.

---

## Subsystems

Specialized procedures invoked through skill-builder. The `shell-safety` subcommand was absorbed into skill-builder during the 4.7 upgrade. In older installs it was a separate skill.

### `/skill-builder shell-safety lint [file]`

**What it does.** Read-only single-file check for shell-safety pitfalls. Path-quoting, ERR traps, defensive stdin, `set -e` foot-guns, grep pattern issues, JSON-embedded shell quoting. Exits 0 on clean, exit 1 on findings. Composes with `&&` for pre-commit or headless use.

**When to use.** Before committing a shell script or `.claude/settings*.json` edit. In a pre-commit hook. Any time you want to confirm a single file is shell-pitfall clean.

**Example.**
```
/skill-builder shell-safety lint .claude/settings.local.json
```

Compose with `&&` for pre-commit or headless use.

```
claude -p "/skill-builder shell-safety lint my-script.sh" && echo "clean"
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/shell-safety.md` plus `.claude/skills/skill-builder/references/shell-safety/` for the rule catalog.

---

### `/skill-builder shell-safety audit [path]`

**What it does.** Scans a directory for pitfalls. Reports findings per file with severity levels (HARD = mechanical fix, SOFT = needs judgment). Does not modify by default. Add `--execute` to patch the mechanical-safe findings, which creates `.bak` files before rewriting.

**When to use.** After generating hooks via `/skill-builder hooks --execute`. After any significant change to `.claude/settings.local.json`. Periodically on `.claude/skills/*/hooks/` to catch drift.

**Example.**
Display mode.

```
/skill-builder shell-safety audit .claude/
```

Patch the mechanical-safe findings.

```
/skill-builder shell-safety audit .claude/ --execute
```

**Under the hood.** Same procedure file as `lint`.

---

### `/skill-builder shell-safety write [target]`

**What it does.** Generates a new shell script or JSON-embedded shell entry from a safe-default template. Hook scripts, settings.local.json entries, standalone scripts. Each has its own template with the safety basics pre-applied (ERR trap, defensive stdin, scope check, path quoting).

**When to use.** Whenever you're about to write shell code by hand. Even better, let `/skill-builder hooks` invoke this for you automatically when it generates a new hook script.

**Example.**
```
/skill-builder shell-safety write hook .claude/skills/deploy/hooks/check-tests-ran.sh
```

**Under the hood.** Same procedure file as `lint`.

---

## Routing

The route system gives the AI a canonical way to find the right skill for a task instead of freelancing its own tool calls. Two skill-builder subcommands maintain it. A user-facing `/route` skill consumes the index and dispatches.

The audit appends both subcommands as its final two task list items. Running `/skill-builder audit` and accepting the execution menu keeps the index and the consultation gates current.

### `/skill-builder route index`

**What it does.** Scans every installed skill, extracts name, description, modes, and trigger phrases, and writes the catalog into `/route`'s `references/index.md`. Bootstraps the `/route` skill from a template if it doesn't exist yet. Diffs against the prior index and reports what's NEW, REMOVED, UPDATED, or UNCHANGED. Default mode is execute (low-risk; only writes auto-generated content inside `/route`).

**When to use.** After adding, renaming, or removing a skill. After editing a skill's frontmatter description or modes. The audit runs this automatically as the second-to-last task item.

**Example.**
```
/skill-builder route index
```

Display-only summary without writing.

```
/skill-builder route index --dry-run
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/route.md` defines the inventory, diff, and bootstrap behavior. The `/route` SKILL.md template lives at the bottom of the same file.

---

### `/skill-builder route embed`

**What it does.** For each installed skill, classifies whether a Route Consultation Gate belongs in its SKILL.md based on workflow heuristics (skills with research, web search, or open-ended follow-up steps qualify). Reconciles the classification against any existing `<!-- ROUTE-EMBED START -->` markers and labels each skill NEW, REFRESH, REMOVE, or NOOP. The same run reconciles all four managed-block families: `ROUTE-EMBED`, `CODE-EVAL-EMBED`, the `MODEL-LANE-GATE` primary-lane preflight, and the `LANE-AGENT-EMBED` Excursion Delegation Map (reconcile-only: delegation maps are created by `/skill-builder agents`, which designs bespoke lane-pinned excursion agents so cross-lane workflow steps run on the other lane's model via a pinned subagent instead of prompting a mid-workflow `/model` switch). `--remove [skill]` strips all four. Display mode by default; `--execute` applies the plan.

**When to use.** After adding new skills with open-ended workflow steps. After significantly restructuring a skill's workflow. The audit runs this automatically as the last task item, immediately after `route index`.

**Example.**
Display mode.

```
/skill-builder route embed
```

Apply the plan.

```
/skill-builder route embed --execute
```

Manually opt a single skill out of the gate.

```
/skill-builder route embed --remove [skill]
```

**Under the hood.** Same procedure file as `index`. The embed block uses START and END HTML comments as replacement anchors so re-runs are idempotent. Hand edits to the auto-generated block are not preserved.

---

### `/skill-builder route lane-status [skill]`

**What it does.** Read-only legibility report for the 2-Brain Harness. For one skill (or all lane-declared skills when no target is given), prints the resolved lane and its provenance, preferred vs. active model, gate state (embedded, off, or suppressed and why), and a one-line verdict: "no prompt expected; silence is correct" or "would prompt at next invocation." Run for all skills, it ends with the coverage accounting line (N declared, M none, K gate-off, J undeclared). Answers "why wasn't I prompted?" without re-deriving the logic by hand.

**When to use.** Whenever gate silence is surprising. After declaring or changing lanes. After a `/model` switch mid-session.

**Example.**

```
/skill-builder route lane-status study-prep
```

**Under the hood.** Same procedure file as `index` (the Mode: `lane-status` section). Reads `model-lanes.md` and the session's model line. Writes nothing, never prompts.

---

### `/route [task description]`

**What it does.** User-facing dispatcher. Reads the auto-generated index, matches the task description against catalog entries, and invokes the right skill and mode. Refuses to invent skill names. If the top match is below clear-best confidence, it stops and asks which to use.

**When to use.** Whenever you want the AI to pick the most relevant installed skill instead of choosing a path on its own. Especially useful for follow-up tasks like research, lookup, or analysis where freelancing risk is highest.

**Example.**
```
/route find recent papers on transformer architecture
/route summarize this URL: https://example.com/article
/route deploy to staging
```

**Under the hood.** `.claude/skills/route/SKILL.md` and `.claude/skills/route/references/index.md`. Both files are generated by `/skill-builder route index`. Run that command after any change to the skill set.

---

## Code Evaluation

The `code-eval` subsystem builds and maintains a `code-evaluator` skill that catches the mistakes an AI tends to leave in code. Dead exports nothing imports, helpers reinvented next to ones that already exist, functions that grew an extra layer of abstraction for a single caller. It is language-agnostic, using ripgrep and whatever native tools a project already has rather than depending on one compiler.

The skill works in three layers. A pre-write advisor agent checks a planned approach before code is written. A post-write reviewer agent reads the diff after. A full sweep surveys the whole tree on demand. The audit creates the skill when it is missing and keeps its detection references current, so running `/skill-builder audit` is enough to adopt the evaluator and keep it up to date.

### `/skill-builder code-eval create`

**What it does.** Scaffolds the `code-evaluator` skill into the current project. Writes its SKILL.md with `lane: coding`, copies the shipped detection references, and creates two agents (a pre-write `code-design-advisor` and a post-write `deadcode-gardener`) after checking their personas are unique across the project. Low-risk and additive, so it executes immediately. Skips if the skill already exists.

**When to use.** Once per project, to install the evaluator. The audit runs this automatically when the skill is missing, so you rarely call it by hand.

**Example.**
```
/skill-builder code-eval create
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/code-eval.md`

---

### `/skill-builder code-eval review [path]`

**What it does.** Post-write evaluation. Spawns the `deadcode-gardener` agent over a diff or a given path, tiers each finding by confidence, and reports dead code, duplication, and complexity. Display mode by default. Add `--execute` to apply fixes, where only high-confidence dead-code findings that clear every false-positive guard get touched, each through a build-and-test safety cycle.

**When to use.** Right after writing or editing code, before considering the task done.

**Example.**
Display mode.

```
/skill-builder code-eval review src/
```

Apply the safe fixes.

```
/skill-builder code-eval review src/ --execute
```

**Under the hood.** Same procedure file as `create`.

---

### `/skill-builder code-eval sweep`

**What it does.** Full-codebase survey. Fans out one reviewer agent per top-level directory and aggregates a ranked report grouped by confidence tier. Report only. It does not auto-fix, since a whole-tree pass is for triage. Route confirmed findings through `review --execute` on a scoped path.

**When to use.** Before a release or a refactor. When you inherit a codebase and want a map of what is unused, duplicated, or over-complex.

**Example.**
```
/skill-builder code-eval sweep
```

**Under the hood.** Same procedure file as `create`.

---

### `/skill-builder code-eval sync`

**What it does.** Refreshes a project's installed `code-evaluator` references from skill-builder's shipped versions when the shipped version is newer. The refresh is block-aware. It overwrites the skill-builder-owned blocks and preserves any blocks you have added. The comparison reads a version stamp locally, so it needs no network.

**When to use.** After `/skill-builder update` ships newer detection intel. The audit runs this automatically when it detects a version gap, so you rarely call it by hand.

**Example.**
```
/skill-builder code-eval sync
```

**Under the hood.** Same procedure file as `create`.

---

### `/code-evaluator [review|sweep]`

**What it does.** The user-facing skill that `code-eval create` installs. `review` evaluates recent changes, `sweep` surveys the whole codebase. The same two agents back it, and the same strict safety model applies. A grep that finds no references is a candidate, never a verdict. Route embed wires its pre-write and post-write gates into every skill that writes, edits, or debugs code, so the evaluator fires inside those workflows without being called by name.

**When to use.** Whenever you want a direct evaluation outside an audit. The embedded gates also invoke it automatically during code-writing skills.

**Example.**
```
/code-evaluator review
/code-evaluator sweep
```

**Under the hood.** `.claude/skills/code-evaluator/SKILL.md` and `.claude/skills/code-evaluator/references/`. Both are generated by `/skill-builder code-eval create`.

---

## Autonomous Task Loops

The `loop-foreman` subsystem builds a `loop-foreman` skill that drives one large, well-specified task to completion unattended, so you can start it and step away. The work runs in a bounded worker-then-grader loop, and "done" is gated behind two checks that must both pass: a mechanical oracle (a test, a build, or a grep) and a fresh-context reasoning grader that never saw the work get written. The loop escalates to you only on genuinely consequential forks.

The consent that earns "step away" is a single up-front **work order**: a checkable definition of done, the reach of the task, and a pre-authorized allowlist for any irreversible action. The loop is **offered, never auto-fired**. Audit will surface it through `/route` for a big multi-step endeavor, but it never installs or arms it on its own. Honest scope: markdown instructs but cannot enforce, so the hard loop bound holds only when the `Workflow` tool drives the loop, and the stop-before-irreversible-action rule is best-effort prose until a host-generated hook lands in a later increment. v1 is the lean increment: `create` only.

### `/skill-builder loop-foreman create`

**What it does.** Scaffolds the `loop-foreman` skill into the current project. Runs the persona-uniqueness gate, stamps each agent's `model:` from the coding lane, writes a fresh-context grader agent and a read-only research-assistant agent and registers them under `.claude/agents/`, copies the shipped recipe and rubric references, then chains `route index` so `/route` can offer the skill for large multi-task endeavors. Low-risk and additive, so it executes immediately. Skips if the skill already exists.

**When to use.** Once per project, to install the loop driver. Unlike the evaluators, audit does not auto-install this one. It is offered at the companion-skill gate and through `/route`, never forced.

**Example.**
```
/skill-builder loop-foreman create
```

**Under the hood.** `.claude/skills/skill-builder/references/procedures/loop-foreman.md`

---

### `/loop-foreman [run|status]`

**What it does.** The user-facing skill that `loop-foreman create` installs. `run` takes a work order (a checkable definition of done, the task's reach, and a pre-authorized allowlist for irreversible actions) and drives a bounded worker-then-grader loop toward it, shipping only when the mechanical oracle and the fresh-context grader both pass. `status` reports where an in-flight loop stands. Persistent grader disagreement is itself the escalation signal: the loop brings a consequential fork back to you rather than guessing.

**When to use.** When you kick off a big multi-step rollout or plan you want to start and walk away from, and you have already provided enough information to act. For smaller or exploratory work, run the relevant skill directly instead.

**Example.**
```
/loop-foreman run
/loop-foreman status
```

**Under the hood.** `.claude/skills/loop-foreman/SKILL.md` and `.claude/skills/loop-foreman/references/`, plus the `loop-foreman-grader` and `loop-foreman-researcher` agents. All are generated by `/skill-builder loop-foreman create`.

---

## Maintenance

Commands for keeping skill-builder itself current and for working against it as a maintainer.

### `/skill-builder update`

**What it does.** Re-runs the installer to pull the latest version of skill-builder from the GitHub main branch. Overwrites the installed files, preserves any project-specific customizations you've made to other skills, and removes known-legacy files from prior installer versions.

**When to use.** Periodically. After reading release notes or the commit log. When your project has been stable and you want to grab any since-released improvements without disturbing the other skills.

**Example.**
```
/skill-builder update
```

After the update completes, restart Claude Code so the new SKILL.md loads in a fresh session.

**Under the hood.** The `update` command is inline inside `.claude/skills/skill-builder/SKILL.md`.

---

### `/skill-builder dev [command]`

**What it does.** Runs any `/skill-builder` command against skill-builder itself. Normally, skill-builder excludes itself from audits, optimizations, and conversions (it's the tool, not a target). The `dev` prefix overrides that self-exclusion for maintainers working on skill-builder directly.

**When to use.** When you're developing skill-builder in its source repo. When you need to convert skill-builder's SKILL.md against itself during a model upgrade. When you're explicitly working on the enforcer, not on a project that uses it.

**Example.**
```
/skill-builder dev audit
```

```
/skill-builder dev convert skill-builder --execute
```

**Under the hood.** Documented in `.claude/skills/skill-builder/SKILL.md` under § Self-Exclusion Rule.

---

## Technical Background

Architectural concepts that underlie the commands above. Read when you want to understand why the tool works the way it does, not just how to invoke it.

### Display vs Execute Mode

Skill-builder commands sort into two risk tiers.

**Low-risk (additive, non-destructive):** `new`, `inline`, `skills`, `list`, `verify`, `ledger`, `checksums`. These execute immediately. They add files or read state. Nothing to preview, nothing to undo.

**High-risk (restructuring, modifying):** `optimize`, `agents`, `hooks`, `audit`, `cascade`, `convert`. These default to display mode. A read-only plan of what would change. Add `--execute` to apply.

**Destructive (deletes files irreversibly):** `strip`. Defaults to display mode like the high-risk tier, but `--execute` requires `--confirm-breaking` when other skills hard-depend on the target. Git is the recovery mechanism. No separate backup is created, so commit before stripping.

The distinction matters because high-risk commands reshape existing content. A bad `optimize` run can break a skill's observable behavior. Display mode gives you a full review surface before anything gets written.

**Execution requires a task plan.** When a high-risk command runs with `--execute`, it first generates a TaskCreate list (one task per discrete action) and works through it sequentially. The task list is the contract. It survives context compaction, makes progress visible, and enforces scope discipline. Do only what's listed. Note new opportunities in the completion report but don't act on them.

**Post-action chaining.** Any command that modifies a skill (`new`, `inline`, adding directives) auto-chains into a scoped mini-audit of the affected skill. Optimize, agents, and hooks run in display mode, followed by an execution menu. The `--no-chain` flag suppresses this.

---

### Individual Agents vs Agent Teams

Two fundamentally different architectures, often confused.

**Individual agents** evaluate in isolation. Each agent runs with `context: none`, reads the same source material, and returns findings independently. The main conversation synthesizes. Disagreement between agents is signal. Where they agree, you have confidence. Where they diverge, the disagreement itself is worth investigating.

Use individual agents for evaluation, judgment, or diagnosis. That covers the optimize-diff-auditor verifying semantic equivalence after a conversion, the prose-evaluator scoring a draft against voice directives, and the three-agent panel on invariant review during optimize Step 4b.

**Agent teams** build together. Teammates share a TaskCreate list, message each other, and divide ownership across files. The frontend architect, the API designer, and the test engineer each handle their piece of the same feature, coordinated through shared task state.

Use agent teams for implementation, coordination, or multi-file work. Teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings (the installer sets this).

| Signal | Individual Agents | Agent Teams |
|--------|------------------|-------------|
| Goal | Evaluate, judge, diagnose | Build, implement, coordinate |
| Interaction | Must NOT influence each other | Should influence each other |
| Output | Independent opinions for synthesis | Coordinated deliverable |
| File ownership | All read the same files | Each owns different files |

**Persona uniqueness.** Every agent gets a distinct persona. Not a label. A genuine evaluative lens. The `check-persona-uniqueness.sh` PreToolUse hook enforces this across every AGENT.md file in the project. Duplicate personas get blocked at write time.

**Mandatory research assistant.** When a team is deployed, one teammate must be a research assistant with read-only reference tools. Other teammates route research queries through it rather than duplicating external lookups.

---

### When Agents Are Mandatory

A sacred directive in skill-builder's own SKILL.md:

> When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY, in order to provide additional input in decision making.

This isn't a recommendation. Skill-builder enforces it in its own procedures. When optimize is deciding whether a piece of content is a structural invariant or safely movable, it can invoke a three-agent panel (via the `--deliberate` flag or an auto-trigger on detected ambiguity). When hooks can't tell whether a directive needs a shell script or an AI evaluator, it can escalate to two agents arguing the boundary. The audit's priority ranking does the same.

If the tool that creates agents doesn't use agents for its own decisions, something is wrong. So it does.

---

### Rules vs Skills

Rules live in `.claude/rules/*.md` and load automatically based on paths or triggers. A rule with `path: src/api/**` only loads when you're working in that directory. A rule with `trigger: deploy` loads when that word appears in your prompt.

This sounds convenient, but it has a cost. Long lists of rules fade. They load at conversation start and drift just like CLAUDE.md. If your rules directory grows into dozens of files, you'll notice the symptoms. Claude runs hot. Claude starts forgetting instructions mid-conversation. Claude ignores what you want to do.

Keep rules lean. Use them for lightweight, always-on guidance that doesn't fit in CLAUDE.md. For anything substantial, use skills instead. Skills load on-demand, refresh mid-conversation, and don't bloat every session.

**Per-project skill-count discipline.** Every installed skill's frontmatter also loads into the listing on every turn. In a project with 30 installed skills, the roster preamble alone costs thousands of tokens per turn. Target fewer than 15 active skills per project. Disable skills not used in the current project (rename the directory to `.disabled-*` rather than uninstalling). Prefer `paths:` frontmatter for domain-specific skills so they only load when matching files are touched.

---

### Optimization Structure

When a skill grows past 150 lines, it starts carrying weight that doesn't belong in every conversation. Lookup tables, API endpoint docs, category mappings. Useful when referenced, wasteful when always loaded.

The `optimize` command splits a bloated skill into two files.

```
┌─────────────────────┐         ┌─────────────────────┐
│      SKILL.md       │         │      SKILL.md       │
│  (150+ lines)       │         │  (lean, ~30 lines)  │
│                     │         │                     │
│  ■ Directives       │         │  ■ Directives       │
│  ■ Workflows        │  ───►   │  ■ Workflows        │
│  ■ ID Tables        │         │  ■ Grounding links  │
│  ■ Mappings         │         └─────────────────────┘
│  ■ API docs         │                    │
│  ■ Examples         │         ┌─────────────────────┐
│                     │         │    reference.md     │
└─────────────────────┘         │  ■ ID Tables        │
                                │  ■ Mappings         │
                                │  ■ API docs         │
                                │  ■ Examples         │
                                └─────────────────────┘
```

| Content | Stays in SKILL.md | Moves to reference.md |
|---------|:-:|:-:|
| Directives (user rules) | ✓ | |
| Workflows | ✓ | |
| Decision logic | ✓ | |
| ID/account tables | | ✓ |
| API endpoint docs | | ✓ |
| Category mappings | | ✓ |

The lean SKILL.md keeps grounding links pointing into `reference.md`. When the skill needs a table or mapping, it tells Claude to read from the reference file rather than carrying the data inline. Context footprint stays small. Full data stays one file-read away.

**When reference.md itself outgrows a single file.** If it crosses 100 lines with three or more substantial sections, the optimizer proposes splitting it into a `references/` directory with separate files (for example, `ids.md`, `mappings.md`, `constraints.md`). Each split file becomes an enforcement boundary. A hook can watch one file without loading the others.

**Directives are sacred.** Through all of this, user directives never get reworded. The original phrasing is preserved verbatim with its source and date. Restructuring moves content. It never rewrites what the user said.

---

### The Awareness Ledger

Institutional memory for a project. When `/skill-builder ledger --execute` runs, it creates a companion skill that records four kinds of things.

| Record | What It Captures |
|--------|-----------------|
| Incidents | What went wrong, root cause, timeline, resolution, lessons learned |
| Decisions | What was chosen, why, alternatives considered, trade-offs accepted |
| Patterns | Reusable knowledge with evidence and counter-evidence (confirmation bias is real) |
| Flows | Step-by-step user or system behavior, code paths, environmental conditions |

Each record follows a structured template modeled on Google's blameless postmortem format, Architecture Decision Records, and NASA's Lessons Learned Information System.

**How consultation works.** The ledger sits quiet until it's needed. During research and planning, before any recommendation is presented, the system checks whether anything in the ledger is relevant to the area under discussion. If nothing matches, zero overhead. If matches are found, three isolated agents evaluate from different angles.

- **The Regression Hunter** searches past incidents and flows for overlap with the current change. Have we been here before? What broke last time?
- **The Skeptic** checks proposed changes against existing decisions and patterns. What are we assuming? Does any counter-evidence challenge our approach?
- **The Premortem Analyst** imagines the change has already failed and works backward. Gary Klein's research showed this technique improves failure identification by 30%.

Each agent runs in isolation. Where they agree, you have confidence. Where they disagree, the disagreement itself is the signal worth investigating.

![Three lanterns illuminating a dark forest path from different angles](assets/images/three-lanterns.png)

**Three capture channels.** You record directly via `/awareness-ledger record [type]`. Agents suggest capture during consultation when they notice knowledge that isn't in the ledger yet. Hooks detect incident/decision/pattern language in tool input and surface a capture suggestion.

**Cold-start seeding.** The `init` process scans git history, CLAUDE.md, and TODO/FIXME comments for initial records. A cold-start empty ledger helps nobody, so the system gives you a starting corpus to build on.

---

### Token Efficiency & Strictness

Two mechanisms added during the Opus 4.7 upgrade to let skills opt into different verification-cost levels.

**The Token Efficiency Scan** runs inside optimize step 4e (and inside every audit). It detects five patterns that compound tokens across invocations.

- **P1.** Agent-type hook doing mechanical work (grep-checkable logic wrapped in an agent). Proposal: downshift to `type: command` with a shell script. Keep agent as escalation path.
- **P2.** `xhigh` effort without a content-creation profile. Proposal: downgrade to `high`. `xhigh` costs roughly 2 to 3 times the tokens per invocation and is only justified for content-creation workflows.
- **P3.** SKILL.md oversized with stable machinery (total over 150 lines AND more than 30 lines of non-directive `origin: skill-builder | modifiable: true` content). Proposal: extract into a reference file.
- **P4.** Always-spawned validator (unconditional Task-tool agent spawn with no precheck). Proposal: add a mechanical precheck gate. Agent fires only when the precheck is inconclusive.
- **P5.** Missing `strictness` frontmatter field. Proposal: add `strictness: standard` default.

Full detection rules and templates live in `.claude/skills/skill-builder/references/token-efficiency.md`.

**The `strictness` frontmatter field** lets a skill opt into different verification intensities.

| Value | Behavior |
|-------|----------|
| `minimal` | Command hooks only. No agent panels. Precheck-gated diff auditor runs; on precheck failure, user gets a summary rather than an auto-spawned agent. Best for token-sensitive projects. |
| `standard` (default) | Current behavior after the 4.7 upgrade. Command-first hooks, opt-in agent panels, precheck-gated diff auditor. |
| `thorough` | Always-spawns diff auditor regardless of precheck. Mandatory agent panels on every `optimize` run. Escalates marginal decisions to agent judgment. For correctness-sensitive skill-builder work against sensitive skills. |

If absent, the behavior matches `standard`. Adding it is additive. No existing skill breaks by omitting the field.

---

### Further Reading

External references for the concepts and research behind this tool.

- [The Complete Guide to Building Skills for Claude](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf). Anthropic's official guide to skill structure, progressive disclosure, and distribution. Skill-builder adds the enforcement layers (hooks, agents, diagnostics) that make instructions stick across long conversations.
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code). Official docs on skills, hooks, and agents.
- [Agent Teams](https://code.claude.com/docs/en/agent-teams). Coordinating multiple Claude Code instances.
- [Lost in the Middle](https://arxiv.org/abs/2307.03172). The research on long-context instruction following.
