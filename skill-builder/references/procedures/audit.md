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

Skip Steps 3–5 (they require existing skills) and go directly to Step 6 with the CLAUDE.md-focused execution choices.

### Step 3: Skills Summary Table

```markdown
## Skills Summary
| Skill | Lines | Description | Directives | Reference Inline | Hooks | Teams | Status |
|-------|-------|-------------|------------|------------------|-------|-------|--------|
| /skill-1 | X | single/multi | Y | Z tables | yes/no | yes/no/N/A | OK/NEEDS WORK |

**Description column:** Flag `multi` if uses `|` or `>` syntax (needs optimization to single line)
```

### Step 4: Run Sub-Commands in Display Mode

For each skill found:
1. Run **optimize** in display mode → collect optimization findings
2. Run **agents** in display mode → collect agent opportunities
3. Run **hooks** in display mode → collect hooks inventory and opportunities

### Step 4a: Ledger Status

Check if `.claude/skills/awareness-ledger/SKILL.md` exists.

**If the ledger exists:**
1. Count records: `find .claude/skills/awareness-ledger/ledger -name "*.md" -not -name "index.md"` (excludes index)
2. Check planning-phase integration: scan project CLAUDE.md for awareness ledger reference (grep for "awareness ledger" or "ledger/index.md")
3. If `consult-before-edit.sh` exists in hooks/ or is wired in settings.local.json, flag as obsolete
4. Report:
   ```
   **Awareness Ledger:** Installed
   - Records: [N] (INC: [n], DEC: [n], PAT: [n], FLW: [n])
   - CLAUDE.md integration: [yes/no]
   - Auto-activation directives: [present/missing]
   - Last updated: [date of most recent record file, or "unknown"]
   - Issues: [missing CLAUDE.md line / missing auto-activation / obsolete hook / empty ledger / none]
   ```

4. **Scan for capture integration gaps** — For each skill (excluding skill-builder and awareness-ledger themselves), check whether it produces institutional knowledge but has no capture mechanism:
   - **Produces institutional knowledge?** Check for: investigation/diagnosis workflow steps, decision-making procedures, debugging flows, architectural evaluation, directives referencing past failures
   - **Has capture mechanism?** Check for any one of: capture workflow step in SKILL.md, Capture Recommender agent in `agents/`, `capture-reminder.sh` hook in `hooks/`
   - If a skill produces institutional knowledge but has no capture mechanism, add to the report:
     ```
     **Capture Gaps:**
     | Skill | Knowledge Type | Recommended Mechanism | Procedure |
     |-------|---------------|----------------------|-----------|
     | /[skill] | [diagnostic findings / decisions / patterns] | [workflow step / agent / hook] | Run `optimize`, `agents`, or `hooks` |
     ```
   - Mechanism recommendation follows the hierarchy: workflow step (if capture is a natural final step) > agent (if capture-worthiness requires judgment) > hook (lightweight fallback). See `references/agents.md` § "Capture Recommender Agent" for the full hierarchy.
   - If no gaps found, omit this subsection.

**If the ledger does NOT exist:**
1. Report:
   ```
   **Awareness Ledger:** Not installed
   - Recommendation: Run `/skill-builder ledger` to create institutional memory.
     Captures incidents, decisions, patterns, and flows so diagnostic findings
     and architectural decisions persist across sessions.
   ```
2. This recommendation MUST appear in the report — do NOT skip silently. The audit is the orchestrator; even though optimize/agents/hooks correctly skip ledger analysis when no ledger exists, the audit is responsible for surfacing the gap.

### Step 4b: Self-Heal Status

Check if `.claude/skills/self-heal/SKILL.md` exists.

**If self-heal is installed:**
1. Scan all skills for the Observer Instruction Block (grep for "Self-Heal Observer")
2. Report:
   ```
   **Self-Heal:** Installed
   - Skills with observer embedded: [N]/[total]
   - Skills missing observer: [list, or "none"]
   - Issues: [missing observers / none]
   ```
3. If any skills are missing the observer, add to execution choices:
   > `self-heal embed` — embed observer into skills missing it

   **When `self-heal embed` is selected for execution:**
   For each skill missing the observer:
   a. Read the skill's SKILL.md
   b. Verify line count will stay under 150 after embedding (~15 lines). If it would exceed, flag the skill and recommend running `optimize --execute` on it first to free line budget. Skip embedding for that skill.
   c. If the skill also has a runtime eval protocol section, verify combined infrastructure (observer + eval protocol) does not exceed 50 lines. If it does, flag and skip.
   d. Append the Observer Instruction Block (from `references/self-heal-templates.md` § "Observer Instruction Block") as the last section of SKILL.md
   e. Report: `Embedded self-heal observer into /[skill-name]`

   After all skills are processed, report summary:
   ```
   Self-heal observer embedded: [N] skills
   Skipped (line budget): [list, or "none"]
   ```

**If self-heal is NOT installed:**
1. Report:
   ```
   **Self-Heal:** Not installed
   - Recommendation: Run `/skill-builder self-heal` to install ambient friction
     detection. Skills will learn from session friction and propose surgical
     corrections automatically.
   ```
2. This recommendation MUST appear — do not skip silently. The audit is the orchestrator.

### Step 4c: Agent panel — priority ranking

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
| Skill | Agent Type | Purpose | Routing | Priority |
|-------|------------|---------|---------|----------|
| /skill-1 | id-lookup | Enforce grounding for IDs | Individual/Team/Both | High |
[from agents display mode per skill]

## Hooks Status
[aggregated from hooks display mode]

## Teams Status
- **Env var enabled:** [yes/no]
- **Skills using teams:** [list or "none"]
- **Research assistant present:** [per-team status or N/A]
- **Issues:** [any team-related issues or "none"]

## Awareness Ledger
[from Step 4a — status, record counts, capture gaps, or installation recommendation]

## Self-Heal
[from Step 4b — status, observer coverage, or installation recommendation]

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
> 5. `ledger --execute` — create Awareness Ledger *(only if ledger does not exist)*
> 6. `self-heal --execute` — install Self-Heal companion skill *(only if self-heal does not exist)*
> 7. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress.
