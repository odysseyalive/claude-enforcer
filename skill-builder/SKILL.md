---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new, strip, optimize, agents, hooks, verify, inline, ledger, cascade, checksums, convert, shell-safety, route"
when_to_use: "When creating, auditing, or optimizing Claude Code skills, or when working with SKILL.md files, hooks, or agents"
argument-hint: "[command] [skill] [--execute]"
version: "1.5"
minimum-effort-level: high
allowed-tools: Read, Glob, Grep, Write, Edit, TaskCreate, TaskUpdate, TaskList, TaskGet
hooks:
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

> **"When the dev flag gets called, you ALWAYS concentrate on the distribution files first, then sync changes to the .claude directory after."**

*— Added 2026-05-08, source: user directive (after dev edits repeatedly landed in the runtime copy instead of the source distribution)*

> **"No hooks! We don't distribute hooks. The project only makes hooks on the host system."**

*— Added 2026-05-08, source: user directive*

> **"Exception to the no-hooks-distribution rule: skill-builder's own load-bearing enforcement hooks — protect-directives.sh and unique-persona.sh — DO ship in the source distribution and the installer fetches them. They protect two sacred user directives (no rewording of immutable blocks; persona uniqueness across agents). Without them, every fresh install silently loses load-bearing enforcement. The general no-distribute rule still applies to every other hook on the host system. Wiring into settings.local.json remains host-local."**

*— Added 2026-05-11, source: user directive (after the regenerate-and-rewire loop revealed that no-distribute leaves load-bearing enforcement off on every fresh host).*

> **"Bifurcate jobs based on the currently selected model — split jobs between creative work (ie image generation, content generation, and design generation) and coding (everything else, including testing). When we run an audit, I want to make sure it's fluid in managing switching between models, with prompting, or not."**

*— Added 2026-06-01, source: user directive (the lane→model mapping is intentionally arbitrary/configurable because models change constantly; the model IDs live in references/model-lanes.md, never inside this immutable block).*

> **"It shouldn't make any decisions based on performance, but the full completion of integrity of skills expected to be performed by the user. Don't make decisions based on 'shortcut' mentality."**

*— Added 2026-06-04, source: user directive (governs the `reconcile` command: redundancy is never the target; only completion-breaking conflict is actionable; integrity over performance, never a shortcut).*
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
3. Glob BOTH agent-file forms and read each file's persona field: `.claude/skills/*/agents/*.md` (flat-file agents like `agents/failure-triage.md`) AND `.claude/skills/*/agents/*/AGENT.md` (subdirectory-form agents like `agents/optimize-diff-auditor/AGENT.md`). Union the two globs — agents may live in either form, and using only one form silently drops uniqueness coverage for the other half of the population.
4. IF the proposed persona string matches any existing persona verbatim OR paraphrases one already in use (same core identity, different words) → STOP. Report: "Persona conflicts with [path]: '[existing persona]'. Choose a different persona."
5. IF no duplicate AND the persona fits the role (step 2 passed) → CONTINUE to write the AGENT.md.
6. There is no shipped backstop hook for this gate (skill-builder does not distribute pre-built hook scripts; cross-platform compatibility takes precedence). The CHECKPOINT above IS the enforcement — follow it literally during authorship. Users who want a deterministic backstop on their own systems can generate one via `/skill-builder hooks dev skill-builder --execute`, which builds an OS-appropriate hook locally without shipping it.
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

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When the dev flag gets called, you ALWAYS concentrate on the distribution files first, then sync changes to the .claude directory after." -->
CHECKPOINT — Source-First Ordering Gate (fires when `dev_mode == true`):
1. Maintainer mode detection: does `${CLAUDE_PROJECT_DIR}/skill-builder/SKILL.md` exist?
   - YES → maintainer mode active. Continue.
   - NO  → end-user mode. This CHECKPOINT is a no-op.
2. Track per-session state: which `skill-builder/<path>` files have been edited so far in this session? Maintain a mental ledger of source paths touched.
3. Before issuing ANY Edit/Write tool call on a file under `.claude/skills/skill-builder/<path>` or `skill-builder/<path>`:
   - IF the planned target is `skill-builder/<path>` → CONTINUE. This is the canonical first-pass edit.
   - IF the planned target is `.claude/skills/skill-builder/<path>`:
     - IF `skill-builder/<path>` has already been edited in this session → CONTINUE. This is the mirror phase.
     - IF `skill-builder/<path>` has NOT been edited in this session → STOP. REWRITE the target to `skill-builder/<path>` BEFORE issuing the call. Edit source first.
