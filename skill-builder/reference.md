# Skill Builder Reference

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
