# Skill File Structure & Templates

## Skill File Structure

```
.claude/skills/my-skill/
├── SKILL.md           # Directives + workflow (keep short)
├── reference.md       # IDs, tables, mappings (externalizable)
├── hooks/
│   └── validate.sh    # Enforcement scripts
└── agents/            # Optional specialized subagents
```

## SKILL.md Template

```markdown
---
name: skill-name
description: "Brief description. Modes: mode1, mode2, mode3. Usage: /skill-name [mode] [args]"
allowed-tools: [minimum needed]
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: prompt
          prompt: "Check if this edit alters any text between <!-- origin: user | immutable: true --> and <!-- /origin --> markers: $ARGUMENTS. If directive content was changed, DENY. Otherwise APPROVE."
          if: "Edit(**/SKILL.md)|Write(**/SKILL.md)"
          statusMessage: "Checking directive integrity..."
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: Directives are sacred. Never reword text between <!-- origin: user | immutable: true --> markers.\"}'"
          statusMessage: "Re-injecting directive awareness..."
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

<!-- origin: user | added: YYYY-MM-DD | immutable: true -->
## Directives

> **[User's exact rule, verbatim]**

*— Added YYYY-MM-DD, source: [where this came from]*

> **[Another directive]**

*— Added YYYY-MM-DD, source: [where this came from]*
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.0 | modifiable: true -->
## Workflow: Mode1

1. Step one
2. Step two
3. Step three

---

## Workflow: Mode2

1. Step one
2. Step two
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.0 | modifiable: true -->
## Grounding

Before using any ID or value from reference.md:
1. Read reference.md
2. State: "I will use [VALUE] for [PURPOSE], found under [SECTION]"

See [reference.md](reference.md) for IDs and mappings.
<!-- /origin -->
```

**For single-purpose skills (no modes):** Omit the Usage/Modes section entirely.

### Content-Creation Skill Template

For skills that produce written content (articles, posts, captions, descriptions). Includes voice directive placeholders and voice validation integration.

```markdown
---
name: skill-name
description: "Brief description. Usage: /skill-name [args]"
allowed-tools: Read, Glob, Grep, Edit, Write, Task
---

# Skill Name

Brief one-line description of what this skill does.

---

<!-- origin: user | added: YYYY-MM-DD | immutable: true -->
## Directives

> **[Voice/style directive — e.g., "Never produce overbuilt, constructed, or AI-sounding prose."]**
> **[Tone directive — e.g., "All drafts must be conversational and natural."]**

*— Added YYYY-MM-DD, source: [where this came from]*
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.0 | modifiable: true -->
## Workflow

1. [Content creation steps]
2. [...]
3. **Text evaluation** — Before presenting any draft to the user, spawn the text evaluation agent pair (see below)
4. Synthesize findings from both agents, fix all flagged issues, then present the clean draft

---

## Text Evaluation (Enforced via Agent Pair)

After generating any draft content, spawn both agents in parallel:

Task tool #1 with subagent_type: "general-purpose"
Prompt: "You are The Reducer — a ruthless editor who has cut 50,000 words from
        manuscripts without losing meaning. Read directives from
        .claude/skills/[skill]/SKILL.md § Directives. Then read [content file].
        Flag every overbuilt, bloated, or unnecessarily complex sentence.
        Report with line numbers and quoted text. If no issues, say PASS."

Task tool #2 with subagent_type: "general-purpose"
Prompt: "You are The Clarifier — a technical writer who has untangled
        contradictory specifications for 20 years. Read directives from
        .claude/skills/[skill]/SKILL.md § Directives. Then read [content file].
        Flag every confusing, ambiguous, or contradictory passage.
        Report with line numbers and quoted text. If no issues, say PASS."

Synthesize both agents' findings. Fix all flagged issues before presenting to user.

---

## Grounding

[If applicable — reference files for IDs, style guides, etc.]
```

**When to use this template:** The `new` command should use this template when the user's description or skill name suggests content creation (writing, articles, posts, editorial, newsletter, social media, captions, copy).

---

## Reference File Templates

### Single-File Pattern (< 100 lines)

Use a single `reference.md` when the file is under 100 lines or has fewer than 3 substantial h2 sections:

```
.claude/skills/my-skill/
├── SKILL.md
└── reference.md       # All IDs, tables, mappings in one file
```

Grounding in SKILL.md:
```markdown
## Grounding

Before using any ID or value from reference.md:
1. Read reference.md
2. State: "I will use [VALUE] for [PURPOSE], found under [SECTION]"

See [reference.md](reference.md) for IDs and mappings.
```

### Multi-File Pattern (> 100 lines, 3+ h2 sections each >20 lines)

Split into a `references/` directory with domain-specific files. Each file is an **enforcement boundary** where hooks and agents can attach independently:

```
.claude/skills/my-skill/
├── SKILL.md
├── references/
│   ├── ids.md          # Account/entity IDs
│   ├── mappings.md     # Category/vendor mappings
│   └── constraints.md  # Limits, thresholds, rules
├── hooks/
│   └── validate.sh
└── agents/
    └── *.md
```

### Per-File Template

Each reference file includes an enforcement attribution footer:

```markdown
# [Domain Title]
<!-- Enforcement: [HIGH|MEDIUM|LOW|NONE] — [mechanism description] -->

## [Section Heading]

[Content copied verbatim from original reference.md]

---
*Split from reference.md by skill-builder optimize. Enforcement boundary: [hook|agent|none].*
```

### Grounding Update Template

When splitting, update the grounding section from single-file to multi-file:

```markdown
## Grounding

Before using any ID, mapping, or constraint:
1. Read the relevant file from `references/`
2. State: "I will use [VALUE] for [PURPOSE], found in references/[file] under [SECTION]"

Reference files:
- [references/ids.md](references/ids.md) — [description]
- [references/mappings.md](references/mappings.md) — [description]
- [references/constraints.md](references/constraints.md) — [description]
```

### Enforcement Opportunities by File Type

| File Domain | Priority | Hook Opportunity | Agent Opportunity |
|-------------|----------|------------------|-------------------|
| IDs/accounts | HIGH | Block unknown IDs in tool input | Validate ID lookups against file |
| Mappings/categories | HIGH | — | Validate input→output matches |
| Constraints/limits | MEDIUM | Block values exceeding thresholds | — |
| API docs | LOW | Block deprecated endpoint calls | — |
| Examples/theory | NONE | — | — |

---

## Frontmatter Requirements

**CRITICAL:** The `description:` field is what users see when they type `/skill-name` without arguments. Claude Code only displays the description — not the body of SKILL.md. **Multi-line descriptions get truncated — use a single line.**

### Required Frontmatter Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | Yes | Skill identifier (matches folder name) |
| `description` | Yes | Single-line summary shown in help output |
| `allowed-tools` | Yes | Tools the skill can use |

### Optional Frontmatter Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `paths` | Only activate when matching files touched | `"**/*.ts"` |
| `effort` | Reasoning effort for forked skills | `low`, `medium`, `high`, `max` |
| `context` | Execution context | `inline` (default), `fork` |
| `memory` | Persistent cross-session memory | `project`, `local`, `user` |
| `background` | Run without blocking parent | `true` |
| `when_to_use` | Tells Claude when to proactively invoke | Free text |
| `model` | Model override | `haiku`, `sonnet`, `opus` |

### Conditional Activation (`paths:` Field)

Skills with `paths:` frontmatter only activate when matching files are touched. This reduces context cost for domain-specific skills.

```yaml
---
name: typescript-helpers
description: "TypeScript utility patterns and type helpers"
paths: "**/*.ts"
allowed-tools: Read, Grep, Glob, Edit
---
```

**Path patterns:**
- `"**/*.ts"` — Any TypeScript file
- `"**/components/**"` — Files under any components directory
- `"src/api/**/*.ts"` — TypeScript files under src/api
- `["**/*.test.ts", "**/*.spec.ts"]` — Array of patterns (match any)

**When to use `paths:`:**
- Language-specific skills (TypeScript, Python, Rust)
- Directory-specific skills (components, API routes, tests)
- File-type-specific skills (Markdown, JSON, YAML)

**When NOT to use `paths:`:**
- Skills invoked by slash command (user decides when to load)
- Cross-cutting skills that apply regardless of file type
- Skills with complex workflows that need full context

### Effort Level (`effort:` Field)

The `effort:` field controls reasoning depth for forked skills and agents. Lower effort = faster and cheaper. Higher effort = more thorough reasoning.

| Level | Use For | Cost | Speed |
|-------|---------|------|-------|
| `low` | Simple lookups, ID validation, format checks | Lowest | Fastest |
| `medium` | Standard tasks, most skills | Default | Normal |
| `high` | Complex analysis, evaluation agents | Higher | Slower |
| `xhigh` | Deep reasoning, architectural decisions | High | Slow |
| `max` | Most thorough reasoning, critical decisions | Highest | Slowest |

**Recommendations by agent type:**

| Agent Type | Recommended Effort |
|-----------|-------------------|
| ID Lookup Agent | `low` — simple pattern matching |
| Matcher Agent | `low` to `medium` — category matching |
| Pre-flight Validator | `medium` — rule checking |
| Text Evaluation Pair | `high` — quality judgment |
| Capture Recommender | `medium` — pattern matching |
| Architectural analysis | `high` to `xhigh` — complex reasoning |

```yaml
---
name: id-lookup
description: "Look up IDs from reference files"
effort: low
context: fork
allowed-tools: Read, Grep
---
```

**Audit check:** Skills and agents without `effort:` default to `medium`. Flag forked skills without explicit effort settings.

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

## Shell Preprocessing (`!` Code Blocks)

Skills can execute shell commands at load time using `!` code blocks. The output replaces the block in the injected content.

**Use cases:**
- Dynamically load procedure content at invocation
- Inject system information or timestamps
- Load content that changes frequently

### Example: Dynamic Procedure Loading

Instead of duplicating procedure content in SKILL.md, load it dynamically:

```markdown
---
name: my-skill
description: "Skill with dynamic procedure loading"
shell: bash
---

# My Skill

## Procedure

!`cat ${CLAUDE_SKILL_DIR}/procedures/main.md`
```

The `${CLAUDE_SKILL_DIR}` variable resolves to the skill's directory, making paths portable.

### Example: Injecting Build Info

```markdown
## Current State

!`echo "Last commit: $(git log -1 --format='%h %s' 2>/dev/null || echo 'not a git repo')"`
!`echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"`
```

### Example: Conditional Content

```markdown
## Environment

!`if [ -f .env ]; then echo "Environment: $(grep -c '^[A-Z]' .env) variables configured"; else echo "No .env file found"; fi`
```

### Shell Preprocessing Rules

1. **Runs at load time** — before Claude sees the skill content
2. **Output replaces the block** — whatever the command prints becomes skill content
3. **MCP skills cannot use this** — security boundary prevents shell execution
4. **Use `shell: powershell`** for Windows compatibility
5. **Errors are visible** — stderr output appears in the skill content
6. **Keep commands fast** — slow commands delay skill loading