4. Reverse-order forbidden: never edit runtime first then "sync back to source." The runtime contains intentional runtime-only content (local hooks frontmatter, sidecars) that must NOT propagate to source.
5. End-of-session check: `git status --short -- skill-builder/`. Empty when changes were expected = FAIL. Report: "Source-first ordering violated. Edits landed in the runtime only. Reverse order and retry."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "No hooks! We don't distribute hooks. The project only makes hooks on the host system." -->
<!-- Exception directive (2026-05-11): protect-directives.sh and unique-persona.sh DO ship in source. -->
CHECKPOINT — No-Distribute-Hooks Gate:
1. Define the EXCEPTION_HOOKS set: `{ protect-directives.sh, unique-persona.sh }`. Every step below applies to all hooks EXCEPT those in this set; the exception steps (1b, 3b) cover the two named hooks explicitly.
2. Before adding any hook script under `skill-builder/hooks/` whose basename is NOT in EXCEPTION_HOOKS → STOP. The source distribution MUST NOT contain hook scripts other than the two named exceptions. Hooks live only in the runtime copy on the host system.
   - 2b. Exception path: adding `skill-builder/hooks/protect-directives.sh` or `skill-builder/hooks/unique-persona.sh` is PERMITTED and REQUIRED per the 2026-05-11 sacred directive. These ship in source.
3. Before adding a `hooks:` frontmatter block to source `skill-builder/SKILL.md` → STOP. Source SKILL.md MUST NOT declare hooks. The runtime SKILL.md may declare hooks the host has generated locally; source must not.
4. Before adding any line to the `install` script that fetches a hook script via `curl` → check against EXCEPTION_HOOKS.
   - 4a. If the basename is in EXCEPTION_HOOKS → PERMITTED. The installer is expected to fetch these two files. Confirm the fetch loop targets `.claude/skills/skill-builder/hooks/` on the host.
   - 4b. If the basename is NOT in EXCEPTION_HOOKS → STOP. Adding the fetch line violates the directive.
5. Hooks ARE permitted in the runtime copy (`.claude/skills/skill-builder/hooks/`) and in runtime `SKILL.md` frontmatter, but only when generated on the host system via `/skill-builder hooks <skill> --execute` or maintained by hand by the host operator. The two EXCEPTION_HOOKS additionally arrive via the installer's fetch loop. Runtime hooks NOT in EXCEPTION_HOOKS never propagate back to the source distribution.
6. IF a workflow proposes shipping a hook NOT in EXCEPTION_HOOKS via `install`, adding non-exception hook scripts to `skill-builder/`, or declaring hooks in source frontmatter → REFUSE and report: "No-distribute-hooks directive violated. Hooks are made on the host system only — only protect-directives.sh and unique-persona.sh are permitted in source per the 2026-05-11 exception."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "Bifurcate jobs based on the currently selected model — split jobs between creative work (ie image generation, content generation, and design generation) and coding (everything else, including testing). When we run an audit, I want to make sure it's fluid in managing switching between models, with prompting, or not." -->
CHECKPOINT — Model-Lane Routing Gate (fires during `audit`; see audit.md § Step 4f):
1. Read `references/model-lanes.md`. Parse the Lane→Model table, the Skill→Lane table, and the `<!-- model-lane-setup: <state> -->` per-project marker (missing = `unset`).
2. IF the Skill→Lane table has no active (non-commented) rows AND no skill self-declares a `lane:` frontmatter key → the mapping is UNCONFIGURED. Branch on the setup-state marker (the onboarding fork; see audit.md § Step 4f-setup):
   - `model-lanes.md` absent entirely, OR marker is `declined`, OR the run is suppressed (headless/non-interactive, `audit --quick`, or `--no-model-prompt`) → STOP this gate silently (no report section, no prompt, no marker write). An undeclared/declined preference is correctly absent, not a gap.
   - marker is `unset` AND this is a full interactive `audit` → run the one-time Setup Onboarding Flow (offer Set it up now / Not now / Never ask). "Set it up now" → suggest+confirm per-skill lanes, confirm the Lane→Model mapping, write them plus `configured` into model-lanes.md (the only write this gate makes; it still never switches the model). "Not now" → leave `unset`. "Never ask" → write `declined`. Then continue or stop accordingly.
