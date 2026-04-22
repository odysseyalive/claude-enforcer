# skill-builder Core Principles

These are the always-applicable principles that govern every skill-builder command. They were moved here from SKILL.md during the 4.7 upgrade to reduce always-loaded context weight. Read this file before running any high-risk command (`optimize`, `agents`, `hooks`, `audit`, `cascade`, `convert`).

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Core Principles

**IMPORTANT: Never break anything.**

Optimization is RESTRUCTURING, not REWRITING. The skill must behave identically after optimization.

**YOU MUST:**

1. **MOVE content, don't rewrite it** — Relocate to new location, preserving wording. Exclude secrets, credentials, API keys, tokens, and passwords — these must never appear in output or be relocated.
2. **PRESERVE all directives exactly** — User's words are sacred
3. **KEEP all workflows intact** — Same steps, same order, same logic
4. **TEST nothing changes** — After optimization, skill works identically

**What optimization IS:**
- Moving reference tables to `reference.md`
- Moving lookup tables and named references to `reference.md`
- Adding grounding requirements
- Creating enforcement hooks
- Splitting into SKILL.md + reference.md

**What optimization is NOT:**
- Rewriting instructions "for clarity"
- Condensing workflows "for brevity"
- Changing step order "for efficiency"
- Removing "redundant" content
- Summarizing user directives
- Reorganizing workflow structure that enforces directives (see enforcement.md § "Behavior Preservation")

**The test:** If the original author reviewed the optimized skill, they should say "this does exactly what mine did, just organized differently."

---

**Directives are sacred.**

When a user says "Never use Uncategorized accounts," those exact words stay in the skill, unchanged, forever.

**YOU MUST distinguish between:**

| Content Type | Can Compress? | Where It Lives |
|--------------|---------------|----------------|
| **Directives** (user's exact rules) | NEVER | Top of SKILL.md, unchanged |
| **Reference** (lookup tables, mappings, theory) | YES | Separate reference.md |
| **Machinery** (hooks, agents, chains) | YES | settings.json, hooks/, agents |
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The Sacred Directive Pattern

When a user gives you a rule, store it unchanged in a `## Directives` section with exact wording, source, and date. Place at TOP of skill file. NEVER summarize or reword. After adding a directive, run the hooks procedure (see [procedures/hooks.md](procedures/hooks.md) § "Directive Pattern") to inventory candidates; create a hook for every directive that matches a pattern in that table. Skip hook enforcement only when the directive cannot be mechanically detected (e.g., purely stylistic voice rules), and record the reason in the hook procedure's output.

**Grounding:** Read [templates.md](templates.md) § "SKILL.md Template" and [procedures/directives.md](procedures/directives.md) for format and workflow.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## § Output Discipline — Cascade, Don't Scatter

**Applies to ALL procedures universally. This is a behavioral constraint on how skill-builder presents its output.**

### Rules

1. **Own-skill actions** (optimize, agents, hooks, ledger for skills managed by skill-builder): Always cascade into the current execution flow via AskUserQuestion + TaskCreate. Never present as standalone slash commands for manual invocation.
2. **Cross-skill actions** (commands belonging to other skills like `/awareness-ledger`): Present in a clearly separated "Related Suggestions" footer, labeled as informational. Never mix into execution menus.
3. **Informational recommendations** in conditional notes (e.g., "Run X to fix this"): Reframe as what the *current procedure* will do, or defer to the execution menu. Example: instead of "Run `/skill-builder optimize` to add eval protocol", say "Missing runtime eval protocol — flagged for optimization."
4. **Anti-pattern**: Never end any procedure output with a list of slash commands the user must copy-paste and run manually. If an action is worth recommending, it's worth cascading.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Grounding Protocol

Before using any template, example, or pattern from reference material:
1. Read the relevant file from `references/`
2. State: "I will use [TEMPLATE/PATTERN] from references/[file] under [SECTION]"

The full reference-file index lives in SKILL.md § Grounding.
<!-- /origin -->
