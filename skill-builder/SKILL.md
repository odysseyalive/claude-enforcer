---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new [name], optimize [skill], agents [skill], hooks [skill]"
allowed-tools: Read, Glob, Grep, Write, Edit
---

# Skill Builder

## Quick Commands

| Command | Action |
|---------|--------|
| `/skill-builder` | Full audit of CLAUDE.md + all skills + rules + agents |
| `/skill-builder audit` | Same as above |
| `/skill-builder skills` | List all local skills available in this project |
| `/skill-builder list [skill]` | Show all modes/options for a skill in a table |
| `/skill-builder new [name]` | Create a new skill from template |
| `/skill-builder optimize [skill]` | Restructure a specific skill |
| `/skill-builder agents [skill]` | Analyze and create agents for a skill |
| `/skill-builder hooks [skill]` | Inventory existing hooks + identify new opportunities |

---

## The `skills` Command

**List all local skills available in this project.**

When invoked with `/skill-builder skills`:

1. Glob for all `.claude/skills/*/SKILL.md` files
2. Read each skill's frontmatter to extract name and description
3. Output a table of all available skills

### Output Format

```
| Skill | Description |
|-------|-------------|
| /deploy | Deploy application to staging or production |
| /api-client | API client integration and authentication |
| /db-migrate | Database migration management |
...
```

### Implementation

```bash
# Find all skills
.claude/skills/*/SKILL.md
```

For each skill file:
1. Read the frontmatter
2. Extract `name` and `description` fields
3. Format as table row: `| /[name] | [description] |`

Sort alphabetically by skill name.

---

## The `list` Mode Requirement

**Every skill with multiple modes MUST support a `list` mode.**

When a user runs `/skill-name list`, output a clean table showing all available modes:

```
| Mode | Command | Purpose |
|------|---------|---------|
| **mode1** | `/skill-name mode1 [args]` | Brief description of what this mode does |
| **mode2** | `/skill-name mode2 [args]` | Brief description of what this mode does |
```

### Why This Matters

The `description:` field in frontmatter is limited to one line and gets truncated. Users need a way to discover all available options without reading the full SKILL.md.

### Implementation

Skills with modes should include a `## Usage` section near the top:

```markdown
## Usage

```
/skill-name [mode] [args]
```

### Modes

| Mode | Command | Description |
|------|---------|-------------|
| `mode1` | `/skill-name mode1 [args]` | What mode1 does |
| `mode2` | `/skill-name mode2 [args]` | What mode2 does |

Default mode is `[default]` if not specified.
```

### Handling `/skill-name list`

When invoked with `list` as the first argument:
1. Read the skill's SKILL.md
2. Find the Modes table
3. Output the table directly to the user

**This is a reserved mode name.** Skills should not use `list` for other purposes.

### Audit Check

When auditing skills, verify:
- Does the skill have multiple modes? → Must have a Modes table
- Is the Modes table in a consistent format? → Command + Description columns
- Does the description mention `list` if applicable? → Add to frontmatter

---

## Full Audit Workflow

**When invoked without arguments, run the full audit:**

### Step 1: Gather Metrics

```
Files to scan:
- CLAUDE.md
- .claude/rules/*.md (if exists)
- .claude/skills/*/SKILL.md
```

### Step 2: Generate Report

```markdown
# Skill System Audit Report

## CLAUDE.md
- **Lines:** [X] (target: < 150)
- **Extraction candidates:** [list sections that could move to skills]

## Rules Files
- **Found:** [count] files in .claude/rules/
- **Should convert to skills:** [yes/no with reasoning]

## Skills Summary
| Skill | Lines | Description | Directives | Reference Inline | Hooks | Status |
|-------|-------|-------------|------------|------------------|-------|--------|
| /skill-1 | X | single/multi | Y | Z tables | yes/no | OK/NEEDS WORK |

**Description column:** Flag `multi` if uses `|` or `>` syntax (needs optimization to single line)

## Priority Fixes
1. [Most impactful optimization]
2. [Second priority]
3. [Third priority]

## Agent Opportunities
| Skill | Agent Type | Purpose | Priority |
|-------|------------|---------|----------|
| /skill-1 | id-lookup | Enforce grounding for IDs | High |
| /skill-2 | validator | Pre-flight validation | Medium |

## Directives Inventory
[List all directives found across all skills - ensures nothing is lost]
```