3. Determine `ACTIVE_MODEL`: read the session system-context line "The exact model ID is ...", strip any `[1m]`/`[200k]` suffix, lowercase. This is a concrete read (no judgment) → no agent required.
4. For each audited skill, resolve its lane ONLY from a declared source: `lane:` frontmatter → Skill→Lane table → NO LANE. A skill with no declared lane is SKIPPED — never auto-classified into a flag. (Audit MAY print a non-blocking lane *suggestion* for undeclared skills per model-lanes.md § Advisory Lane Suggestion; a suggestion never triggers a prompt.)
5. Look up the resolved lane's Preferred Model. IF empty/absent → do NOT flag (lane flagging disabled by an empty cell). IF non-empty AND `preferred_model != ACTIVE_MODEL` → record a mismatch.
6. Reporting: list every mismatch in the Step 5 "Model Lane" report section (Skill | Lane | Preferred | Active | Source). This is report-only and never blocks.
7. Prompting ("flag + prompt to switch"): in an INTERACTIVE session, after the report, emit ONE batched switch prompt per distinct preferred model (not one per skill) via AskUserQuestion, styled on the `update` CHECKPOINT — a skill CANNOT change the session model itself; the prompt instructs the user to run `/model`. Offer "switched / skip / continue". After acknowledgement, re-read the model line ONCE to confirm; do not loop.
8. Suppression ("or not"): IF `--no-model-prompt` is set, OR the session is headless/non-interactive (e.g. `verify`), OR this is `audit --quick` → SUPPRESS the prompt and report only (quick: omit the section entirely). `--model-prompt` forces the prompt even when it would otherwise be report-only.
9. IF the gate fired but the model-lanes mapping could not be read while at least one skill declares a lane → STOP. Report: "Model-lane mapping unreadable; cannot evaluate model routing. Fix references/model-lanes.md."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "It shouldn't make any decisions based on performance, but the full completion of integrity of skills expected to be performed by the user. Don't make decisions based on 'shortcut' mentality." -->
CHECKPOINT — Integrity-Over-Performance Gate (governs the `reconcile` command; see reconcile.md):
1. This gate fires for every `reconcile` finding and for any cross-skill remediation decision.
2. **Redundancy alone is NEVER a reason to act.** Before reporting or fixing anything, confirm the overlap demonstrably threatens a skill's *full completion* (selection-shadowing, dispatch-bypass, suppression cascade, mutation race, or a hard name/embed collision). IF it does not → DROP it silently. It is not a finding.
3. **No performance/tidiness justification.** IF the only rationale for a removal or modification is speed, token savings, deduplication, or "cleaner" — STOP. That is the shortcut mentality this directive forbids. Do not act.
4. **No shortcut on judgment.** A non-obvious conflict call requires the agent panel (per the Non-Obvious Decision Gate). Skipping the panel to reach a faster verdict is forbidden. Agents disagree → keep both, flag for the human.
5. **Directive blocks are untouchable.** Any remediation whose edit span intersects an `<!-- origin: user | immutable: true -->` block downgrades to FLAG-ONLY, overriding its class default. Never reword, reorder, or delete to "resolve" a directive conflict.
6. **Deletion is delegated, never reimplemented.** A confirmed redundant skill routes through `/skill-builder strip` (with its BREAKING detection and `--confirm-breaking` gate) — `reconcile` never deletes.
<!-- END ENFORCEMENT ANNOTATION -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Phase 0: Dev Path Discipline (BLOCKING — maintainer mode)

**When `dev_mode == true` AND `${CLAUDE_PROJECT_DIR}/skill-builder/SKILL.md` exists (this repo IS the skill-builder source distribution), every Edit/Write on a skill-builder file MUST target the source path under `skill-builder/...` BEFORE any mirror to the runtime copy at `.claude/skills/skill-builder/...`.**

The runtime is gitignored. It gets overwritten on every `bash install`. Runtime-only edits never reach end users.

**Mandatory order — non-negotiable:**

