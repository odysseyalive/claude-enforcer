## Audit Command Procedure

**When invoked without arguments or with `audit`, run the full audit as an orchestrator.**

### Step 1: Gather Metrics

**Preflight — self-exclusion.** Detect invocation form:
- Invoked as `/skill-builder dev audit …` → include `skill-builder` in the skill set
- Otherwise → exclude `skill-builder` from any `.claude/skills/*/SKILL.md` glob

Apply this filter to every step below that iterates skills (Steps 2.5, 3, 4, 4b, 4d, Step 5 Skills Summary, Step 5 Directives Inventory). See SKILL.md § Self-Exclusion Rule.

```
Files to scan:
- CLAUDE.md
- .claude/rules/*.md (if exists)
- .claude/skills/*/SKILL.md  (exclude skill-builder unless dev prefix)
```

### Step 2: CLAUDE.md & Rules Analysis

```markdown
## CLAUDE.md
- **Lines:** [X] (target: < 150)
- **Extraction candidates:** [list sections that could move to skills]

## Rules Files
- **Found:** [count] files in .claude/rules/
- **Should convert to skills:** [yes/no with reasoning]

## Settings
- **Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`):** [enabled/disabled]
  (Read `.claude/settings.local.json` → `env` section)
```

### Step 2.5: Bootstrap Check (No Skills Found)

If no `.claude/skills/*/SKILL.md` files exist (excluding skill-builder itself):

**Switch to bootstrap mode.** Do NOT report "no skills found" and stop. Instead:

1. Report that no skills exist yet — this is a fresh project
2. Run the **CLAUDE.md Optimization Procedure** (see [claude-md.md](claude-md.md)) as the primary action
3. Analyze CLAUDE.md for extraction candidates (domain-specific sections, inline tables, procedures >10 lines, rules that only apply to specific tasks)
4. Propose new skills to create from extraction candidates
5. Present the CLAUDE.md optimization report with proposed skill extractions
6. Offer execution: "Should I extract these sections into skills?"

Skip Steps 3, 4 (sub-commands), 4c–4f (they require existing skills).

**Still run Step 4a** (Awareness Ledger status check). This is a companion skill installation — it doesn't depend on existing skills and the audit is the orchestrator for surfacing it.

**Still run Step 4g — but only the `route index` half.** `/route` can (and should) bootstrap with an empty catalog so the dispatcher exists the moment the user's first skill is created. The `route embed` half is SKIPPED in bootstrap mode (there are no skills to embed into). See [route.md](route.md) § Mode: `index` → Step 1 "Zero-skill case is valid" and § Mode: `embed` → Step 1 "Zero-candidate case." Surface `route index --execute` as a recommended terminal action in the bootstrap report.

Go to Step 6 with execution choices that include:
- CLAUDE.md extraction candidates (from above)
- Awareness Ledger installation (from Step 4a, if not installed)
- `route index --execute` — bootstrap `/route` with an empty catalog (from Step 4g, always offered in bootstrap mode if `/route` is not yet installed)

**Post-bootstrap chaining:** When CLAUDE.md extraction is executed and new skills are created, post-action chaining (per § Display/Execute Mode Convention rule 6) fires automatically — running optimize, agents, and hooks in display mode for each newly created skill, then offering execution choices. This ensures agents and hooks are surfaced in the same session, not deferred to a second audit. The chain also re-runs `route index` after new skills appear so the freshly-bootstrapped catalog picks them up.

### Step 3: Skills Summary Table

```markdown
## Skills Summary
| Skill | Lines | Description | Directives | Reference Inline | Hooks | Status |
|-------|-------|-------------|------------|------------------|-------|--------|
| /skill-1 | X | single/multi | Y | Z tables | yes/no | OK/NEEDS WORK |

**Description column:** Flag `multi` if uses `|` or `>` syntax (needs optimization to single line)
```

### Step 4: Run Sub-Commands in Display Mode

**Agent budget:** Sub-procedures running in display mode during audit skip their own agent panels. Agent panels fire only in standalone mode or `--execute` mode where decisions have real consequences. The audit's only agent panel is the priority ranking panel (Step 4f) — one per audit run, not per skill.

- Quick audit (`--quick`): **0 agent panels** — pure checklist, no spawning
- Standard audit: **1 agent panel total** (Step 4f priority ranking), plus lightweight cascade guard checks (no panel)

For each skill found:
1. Run **optimize** in display mode (skip agent panels in Steps 4b and 5b) → collect optimization findings
2. Run **agents** in display mode (skip agent panel in Step 5) → collect agent opportunities
3. Run **hooks** in display mode (skip agent panel in Step 3b) → collect hooks inventory and opportunities

### Step 4a: Ledger Status

Check if `.claude/skills/awareness-ledger/SKILL.md` exists.

**If the ledger exists:**
1. Count records: `find .claude/skills/awareness-ledger/ledger -name "*.md" -not -name "index.md"` (excludes index)
2. Check planning-phase integration: scan project CLAUDE.md for awareness ledger reference (grep for "awareness ledger" or "ledger/index.md")
3. If `consult-before-edit.sh` exists in hooks/ or is wired in settings.local.json, flag as obsolete
4. Report **status only**:
   ```
   **Awareness Ledger:** Installed
   - Records: [N] (INC: [n], DEC: [n], PAT: [n], FLW: [n])
   - CLAUDE.md integration: [yes/no]
   - Last updated: [date of most recent record file, or "unknown"]
   - Issues: [missing CLAUDE.md line / obsolete hook / empty ledger / none]
   ```

Per-skill ledger integration recommendations (capture gaps, grounding notes) are surfaced only when a specific skill is targeted via `optimize`, `agents`, or `hooks` — not as a global scan during audit.

**If the ledger does NOT exist:**
1. Report:
   ```
   **Awareness Ledger:** Not installed
   - Captures incidents, decisions, patterns, and flows so diagnostic findings
     and architectural decisions persist across sessions.
   - Available in the execution menu below.
   ```
2. This recommendation MUST appear in the report — do NOT skip silently. The audit is the orchestrator; even though optimize/agents/hooks correctly skip ledger analysis when no ledger exists, the audit is responsible for surfacing the gap.

### Step 4a-bis: Code Evaluator Status & Reference Sync

The `code-evaluator` skill prevents common AI coding mistakes (dead code, duplication, complexity). Audit ensures it exists and keeps its references current automatically. Like Step 4a, this is a **companion-skill singleton check** — run once, not per-skill. **SKIP in `audit --quick`** (it is a structural/file action, not a checklist item).

Check if `.claude/skills/code-evaluator/SKILL.md` exists.

**If it does NOT exist:**
1. Report:
   ```
   **Code Evaluator:** Not installed
   - Prevents dead code, duplication, complexity hotspots, reinvented helpers,
     and leftover scaffolding in code the AI writes.
   - Will be created automatically when you run audit with execution.
   ```
2. Append `code-eval create` to the execution task list (Step 6) — by default, not opt-in. It is low-risk/additive (scaffolds a new skill; touches nothing existing). Running it makes `code-evaluator` available and lets the route terminal tasks (4g) wire its gates into code-touching skills.

**If it DOES exist:**
1. Read its frontmatter `code_eval_ref_version` (= `recorded`).
2. Read skill-builder's shipped version: the integer in `.claude/skills/skill-builder/references/code-evaluator/version.md` (= `shipped`). (In `dev` maintainer mode read from the source path `skill-builder/references/code-evaluator/version.md`.)
3. Compare:
   - `recorded >= shipped` → report **status only**:
     ```
     **Code Evaluator:** Installed (references v[recorded], current)
     ```
   - `recorded < shipped` → references are **stale**. Report:
     ```
     **Code Evaluator:** Installed (references v[recorded] → v[shipped] available)
     - skill-builder ships newer evaluation intel; your copy is behind.
     ```
     and append `code-eval sync` to the execution task list (Step 6) — by default. Sync is a block-aware refresh of skill-builder-owned (`modifiable: true`) reference blocks that preserves any `origin: user` seams (see [code-eval.md](code-eval.md) § sync).

**Both `code-eval create` and `code-eval sync` auto-append to audit's execute task list by default** — mirroring how `route index`/`route embed` are appended (Step 4g). The user may deselect them in the Step 6 menu, but they appear automatically; audit never silently writes during the display scan. In display mode, surface the pending create/sync as recommended actions in the report's Priority Fixes section.

**Grounding:** Read [code-eval.md](code-eval.md) for the create/sync procedure and [../code-evaluator/version.md](../code-evaluator/version.md) for the drift-anchor format.

### Step 4b: Temporal Reference Risk

For each skill, assess temporal reference risk:

1. Check the skill's temporal risk level per `references/temporal-validation.md` § "Temporal Risk Classification"
2. Check whether a temporal validation hook exists for the skill
3. If HIGH or MEDIUM risk with no hook, include in the aggregate report

Skip silently for LOW-risk skills or skills with temporal hooks already in place.

**Grounding:** Read [references/temporal-validation.md](../temporal-validation.md) for risk classification criteria.

### Step 4c: Per-Skill Integration Checks

These checks run only for skills **explicitly targeted** by the user (e.g., `/skill-builder optimize [skill]`, `/skill-builder agents [skill]`). During a full audit, skip per-skill integration checks — companion skill status is reported in Step 4a.

When running for a targeted skill:

**Awareness Ledger relevance** — If `.claude/skills/awareness-ledger/` exists with records:
- Scan `ledger/index.md` for tags overlapping the skill's domain (file paths, function names, component names)
- Only recommend integration if matching records actually exist for this skill's domain
- If the skill IS the awareness-ledger, verify auto-activation directives (Auto-Consultation + Auto-Capture)

**Capture Integration gap** — If the awareness-ledger exists, check whether the targeted skill produces institutional knowledge but lacks a capture mechanism. If gap found, include in report with recommended mechanism per hierarchy: workflow step > agent > hook.

### Step 4d: Validation Cascade Analysis

For each skill with 2+ validators or evaluation agents:
1. Run the cascade analysis per [cascade.md](cascade.md)
2. Include findings in the aggregate report under "Validation Cascade"
3. If cascade risk is MODERATE or HIGH, add to Priority Fixes

Skip silently for skills with 0-1 validators.

### Step 4e: Agent panel — priority ranking

After collecting findings from all sub-commands, the audit must rank fixes by priority. This is a judgment call — which fix has the highest impact? Which is most urgent? Per directive: agents are mandatory when guessing is involved.

Spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

- **Agent 1** (persona: Risk analyst — prioritizes by blast radius and failure probability) — Review all findings. Rank by: what breaks first if left unfixed? What affects the most users or invocations?
- **Agent 2** (persona: Developer experience advocate — prioritizes by friction and daily pain) — Review all findings. Rank by: what slows people down the most? What causes the most confusion or repeated mistakes?
- **Agent 3** (persona: Architectural debt specialist — prioritizes by compounding cost) — Review all findings. Rank by: what gets harder to fix over time? What blocks other improvements?

Each agent reads the aggregated findings from optimize, agents, and hooks across all skills. They return independently ranked priority lists. Synthesize:
- Items ranked top-3 by 2+ agents → highest priority
- Items ranked top-3 by only 1 agent → medium priority
- Present the synthesized ranking with attribution to each agent's rationale

### Step 4f: Model Lane Check (report-only scan + suppressible switch prompt)

Make the audit model-aware per the user directive (SKILL.md § Directives → Model-Lane Routing Gate). This step runs **after** the priority panel (4e) and **before** the route terminal tasks (4g). It is report-only at its core; the optional switch prompt is interactive and never blocks.

**SKIP this step entirely in `audit --quick`** — the quick path does no structural/narrative scanning (see [quick-audit.md](quick-audit.md) § Step 4).

1. **Read the mapping.** Read `references/model-lanes.md` (path relative to the skill-builder install). Parse the Lane→Model table and the Skill→Lane table.
2. **Unconfigured → no-op (silent).** IF `model-lanes.md` is absent, OR the Skill→Lane table has no active (non-commented) rows AND no audited skill self-declares a `lane:` frontmatter key → the feature is unconfigured. **Omit the Model Lane report section entirely** (per Step 5 "absence vs. gap"). Do not flag, do not prompt. Stop this step.
3. **Detect the active model.** Read the session system-context line "The exact model ID is …", strip any `[1m]`/`[200k]` suffix, lowercase → `ACTIVE_MODEL`. See [model-lanes.md](../model-lanes.md) § Active-Model Detection. This is a concrete read — no agent.
4. **Resolve each skill's lane from a DECLARED source only.** For each audited skill (respecting self-exclusion from Step 1): `lane:` frontmatter → Skill→Lane table → **NO LANE**. A skill with no declared lane is **skipped for flagging** — never auto-classified. Optionally compute a non-blocking lane *suggestion* for undeclared skills per [model-lanes.md](../model-lanes.md) § Advisory Lane Suggestion (suggest-only; a suggestion never triggers a prompt).
5. **Compare.** Look up the lane's Preferred Model. IF empty/absent → skip (flagging disabled by empty cell). IF non-empty AND `preferred_model != ACTIVE_MODEL` → record a **mismatch**. Apply the stale-ID self-check from [model-lanes.md](../model-lanes.md) § Comparison Rule: if a non-empty preferred model is not of `claude-<family>-<major>-<minor>` shape or names a clearly superseded family, downgrade to a "mapping may be stale" advisory instead of a switch prompt.
6. **Report (always).** Emit the Model Lane section in the Step 5 aggregate report (table below). Report-only; never blocks.
7. **Prompt to switch (interactive only; the user's "flag + prompt").** In an interactive session with mismatches present AND prompting not suppressed (see step 8): after the report, emit **one batched prompt per distinct preferred model** (group mismatched skills by their preferred model — never one prompt per skill) via **AskUserQuestion**, styled on the `update` command's CHECKPOINT. The prompt instructs the user to run `/model` to switch — a skill cannot change the session model itself. Offer options: **switched / skip / continue**. After acknowledgement, re-read the model line **once** to confirm; do not loop or re-prompt beyond that one confirmation.
8. **Suppression ("or not").** SUPPRESS the prompt (report only) when ANY of: `--no-model-prompt` is set; the session is headless/non-interactive (the prompt would block or loop because the model never changes between re-invocations — keep `verify`-style runs safe); or this is `audit --quick` (section omitted entirely). `--model-prompt` forces the prompt even in display mode. Default interactive `audit` (no flag) prompts.
9. **Unreadable mapping with declared lanes → stop.** IF at least one skill declares a lane but `model-lanes.md` cannot be parsed → report "Model-lane mapping unreadable; cannot evaluate model routing. Fix references/model-lanes.md." and continue the rest of the audit.

**No Step 6 menu entry, no TaskCreate item.** This step produces advisory report text and an optional inline prompt only — there is no `--execute` action because Claude cannot switch the model on the user's behalf. It must not wedge into the route terminal tasks (4g) or the execution menu.

**Grounding:** [model-lanes.md](../model-lanes.md), SKILL.md § Directives (Model-Lane Routing Gate), SKILL.md § The `update` Command (prompt-style precedent).

### Step 4g: Route Index & Embed (final task list items)

After all sub-commands and the priority ranking panel finish, the audit's execution task list MUST end with these two items, in this exact order:

- **Second-to-last task:** `route index` — refresh the `/route` skill's catalog. Skills that were renamed, added, or had their description/modes changed by earlier optimize/agents/hooks tasks need to be reflected in the index immediately. Also fires in **bootstrap mode** (Step 2.5) — `/route` bootstraps with an empty catalog so the dispatcher is ready as soon as the user creates their first skill.
- **Last task:** `route embed` — refresh consultation gates across skills. Earlier tasks may have added or removed workflow steps that change which skills should carry the route gate; this step reconciles. **Skipped in bootstrap mode** — no skills exist to embed into; the embed mode itself stops cleanly in that state ([route.md](route.md) § Mode: `embed` → Step 1 "Zero-candidate case").

Both appear in Step 6's execution menu as discrete items the user can include or skip. They are appended to whatever combined task list TaskCreate produces — they do NOT replace any earlier task. Order matters: `route index` must run before `route embed` so that `embed`'s index-refresh chain (Step 6 of `route.md` § `embed` — Post-Embed Index Refresh) does not double-rebuild a stale catalog.

**During audit display mode** (no `--execute` selected), surface these two as recommended terminal actions in the report's Priority Fixes section so the user knows they would run last. In bootstrap mode, surface only `route index` (embed is N/A).

**Grounding:** [route.md](route.md)

### Step 5: Aggregate Report

Combine all sub-command outputs into a single report:

**Reporting principle — absence vs. gap:** Capability sections (Teams, Temporal Hooks, Validation Cascade) that have nothing to report should be omitted entirely rather than displayed with "none" values. A capability that doesn't apply is correctly absent, not missing. The Awareness Ledger section is always included regardless of state — it has an explicit installation recommendation and is surfaced by design as the audit is the orchestrator for companion skill adoption.

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

## Token Efficiency
[aggregated from optimize step 4e Token Efficiency Scan per skill — see token-efficiency.md for pattern list]
| Skill | Agent hooks flagged | Effort downgrade | SKILL.md slim-down | Precheck gates | Strictness |
|-------|---------------------|------------------|--------------------|----------------|------------|
| /skill-1 | [count + hook names] | [yes/no] | [lines trimmable] | [count] | [missing/present] |

## Agent Opportunities
| Skill | Agent Type | Purpose | Priority |
|-------|------------|---------|----------|
| /skill-1 | id-lookup | Enforce grounding for IDs | High |
[from agents display mode per skill]

## Hooks Status
[aggregated from hooks display mode]

### Hook Wiring Drift
*(Include only if the hooks sub-command's Step 2.5 surfaced dead wiring — wired entries pointing at files that do not exist on disk. Omit entirely when every wired entry resolves to a real file. Non-blocking at runtime but silently drops whatever enforcement the missing hook provided; load-bearing cases warrant recovery, advisory cases warrant unwiring.)*

Surface the full Dead Wiring table from the hooks sub-report (Skill | Hook | Event/Matcher | Intent | Intent source | Criticality | Recoverable). Do not summarize the table away — the intent/criticality/recoverability columns are what turn this from "broken reference" into an actionable recommendation.

**Priority Fixes elevation rule:** Every **Load-bearing** dead-wiring finding MUST appear in the Priority Fixes list at or above any optimization or agent-opportunity finding. Rationale: load-bearing hooks enforce sacred directives or content-quality rules whose silent absence is a larger regression than most structural improvements. Protective findings enter Priority Fixes at medium priority; advisory findings do not unless there are enough of them (3+) that the log noise itself is the problem.

## Teams Status
*(Include this section only if agent teams are actively configured — i.e., `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set AND at least one skill uses team routing. If no skills use teams, omit this section entirely. Team routing is evaluated per-skill during Step 4 via the agents sub-command, which applies the routing decision framework from `references/agents-teams.md`. Absence of teams is not a gap — it means individual agent routing is correct for the current workloads.)*

- **Skills using teams:** [list]
- **Research assistant present:** [per-team status]
- **Issues:** [any team-related issues or "none"]

## Awareness Ledger
[from Step 4a — status, record counts, capture gaps, or installation recommendation]

## Temporal Reference Risk
[from Step 4b — per-skill risk levels, missing hooks]
| Skill | Risk Level | Exposure | Temporal Hook |
|-------|-----------|----------|---------------|
| /skill-1 | HIGH/MEDIUM | [temporal patterns found] | present/MISSING |

## Model Lane
*(Include only if Step 4f found at least one declared lane with a non-empty preferred model. Omit entirely when the mapping is unconfigured — absence is not a gap. Always omitted in `audit --quick`.)*

Active session model: `[ACTIVE_MODEL]`

| Skill | Lane | Lane Source | Preferred | Active | Match |
|-------|------|-------------|-----------|--------|-------|
| /skill-1 | creative | frontmatter/table | claude-opus-4-6 | claude-opus-4-8 | ✗ MISMATCH |

*Undeclared skills (advisory suggestions only — not flagged):* [skill → suggested lane (confidence), or "none"]

If mismatches exist and prompting is not suppressed, the batched switch prompt (one per distinct preferred model) follows this report — see Step 4f.

## Validation Cascade
[from Step 4d — per-skill cascade risk]
| Skill | Validators | Cascade Risk | Top Finding |
|-------|-----------|-------------|-------------|
| /skill-1 | [count] | [NONE/LOW/MODERATE/HIGH] | [summary] |

## Directives Inventory
[List all directives found across all skills - ensures nothing is lost]

## Priority Fixes
1. [Most impactful optimization]
2. [Second priority]
3. [Third priority]
```

### Step 6: Offer Execution

After presenting the report, use **AskUserQuestion** (not plain text) to present execution choices:

> "Which actions should I execute?"
> 1. `optimize --execute` for [skill(s)]
> 2. `agents --execute` for [skill(s)]
> 3. `hooks --execute` for [skill(s)]
> 4. All of the above for [skill]
> 5. `ledger --execute` — create Awareness Ledger *(only if ledger does not exist)*
> 6. `hooks --execute` for temporal validation — generate temporal hooks for high-risk skills *(only if high-risk skills lack temporal hooks)*
> 7. `hooks --execute` for dead wiring — auto-recover load-bearing + recoverable findings, auto-unwire advisory findings, stop on each protective / not-recoverable finding for user decision *(only if Step 2.5 surfaced dead wiring)*
> 8. `code-eval create` / `code-eval sync` — create the `code-evaluator` skill if absent, or refresh its references if stale (auto-appended; runs before the route tasks, per § Step 4a-bis) *(only if code-evaluator is missing or its references are behind)*
> 9. `route index --execute` + `route embed --execute` — refresh the `/route` index and reconcile consultation gates (auto-appended; final two tasks per § Step 4g)
> 10. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress. Append tasks in this tail order so each prerequisite runs first: **(1)** per § Step 4a-bis, `code-eval create` (if code-evaluator is missing) and/or `code-eval sync` (if its references are stale) — auto-appended by default whenever any execute option is selected, so the evaluator exists and is current before routing; then **(2)** per § Step 4g, `route index` (second-to-last) and `route embed` (last) — auto-appended whenever option 9 is selected OR by default whenever any other execute option (1–4, 6, 7, 8) is selected, so `route embed` wires the (possibly newly-created) `code-evaluator` gates into code-touching skills. Option 5 (ledger creation) does not auto-trigger route refresh.

**Follow § Output Discipline** (in SKILL.md) for cascade execution and cross-skill separation.
