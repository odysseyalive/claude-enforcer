# Optimization Examples & Targets

## Safe Optimization Example

**Before optimization (all in SKILL.md, 100 lines):**

```markdown
# Budget Skill

## Rules
- Never use Uncategorized account
- Always ask before allocating > $100

## Workflow
1. Get uncategorized transactions
2. Match vendor to category
3. Apply via API

## Category IDs
| Category | ID |
|----------|-----|
| Groceries | 20df1075-d833-4701-bd36-48af716e3104 |
| Dining | 8c606c51-11d9-41ca-9d15-cb86b25069ce |
[... 50 more rows ...]

## Vendor Mappings
| Vendor | Category |
|--------|----------|
| Whole Foods | Groceries |
[... 30 more rows ...]
```

**After optimization (SKILL.md 30 lines + reference.md 70 lines):**

`SKILL.md`:
```markdown
# Budget Skill

## Directives

> **Never use Uncategorized account.**
> **Always ask before allocating > $100.**

*— Source: original skill*

## Workflow

1. Get uncategorized transactions
2. Match vendor to category
3. Apply via API

## Grounding

Before using any category ID, state: "I will use [ID] for [category], found in reference.md under Category IDs"

See [reference.md](reference.md) for IDs and mappings.
```

`reference.md`:
```markdown
# Budget Reference

## Category IDs
| Category | ID |
|----------|-----|
| Groceries | 20df1075-d833-4701-bd36-48af716e3104 |
| Dining | 8c606c51-11d9-41ca-9d15-cb86b25069ce |
[... 50 more rows - COPIED VERBATIM ...]

## Vendor Mappings
| Vendor | Category |
|--------|----------|
| Whole Foods | Groceries |
[... 30 more rows - COPIED VERBATIM ...]
```

**What changed:**
- Tables MOVED (not rewritten)
- Directives QUOTED (not summarized)
- Workflow UNCHANGED
- Grounding ADDED

**What didn't change:**
- Every table row identical
- Every directive word-for-word
- Every workflow step in same order

---

## Optimization Targets (What CAN Be Moved)

**Optimization = MOVE, not rewrite.**

| Content | Action | Destination |
|---------|--------|-------------|
| ID/account tables | **Copy verbatim** | `reference.md` |
| API endpoint docs | **Copy verbatim** | `reference.md` |
| Category/payee mappings | **Copy verbatim** | `reference.md` |
| Rate limit info | **Copy verbatim** | `reference.md` |
| Example API calls | **Copy verbatim** | `reference.md` |

**What stays in SKILL.md (never moved):**
- Directives (user's rules) — verbatim
- Workflows (step sequences) — verbatim
- Grounding requirements
- Decision logic ("if X, then Y")

**What gets ADDED (not changed):**
- Link to reference.md: `See [reference.md](reference.md) for IDs`
- Grounding statement: "State which ID you will use and where you found it"
- Enforcement hooks (optional)

**What NEVER happens:**
- Rewriting instructions
- Condensing workflows
- Summarizing directives
- Removing "redundant" steps
- Changing the order of operations
- Reorganizing agent workflow phases, blocking gates, or pre-conditions
- Removing content that enforces a directive through structure (see enforcement.md § "Behavior Preservation")
- Consolidating steps that have data flow dependencies between them
- Treating declaration (SKILL.md) + implementation (agent file) as duplication

---

## Reference Splitting Example

When a skill's `reference.md` exceeds 100 lines with 3+ h2 sections (each >20 lines), split into a `references/` directory. Each file becomes an enforcement boundary.

**Before (single `reference.md`, 142 lines):**

```markdown
# Budget Reference

## Account IDs
| Account | ID |
|---------|-----|
| Checking | a1b2c3d4-... |
| Savings | e5f6g7h8-... |
[... 30 rows ...]

## Category Mappings
| Vendor | Category |
|--------|----------|
| Whole Foods | Groceries |
[... 40 rows ...]

## Budget Constraints
| Category | Monthly Limit | Alert Threshold |
|----------|--------------|-----------------|
| Dining | $500 | 80% |
[... 30 rows ...]
```

**After (3 domain files in `references/`):**

`references/ids.md`:
```markdown
# Account IDs
<!-- Enforcement: HIGH — hook (block unknown IDs) + agent (validate lookups) -->

| Account | ID |
|---------|-----|
| Checking | a1b2c3d4-... |
| Savings | e5f6g7h8-... |
[... 30 rows — COPIED VERBATIM ...]
```

`references/mappings.md`:
```markdown
# Category Mappings
<!-- Enforcement: HIGH — agent (validate vendor→category matches) -->

| Vendor | Category |
|--------|----------|
| Whole Foods | Groceries |
[... 40 rows — COPIED VERBATIM ...]
```

`references/constraints.md`:
```markdown
# Budget Constraints
<!-- Enforcement: MEDIUM — hook (block over-limit allocations) -->

| Category | Monthly Limit | Alert Threshold |
|----------|--------------|-----------------|
| Dining | $500 | 80% |
[... 30 rows — COPIED VERBATIM ...]
```

**Updated grounding section in SKILL.md (before → after):**

Before:
```markdown
## Grounding

Before using any ID or value from reference.md:
1. Read reference.md
2. State: "I will use [VALUE] for [PURPOSE], found under [SECTION]"

See [reference.md](reference.md) for IDs and mappings.
```

After:
```markdown
## Grounding

Before using any ID, mapping, or constraint:
1. Read the relevant file from `references/`
2. State: "I will use [VALUE] for [PURPOSE], found in references/[file] under [SECTION]"

Reference files:
- [references/ids.md](references/ids.md) — Account IDs
- [references/mappings.md](references/mappings.md) — Vendor→category mappings
- [references/constraints.md](references/constraints.md) — Budget limits and thresholds
```

**Migration steps:**

1. Create `references/` directory
2. Split each h2 section verbatim into its domain file
3. Add enforcement attribution comment to each file
4. Update grounding links in SKILL.md
5. Verify all grounding links resolve
6. Delete original `reference.md`

**Enforcement opportunities per file:**

| File | Domain | Priority | Mechanism |
|------|--------|----------|-----------|
| `ids.md` | IDs/accounts | HIGH | Hook (block unknown IDs) + Agent (validate lookups) |
| `mappings.md` | Vendor→category | HIGH | Agent (validate matches) |
| `constraints.md` | Budget limits | MEDIUM | Hook (block over-limit values) |