1. **Edit `skill-builder/<path>` first** (the source distribution under repo root).
2. **Then mirror the same change to `.claude/skills/skill-builder/<path>`** so the running session matches source. The mirror is a content sync, not a wholesale overwrite. Preserve runtime-only content the source intentionally lacks: local hooks frontmatter, `.directives.sha` sidecars, generated artifacts.
3. **Never reverse the order.** Runtime contains intentional runtime-only content that must NOT propagate to source.

**Hooks-in-source exception:** Two skill-builder hooks ship in the source distribution per the 2026-05-11 sacred directive — `protect-directives.sh` and `unique-persona.sh`. When `dev` mode targets either file, the canonical source path is `skill-builder/hooks/<name>` — edit there first, then mirror to `.claude/skills/skill-builder/hooks/<name>`. Every other hook file remains runtime-only and follows the original no-distribute rule.

**CHECKPOINT — fires before any skill-builder Read/Edit/Write when `dev` is in the invocation:**

1. Maintainer mode: does `${CLAUDE_PROJECT_DIR}/skill-builder/SKILL.md` exist?
   - YES → maintainer mode active. Continue.
   - NO  → end-user mode. This CHECKPOINT is a no-op. Proceed to dispatch.
2. For every planned Edit/Write whose path starts with `.claude/skills/skill-builder/`:
   - REWRITE the path BEFORE issuing the tool call: replace `.claude/skills/skill-builder/` with `skill-builder/`. The source path is the canonical first-pass edit target.
   - IF the source file does not exist while the runtime file does → STOP. Report: "Runtime is ahead of source for [path]. Determine canonical state before editing." Do not auto-mirror.
   - Hook path exception: paths matching `.claude/skills/skill-builder/hooks/protect-directives.sh` or `.claude/skills/skill-builder/hooks/unique-persona.sh` rewrite to `skill-builder/hooks/<name>` (these two ship in source per the 2026-05-11 directive). Any OTHER `.claude/skills/skill-builder/hooks/*.sh` path stays runtime-only — do NOT rewrite to source for those.
3. For Reads on skill-builder content: prefer `skill-builder/<path>` so planning grounds on canonical source. Reads from runtime are allowed but second choice — the runtime may be stale.
4. After all source edits land, perform the runtime mirror as a separate, explicit phase. For each `skill-builder/<path>` modified in this session, replicate the same change to `.claude/skills/skill-builder/<path>`. Touch only the changed sections; do not overwrite runtime-only frontmatter, hook scripts, or sidecars.
5. End-of-session check: `git status --short -- skill-builder/`. Empty output when changes were expected = FAIL. The edits landed in the runtime only. Reverse order and retry from step 2.

**No hook backstop for this gate.** Per the user directive "No hooks! We don't distribute hooks. The project only makes hooks on the host system" (see § Directives), there is no shipped hook for Phase 0 enforcement. The CHECKPOINT above IS the enforcement and must run during authorship. A maintainer who wants a local mechanical backstop on their own host can generate one via `/skill-builder hooks dev skill-builder --execute`, but that is a host-system action and is never part of the source distribution.
<!-- /origin -->

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
| `reconcile [skill]` | [reconcile.md](references/procedures/reconcile.md) | Cross-skill conflict detection + integrity-preserving remediation |
| `convert [skill]` | [convert.md](references/procedures/convert.md) | Convert 4.6-era skill to 4.7-compatible (annotations + explicit steps) |
| `optimize [skill]` | [optimize.md](references/procedures/optimize.md) | Restructure for context efficiency |
| `optimize claude.md` | [claude-md.md](references/procedures/claude-md.md) | Extract domain content to skills |
| `agents [skill]` | [agents.md](references/procedures/agents.md) | Analyze/create agents |
| `hooks [skill]` | [hooks.md](references/procedures/hooks.md) | Inventory/create hooks |
| `new [name]` | [new.md](references/procedures/new.md) | Create skill from template |
| `strip [skill]` | [strip.md](references/procedures/strip.md) | Delete a skill and remove all cross-references |
| `inline [skill] [directive]` | [inline.md](references/procedures/inline.md) | Quick-add directive |
| `skills` | [skills.md](references/procedures/skills.md) | List local skills |
| `list [skill]` | [list.md](references/procedures/list.md) | Show modes/options |
| `verify` | [verify.md](references/procedures/verify.md) | Health check (headless-compatible) |
| `ledger` | [ledger.md](references/procedures/ledger.md) | Create Awareness Ledger |
| `checksums [skill]` | [checksums.md](references/procedures/checksums.md) | Generate/verify directive checksums |
| `shell-safety [mode] [path]` | [shell-safety.md](references/procedures/shell-safety.md) | Write / audit / lint shell code and JSON-embedded shell for pitfalls |
| `route [mode]` | [route.md](references/procedures/route.md) | Maintain `/route` skill index and embed route-consultation hooks into other skills |
| `code-eval [mode]` | [code-eval.md](references/procedures/code-eval.md) | Scaffold/maintain the `code-evaluator` skill (create / review / sweep / sync) |
| `update` | *(inline below)* | Update to latest version |
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `update` Command