### Step 3: Offer Actions

After presenting the report, ask:
> "Which would you like me to do first?"
> 1. Optimize [highest priority item]
> 2. Show detailed audit for a specific skill
> 3. Create missing reference.md files
> 4. Set up enforcement hooks
> 5. Create agents for [skill with highest agent opportunity]
> 6. Full optimization (reference.md + hooks + agents) for a skill

---

## Core Principles

**IMPORTANT: Never break anything.**

Optimization is RESTRUCTURING, not REWRITING. The skill must behave identically after optimization.

**YOU MUST:**

1. **MOVE content, don't rewrite it** — Copy verbatim to new location
2. **PRESERVE all directives exactly** — User's words are sacred
3. **KEEP all workflows intact** — Same steps, same order, same logic
4. **TEST nothing changes** — After optimization, skill works identically

**What optimization IS:**
- Moving reference tables to `reference.md`
- Moving IDs/accounts to `reference.md`
- Adding grounding requirements
- Creating enforcement hooks
- Splitting into SKILL.md + reference.md

**What optimization is NOT:**
- Rewriting instructions "for clarity"
- Condensing workflows "for brevity"
- Changing step order "for efficiency"
- Removing "redundant" content
- Summarizing user directives

**The test:** If the original author reviewed the optimized skill, they should say "this does exactly what mine did, just organized differently."

---

## Context Mutability & Enforcement Hierarchy

CLAUDE.md and skills load at conversation start. Under long context windows, Claude's adherence to these instructions **drifts** — directives get forgotten or reinterpreted.

### What's Mutable (Can Drift)

- CLAUDE.md instructions
- Rules (`.claude/rules/*.md`)
- Directives in SKILL.md (once loaded)
- Grounding statements ("state which ID...")
- Any text-based instruction in context

### What's Immutable (External Enforcement)

- **Hooks** — Bash scripts run outside Claude's context, block regardless of drift
- **Agents with `context: none`** — Fresh subprocess, reads files without inherited drift

### Enforcement Hierarchy

| Level | Mechanism | Drift-Resistant? | Use For |
|-------|-----------|------------------|---------|
| Guidance | Directives in SKILL.md | No | Soft preferences |
| Grounding | "State which ID you'll use" | No | Important but not critical |
| Validation | Agent (`context: none`) | Yes | Important rules |
| Hard block | Hook (PreToolUse) | Yes | Critical/never-violate |

### Skill-Builder Recommendations

When optimizing or creating skills:

- **Soft guidance** → Directives only
- **Important rules** → Directives + agent validation
- **Critical rules** → Directives + hook enforcement

### Why Not Rules?

Rules (`.claude/rules/*.md`) are:
- Always loaded (wastes context on irrelevant tasks)
- Mutable under long context (same drift problem as CLAUDE.md)
- Redundant when you have skills

Prefer: Lean CLAUDE.md (~100-150 lines) + on-demand skills + hooks for critical enforcement.

---

**Directives are sacred.**

When a user says "Never use Uncategorized accounts" — those exact words stay in the skill, verbatim, forever.

**YOU MUST distinguish between:**

