## Cascade Command Procedure

**Validation cascade analysis — diagnostic only. Never modifies files.**

When running `/skill-builder cascade [skill]` (specific skill) or as part of audit:

### Step 1: Inventory Validators

Count all validation mechanisms attached to the skill:

| Type | Where to Look |
|------|---------------|
| Hooks | `.claude/skills/[skill]/hooks/*.sh` + `settings.local.json` wiring |
| Evaluation agents | `.claude/skills/[skill]/agents/*.md` with evaluation/validator role |
| Text Evaluation Pair | Agent files with "Reducer" or "Clarifier" persona |
| Agent panels in procedures | Procedure files that spawn agents for this skill |
| Inline validation steps | SKILL.md workflow steps that validate before proceeding |

Record: total validator count, validator types, what each validates.

### Step 2: Map Validation Overlap

For each pair of validators, check whether they evaluate the same concern:

```
Validator A: [name] — validates [concern]
Validator B: [name] — validates [concern]
Overlap: [none / partial / full]
```

**Full overlap** = both validators check the same thing (redundant).
**Partial overlap** = validators share some scope but have distinct coverage.
**No overlap** = validators are independent (healthy).

### Step 3: Measure Validation Cost

For each validator, estimate token cost category:

| Cost | Mechanism |
|------|-----------|
| Free | Hook (shell script, no LLM tokens) |
| Cheap | Single agent read + evaluate |
| Moderate | Agent panel (2-3 agents in parallel) |
| Expensive | Agent team with research assistant |

Sum the total validation cost per skill invocation.

### Step 4: Assess Creative Suppression Risk

Check whether validators collectively constrain the skill's creative output:

**High suppression indicators:**
- 3+ validators that evaluate style, tone, or voice
- Evaluation agents whose criteria overlap with hook enforcement (belt AND suspenders on the same concern)
- Validation steps that gate output before any human review
- Text Evaluation Pair + additional style hooks on the same skill

**Low suppression indicators:**
- Validators target different concerns (correctness vs. style vs. security)
- Hook enforcement is limited to mechanical rules (forbidden IDs, required fields)
- Human review is the final gate, not agent evaluation

### Step 5: Classify Cascade Risk

| Risk | Criteria |
|------|----------|
| **NONE** | 0-1 validators. No analysis needed. |
| **LOW** | 2-3 validators with no overlap. Healthy separation of concerns. |
| **MODERATE** | 3-4 validators with partial overlap, OR 2+ style/voice validators. |
| **HIGH** | 5+ validators, OR full overlap between any pair, OR 3+ style validators. |

### Step 6: Report

```markdown
## Validation Cascade Analysis: /[skill-name]

**Validators:** [count]
**Cascade Risk:** [NONE / LOW / MODERATE / HIGH]

### Validator Inventory
| Validator | Type | Validates | Cost |
|-----------|------|-----------|------|
| [name] | [hook/agent/panel/inline] | [what it checks] | [free/cheap/moderate/expensive] |

### Overlap Matrix
| | Validator A | Validator B | ... |
|---|---|---|---|
| Validator A | — | [none/partial/full] | ... |

### Findings
- [List overlaps, redundancies, suppression risks]
- [Recommendations: remove redundant validators, consolidate overlapping ones, rebalance]

### Estimated Cost per Invocation
[Total token cost category for all validators combined]
```

**When run standalone** (`/skill-builder cascade [skill]`): output the full report above.

**When run as part of audit** (Step 4e in audit.md): include findings in the aggregate report under "Validation Cascade." If risk is MODERATE or HIGH, add to Priority Fixes.

**When no skill is specified** (`/skill-builder cascade`): run for all skills, output a summary table:

```markdown
## Validation Cascade Summary

| Skill | Validators | Cascade Risk | Top Finding |
|-------|-----------|-------------|-------------|
| /skill-1 | 3 | LOW | No overlap |
| /skill-2 | 6 | HIGH | 3 style validators with full overlap |
```