Re-run the installer to update skill-builder to the latest version.

The installer issues many file writes and bash calls in sequence. Without auto-accept, the user will be prompted to approve each one. Claude Code does NOT expose a way for a skill to flip the session into "accept edits on" mode programmatically, nor to detect the current permission mode at runtime — mode changes require the user to press Shift+Tab. The procedure below therefore prompts the user to enable auto-accept before the installer runs.

**CHECKPOINT — fires when `/skill-builder update` is invoked:**

1. **BEFORE running the installer**, output this notice to the user verbatim and STOP for their acknowledgement:

   > **Before I run the installer, please enable "accept edits on" mode so you don't get prompted for every file write and bash call.**
   >
   > Press **Shift+Tab** until the prompt indicator shows **"accept edits on"** (it cycles: default → accept edits on → plan mode).
   >
   > I cannot detect or set this mode from inside the session — it has to be you. Reply with anything (e.g., "go") once it's enabled and I'll run the installer.

2. After the user acknowledges, run the installer via Bash: `bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"`
3. Tell the user: **"Restart Claude Code to load the updated skill."** The current session still has the old skill loaded in memory, so start a new conversation. Once you're back, run `/skill-builder audit` — updates often add new recommendations that apply to your existing skills.
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
## The `route` Command

Maintain the `/route` skill — a glorified, auto-generated index of every installed skill — and embed route-consultation hooks into other skills so the AI dispatches through registered skills instead of freelancing. `/route` is a peer to `intent-router`, not a replacement: `intent-router` handles freeform `/skill-builder <text>` invocations within skill-builder; `/route` handles user-level task routing across every installed skill.

- `/skill-builder route index` — scan all skills, regenerate `/route`'s catalog. Bootstraps `/route` if missing. Diffs against the prior index and reports NEW / REMOVED / UPDATED / UNCHANGED. Default mode is execute (low-risk; only writes auto-generated content inside `/route`).
- `/skill-builder route index --dry-run` — display-only summary of what would change.
- `/skill-builder route embed` — display mode (high-risk default). For each skill, classify NEW / REFRESH / REMOVE / NOOP based on workflow heuristics + a reconciliation against any embed blocks already on disk.
- `/skill-builder route embed --execute` — apply the planned embeds, refreshes, and removals; auto-runs `route index --execute` afterward to keep the catalog current.
- `/skill-builder route embed --remove [skill]` — manually opt a skill out of the route gate.

Both `index` and `embed` are intelligent on re-run: `index` diffs against the prior catalog and rewrites idempotently; `embed` reconciles against existing `<!-- ROUTE-EMBED START -->` markers and either refreshes them, removes them when the skill no longer qualifies, or adds them where workflows now require routing.

`route embed` manages **three independent managed-block families** in one pass: the `ROUTE-EMBED` consultation gate (freeform-follow-up skills), the `CODE-EVAL-EMBED` gate (code-touching skills), and the `MODEL-LANE-GATE` invocation-time preflight (skills that resolve to a model lane with a non-empty preferred model — see [route.md](references/procedures/route.md) § Step 8). The model-lane gate is the invocation-time complement to audit's report-only Step 4f: embedded near the top of a lane-declared skill's workflow, it prompts the user to `/model`-switch before any generative step when the active model does not match the skill's lane. It never switches the model itself, and it is a silent no-op when no lane is declared or the lane's preferred-model cell is empty. `--remove [skill]` strips all three families.

**Audit integration:** `route index` is appended as the second-to-last item in audit's task list, and `route embed` is the last item — and `route embed` is the single write path for the model-lane gate (no separate menu item). See [audit.md](references/procedures/audit.md) § Step 4g.

