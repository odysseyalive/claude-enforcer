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
minimum-effort-level: high
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

**4.7 compatibility note:** Voice and style directives in this template are high-priority candidates for enforcement annotations on Opus 4.7+. Phrases like "conversational", "natural", "not overbuilt" rely on inference that 4.6 supplied automatically and 4.7 does not. When `/skill-builder convert [skill]` or `/skill-builder optimize [skill] --execute` runs, it generates a CHECKPOINT block beneath each voice directive — the original directive stays verbatim; the annotation adds explicit numbered steps. See the Enforcement Annotation Template section below.

---

## Content Author Agent Template (Opus 4.6 Bookending)

For dedicated content-author subagents that handle writing work (creative prose AND technical documentation) on `claude-opus-4-6` while the parent skill stays on Opus 4.7. Used by the `agents` step 4d Content Bookending Detection. Full design in [content-bookending.md](content-bookending.md).

### When to use

A skill produces written content and is being routed through the bookending pattern. The detection signals (≥2 of 4) are documented in `content-bookending.md` § "Detection signals". This template is for the AGENT.md file at `.claude/skills/<skill>/agents/<role>-author/AGENT.md` plus the dispatch CHECKPOINT that goes into the parent SKILL.md.

### AGENT.md template

```markdown
---
name: <role>-author
description: Authors [content artifact] for the <parent-skill> <command> command. Loads grounding inside the subagent; returns a structured payload the orchestrator integrates.
persona: "[unique persona — see agents-personas.md and the Persona Assignment Gate. Examples: 'A children's-museum exhibit copywriter who writes the placard text that turns a glass case into a moment of curiosity'; 'A radio-drama dialogue writer who voiced thirty distinct characters across serialized weekly episodes'; 'A technical writer who has documented twelve developer platforms and learned that the first paragraph either earns the read or loses it']"
model: claude-opus-4-6
allowed-tools: Read, Grep, Glob
context: none
---

# <Role> Author

You author [specific content artifact] for the <parent-skill> game/project/system. Your output is the prose surface — the [paragraphs, dialogue, descriptions, lessons] that the orchestrator integrates into the larger artifact. You do not author structural data, code, or anything outside the prose layer.

## Loading order (mandatory before any prose)

1. Read [grounding files: voice profile, style guide, glossary, prior work] OR read `references/prose-grounding-bundle.md` if the parent skill uses a bundle.
2. State the four proof sentences confirming you've absorbed the grounding (this is the literal-execution check that 4.6 actually loaded the inputs).
3. Read the inputs the orchestrator passed (target artifact, scope, prior context).
4. Author the prose.

## Output

Return a structured payload describing the prose. The orchestrator integrates it; you do not write to files unless `Edit` is in `allowed-tools`.

[Specify exact payload shape — fields, format, length, constraints.]

## What you do NOT do

- [Out-of-scope item 1: e.g., propose new vocabulary]
- [Out-of-scope item 2: e.g., assign mechanical state]
- [Out-of-scope item 3: e.g., write to files outside the prose payload]
```

### Dispatch CHECKPOINT for parent SKILL.md

Add this block to the parent SKILL.md once authors are defined. It sits in the same SKILL.md region as other ENFORCEMENT ANNOTATIONs.

    <!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
    <!-- Source: Content Bookending — route writing work to claude-opus-4-6 subagents -->
    CHECKPOINT — Prose Subagent Dispatch:
    1. Detect content-producing command. The following commands produce written content:
       - <command-1> → dispatches to <author-1>
       - <command-2> → dispatches to <author-2>
    2. IF invocation includes `--manual-prose` → bypass dispatch; main agent (4.7) authors the content directly. Continue to step 5.
    3. IF command matches a content-producing entry → spawn the named author subagent via Task tool with `subagent_type: "<author-name>"`. The platform reads `model: claude-opus-4-6` from the agent's frontmatter.
    4. Receive the structured payload from the subagent. Integrate it into the surrounding artifact (file, response, or downstream procedure step) without rewording the prose.
    5. Continue with the parent procedure.
    <!-- END ENFORCEMENT ANNOTATION -->

### `--manual-prose` flag

Document the escape hatch in the parent SKILL.md commands table:

```markdown
| Flag | Effect |
|------|--------|
| `--manual-prose` | Bypass content-author dispatch; the parent agent (Opus 4.7) authors the prose directly. Use when 4.6's output regresses on a specific run or when prose is short enough that subagent overhead isn't worth it. |
```

### Persona uniqueness reminder

Every new author needs a persona that doesn't duplicate any existing one. The Persona Assignment Gate (parent SKILL.md CHECKPOINT) checks at authorship time; the `check-persona-uniqueness.sh` PreToolUse hook is the deterministic backstop at AGENT.md write time. Match creative prose → editorial/craft personas, technical docs → instructional personas, dialogue → voice-aware personas.

### Idempotency reminder

Before creating a new author, re-run the idempotency check from `agents.md` step 4d.i. If the configuration changed since the audit (a parallel session added bookending), do NOT overwrite the existing wiring. See `content-bookending.md` § "Idempotency".

### Grounding

- [content-bookending.md](content-bookending.md) — Full bookending design, signal definitions, idempotency rules
- [agents-personas.md](agents-personas.md) — Persona assignment heuristic
- [procedures/agents.md](procedures/agents.md) § Step 4d — Detection procedure that drives this template

---

## Enforcement Annotation Template

