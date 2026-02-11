# Agents

Agents are specialized subprocesses that handle specific tasks with isolation and tool restrictions.

## When to Use Agents vs Hooks

| Mechanism | Use When | Strengths | Weaknesses |
|-----------|----------|-----------|------------|
| **Hooks** | Hard rules, forbidden values, simple validation | Fast, blocks before execution, no token cost | Limited logic, can't reason |
| **Agents** | Judgment calls, multi-file lookups, complex validation | Can reason, access context, make decisions | Slower, costs tokens |

**Rule of thumb:** Use hooks for "never do X", use agents for "figure out the right X".

## Agent Opportunity Detection

When auditing a skill, look for these patterns that suggest an agent would help:

| Pattern | Agent Type | Example |
|---------|------------|---------|
| "Read reference.md before..." | **ID Lookup Agent** | Get category ID before categorizing |
| "Verify that..." | **Validator Agent** | Check all required fields before submit |
| "Evaluate for..." | **Evaluation Agent** | Check output quality, validate formatting |
| "Match X to Y" | **Matcher Agent** | Match payee to category |
| "If unclear, ask" | **Triage Agent** | Determine if user input is needed |
| "Never produce overbuilt/AI prose" | **Voice Validator Agent** | Validate draft against voice directives |
| "Conversational tone" / "No promotional language" | **Voice Validator Agent** | Catch style violations before user sees them |

## Agent Templates

### 1. ID Lookup Agent (Grounding Enforcement)

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

### 2. Pre-Flight Validator Agent

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

### 3. Evaluation Agent (Context Isolation)

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

### 4. Matcher Agent

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

### 5. Voice/Style Validator Agent (Content Enforcement)

**Purpose:** Evaluate generated content against voice/style directives without inheriting conversational bias.

```markdown
---
name: voice-validator
description: Validate content against voice and style directives
allowed-tools: Read, Grep, Glob
context: none
---

# Voice/Style Validator Agent

You evaluate written content against voice and style directives. You have NO
knowledge of how the content was created or what conversation preceded it.

## Rules
1. Read the skill's directives section FIRST
2. Read the content to evaluate
3. Flag every sentence that violates a directive — quote it and cite which directive
4. Do NOT rewrite — only identify violations
5. If no violations found, say "PASS: Content aligns with voice directives"

## Response Format
```
PASS: Content aligns with voice directives
```
or
```
VIOLATIONS FOUND: [count]

1. Line [N]: "[quoted sentence]"
   Violates: "[quoted directive]"
   Issue: [specific problem — e.g., promotional language, stacked adjectives, constructed phrasing]

2. Line [N]: "[quoted sentence]"
   ...

Summary: [count] violations across [count] directives
```
```

**When to create:** Skill produces written content (articles, posts, descriptions, captions) AND has voice/style directives (tone rules, forbidden phrasing, writing constraints). Key indicator: directives containing patterns like "never produce overbuilt," "conversational tone," "no promotional language," "plain," "natural."

**Implementation in parent skill:**
```markdown
## Voice Validation (Enforced via Agent)

After generating any draft content, spawn the voice-validator agent:

Task tool with subagent_type: "general-purpose"
Prompt: "Read directives from .claude/skills/[skill]/SKILL.md § Directives.
        Then read [content file]. Evaluate every sentence against the voice
        directives. Report violations with line numbers and quoted text.
        If no violations, say PASS."

If agent reports violations, fix them before presenting to user.
```

## Creating Agents for a Skill

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

## Agent File Structure

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