**Grounding:** Read [references/procedures/route.md](references/procedures/route.md) for the full procedure, including the embed block format, reconciliation rules, and the `/route` skill template used during bootstrap.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `code-eval` Command

Scaffold and maintain the `code-evaluator` skill — a language-agnostic code quality evaluator that prevents common AI coding mistakes (dead code, duplication, complexity hotspots, reinvented helpers, leftover scaffolding). This command is skill-builder machinery; the `code-evaluator` skill it produces is what end users run. The evaluator is AI-driven (ripgrep + opportunistic native tools, no compiled analyzer), built on a strict safety model: grep proposes candidates, the compiler and the test suite decide.

The created skill has a **three-layer model**, all owned by `code-evaluator`:
- **L1 — pre-write advisor:** the `code-design-advisor` agent, spawned by *other* code-touching skills at non-obvious code decisions (wired in by `route embed`), to evaluate a planned approach before code is written.
- **L2 — post-write review:** `/code-evaluator review [path]` runs the `deadcode-gardener` agent over a diff; only HIGH-confidence, guard-cleared dead code is auto-fixed.
- **L3 — full sweep:** `/code-evaluator sweep` fans out a whole-codebase report (report-only at scale).

Subcommands of `code-eval`:
- `/skill-builder code-eval create` — scaffold `code-evaluator` if absent (low-risk; executes). Copies the shipped intel references and writes the two agents after a persona-uniqueness check.
- `/skill-builder code-eval review [path]` — post-write evaluation (high-risk; display default, `--execute` to apply HIGH-tier fixes).
- `/skill-builder code-eval sweep` — full-codebase report (high-risk; display default).
- `/skill-builder code-eval sync` — refresh a user's `code-evaluator` references from skill-builder's shipped versions when the shipped `code-eval-ref-version` is newer (block-aware; preserves user-origin seams).

**Audit integration:** `audit` automatically ensures `code-evaluator` exists (creating it if absent) and runs `code-eval sync` to keep its references current, before the route terminal tasks. See [audit.md](references/procedures/audit.md) § Step 4a-bis.

**Grounding:** Read [references/procedures/code-eval.md](references/procedures/code-eval.md) for the full procedure (create / review / sweep / sync), [references/code-evaluator/skill-template.md](references/code-evaluator/skill-template.md) for the generated SKILL.md + advisor/reviewer agent templates, and [references/code-evaluator/cross-file-detection.md](references/code-evaluator/cross-file-detection.md) + [guards.md](references/code-evaluator/guards.md) for the detection method and false-positive guards.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `reconcile` Command

Detect redundancies and collisions **across** skills and remediate only the ones that are mechanically safe. Where `cascade` looks inside one skill for over-suppression, `reconcile` looks across the whole installed set for the colliding-task failure mode: as a project grows and skills accumulate, two skills can fight over the same trigger, hook matcher, command name, dispatch step, or file region — so a skill "seems to fail to run" when it was really shadowed, bypassed, suppressed, or overwritten.

Governed by the sacred integrity-over-performance directive (§ Directives, 2026-06-04): **redundancy is never the target — only a conflict that breaks a skill's full completion is actionable. No shortcut mentality.** Harmless or intentional overlap (chains, shared kernels, defense-in-depth) is left alone.

- Display mode (default): `/skill-builder reconcile` — scan all skills, report cross-skill conflicts with `file:line` evidence; change nothing
- Targeted: `/skill-builder reconcile [skill]` — report conflicts involving one skill
- Execute mode: `/skill-builder reconcile --execute` — apply ONLY the two mechanical auto-fixes (collapse a duplicate machine-generated embed block; drop a byte-identical duplicate hook entry). Everything touching a directive, description, persona, conflicting hook, or chain stays flag-only; a confirmed redundant skill is routed to `strip`, never deleted here

High-risk command — defaults to display mode, requires `--execute`. `--execute` never edits `origin: user | immutable: true` content, never rewords descriptions or personas, and never deletes a skill directly.

**Audit integration:** `reconcile` runs as audit **Step 4d-bis** (between cascade and the priority panel), display-only with its agent panels suppressed; completion-breaking findings elevate into Priority Fixes. Skipped in `audit --quick`. See [audit.md](references/procedures/audit.md) § Step 4d-bis.

