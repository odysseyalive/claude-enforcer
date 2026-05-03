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

Go to Step 6 with execution choices that include:
- CLAUDE.md extraction candidates (from above)
- Awareness Ledger installation (from Step 4a, if not installed)

**Post-bootstrap chaining:** When CLAUDE.md extraction is executed and new skills are created, post-action chaining (per § Display/Execute Mode Convention rule 6) fires automatically — running optimize, agents, and hooks in display mode for each newly created skill, then offering execution choices. This ensures agents and hooks are surfaced in the same session, not deferred to a second audit.

### Step 3: Skills Summary Table

```markdown
## Skills Summary
| Skill | Lines | Description | Directives | Reference Inline | Hooks | Status |
|-------|-------|-------------|------------|------------------|-------|--------|
| /skill-1 | X | [full description verbatim] | Y | Z tables | yes/no | OK/NEEDS WORK |

**Description column:**
- Quote the skill's frontmatter `description:` field IN FULL. Do NOT abbreviate, ellipse, or truncate.
- Per SKILL.md § Description Preservation Gate, quoting in full is mandatory regardless of table-layout aesthetics. If the description is too long for a single visual row, let it wrap or render on a continuation line; never elide content.
- Separately, flag the FORMAT (single-line vs. multi-line `|` / `>` syntax). Format flagging is independent of content. A multi-line `description: |` should be flagged for collapse; the contents stay intact through the collapse per the gate's step 4 (mechanical transformation only).
```

### Step 4: Run Sub-Commands in Display Mode

**Agent budget:** Sub-procedures running in display mode during audit skip their own agent panels. Agent panels fire only in standalone mode or `--execute` mode where decisions have real consequences. The audit's only agent panel is the priority ranking panel (Step 4g) — one per audit run, not per skill.

- Quick audit (`--quick`): **0 agent panels** — pure checklist, no spawning
- Standard audit: **1 agent panel total** (Step 4f priority ranking), plus lightweight cascade guard checks (no panel)

**CHECKPOINT — Sub-Command Run Mandate (Opus 4.7 literal-execution gate):**

1. The per-skill sub-command runs below are NOT optional. They are not a heuristic and not a "if signal seems sufficient" shortcut.
2. IF the auditor's reasoning suggests skipping these runs because "the gathered signals already isolate findings", "the small finding set has measurable criticality", or any similar inference → STOP. That reasoning is invalid for this step. Resume the runs.
3. The Non-Obvious Decision Gate exception (SKILL.md § Directives) governs the agent-panel spawn in Step 4g ONLY. It does NOT authorize skipping the per-skill sub-command runs in Step 4. Do not conflate.
4. IF a sub-command run is skipped for any reason → the audit MUST report this explicitly in Step 5 under "Audit Coverage Gaps" with the reason and the analyses that did not fire (Token Efficiency Scan, Content Bookending Detection, agent-opportunity detection per skill, etc.). Silent skipping is forbidden.
5. The runs are bounded and cheap in display mode (no agent spawns, no file writes). The cost of running them is far lower than the cost of a silently incomplete audit that the user trusts as complete.

**For each skill found:**
1. Run **optimize** in display mode (skip agent panels in Steps 4b and 5b) → collect optimization findings AND token efficiency scan
2. Run **agents** in display mode (skip agent panel in Step 5) → collect agent opportunities AND Content Bookending Detection per `agents.md` Step 4d
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

### Step 4e: Content Bookending Detection (audit-level, mandatory)

This step is owned by the audit, not by the per-skill `agents` sub-command run. It fires for every audit, every skill, regardless of whether Step 4 sub-command runs completed. The detection itself is cheap (3 grep operations + 4 signal checks per skill) — no agent spawns, no file writes.

**Grounding:** Read [content-bookending.md](../content-bookending.md) before this step for the signal definitions, idempotency rules, and false-positive guardrails.

**Procedure (run for every skill in the filtered skill set):**

1. **Idempotency precheck.** For each skill, run all three checks. ANY match means "already configured":
   - Glob `.claude/skills/<skill>/agents/*/AGENT.md`. Read each. Frontmatter `model: claude-opus-4-6`?
   - Grep `.claude/skills/<skill>/SKILL.md` and `.claude/skills/<skill>/references/procedures/*.md` for the literal string `claude-opus-4-6`.
   - Grep `.claude/skills/<skill>/SKILL.md` for any CHECKPOINT named "Prose Subagent Dispatch", "Subagent Dispatch", or "Content Subagent".
2. **Signal scan** (only if 4d.i found nothing). Compute the four signals from `content-bookending.md` § "Detection signals":
   - Skill grounds against `voice/`, `writing/`, `edit/`, or `text-eval/`
   - Authoring verbs in execute steps ("author", "draft prose", "compose", "write the description", "produce the article")
   - Output contract is freeform paragraphs (not yaml/json/tables)
   - Skill name/description matches content vocabulary (writing, voice, prose, narrative, dialogue, copy, lesson, story, article, post, newsletter, README, docs, documentation, tutorial, runbook, guide)
3. **Classify each skill** as one of:
   - `Already configured` — idempotency check matched
   - `Partially configured` — idempotency matched some authors but not all content surfaces
   - `Applicable` — 2+ signals matched, no existing wiring
   - `Not applicable` — fewer than 2 signals matched