| Content Type | Can Compress? | Where It Lives |
|--------------|---------------|----------------|
| **Directives** (user's exact rules) | NEVER | Top of SKILL.md, verbatim |
| **Reference** (IDs, tables, theory) | YES | Separate reference.md |
| **Machinery** (hooks, agents, chains) | YES | settings.json, hooks/, agents |

---

## The Sacred Directive Pattern

When a user gives you a rule, store it verbatim in a `## Directives` section:

```markdown
## Directives

> **NEVER assign a transaction or expense to Uncategorized or Other Expenses.**
> Every transaction must go to a specific, meaningful expense category.
> If a transaction doesn't clearly match a known category, stop and ask.

*— Added 2026-01-15, source: user instruction*
```

**Rules for directives:**
1. Quote the user's exact words
2. Add source and date
3. Place at TOP of skill file
4. NEVER summarize or reword for brevity
5. Enforce with hooks when possible

---

## Enforcement Mechanisms

### 1. PreToolUse Hooks (Strongest)

Block actions that violate directives BEFORE they execute:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": ".claude/skills/my-skill/hooks/validate.sh"
      }]
    }]
  }
}
```

Hook script exits 2 to block, 0 to allow. Receives JSON via stdin.

### 2. Permission Denials (Deny always wins)

```json
{
  "permissions": {
    "deny": ["Edit(.env)", "Bash(rm:*)"],
    "allow": ["Read", "Bash(curl:*)"]
  }
}
```

Deny rules are evaluated FIRST and cannot be overridden.

### 3. Allowed-Tools in Skills (Workflow restriction)

```yaml
---
allowed-tools: Read, Grep, Glob
---
```

Claude needs explicit permission for tools not listed.

### 4. Subagents with Tool Restrictions

Delegate to a specialized agent with limited tools:

```yaml
---
name: read-only-analyst
allowed-tools: Read, Grep, Glob, WebSearch
context: fork
---
```

---

## Agents

Agents are specialized subprocesses that handle specific tasks with isolation and tool restrictions.

### When to Use Agents vs Hooks

| Mechanism | Use When | Strengths | Weaknesses |
|-----------|----------|-----------|------------|
| **Hooks** | Hard rules, forbidden values, simple validation | Fast, blocks before execution, no token cost | Limited logic, can't reason |
| **Agents** | Judgment calls, multi-file lookups, complex validation | Can reason, access context, make decisions | Slower, costs tokens |

**Rule of thumb:** Use hooks for "never do X", use agents for "figure out the right X".

### Agent Opportunity Detection

When auditing a skill, look for these patterns that suggest an agent would help:

| Pattern | Agent Type | Example |
|---------|------------|---------|
| "Read reference.md before..." | **ID Lookup Agent** | Get category ID before categorizing |
| "Verify that..." | **Validator Agent** | Check all required fields before submit |
| "Evaluate for..." | **Evaluation Agent** | Check output quality, validate formatting |
| "Match X to Y" | **Matcher Agent** | Match payee to category |
| "If unclear, ask" | **Triage Agent** | Determine if user input is needed |

### Agent Templates

#### 1. ID Lookup Agent (Grounding Enforcement)

**Purpose:** Guarantee IDs come from reference.md, not from Claude's memory.

```markdown
---
name: id-lookup
description: Look up IDs from reference files
allowed-tools: Read, Grep
context: none
---

# ID Lookup Agent

You are a reference lookup agent. Given a request, read the appropriate
reference.md and return ONLY the requested value with its context.

## Rules
1. ONLY return values found in reference files
2. If not found, return "NOT FOUND: [what was requested]"
3. Never guess or use memory
4. Include the section where the value was found

## Response Format
```
FOUND: [value]
Source: [file] > [section]
Context: [surrounding info if helpful]
```
```

**When to create:** Skill has `reference.md` with IDs/mappings AND grounding is critical (API calls, financial data).

**Implementation in parent skill:**
```markdown
## Grounding (Enforced via Agent)

Before using any ID, spawn the id-lookup agent:

Task tool with subagent_type: "general-purpose"
Prompt: "Look up [description] in .claude/skills/[skill]/reference.md.
        Return only the ID and its context. If not found, say NOT FOUND."

Only proceed if agent returns FOUND.
```

#### 2. Pre-Flight Validator Agent

**Purpose:** Validate complex operations before execution.

```markdown
---
name: preflight-validator
description: Validate operations against skill rules
allowed-tools: Read, Grep
context: fork
---

# Pre-Flight Validator

You validate proposed operations against skill rules before execution.

## Input
You receive: the proposed operation details

## Process
1. Read the relevant SKILL.md directives
2. Read reference.md for valid values
3. Check each aspect of the operation