**Grounding:** Read [references/procedures/reconcile.md](references/procedures/reconcile.md) for the full procedure — the collision-class table with reliability tiers, the conflicts-only filter and complementary-overlap allow-list, the remediation ladder with the directive-touch hard floor, the mandatory agent adjudication for judgment-class findings, and the `strip` hand-off.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `strip` Command

Delete a skill completely and remove every connection to it from other skills, settings, hook bindings, and dev-repo manifests. The destructive counterpart to `new`.

- Display mode (default): `/skill-builder strip [skill]` — produce an impact report listing every file to be deleted, every cross-reference to be removed, dependent skills, and BREAKING status if any HARD references exist
- Execute mode: `/skill-builder strip [skill] --execute` — apply the deletion plan
- Breaking confirmation: `/skill-builder strip [skill] --execute --confirm-breaking` — required when the target has HARD references in other skills (workflow Read instructions, hook scripts, or AGENT.md grounding)

Destructive command — defaults to display mode, requires `--execute`. Stripping `skill-builder` itself is HARD-REFUSED even with the `dev` prefix; the prefix permits self-modification, not self-deletion.

After deletion, the procedure auto-runs `route index --execute` to drop the target from the `/route` catalog (when `/route` is installed).

**Grounding:** Read [references/procedures/strip.md](references/procedures/strip.md) for the full procedure, including the 15 cross-reference detection patterns, dependent classification, settings.local.json mutation rules, and the strict task ordering (sweep references before deletion).
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
3. Define the known-command set: `{ audit, optimize, agents, hooks, new, inline, skills, list, verify, ledger, cascade, reconcile, checksums, convert, shell-safety, route, code-eval, update }`.
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

**Dev Path Discipline (defense-in-depth pointer):** Phase 0 at the top of this SKILL.md is the primary gate for source-vs-runtime path resolution in maintainer mode. It fires BEFORE this CHECKPOINT in document order. If Phase 0 ran cleanly, the path was already rewritten to the source location before reaching dispatch. If you reached this point and a planned Edit/Write still targets `.claude/skills/skill-builder/...`, STOP and re-read § Phase 0.

**Post-dev check:** After any `dev` command that modifies skill-builder files, run BOTH of the following:

1. **Manifest check.** Glob `skill-builder/**/*.md`. Compare against the files downloaded in the installer's `for ref`, `for proc`, `for ss`, and `for ce` loops, plus the explicit `curl` lines for `SKILL.md` and `agents/*/AGENT.md`. Flag any new/renamed/removed files the installer doesn't handle. This prevents drift between the repo and what users receive on install. (skill-builder no longer ships hook scripts; users generate per-system hooks via `/skill-builder hooks` if they want them.)
2. **Source-edit verification.** Run `git status --short -- skill-builder/`. If the dev session was expected to produce changes and the output is empty, the edits landed in the runtime copy. Report the failure with the runtime/source diff so the user can mirror canonical changes back to source.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Display/Execute Mode Convention

**Commands are classified by risk level, which determines their default mode:**

| Risk | Commands | Default Mode |
|------|----------|-------------|
| **Low-risk** (additive, non-destructive) | `new`, `inline`, `skills`, `list`, `verify`, `ledger`, `checksums`, `route index`, `code-eval create`, `code-eval sync` | **Execute directly** |
| **High-risk** (restructuring, modifying) | `optimize`, `agents`, `hooks`, `audit`, `cascade`, `reconcile`, `convert`, `route embed`, `code-eval review`, `code-eval sweep` | **Display mode** (requires `--execute`) |
| **Destructive** (deletes files irreversibly) | `strip` | **Display mode** (requires `--execute`; `--confirm-breaking` if dependents exist) |

| Mode | Behavior | Flag |
|------|----------|------|
| **Display** | Read-only plan of what would change | *(default for high-risk)* |
| **Execute** | Apply changes to files | `--execute` or *(default for low-risk)* |

### Rules

