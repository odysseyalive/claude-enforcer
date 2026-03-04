# Temporal Reference Validation

LLMs are unreliable at date/time math. They confidently produce wrong temporal claims — writing "a few weeks later" for a 92-day gap, or miscalculating relative dates. Temporal validation hooks perform deterministic datetime arithmetic that the model cannot reliably do.

## Temporal Risk Classification

| Risk Level | Indicators | Action |
|------------|-----------|--------|
| **HIGH** | Content-creation skill with citations/references containing dates; scheduling/calendar workflows; data reporting with date ranges; directives requiring temporal accuracy ("dates must be accurate," "verify timelines") | Temporal validation hook recommended |
| **MEDIUM** | Skills that generate date-stamped output; changelog/release note workflows; skills referencing "recent," "latest," or "current" in output | Temporal validation hook available |
| **LOW** | Skills that consume but don't produce dates; date appears only in metadata/frontmatter; purely mechanical date stamping | No action needed |

**Highest-risk pattern:** Content-creation skills that produce prose with embedded references (articles, newsletters, reports). These combine the model's tendency to hallucinate temporal relationships with citations that readers will verify. A hook catches what the model cannot.

## Temporal Phrase → Day-Range Mapping

| Phrase Pattern | Expected Range (days) | Category |
|---------------|----------------------|----------|
| "yesterday" | 1 | Explicit |
| "a few days ago/later" | 2–4 | Quantified |
| "last week" / "a week ago" | 5–9 | Quantified |
| "a couple of weeks" | 10–18 | Quantified |
| "a few weeks" | 14–28 | Quantified |
| "last month" / "a month ago" | 25–35 | Quantified |
| "a couple of months" | 50–70 | Quantified |
| "a few months" | 60–120 | Quantified |
| "earlier this year" | context-dependent | Generic |
| "last year" | 330–400 | Quantified |
| "recently" / "lately" | 1–30 | Generic |
| "soon" / "shortly" | 1–14 | Generic |
| "[N] days/weeks/months ago/later" | compute from N | Explicit range |
| "since [date]" / "from [date] to [date]" | compute from dates | Relative-to-now |

## Hook Generation Specification

This section defines the architecture for temporal validation hooks. No scripts are included — generate hooks on target systems adapted to available toolchains.

### Scope Check

- **Content files only.** Skip `.claude/` infrastructure files (skills, hooks, agents, settings).
- **Edit vs. Write handling:** For `Write` tool calls, validate all content. For `Edit` tool calls, validate only the `new_string` content (the incoming change, not the existing file).

### Detection Patterns

Four regex categories to scan for temporal phrases in tool input:

1. **Quantified phrases:** `(a few|a couple of|several)\s+(days?|weeks?|months?|years?)\s+(ago|later|after|before|earlier|since)`
2. **Generic temporal:** `(recently|lately|soon|shortly|earlier this|last)\s*(week|month|year|time|spring|summer|fall|winter)?`
3. **Explicit ranges:** `(since|from|between)\s+\w+\s+\d{1,2},?\s*\d{4}` and `\d+\s+(days?|weeks?|months?)\s+(ago|later|after|before)`
4. **Relative-to-now:** `(today|yesterday|tomorrow|this\s+(week|month|year)|next\s+(week|month|year)|last\s+(week|month|year))`

### Date Anchor Extraction

When a temporal phrase is detected:

1. Extract a ~500-character radius around the phrase
2. Search that context window for date anchors: ISO dates (`YYYY-MM-DD`), written dates (`Month DD, YYYY`), partial dates (`Month YYYY`, `MM/DD/YYYY`)
3. If two dates found, compute the actual day gap and compare against the phrase's expected range from the mapping table
4. If the computed gap falls outside the expected range, block with specifics

### Year Inference Heuristic

When a date lacks an explicit year:

- If the referenced month is **later** than the content's context month → assume **previous year**
- If the referenced month is **earlier or same** → assume **current year**
- When in doubt, do not block (exit 0) — false positives erode trust

### Non-Prose Stripping

Before scanning, strip content that shouldn't trigger temporal validation:

- YAML/TOML frontmatter (between `---` or `+++` delimiters)
- Image alt text (`![...](...)`)
- HTML comments (`<!-- ... -->`)
- Code blocks (between `` ``` `` fences)
- Captions in known patterns (`*Caption:*`, `<figcaption>`)

### Tool Detection Order

Hooks must perform datetime arithmetic. Detect available tools in this order:

1. **Python `datetime`** (preferred) — `python3 -c "from datetime import date; ..."` Most portable and precise.
2. **GNU `date`** — `date -d "2024-01-15" +%s` Converts to epoch seconds for arithmetic.
3. **BSD `date`** (macOS default) — `date -j -f "%Y-%m-%d" "2024-01-15" +%s` Different flag syntax.

The generated hook should detect which tool is available at runtime and use the first match.

### Exit Behavior

- **Mismatch detected:** `echo "BLOCKED: Temporal mismatch — '[phrase]' used for [N]-day gap (expected [range]). Verify the date relationship." >&2` then `exit 2`
- **Temporal phrase found but unverifiable** (no anchor dates in context): `exit 0` — allow the content through. The hook catches provable mismatches, not potential ones.
- **No temporal phrases found:** `exit 0`

### Reference Implementation

A working implementation of this pattern exists in the Odyssey Alive project at `.claude/skills/focus/hooks/check-temporal-refs.sh`. That hook validates temporal references in content files against citation dates, using Python datetime for arithmetic with GNU date as fallback.

## Integration Points

- **Optimize procedure** (Step 4e): Classifies temporal risk during skill audit
- **Hooks procedure** (Step 3c): Detects temporal validation opportunities and generates hook specs
- **Audit procedure** (Step 4c): Aggregates temporal risk across all skills
- **New skill procedure** (Step 2): Flags content-creation skills with citation workflows for temporal risk during post-action chain