4. **Aggregate** counts: total skills, configured count, partial count, applicable count, not-applicable count.
5. **Pass results to Step 4f** (priority ranking) so the agent panel can rank bookending findings alongside other priorities.
6. **Pass results to Step 5** for inclusion in the aggregate report. The Content Bookending section in Step 5 ALWAYS renders a one-line summary, regardless of whether any skill was applicable. Project-wide visibility on the gap is the point of the step. See § "Step 5: Aggregate Report" → "Content Bookending" for the rendering rules.

**Why this is at audit level rather than inside the agents sub-command:** The original design had detection inside `agents.md` Step 4d, called transitively from audit Step 4. When an auditor (incorrectly) skips the per-skill sub-command runs, the detection silently doesn't fire and the report shows nothing — the user has no signal that the analysis was missed. Lifting detection here makes it independent of Step 4 completeness. The `agents.md` Step 4d still exists for standalone `/skill-builder agents [skill]` invocations.

### Step 4f: Agent panel — priority ranking

After collecting findings from all sub-commands, the audit must rank fixes by priority. This is a judgment call — which fix has the highest impact? Which is most urgent? Per directive: agents are mandatory when guessing is involved.

Spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

- **Agent 1** (persona: Risk analyst — prioritizes by blast radius and failure probability) — Review all findings. Rank by: what breaks first if left unfixed? What affects the most users or invocations?
- **Agent 2** (persona: Developer experience advocate — prioritizes by friction and daily pain) — Review all findings. Rank by: what slows people down the most? What causes the most confusion or repeated mistakes?
- **Agent 3** (persona: Architectural debt specialist — prioritizes by compounding cost) — Review all findings. Rank by: what gets harder to fix over time? What blocks other improvements?

Each agent reads the aggregated findings from optimize, agents, and hooks across all skills. They return independently ranked priority lists. Synthesize:
- Items ranked top-3 by 2+ agents → highest priority
- Items ranked top-3 by only 1 agent → medium priority
- Present the synthesized ranking with attribution to each agent's rationale

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

## Content Bookending
*(Aggregated from Step 4e Content Bookending Detection across all skills. Per `references/content-bookending.md`. **Always include this section** — even when every skill is "not applicable" or zero skills are configured. Project-wide visibility on the gap is the point of the feature; absence-vs-gap is NOT applied here. The one-line summary surfaces the count regardless of state.)*

**Summary line (mandatory, render even when zeros):**

> **Content Bookending:** [N configured] of [M content-producing skills] have `claude-opus-4-6` author subagents wired up. [P applicable, Q partially configured, R not applicable] across [Total] skills audited.

Then render the per-skill table:

| Skill | Status | Signals Matched | Proposed Authors | Persona Drafts | Priority |
|-------|--------|-----------------|------------------|----------------|----------|
| /skill-1 | Applicable | 3/4 (voice ground, authoring verbs, prose output) | role-author-1, role-author-2 | [unique strings] | Medium |
| /skill-2 | Already configured | — (idempotency match) | — | — | — |
| /skill-3 | Partially configured | 4/4 | mission-prose-author | [unique string] | Medium |
| /skill-4 | Not applicable | 1/4 | — | — | — |

Include "Not applicable" rows in the table only when there are fewer than 8 skills total. For larger skill sets, suppress "Not applicable" rows from the table but include their count in the summary line.

**Idempotency note:** Skills marked "Already configured" are detected via existing `model: claude-opus-4-6` frontmatter, dispatch invocations, or Prose Subagent Dispatch CHECKPOINT. Their configurations are NOT modified by audit recommendations. See `content-bookending.md` § "Idempotency".

**If zero skills are content-producing** (M = 0): the summary line still renders as `Content Bookending: 0 of 0 content-producing skills detected. No applicable bookending opportunities.` This confirms the analysis ran and found nothing, distinguishing it from a missed analysis.

## Audit Coverage Gaps
*(Render this section ONLY when one or more analyses did not fire — e.g., a sub-command run was skipped, a tool failure aborted a step, or a permission denial blocked detection. Per Step 4 § "Sub-Command Run Mandate", silent skipping is forbidden. If every analysis fired completely, omit this section entirely.)*

| Analysis | Skill(s) | Reason Not Fired | Impact |
|----------|----------|------------------|--------|
| [e.g., Token Efficiency Scan] | [/skill-1, /skill-2] | [e.g., optimize sub-command run was skipped] | [What detection was missed] |
| [e.g., Agent Opportunities] | [/skill-3] | [e.g., agents sub-command run was skipped] | [What detection was missed] |

Recommend: re-run the audit with the missing analyses, or run the affected sub-commands directly.

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
> 8. `agents --execute` for content bookending — create proposed `claude-opus-4-6` author subagents, add Prose Subagent Dispatch CHECKPOINTs, and rewrite procedures to dispatch *(only if the Content Bookending section reports Applicable or Partially configured for at least one skill)*
> 9. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress.

**Follow § Output Discipline** (in SKILL.md) for cascade execution and cross-skill separation.

### Post-execution notice (audit-level)

Audits in pure display mode (the user picks option 9 / Skip, or runs `audit` without choosing any execute action) MUST NOT prompt for a session restart. Display mode is read-only — nothing was loaded that needs reloading. Adding a restart prompt to read-only output trains users to dismiss it.

When the user selects an execute option that creates or modifies AGENT.md files (options 2, 4, or 8), the executing sub-procedure surfaces its own restart notice per `agents.md` § "Post-execution notice". The audit does NOT duplicate that notice at the orchestrator level; defer to the sub-command.

When the user selects only optimize, hooks (non-agent), ledger, or other non-agent actions, no restart notice is required — those changes take effect when the modified skill is next invoked.
