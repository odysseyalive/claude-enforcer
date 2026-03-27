# Eval History Format Reference

Templates for `eval-history.md` files. Populated by the runtime evaluation protocol after every skill invocation. Used by the pre-flight step to detect trends and apply compensations.

---

## eval-history.md Header

When creating a new `eval-history.md`, start with:

```markdown
# Eval History: [skill-name]

<!-- Append-only log. Do not edit existing entries. -->
<!-- Populated by runtime eval protocol after each skill invocation. -->
<!-- Max depth: 10 runs. Archive older runs to eval-archive.md if needed. -->
```

---

## Run Entry Format

Each post-flight evaluation appends one entry:

```markdown
## Run: YYYY-MM-DD

### Invocation
Task: [what the skill was invoked to do — brief summary]
Output: [what the skill produced — one-line summary]

### Rubric Scores
| Criterion | Score | Delta |
|-----------|-------|-------|
| Directives followed | 3 | ↑ from 2 |
| Output completeness | 2 | → 2 |
| Workflow execution | 1 | ↓ from 2 |

### Findings
- [Specific behavioral finding — what went wrong or right, with evidence]
- [e.g., "Directive X was violated in output line 34 — used Uncategorized despite prohibition"]
- [e.g., "Workflow step 3 was skipped — jumped from analysis to report"]

### Compensation Applied
- [What compensations from history were applied this run, if any]
- [e.g., "Extra scrutiny on ID lookup — chronic failure on directive adherence"]
- [Or "None — first run / no history"]

### Proposed
- [Compensation proposed for future runs based on this run's findings]
- [e.g., "Propose: add hook to block Uncategorized in API calls (3rd consecutive failure)"]
- [Or "None — all criteria ≥ 2"]
```

**Delta computation:**
- First run: all deltas are "—" (baseline)
- Subsequent runs: compare against most recent prior run
- `↑ from N` = score increased from N
- `↓ from N` = score decreased from N
- `→ N` = score unchanged at N

---

## Trend Summary

Trends are computed at read-time from the raw entries — they are NOT stored in the file. The pre-flight step computes trends by reading the last 10 run entries.

**Trend direction indicators (for audit summary):**

| Symbol | Meaning |
|--------|---------|
| ↑ | Improving — most recent score higher than 2 runs ago |
| ↓ | Declining — most recent score lower than 2 runs ago |
| → | Stable — no change over last 3 runs |
| — | Insufficient data (fewer than 2 runs) |

---

## History Depth Management

**Max depth:** Keep the last 10 run entries in `eval-history.md`.

**Archival:** When a new run would exceed the 10-run limit:
1. Move the oldest run entry to `.claude/skills/[skill]/eval-archive.md`
2. If `eval-archive.md` doesn't exist, create it with header: `# Eval Archive: [skill-name]`
3. Append the archived entry to `eval-archive.md`
4. Remove it from `eval-history.md`

Trend detection reads only `eval-history.md` (last 10 runs). Archived data is preserved for reference but not actively analyzed.

---

## Archive Compaction

The archive (`eval-archive.md`) must not grow indefinitely. When the archive exceeds 20 entries, compact it.

**Compaction procedure:**

Replace all individual run entries with a single summary block:

```markdown
## Archive Summary (compacted YYYY-MM-DD)

**Period:** [earliest date] — [latest date]
**Runs:** [N]

### Score Ranges
| Criterion | Min | Max | Final |
|-----------|-----|-----|-------|
| [name] | 1 | 3 | 2 |

### Chronic Issues Resolved
- [Issue]: resolved on [date] via [compensation that worked]

### Compensations Promoted
- [Compensation] → [permanent change] on [date]

### Compensations Retired
- [Compensation] — ineffective, retired on [date]

### Criteria Retired
- [Criterion] — stable at 3 for [N] runs, retired on [date]
```

Individual run entries are deleted. The summary preserves the institutional knowledge (what was learned, what worked, what failed) without the per-run detail.

**After compaction:** The archive contains only summary blocks. Each summary covers the period it replaced. New individual entries accumulate below the summaries until the next compaction threshold.

---

## Lifecycle Entries

In addition to run entries, eval-history.md records lifecycle events inline:

```markdown
## Promoted: YYYY-MM-DD
Compensation: [what was being compensated]
Permanent change: [what was added to the skill — directive, hook, agent, workflow step]
Criterion: [which criterion this addressed]
Score before: [score when compensation was first applied]
Score after: [score at time of promotion]
```

```markdown
## Retired: YYYY-MM-DD
Compensation: [what was being compensated]
Reason: ineffective after [N] runs — score did not improve
Criterion: [which criterion this addressed]
```

```markdown
## Criterion Retired: YYYY-MM-DD
Criterion: [name]
Reason: stable at 3 for [N] consecutive runs
Replacement: [new criterion name, or "none — at minimum"]
```

These entries do NOT count toward the 10-run depth limit. They are metadata, not run data.