1. **Low-risk commands execute immediately.** `new`, `inline`, `skills`, `list`, `verify`, `ledger`, `checksums`, and `route index` do their work directly without requiring `--execute`. They are additive or read-only — there is nothing to preview. (`route index` is auto-generated content inside the `/route` skill only — idempotent regeneration.)
2. **High-risk commands default to display mode.** Running `/skill-builder optimize my-skill` shows what *would* change without modifying anything. Add `--execute` to apply.
3. **Audit always calls sub-commands in display mode**, then offers the user a choice of which to execute.
4. **Execution requires a task plan.** When a high-risk command runs with `--execute`, the command MUST:
   - First produce a numbered task list using TaskCreate, one task per discrete action
   - Execute each task sequentially, marking progress via TaskUpdate
   - This ensures context can be refreshed mid-execution without losing track, no tasks get forgotten during long context windows, and the user can see progress and resume if interrupted
5. **Scope discipline during execution.** Execute ONLY the tasks in the task list. Do not add bonus tasks, expand scope, or create deliverables not in the original plan. If execution reveals a new opportunity, note it in the completion report — do not act on it. The task list is the contract.
6. **Post-action chaining.** Any action that modifies a skill (`new`, `inline`, adding directives) automatically chains into a scoped mini-audit for the affected skill — running optimize, agents, and hooks in display mode, then offering execution choices. Use `--no-chain` to suppress.
7. **Model-lane prompting (audit only).** When `audit` finds a skill whose declared lane's preferred model differs from the active session model (see § Directives → Model-Lane Routing Gate and audit.md § Step 4f), the default in an interactive session is to **report + prompt** the user to switch via `/model` (the "flag + prompt" behavior). Use `--no-model-prompt` to report-only ("or not"); use `--model-prompt` to force the prompt even where it would otherwise be suppressed. The prompt is always suppressed in headless/non-interactive runs and in `audit --quick`. A skill cannot change the session model itself — the prompt instructs the user, mirroring the `update` command's permission-mode prompt. **Onboarding:** when a project has no lanes configured yet, a full interactive `audit` instead offers a one-time setup prompt (Set it up now / Not now / Never ask in this project), tracked per project via the `model-lane-setup` marker in `model-lanes.md`. "Set it up now" suggests per-skill lanes for confirmation and lets the user confirm the Lane→Model mapping, then writes them — the only file write Step 4f makes. See audit.md § Step 4f-setup and model-lanes.md § Setup State.
8. **Decision handoffs use AskUserQuestion — never a free-text "should I?".** Every point where a command ends its turn to let the user decide *whether to proceed, what to change, or which direction to take* MUST be presented via **AskUserQuestion** (a clickable menu), not as end-of-turn prose like "Would you like me to proceed?". This holds for **every** command, display and execute alike, and generalizes Rules 3, 6, and 7 into one invariant. **Over-fire guard:** if you cannot name at least two concrete options, it is not a decision handoff — ask in prose (open-ended freeform like "paste the error text" stays prose; in-turn status, progress narration, and bare acknowledgements never prompt). **Option floor:** every decision menu offers at least the recommended path, one genuine alternative, and an explicit **"Skip / not now"** so the user is never trapped into authorizing an action (AskUserQuestion's auto-appended "Other" preserves freeform on top of these). Style on the `update` CHECKPOINT and audit § Step 6's execution menu.
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
- [references/model-lanes.md](references/model-lanes.md) — Lane→Model routing map (user-editable), active-model detection, advisory lane classification (read by audit Step 4f)
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
- [references/procedures/route.md](references/procedures/route.md) — Route subcommand procedure (index + embed) with `/route` skill bootstrap template
- [references/procedures/code-eval.md](references/procedures/code-eval.md) — Code-eval subcommand procedure (create / review / sweep / sync) for the `code-evaluator` skill
- [references/procedures/reconcile.md](references/procedures/reconcile.md) — Reconcile subcommand procedure (cross-skill collision detection, conflicts-only scope, integrity-preserving remediation ladder, strip hand-off)
- [references/code-evaluator/](references/code-evaluator/) — Shipped intel for the generated `code-evaluator` skill: version.md (drift anchor), cross-file-detection.md, guards.md, mistake-taxonomy.md, native-tool-map.md, gotchas.md, skill-template.md
- [references/shell-safety/](references/shell-safety/) — Shell-safety rule set (rules.md, templates.md, audit-patterns.md) — the canonical pitfall catalog used by hooks, verify, and shell-safety
- [agents/optimize-diff-auditor/](agents/optimize-diff-auditor/) — Post-optimize semantic equivalence verification agent
<!-- /origin -->
