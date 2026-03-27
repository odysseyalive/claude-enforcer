## Audit Command Procedure

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

## Agent Opportunities
| Skill | Agent Type | Purpose | Priority |
|-------|------------|---------|----------|
| /skill-1 | id-lookup | Enforce grounding for IDs | High |
[from agents display mode per skill]

## Hooks Status
[aggregated from hooks display mode]

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
> 8. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress.

**Follow § Output Discipline** (in SKILL.md) for cascade execution and cross-skill separation.
