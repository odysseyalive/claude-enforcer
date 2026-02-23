# Awareness Ledger Templates
<!-- Enforcement: HIGH — record structure enables cross-referencing and agent consultation -->

Templates for the awareness-ledger skill. Used by the `ledger` command when creating a new ledger, and by the awareness-ledger skill itself when recording entries.

---

## Record Type Templates

### Incident Record (INC)

**ID format:** `INC-YYYY-MM-DD-slug`
**Modeled on:** Google SRE blameless postmortems, NASA Lessons Learned (LLIS)

```markdown
# INC-YYYY-MM-DD-slug

**Status:** active | resolved | superseded
**Tags:** [domain tags, file paths, function names]
**Related:** [DEC-xxx, PAT-xxx, FLW-xxx, INC-xxx]

## What Happened

[Factual description of the incident. No blame. What was observed?]

## Timeline

| Time/Commit | Event |
|-------------|-------|
| [ref] | [what happened] |

## Root Cause

[Direct technical cause]

## Contributing Factors (Swiss Cheese Layers)

Each layer that had to align for this incident to occur:

1. **[Layer]** — [How this factor contributed]
2. **[Layer]** — [How this factor contributed]

## Resolution

[What was done to fix it]

## Lessons Learned

> **"[Verbatim lesson, in the words of whoever identified it]"**

*— Captured YYYY-MM-DD, source: [conversation / commit / user]*

## Prevention

[What would prevent recurrence — link to DEC or PAT records if applicable]
```

### Decision Record (DEC)

**ID format:** `DEC-YYYY-MM-DD-slug`
**Modeled on:** MADR/ADR standard (Michael Nygard, Olaf Zimmermann)

```markdown
# DEC-YYYY-MM-DD-slug

**Status:** proposed | accepted | deprecated | superseded-by [DEC-xxx]
**Tags:** [domain tags, file paths, architectural area]
**Related:** [INC-xxx, PAT-xxx, FLW-xxx, DEC-xxx]

## Context

[What is the issue that we're seeing that motivates this decision?]

## Decision Drivers

- [Driver 1]
- [Driver 2]

## Options Considered

### Option A: [Name]

- Good, because [argument]
- Bad, because [argument]

### Option B: [Name]

- Good, because [argument]
- Bad, because [argument]

## Decision

Chosen option: **[Option X]**, because [justification].

> **"[Verbatim rationale from the person who made the call]"**

*— Captured YYYY-MM-DD, source: [conversation / commit / user]*

## Consequences

- [Consequence 1 — positive or negative]
- [Consequence 2]

## Confirmation Criteria

[How will we know this decision was right? What would trigger reconsideration?]
```

### Pattern Record (PAT)

**ID format:** `PAT-YYYY-MM-DD-slug`
**Modeled on:** skill-builder patterns.md, with forced counter-evidence examination

```markdown
# PAT-YYYY-MM-DD-slug

**Status:** active | deprecated | under-review
**Tags:** [domain tags, file paths, language/framework]
**Related:** [INC-xxx, DEC-xxx, FLW-xxx, PAT-xxx]

## Pattern

[What is the reusable knowledge?]

## Evidence

Observations supporting this pattern:

1. **[Evidence]** — [source/date]
2. **[Evidence]** — [source/date]

## Counter-Evidence

Observations that challenge or limit this pattern:

1. **[Counter-evidence]** — [source/date]
2. **[Counter-evidence]** — [source/date]

> **"[Verbatim observation, especially if it contradicts the pattern]"**

*— Captured YYYY-MM-DD, source: [conversation / commit / user]*

## Applicability

- **When to use:** [conditions where this pattern applies]
- **When NOT to use:** [conditions where this pattern fails or misleads]

## Confidence

[HIGH / MEDIUM / LOW] — Based on evidence-to-counter-evidence ratio and recency.
```

### Flow Record (FLW)

**ID format:** `FLW-YYYY-MM-DD-slug`
**Novel record type** — addresses proactive flow capture for user/system behavior

```markdown
# FLW-YYYY-MM-DD-slug

**Status:** active | outdated | superseded-by [FLW-xxx]
**Tags:** [domain tags, user action, system component]
**Related:** [INC-xxx, DEC-xxx, PAT-xxx, FLW-xxx]

## Flow Description

[What user action or system process does this flow capture?]

## Steps

| Step | Action | Code Path | Notes |
|------|--------|-----------|-------|
| 1 | [what happens] | `file:line` | [relevant detail] |
| 2 | [what happens] | `file:line` | |

## Environmental Conditions

- [Condition that must be true for this flow to occur]
- [Dependency, version, configuration, etc.]

## Edge Cases

- [Edge case 1]
- [Edge case 2]

> **"[Verbatim observation about this flow]"**

*— Captured YYYY-MM-DD, source: [conversation / commit / user]*
```

