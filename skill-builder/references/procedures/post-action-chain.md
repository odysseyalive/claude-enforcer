## Post-Action Chain Procedure

**Reusable scoped mini-audit triggered after commands that modify a skill (`new`, `inline`).**

Called by: New Command Procedure (Step 5), Adding Directives Procedure (Step 4), Inline Directive Procedure (Step 5).

### Pre-Check: `--no-chain` Flag

If the invoking command included `--no-chain`, skip this entire procedure. Report:

```
Skipping post-action review (--no-chain). Run `/skill-builder optimize [skill]` manually to review.
```

### Step 1: Run Sub-Commands in Display Mode

For the single affected skill, run each sub-command in display mode (read-only):

1. **Optimize** — per [optimize.md](optimize.md), display mode. Collect optimization findings.
2. **Agents** — per [agents.md](agents.md), display mode. Collect agent opportunities.
3. **Hooks** — per [hooks.md](hooks.md), display mode. Collect hooks inventory and opportunities.

### Step 1b: Check Ledger Capture Relevance

If `.claude/skills/awareness-ledger/` exists, evaluate whether the skill modification itself is ledger-worthy:

- **New skill (`new`):** A new skill often encodes a decision (DEC) — why this skill exists, what problem it solves, what alternatives were considered. If the skill's directives reference rationale ("because," "instead of," "to prevent"), flag as a capture opportunity.
- **New directive (`inline`):** A directive often encodes a pattern (PAT) or decision (DEC) — a rule discovered through experience, a constraint chosen after evaluation. If the directive text contains learned knowledge ("we found that," "turns out," "after trying"), flag as a capture opportunity.
- **Structural change:** If the modification adds or reorganizes workflow steps, agents, or hooks, it may encode an architectural pattern (PAT) worth recording.

If any capture opportunity is detected, add to the scoped report (Step 2):
```
### Ledger Capture Opportunity
The modification to /[skill] contains knowledge that may be worth recording:
- **Suggested type:** [DEC/PAT]
- **Source:** [quoted directive or skill description]
- **Action:** Run `/awareness-ledger record` to capture, or skip.
```

And add to the execution choices (Step 3):
> 6. `/awareness-ledger record` — capture this modification as a ledger entry

If the ledger does not exist, skip this step silently.

### Step 2: Present Scoped Report

```markdown
## Post-Action Review: /[skill]

### Optimization Findings
[from optimize display mode — proposed changes, line count, reference splitting recommendation]

### Agent Opportunities
| Agent Type | Recommended | Purpose | Priority |
|------------|-------------|---------|----------|
[from agents display mode]

### Hooks Status
[from hooks display mode — existing hooks, new opportunities, needs-agent-not-hook items]

### Priority Fixes
1. [Most impactful action]
2. [Second priority]
3. [Third priority]
```

If all three sub-commands find nothing actionable, report:

```
Post-action review: No optimization, agent, or hook opportunities found for /[skill]. Skill is clean.
```

### Step 3: Offer Execution Choices

If any opportunities were found, ask:

> "Which actions should I execute?"
> 1. `optimize --execute` for /[skill]
> 2. `agents --execute` for /[skill]
> 3. `hooks --execute` for /[skill]
> 4. All of the above for /[skill]
> 5. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress.
