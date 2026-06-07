## Post-Action Chain Procedure

**Reusable scoped mini-audit triggered after commands that modify a skill (`new`, `inline`).**

Called by: New Command Procedure (Step 5), Adding Directives Procedure (Step 4), Inline Directive Procedure (Step 5) — and, for Step 1a's scoped route reconciliation only, by EVERY skill-mutating execute path (`convert --execute`, `agents --execute`, `optimize --execute`, `code-eval create`) per SKILL.md § Display/Execute Mode Convention rule 6.

### Pre-Check: `--no-chain` Flag

If the invoking command included `--no-chain`, skip this entire procedure. Report:

```
Skipping post-action review (--no-chain). Optimization opportunities may exist.
```

### Step 1: Run Sub-Commands in Display Mode

For the single affected skill, run each sub-command in display mode (read-only):

1. **Optimize** — per [optimize.md](optimize.md), display mode. Collect optimization findings.
2. **Agents** — per [agents.md](agents.md), display mode. Collect agent opportunities.
3. **Hooks** — per [hooks.md](hooks.md), display mode. Collect hooks inventory and opportunities.

### Step 1a: Scoped Route Reconciliation (ALWAYS chained — 2-Brain Harness, 2026-06-06)

Route index + embed are the harness's circulatory system: a skill mutation that bypasses them leaves the catalog stale (the skill or its new functions are unroutable / wrongly-laned) and its managed blocks unreconciled (a new lane declaration without its slim gate). Therefore EVERY command that creates or modifies a skill — `new`, `inline`, `convert --execute`, `agents --execute`, `optimize --execute`, `code-eval create` — chains, for the affected skill(s) only:

1. **Scoped `route index`** — re-extract the affected skill's catalog row (description, modes per the Mode-Detection Ladder, lane + provenance). New skills and newly generated functions enter the index the moment they exist. Low-risk, executes with the parent command's execute consent.
2. **Scoped `route embed` reconciliation** — re-classify the affected skill for all four managed-block families (ROUTE-EMBED / CODE-EVAL-EMBED / MODEL-LANE-GATE / LANE-AGENT-EMBED reconcile-only) and report NEW/REFRESH/REMOVE/NOOP. In a display-mode chain, this is report-only; in an execute chain it applies with the same consent the parent command already carried.

The FULL-project reconciliation remains audit's terminal Step 4g — this scoped pass keeps individual mutations current between audits, not instead of them. `--no-chain` suppresses this step along with the rest of the chain.

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
```

And add to a **Related Suggestions** footer in the report (per § Output Discipline — this is a cross-skill action):
```markdown
### Related Suggestions (other skills)
- `/awareness-ledger record` — capture this modification as a ledger entry
```

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

**Under-audit suppression (Audit Autonomy Gate, 2026-06-06):** when this chain fires INSIDE an audit run (e.g., bootstrap extraction created the skill), do NOT present the menu — the audit's Step 0 disclaimer consent covers the chain. Execute the AUTO-tier opportunities directly (same tiers as audit.md § Step 6) and route the DEFER tier into the audit's Deferred Items table. The menu below applies only when the chain's parent is a standalone command (`new`, `inline`, …).

If any opportunities were found (standalone parent), use **AskUserQuestion** to present execution choices:

> "Which actions should I execute?"
> 1. `optimize --execute` for /[skill]
> 2. `agents --execute` for /[skill]
> 3. `hooks --execute` for /[skill]
> 4. All of the above for /[skill]
> 5. Skip — just review for now

When the user selects execution targets, generate a **combined task list** via TaskCreate before any files are modified — one task per discrete action across all selected sub-commands. Then execute sequentially, marking progress.

**Follow § Output Discipline** (in SKILL.md) for cascade execution and cross-skill separation.