---

## Status Lifecycle

All record types follow the same lifecycle:

```
proposed → active → [resolved | deprecated | superseded-by REF]
                  → under-review → active (re-confirmed)
```

- **proposed** — Draft, not yet validated
- **active** — Confirmed and current
- **resolved** — (incidents only) Root cause addressed
- **deprecated** — No longer applicable
- **superseded-by [REF]** — Replaced by a newer record
- **under-review** — Being re-evaluated (patterns especially)

---

## Index Generation Rules

The `ledger/index.md` file is regenerated when records are added or updated. Format:

```markdown
# Awareness Ledger Index

*Auto-generated. Last updated: YYYY-MM-DD*

## By Tag

### [tag-name]
- [ID] — [one-line summary] (status)
- [ID] — [one-line summary] (status)

## By Status

### Active
- [ID] — [one-line summary] [tags]

### Resolved
- [ID] — [one-line summary] [tags]

### Under Review
- [ID] — [one-line summary] [tags]

## Relationship Map

- [ID] → related to [ID], [ID]
- [ID] → superseded by [ID]

## Statistics

| Type | Total | Active | Resolved | Deprecated |
|------|-------|--------|----------|------------|
| Incidents | N | N | N | N |
| Decisions | N | N | N | N |
| Patterns | N | N | N | N |
| Flows | N | N | N | N |
```

**Tag-based grouping:** Group by the most common tags across all records. Tags should be file paths, function names, domain areas, or component names — anything that helps agents match records to the current work context.

---

## Consultation Briefing Format

When agents produce findings, synthesize into this format:

```markdown
## Ledger Consultation

### Warnings (HIGH confidence — agents agree)

- **[Warning]** — [INC/DEC/PAT/FLW reference] — [one-line explanation]

### Considerations (agents disagree — investigate the disagreement)

- **[Topic]**
  - Regression Hunter: [finding]
  - Skeptic: [finding]
  - Premortem Analyst: [finding]

### Context (relevant records, no warnings)

- [ID] — [why it's relevant but not a warning]

### No Records

No ledger records match the current context. Proceeding without historical consultation.

### Capture Opportunity

The current conversation contains knowledge not yet in the ledger:
- **Suggested type:** [INC/DEC/PAT/FLW]
- **Suggested ID:** [auto-generated from context]
- **Source material:** [quote from conversation]

Confirm to record, or skip.
```

<!-- Consumed by: optimize.md Step 4d (capture integration), agents.md Step 4b (capture agent evaluation), post-action-chain.md Step 1b (ledger capture relevance), audit.md Step 4a (capture gaps) -->

**Proportional overhead rules:**

| Match Scope | Agents Spawned | Rationale |
|-------------|----------------|-----------|
| No records match | None | Zero overhead until records exist |
| Only incidents/flows match | Regression Hunter only | Single relevant perspective |
| Only decisions/patterns match | Skeptic only | Single relevant perspective |
| Risk/failure language detected | Premortem Analyst only | Targeted premortem |
| Multiple record types match | All three agents (full panel) | Cross-referencing needed |

---

## Capture Trigger Patterns

Conversation signals that suggest a record should be created:

### Incident Triggers

- Rollback or revert language: "roll back," "revert," "undo," "broke," "regression"
- Error investigation: "root cause," "why did this," "what went wrong"
- Post-fix reflection: "that was caused by," "the fix was," "lesson learned"

### Decision Triggers

- Choice justification: "I chose X because," "we should use X instead of Y"
- Trade-off discussion: "the trade-off is," "downside of this approach"
- Architecture language: "going forward," "from now on," "the pattern should be"

### Pattern Triggers

- Repeated observation: "this keeps happening," "every time we," "I've noticed"
- Rule discovery: "turns out," "the trick is," "what works is"
- Exception identification: "except when," "doesn't apply to," "unless"

### Flow Triggers

- Step-by-step debugging: "first it does X, then Y, then Z"
- User behavior description: "when the user does X," "the flow is"
- Environment-specific: "only happens when," "requires X to be running"

**Capture is always user-confirmed.** Agents suggest, user decides. Directives are sacred — never auto-record.

<!-- Consumed by: optimize.md Step 4d (trigger pattern matching), hooks.md Step 3a-ii (capture-reminder hook), agents.md § Capture Recommender Agent (trigger detection logic) -->

---

## Agent Definitions

### Regression Hunter