## Output
```
VALID: [operation can proceed]
```
or
```
INVALID: [specific reason]
Directive violated: [quote the directive]
Suggested fix: [how to correct]
```
```

**When to create:** Skill has multiple directives that interact, or validation requires checking multiple files.

#### 3. Evaluation Agent (Context Isolation)

**Purpose:** Evaluate output without bias from creation context.

```markdown
---
name: evaluator
description: Evaluate content for quality/issues
allowed-tools: Read, Glob, Grep
context: none
---

# Evaluation Agent

You evaluate content against criteria WITHOUT knowledge of how it was created.

## Rules
1. Read only the content and the evaluation criteria
2. Do not ask about creation intent
3. Report what you observe, not what was intended
4. Be specific with line numbers and quotes
```

**When to create:** Output quality matters and creator bias could mask issues.

#### 4. Matcher Agent

**Purpose:** Match inputs to categories/mappings with reasoning.

```markdown
---
name: matcher
description: Match inputs to predefined categories
allowed-tools: Read, Grep
context: none
---

# Matcher Agent

You match inputs to categories from reference files.

## Process
1. Read the mappings from reference.md
2. Find the best match for the input
3. If confident (>90%), return the match
4. If uncertain, return top 3 candidates with confidence

## Output
```
MATCH: [category]
Confidence: [high/medium/low]
Reasoning: [why this match]
```
or
```
UNCERTAIN - Candidates:
1. [category] - [why]
2. [category] - [why]
3. [category] - [why]
Recommendation: Ask user to choose
```
```

**When to create:** Skill involves matching user input to predefined categories (payees to expense categories, files to projects, etc.).

### Creating Agents for a Skill

When running `/skill-builder agents [skill]`:

**Step 1: Analyze the skill for agent opportunities**

```
Read SKILL.md and identify:
- Grounding requirements → ID Lookup Agent?
- Complex validation → Validator Agent?
- Quality checks → Evaluation Agent?
- Matching/categorization → Matcher Agent?
```

**Step 2: For each opportunity, assess value**

| Factor | High Value | Low Value |
|--------|------------|-----------|
| Frequency | Used every invocation | Rare edge case |
| Risk | Errors cause real harm | Errors easily caught |
| Complexity | Multi-step reasoning | Simple lookup |
| Hook alternative | Can't be done with grep | Simple pattern match |

**Step 3: Create agent files**

```
.claude/skills/[skill]/agents/
├── id-lookup.md
├── validator.md
└── matcher.md
```

**Step 4: Update SKILL.md to invoke agents**

Add to the workflow section:
```markdown
### Step N: [Agent Name]

Before [action], spawn the [agent-name] agent:

Task tool with subagent_type: "general-purpose"
Prompt: "[specific prompt for this use case]"

[What to do with the result]
```

**Step 5: Document in audit report**

```
## Agents Created
| Agent | Purpose | Invoked When |
|-------|---------|--------------|
| id-lookup | Enforce grounding | Before any API call using IDs |
| validator | Pre-flight checks | Before bulk operations |
```

### Agent File Structure

```
.claude/skills/my-skill/
├── SKILL.md           # Directives + workflow
├── reference.md       # IDs, tables, mappings
├── hooks/
│   └── validate.sh    # Hard rule enforcement
└── agents/
    ├── id-lookup.md   # Grounding enforcement
    ├── validator.md   # Complex validation
    └── matcher.md     # Category matching