Soft directives (phrasing that relies on inference or subjective terms like "appropriate", "clean", "when needed", "naturally") are under-executed on Opus 4.7+, which reads literally. The fix is an **enforcement annotation**: the user's directive stays verbatim; a machine-generated CHECKPOINT block beneath it translates the intent into explicit numbered steps with STOP/CONTINUE gates.

### Rules

1. Annotations sit IMMEDIATELY below the directive they interpret.
2. Annotations NEVER alter the directive text. The directive stays inside its `<!-- origin: user | immutable: true -->` block; the annotation sits OUTSIDE that block.
3. Annotations include a `<!-- Source directive: "..." -->` comment quoting the verbatim original, so provenance is traceable.
4. Annotations use numbered steps with explicit gates: `IF [condition] → STOP. Report: "..."` and `IF [condition] → CONTINUE to [next phase]`.
5. Annotations are marked `auto-generated for Opus 4.7+` so the reader knows a human didn't write them.
6. HARD directives (explicit IDs, concrete never/always rules, measurable conditions) do NOT need annotations — skip them.
7. Annotations are generated during `/skill-builder optimize --execute` and `/skill-builder convert --execute`. They are NEVER generated by `inline`, which captures raw user wording only.

### Format

Placed directly below the sacred `<!-- /origin -->` close marker:

    <!-- origin: user | added: YYYY-MM-DD | immutable: true -->
    ## Directives

    > **"[Original user directive verbatim]"**

    *— Added YYYY-MM-DD, source: [provenance]*
    <!-- /origin -->

    <!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
    <!-- Source directive: "[verbatim copy of original]" -->
    CHECKPOINT — [gate name]:
    1. [explicit action]
    2. [explicit action with measurable condition]
    N. IF [condition] → STOP. Report: "[user-facing message]". Do not proceed.
    N+1. IF [condition] → CONTINUE to [next phase]
    <!-- END ENFORCEMENT ANNOTATION -->

### Worked example

For the directive "Do not begin drafting unless at least 3 independent, accessible, on-topic source URLs have been verified":

    <!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
    <!-- Source directive: "Do not begin drafting unless at least 3 independent, accessible, on-topic source URLs have been verified." -->
    CHECKPOINT — Source Verification Gate:
    1. Collect all candidate source URLs.
    2. For EACH URL: fetch the page, confirm HTTP 200, confirm content is on-topic by reading at least the first 3 paragraphs.
    3. Count URLs that pass all three checks (loads, accessible, on-topic).
    4. IF count < 3 → STOP. Report to user: "[N] of 3 required sources verified. Missing: [what failed]." Do not proceed.
    5. IF count ≥ 3 → Log verified sources and continue to drafting phase.
    <!-- END ENFORCEMENT ANNOTATION -->

### Grounding

- [patterns.md](patterns.md) §§ "Opus 4.7 literal execution breaks soft directives", "Enforcement annotations preserve directive sanctity"
- [enforcement.md](enforcement.md) § "Opus 4.7 Behavioral Contract"

---

## Runtime Evaluation Template

For skills that apply compensation based on historical evaluation results. The pre-flight reads `eval-history.md` to decide whether recent runs hit chronic failures, then adjusts behavior accordingly.

### Pre-flight

Before the main workflow runs, execute this step:

1. Read `.claude/skills/[skill]/eval-history.md`.
2. IF the file does not exist → state "No evaluation history found" and proceed without compensation. Do not infer that history exists elsewhere.
3. IF the file exists → parse the last 3 runs. Identify any criterion scored 1 in 3+ consecutive runs — these are chronic issues.
4. IF chronic issues found → apply compensation rules documented in this skill's `## Compensation` section. Otherwise → proceed without compensation.

### Compensation block

A skill using this template includes a `## Compensation` section that maps chronic criteria to behavioral adjustments. Each entry is explicit, not inferential:

    - Criterion X scored 1 for 3+ runs → action: [specific pre-flight instruction]
    - Criterion Y scored 1 for 3+ runs → action: [specific pre-flight instruction]

### Grounding

- [eval-history-format.md](eval-history-format.md) — Evaluation history file format
- [eval-rubrics.md](eval-rubrics.md) — Rubric construction (what to score)
- [procedures/eval.md](procedures/eval.md) — Runtime evaluation procedure

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
| `minimum-effort-level` | Minimum session effort required for this skill to function correctly on Opus 4.7+. Declares the reasoning budget the skill needs to reliably make its tool calls (grounding reads, agent spawns, hook triggers). Default: `high`. Content-creation skills: `xhigh`. Distinct from `effort:` — that field sets fork effort; this one declares session requirement. | `high`, `xhigh` |
| `context` | Execution context | `inline` (default), `fork` |
| `memory` | Persistent cross-session memory | `project`, `local`, `user` |
| `background` | Run without blocking parent | `true` |
| `when_to_use` | Tells Claude when to proactively invoke | Free text |
| `model` | Model override | `haiku`, `sonnet`, `opus` |
| `strictness` | Governs how aggressively skill-builder procedures verify this skill. `minimal` runs command hooks only, skips agent panels, and runs precheck-gated diff auditors; token-sensitive projects default here. `standard` is the default: existing behavior after the 4.7 upgrade. `thorough` runs mandatory agent panels, always-spawns the diff auditor, and escalates marginal decisions to agent judgment. See [token-efficiency.md](token-efficiency.md) § P5 for rationale. | `minimal`, `standard`, `thorough` |

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