```yaml
---
name: regression-hunter
description: Search past incidents and flows for overlap with current change
persona: "Veteran QA engineer who has seen the same bug return three times — methodical, pattern-obsessed, treats every change as a potential recurrence vector"
allowed-tools: Read, Glob, Grep
context: none
---
```

**Instructions:** Read `ledger/incidents/` and `ledger/flows/` for active records. Compare file paths, function names, and tags against the current change context. Report any overlap with severity assessment. If a previous incident touched the same files or logic, flag it as a recurrence risk.

**Operationalizes:** Recognition-Primed Decision Making — augments historical pattern matching with systematic cross-referencing of past failures.

### Skeptic

```yaml
---
name: skeptic
description: Challenge assumptions against counter-evidence in decisions and patterns
persona: "Epistemologist who treats every assumption as a hypothesis requiring evidence — never hostile, always curious, relentlessly asks 'what if we're wrong?'"
allowed-tools: Read, Glob, Grep
context: none
---
```

**Instructions:** Read `ledger/decisions/` and `ledger/patterns/` for active records. Focus on counter-evidence fields and confirmation criteria. For each relevant record, assess whether the current approach contradicts existing counter-evidence or violates confirmation criteria. Report challenged assumptions with the specific counter-evidence.

**Operationalizes:** Confirmation bias mitigation — forces examination of contradictory evidence that natural reasoning tends to dismiss.

### Premortem Analyst

```yaml
---
name: premortem-analyst
description: Imagine the proposed change has already failed and work backward
persona: "Risk specialist trained in Gary Klein's premortem methodology — assumes failure has already happened, then reverse-engineers the most likely causes"
allowed-tools: Read, Glob, Grep
context: none
---
```

**Instructions:** Read `ledger/index.md` for full scope. Given the current change context, assume the change has already been deployed and has failed. Work backward: what are the three most likely causes of failure? Cross-reference each against ledger records. Report failure scenarios ranked by likelihood, with links to supporting records.

**Operationalizes:** Klein's Premortem technique — research shows 30% improvement in identifying failure causes by imagining failure first rather than trying to predict it.

---

## Hook Definition

### consult-before-edit.sh

```bash
#!/bin/bash
# Awareness Ledger: consultation trigger
# PreToolUse hook on Edit/Write
# Exits 0 always (awareness, not blocking)
# Outputs stderr reminder when edits target project source files

TOOL_NAME="$1"

# Only trigger on Edit and Write
if [[ "$TOOL_NAME" != "Edit" && "$TOOL_NAME" != "Write" ]]; then
    exit 0
fi

# Read file_path from stdin (JSON)
FILE_PATH=$(cat /dev/stdin | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')

# Skip .claude/ infrastructure files
if [[ "$FILE_PATH" == *".claude/"* ]]; then
    exit 0
fi

# Check if ledger has any records
LEDGER_DIR=".claude/skills/awareness-ledger/ledger"
RECORD_COUNT=$(find "$LEDGER_DIR/incidents" "$LEDGER_DIR/decisions" "$LEDGER_DIR/patterns" "$LEDGER_DIR/flows" -name "*.md" 2>/dev/null | wc -l)

if [[ "$RECORD_COUNT" -gt 0 ]]; then
    echo "Awareness Ledger: $RECORD_COUNT records available. Consider /awareness-ledger consult before this change." >&2
fi

exit 0
```

**Wiring (settings.local.json):**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "command": ".claude/skills/awareness-ledger/hooks/consult-before-edit.sh $TOOL_NAME"
      }
    ]
  }
}
```

### capture-reminder.sh

```bash
#!/bin/bash
# Awareness Ledger: post-action capture reminder
# PostToolUse hook on Task (fires after agent/skill completion)
# Exits 0 always (awareness, not blocking)
# Outputs stderr reminder when skill output may contain capturable knowledge

TOOL_NAME="$1"

# Only trigger on Task (skill/agent completion)
if [[ "$TOOL_NAME" != "Task" ]]; then
    exit 0
fi

# Check if ledger exists
LEDGER_DIR=".claude/skills/awareness-ledger/ledger"
if [[ ! -d "$LEDGER_DIR" ]]; then
    exit 0
fi

echo "Awareness Ledger: Skill completed. If findings, decisions, or patterns emerged, consider recording with /awareness-ledger record." >&2

exit 0
```

**Wiring (settings.local.json):**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Task",
        "command": ".claude/skills/awareness-ledger/hooks/capture-reminder.sh $TOOL_NAME"
      }
    ]
  }
}
```

<!-- Consumed by: hooks.md Step 3a-ii (post-action capture hook template) -->

---
*Created by skill-builder ledger command. Templates modeled on Google SRE postmortems, MADR/ADR, NASA LLIS, and Klein's premortem methodology.*
