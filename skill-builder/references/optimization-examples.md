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