```

---

## Hooks Command

When running `/skill-builder hooks` (all skills) or `/skill-builder hooks [skill]` (specific skill):

### Step 1: Inventory Existing Hooks

Scan for hook scripts and their wiring:

```
1. Glob for .claude/skills/**/hooks/*.sh
2. Read .claude/settings.local.json → hooks section
3. Cross-reference: which scripts are wired, which are orphaned
```

### Step 2: Validate Existing Hooks

For each hook script found:

| Check | What to Verify |
|-------|----------------|
| **Wired** | Listed in settings.local.json `hooks` section |
| **Matcher** | Correct tool matcher (Bash, Edit, etc.) |
| **Exit codes** | Uses `exit 2` to block, `exit 0` to allow |
| **Reads stdin** | Captures `INPUT=$(cat)` for tool input |
| **Permission** | Script is executable (`chmod +x`) |
| **Error output** | Writes block reason to stderr (`>&2`) |

### Step 3: Identify New Opportunities

Scan each skill's SKILL.md for directive patterns that can be enforced with hooks:

| Directive Pattern | Hook Type | Example |
|-------------------|-----------|---------|
| "Never use X" / "Never assign to X" | **Grep-block** | Block forbidden IDs/values |
| "Always use script Y" | **Require-pattern** | Block direct API calls, require helper |
| "Never call Z directly" | **Grep-block** | Block forbidden endpoints |
| "Must include X" | **Require-pattern** | Ensure required fields present |
| "Never exceed N" | **Threshold** | Block values above limit |

**Skip these** (need agents, not hooks):
- "Choose the best X" → judgment call
- "If unclear, ask" → context-dependent
- "Match X to Y" → reasoning required

### Step 4: Generate Report

```markdown
# Hooks Audit Report

## Existing Hooks

| Script | Skill | Matcher | Wired | Status |
|--------|-------|---------|-------|--------|
| no-uncategorized.sh | /budget | Bash | Yes | OK |
| validate-org-id.sh | /api-client | Bash | Yes | OK |
| orphaned-script.sh | /skill | — | No | ORPHANED |

## Wiring Issues
- [List any scripts not in settings.json]
- [List any settings.json entries pointing to missing scripts]

## New Opportunities

| Skill | Directive | Hook Type | Priority |
|-------|-----------|-----------|----------|
| /skill-name | "Never use Uncategorized" | Grep-block | High |

## Recommended Actions
1. [Wire orphaned script X]
2. [Create hook for directive Y in /skill-name]
3. [Fix exit code in script Z]
```

### Step 5: Offer Actions

After presenting the report, ask:
> "Which hooks should I create?"
> 1. Create [highest priority hook]
> 2. Wire orphaned hooks
> 3. Fix validation issues
> 4. Create all recommended hooks

### Creating a Hook Script

When creating a new hook:

1. **Create the script** in `.claude/skills/[skill]/hooks/[name].sh`
2. **Make executable:** `chmod +x [script]`
3. **Wire in settings.local.json** under `hooks.PreToolUse`
4. **Test** by running a command that should be blocked

**Template for grep-block hooks:**
```bash
#!/bin/bash
INPUT=$(cat)
if echo "$INPUT" | grep -q "FORBIDDEN_VALUE"; then
  echo "BLOCKED: [reason] per [skill] directive" >&2
  exit 2
fi
exit 0
```

---

## Skill File Structure

```
.claude/skills/my-skill/
├── SKILL.md           # Directives + workflow (keep short)
├── reference.md       # IDs, tables, mappings (externalizable)
├── hooks/
│   └── validate.sh    # Enforcement scripts
└── agents/            # Optional specialized subagents
```

### SKILL.md Template

```markdown
---
name: skill-name
description: "Brief description. Modes: mode1, mode2, mode3. Usage: /skill-name [mode] [args]"
allowed-tools: [minimum needed]
---

# Skill Name

Brief one-line description of what this skill does.

## Usage

```
/skill-name [mode] [args]
```

### Modes

| Mode | Command | Description |
|------|---------|-------------|
| `mode1` | `/skill-name mode1 [args]` | What mode1 does |
| `mode2` | `/skill-name mode2 [args]` | What mode2 does |
| `mode3` | `/skill-name mode3 [args]` | What mode3 does |

Default mode is `mode1` if not specified.

---

## Directives

> **[User's exact rule, verbatim]**

*— Added YYYY-MM-DD, source: [where this came from]*

> **[Another directive]**

*— Added YYYY-MM-DD, source: [where this came from]*

---

## Workflow: Mode1

1. Step one
2. Step two
3. Step three

---

## Workflow: Mode2

1. Step one
2. Step two

---

## Grounding

Before using any ID or value from reference.md:
1. Read reference.md
2. State: "I will use [VALUE] for [PURPOSE], found under [SECTION]"

See [reference.md](reference.md) for IDs and mappings.
```

**For single-purpose skills (no modes):** Omit the Usage/Modes section entirely.

---

## Frontmatter Requirements

**CRITICAL:** The `description:` field is what users see when they type `/skill-name` without arguments. Claude Code only displays the description — not the body of SKILL.md. **Multi-line descriptions get truncated — use a single line.**

### Required Frontmatter Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | Yes | Skill identifier (matches folder name) |
| `description` | Yes | Single-line summary shown in help output |
| `allowed-tools` | Yes | Tools the skill can use |

### Description Field Pattern

**ALWAYS use a single quoted line.** Include modes/usage inline:

```yaml
---
name: study-prep
description: "Strategic test prep with Readwise integration. Modes: auto, review, teach, quiz, calibrate, vocab, ikanum, translate"
allowed-tools: Read, Glob, Grep, mcp__readwise-mcp__*
---
```

```yaml
---
name: text-eval
description: "Evaluate text for AI tells and voice alignment. Modes: personal, academic, email. Usage: /text-eval [file] [mode]"
allowed-tools: Read, Grep, Glob, Task
---
```

```yaml
---
name: cw-pdf-ingest
description: "Extract CW vocab/grammar from PDFs, update dictionary. Usage: /cw-pdf-ingest [pdf] [--type vocab|story|grammar] [--convert]"
allowed-tools: Read, Grep, Glob, Edit, Bash
---
```

**Single-purpose skills (no modes):**
```yaml
---
name: deploy
description: "Deploy application to staging or production environments."
allowed-tools: Bash, Read
---
```

### When Creating or Updating Skills

**Always verify:**

1. **Frontmatter exists** with `---` delimiters
2. **`name:` matches folder name**
3. **`description:` is a single quoted line** (no multi-line `|` syntax)
4. **Modes/usage included inline** if skill has subcommands

### Audit Check for Frontmatter

When auditing skills, include:

```
## Frontmatter Check: /skill-name

- Has frontmatter: [yes/no]
- name matches folder: [yes/no]
- description is single line: [yes/no]
- Has modes/subcommands: [yes/no]
- Modes listed in description: [yes/no/N/A]

Status: [OK / NEEDS UPDATE]
```

### Fixing Missing or Multi-line Frontmatter

**Before (multi-line — gets truncated):**
```yaml
---
name: my-skill
description: |
  Brief description.

  Modes:
    mode1 - does thing
    mode2 - does other thing
---
```

**After (single line — displays fully):**
```yaml
---
name: my-skill
description: "Brief description. Modes: mode1, mode2. Usage: /my-skill [mode] [args]"
allowed-tools: Read, Grep
---
```

---

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

## Adding Directives to Existing Skills

When user gives a new rule for an existing skill:

1. **Extract exact wording** — Quote their instruction verbatim
2. **Add to Directives section** — With date and source
3. **Create enforcement hook** — If rule can be validated programmatically
4. **Test the hook** — Ensure it blocks violations
5. **Update settings.json** — Wire up the hook

**Example conversation:**

User: "For my budget app, I never want you to use the Uncategorized account, ID 12345678"

Your action:
```markdown
## Directives

> **NEVER assign a transaction to Uncategorized (ID: 12345678).**
> If a transaction doesn't match a known category, stop and ask which category to use.

*— Added 2026-01-22, source: user instruction*
```

Then create hook `.claude/skills/budget/hooks/no-uncategorized.sh`:
```bash
#!/bin/bash
INPUT=$(cat)
if echo "$INPUT" | grep -q "12345678"; then
  echo "BLOCKED: Uncategorized account (12345678) is forbidden per user directive" >&2
  exit 2
fi
exit 0
```

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

---

## Auditing Existing Skills

When auditing, report:

```
## Audit: /skill-name

**Frontmatter:**
- Has YAML frontmatter: [yes/no]
- name matches folder: [yes/no]
- description is single line: [yes/no] ← CRITICAL (multi-line gets truncated)
- Has modes/subcommands: [yes/no]
- Modes listed in description: [yes/no/N/A]

**Modes/List Support:**
- Has multiple modes: [yes/no]
- Has Modes table: [yes/no/N/A]
- Table format correct (Mode | Command | Description): [yes/no/N/A]
- Supports `/skill-name list`: [yes/no/N/A]

**Directives found:** [count]
- Are they verbatim user rules? [yes/no]
- Are they at the top? [yes/no]

**Reference material inline:** [count] tables/lists
- Should move to reference.md? [yes/no]

**Enforcement:**
- allowed-tools: [current]
- hooks: [present/missing]
- agents: [present/missing]
- Directives enforceable by hooks? [yes/no/partial]

**Agent opportunities:**
- Grounding enforcement needed? [yes/no] → ID Lookup Agent
- Complex validation needed? [yes/no] → Validator Agent
- Output evaluation needed? [yes/no] → Evaluation Agent
- Input matching needed? [yes/no] → Matcher Agent

**Line count:** [X] (target: < 150 excluding reference.md)

### Recommendations
1. [specific action]
2. [specific action]
```

### Detecting Multi-line Descriptions

When auditing, check for these patterns that indicate a multi-line description needing optimization:

```yaml
# BAD - uses | for multi-line (gets truncated)
description: |
  Some description here.
  More text...

# BAD - uses > for folded (gets truncated)
description: >
  Some description here.

# GOOD - single quoted line
description: "Brief desc. Modes: a, b, c. Usage: /skill [args]"

# GOOD - single unquoted line (if no special chars)
description: Brief description without special characters
```

**If multi-line detected, recommend:**
```
⚠️ FRONTMATTER: Description uses multi-line syntax (gets truncated in help)
   Current: description: |
              Long multi-line text...
   Fix to:  description: "Condensed single line. Modes: x, y, z"
```

---

## CLAUDE.md Optimization

CLAUDE.md loads into EVERY conversation. Keep it lean — move domain-specific content to skills.

### What MUST Stay in CLAUDE.md

| Content | Why |
|---------|-----|
| Build commands | Needed for any dev work |
| Project structure | Universal orientation |
| Tech stack | Framework context |
| Path aliases | Import resolution |
| Skills reference table | Discovery/navigation |
| Universal rules | Apply to ALL tasks |

### What Should Move to Skills

| Content | Move To |
|---------|---------|
| API integration rules | `/api-name` skill |
| Domain-specific workflows | Domain skill |
| ID/account tables | `skill/reference.md` |
| Vendor-specific instructions | Vendor skill |
| Complex procedures | Dedicated skill |

### CLAUDE.md Optimization Workflow

When asked to optimize CLAUDE.md:

**Step 1: Analyze current CLAUDE.md**
```bash
wc -l CLAUDE.md  # Line count
```

**Step 2: Identify extraction candidates**

Scan for:
- Sections with domain-specific rules (API integrations, budgeting, etc.)
- Inline tables with IDs/accounts
- Procedures longer than 10 lines
- Rules that only apply to specific tasks

**Step 3: For each extraction candidate**

1. Create skill if doesn't exist:
   ```
   .claude/skills/[domain]/
   ├── SKILL.md
   └── reference.md
   ```

2. Move directives (verbatim) to skill's `## Directives` section

3. Move reference tables to `reference.md`

4. Replace CLAUDE.md section with skill pointer:
   ```markdown
   ### [Domain] Integration

   See `/domain` skill for rules and workflows.
   ```

**Step 4: Verify skills table is updated**

Ensure extracted skills appear in the Skills Reference table.

**Step 5: Report savings**
```
## CLAUDE.md Optimization Report

Before: [X] lines
After: [Y] lines
Savings: [Z] lines ([%]%)

Extracted to skills:
- /skill-1: [description]
- /skill-2: [description]
```

### Target CLAUDE.md Structure

After optimization, CLAUDE.md should be ~100-150 lines:

```markdown
# CLAUDE.md

## Commands
[3-5 essential commands]

## Architecture
[Brief project structure - 20 lines max]

## Tech Stack
[One-liner per technology]

## Skills Reference
[Table pointing to skills]

## Important Rules
[Only rules that apply to EVERY task]

## Self-Improvement Protocol
[Meta-rules for learning]
```

Everything else lives in skills.

---

## Portability / Transmutability

This skill is designed to be copied to any Claude Code installation.

### Installing in Another Account

```bash
# Copy entire skill-builder directory
cp -r .claude/skills/skill-builder ~/.claude/skills/

# Or for project-level
cp -r .claude/skills/skill-builder /path/to/project/.claude/skills/
```

### Converting Existing Rules to Skills

When imported to a new account, run: `/skill-builder audit`

**Workflow:**

1. **Scan for existing instructions**
   - Read `CLAUDE.md` for inline rules
   - Read `.claude/rules/*.md` for rule files
   - Read any existing `.claude/skills/`

2. **Identify directive candidates**
   Look for patterns like:
   - "Never...", "Always...", "Do not..."
   - "IMPORTANT:", "CRITICAL:", "WARNING:"
   - Conditional rules: "If X, then Y"
   - Workflow descriptions

3. **Extract and quote verbatim**
   ```markdown
   ## Directives

   > **[Exact text from CLAUDE.md or rules file]**

   *— Migrated from [source file], line [X]*
   ```

4. **Separate reference material**
   Move ID tables, API docs, configuration to `reference.md`

5. **Create enforcement hooks**
   For any directive that can be validated programmatically

### Conversion Example

**Before (in CLAUDE.md):**
```markdown
## API Integration Rules
- Always use the helper script for tokens: `./scripts/api-token.sh`
- Never call OAuth endpoint directly for each request
- Organization ID is always 123456789

### Account IDs
| Account | ID |
|---------|-----|
| Primary | 12345 |
```

**After (as skill):**

`SKILL.md`:
```markdown
## Directives

> **Always use the helper script for tokens: `./scripts/api-token.sh`**
> **Never call OAuth endpoint directly for each request.**

*— Migrated from CLAUDE.md, API Integration Rules section*

## Grounding

Before any API call, state: "I will use org ID [X], found in reference.md"

See [reference.md](reference.md) for IDs.
```

`reference.md`:
```markdown
# API Reference

Organization ID: 123456789

## Account IDs
| Account | ID |
|---------|-----|
| Primary | 12345 |
```

---

## Self-Contained Hook Paths

Hooks should use relative paths from project root:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/skills/api-client/hooks/validate.sh"
      }]
    }]
  }
}
```

`$CLAUDE_PROJECT_DIR` resolves to the project root, making hooks portable.

---

## Discovered Patterns

*Document what works and what doesn't as you build skills:*

- **Hooks for hard rules, agents for judgment** — Hooks are fast and free (no tokens) but can only grep. Agents can reason but cost tokens and time. Use hooks for "never use ID X", use agents for "find the right ID for Y". (2026-01-22)

- **Context isolation for evaluation** — Evaluation skills should use `context: none` agents so the evaluator isn't biased by the conversation that created the content. This pattern works well for any quality check. (2026-01-22)

- **Grounding statements aren't enough** — Adding "state which ID you will use" to a skill helps but doesn't guarantee Claude reads reference.md. An ID Lookup Agent with `context: none` guarantees the ID comes from the file, not from memory. (2026-01-22)

- **reference.md reduces SKILL.md but total lines stay similar** — The goal isn't fewer total lines, it's fewer lines in SKILL.md (which loads every invocation). reference.md only loads when explicitly read. (2026-01-22)

- **Hook exit code 2 blocks, 0 allows** — Other exit codes are treated as errors but don't block. Always use exactly 2 to block. (2026-01-22)

- **Context mutability is the fundamental problem** — All text-based instructions (CLAUDE.md, rules, skills) can drift under long context. Only external enforcement (hooks, `context: none` agents) is truly immutable. See "Context Mutability & Enforcement Hierarchy" section above. (2026-01-22)

- **Description must be single line** — Claude Code only shows the `description:` field when users type `/skill-name`, and multi-line descriptions get truncated. Use a single quoted line with modes/usage inline: `"Brief desc. Modes: a, b, c. Usage: /skill [args]"`. See "Frontmatter Requirements" section above. (2026-01-24)
