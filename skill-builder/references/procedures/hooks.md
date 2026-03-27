## Hooks Command Procedure

**Inventory existing hooks and identify new enforcement opportunities.**

When running `/skill-builder hooks` (all skills) or `/skill-builder hooks [skill]` (specific skill):

### Display Mode (default)

#### Step 1: Inventory Existing Hooks

Scan for hook scripts and their wiring:

```
1. Glob for .claude/skills/**/hooks/*.sh
2. Read .claude/settings.local.json → hooks section
3. Cross-reference: which scripts are wired, which are orphaned
```

#### Step 2: Validate Existing Hooks

For each hook script found:

| Check | What to Verify |
|-------|----------------|
| **Wired** | Listed in settings.local.json `hooks` section |
| **Matcher** | Correct tool matcher (Bash, Edit, etc.) |
| **Exit codes** | Uses `exit 2` to block, `exit 0` to allow |
| **Reads stdin** | Captures `INPUT=$(cat)` for tool input |
| **Permission** | Script is executable (`chmod +x`) |
| **Error output** | Writes block reason to stderr (`>&2`) |
| **Hardened** | Has ERR trap writing to crash sentinel (grep for `trap.*ERR` or `CRASH_LOG`) |
| **No set -e** | Does NOT use `set -e` (causes immediate exit, bypasses ERR trap logging) |
| **Defensive I/O** | Uses `2>/dev/null` and `|| exit 0` on fallible operations |

Unhardened hooks should be flagged as: "Hook lacks defensive hardening — vulnerable to silent crashes. See Hook Hardening Pattern."

#### Step 3: Identify New Opportunities

**Handler type decision guide** (see `references/enforcement.md` § "Hook Handler Types"):

| Check Requirement | Handler Type | Cost |
|-------------------|-------------|------|
| Pattern/regex match (deterministic) | `command` | Free |
| Meaning/intent evaluation (semantic) | `prompt` | 1 LLM call |
| Multi-file cross-reference (analytical) | `agent` | 1+ LLM calls |
| External service call | `http` | Network call |

Scan each skill's SKILL.md for directive patterns that can be enforced with hooks:

| Directive Pattern | Handler Type | Example |
|-------------------|-------------|---------|
| "Never use X" / "Never assign to X" | **command** (grep-block) | Block forbidden IDs/values |
| "Always use script Y" | **command** (require-pattern) | Block direct API calls, require helper |
| "Never call Z directly" | **command** (grep-block) | Block forbidden endpoints |
| "Must include X" | **command** (require-pattern) | Ensure required fields present |
| "Never exceed N" | **command** (threshold) | Block values above limit |
| "Never alter/reword directives" | **prompt** (semantic) | Block paraphrasing of sacred text |
| "Each X must be unique across Y" | **agent** (cross-reference) | Scan multiple files for duplicates |
| "No promotional language" | **prompt** (semantic) | LLM evaluates tone/style |
| "Verify dates are correct" | **command** (temporal) | Arithmetic check on date phrases |

**Prompt hooks unlock new enforcement:** Directives previously classified as "needs agent, not hook" may now be enforceable via prompt hooks. Re-evaluate style/tone/meaning directives — if a single-turn LLM evaluation suffices, a prompt hook is cheaper than a full agent and fires automatically.

**Still cannot be hooks — recommend agents instead:**
- "Choose the best X" → judgment call requiring context → **Matcher Agent**
- "If unclear, ask" → context-dependent → **Triage Agent**
- Complex multi-step evaluation → **Text Evaluation Pair** or **context: none agent**

These MUST appear in the hooks report under a **"Needs Agent, Not Hook"** section (see report template below) so the recommendation isn't lost.

**Scoping requirement:** Hooks that enforce writing/voice style rules must skip `.claude/` infrastructure files. Style hooks apply to project content output, not skill machinery. Use the scope check pattern from the grep-block template or the `if` field for frontmatter hooks.

**PostCompact opportunity:** For every skill with sacred directives, consider a PostCompact hook that re-injects critical rules after context compaction. This is low-cost (command hook echoing JSON) and addresses the root cause of drift.

#### Step 3a: Detect Awareness Ledger Hook Opportunities

Check if `.claude/skills/awareness-ledger/` exists. If it does:

1. **Check for skill-specific consultation gaps** — If the skill has directives that reference past failures, learned patterns, or architectural decisions (phrases like "we decided to," "after the incident," "this was chosen because"), and those aren't captured in the ledger, flag as: "Directive references historical knowledge not yet in the ledger. Recommend `/awareness-ledger record` to capture."
2. **Check for outdated capture hook** — If `capture-reminder.sh` fires on every Task completion without trigger pattern matching (grep for the generic "If findings, decisions, or patterns emerged" message, or check if it's a PostToolUse hook instead of PreToolUse), flag as: "capture-reminder.sh uses blanket reminders. Enhanced template available with trigger-pattern matching that eliminates reminder fatigue — see `references/ledger-templates.md` § capture-reminder.sh." Add to the report under "Recommended Actions" as an upgrade opportunity.
3. **Check for obsolete consult-before-edit.sh** — If `consult-before-edit.sh` exists in the skill's `hooks/` directory or is wired in `settings.local.json`, flag as: "consult-before-edit.sh is obsolete. Ledger consultation belongs in the planning phase (CLAUDE.md line + skill directive), not at edit time. Remove the hook and ensure the CLAUDE.md Integration Line and READ auto-activation directive are in place — see `references/ledger-templates.md` § Auto-Activation Directives and § CLAUDE.md Integration Line."

If the ledger does not exist, skip this step silently.

#### Step 3a-ii: Evaluate Post-Action Capture Hook

If `.claude/skills/awareness-ledger/` exists, evaluate whether a lightweight post-action reminder hook would help capture institutional knowledge from skill output.

**Proportionality checks — skip if any apply:**
- Skill already has a capture workflow step in SKILL.md (keywords: "capture," "record," "ledger," "/awareness-ledger record") → workflow step is superior, no hook needed
- Capture Recommender agent was recommended by the `agents` procedure → agent provides intelligent filtering, hook would be redundant
- Skill runs frequently with routine output (formatting, linting, status checks) → reminder fatigue outweighs capture value

**When to recommend:**
- Skill produces occasional findings worth capturing, but not enough to justify an agent
- No other capture mechanism exists for this skill
- Skill completes as a discrete action (agent/Task tool) so PostToolUse hook can fire

If recommending, reference the `capture-reminder.sh` template from `references/ledger-templates.md` § "capture-reminder.sh". Add to the report under "New Opportunities" with hook type "Post-action capture reminder" and note the capture mechanism hierarchy:

**Capture mechanism hierarchy:** workflow step (zero cost, recommended by `optimize`) > Capture Recommender agent (judgment-based, recommended by `agents`) > post-action reminder hook (lightweight fallback, recommended here). Only one mechanism per skill.

If the ledger does not exist, skip this step silently.

#### Step 3b: Agent panel — enforcement boundary decisions *(skip when running as sub-command of audit — fires only in standalone or `--execute` mode)*

Some directives sit at the boundary between hook-enforceable and agent-required. "Never use informal language" — is that a grep pattern or a judgment call? "Always validate inputs" — is that a pre-flight check or a simple pattern match? Per directive: agents are mandatory when guessing is involved.

For directives that aren't clearly in the "hook" or "agent" column, spawn 2 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

- **Agent 1** (persona: Shell scripting pragmatist — writes hooks that catch 80% of violations with zero false positives) — Review the ambiguous directives. Which can be reliably enforced with grep/pattern matching? What specific patterns would the hook check? What's the false positive risk?
- **Agent 2** (persona: AI evaluation specialist — designs agent-based validation for nuanced rules) — Review the same directives. Which require reasoning, context, or judgment that a shell script can't provide? What would the agent need to read and evaluate?

Synthesize:
- Directives both agree are hook-enforceable → hooks section
- Directives both agree need agents → "Needs Agent, Not Hook" section
- Disagreements → present in the report with both arguments; let the user decide

Skip this panel when all directives are clearly one category or the other (e.g., "Never use account ID X" is obviously a grep-block hook).

#### Step 3c: Detect Temporal Validation Opportunities

Scan each skill for temporal exposure — patterns that indicate the skill produces or manipulates date/time-sensitive content where the model's arithmetic could silently fail.

**Temporal exposure indicators** (any 2+ → temporal risk):
- Content generation with citations or references containing dates
- Scheduling, calendar, or timeline workflows
- Data reporting with date ranges or period comparisons
- Directives requiring temporal accuracy ("dates must be accurate," "verify timelines")
- Output that embeds relative time phrases ("a few weeks ago," "recently," "since [date]")

**Classify risk per `references/temporal-validation.md` § "Temporal Risk Classification":**

- **HIGH risk:** Add to "New Opportunities" table with hook type "Temporal-validation" and **High** priority. Classify based on actual temporal patterns found (citation workflows, date arithmetic, timeline generation), not domain assumption.
- **MEDIUM risk:** Add to "New Opportunities" table with hook type "Temporal-validation" and **Medium** priority.
- **LOW risk:** Skip silently — no hook needed.

**In execute mode:** Generate the hook script following the architecture specification in `references/temporal-validation.md` § "Hook Generation Specification," adapted to the target system's available tools (detect Python/GNU date/BSD date at runtime). The hook:
- Scopes to content files only (skips `.claude/` infrastructure)
- Handles Edit vs. Write tool input differently (new content only for edits)
- Strips non-prose content before scanning
- Uses the temporal phrase → day-range mapping for mismatch detection
- Exits 2 with specifics on mismatch, exits 0 when unverifiable

**Grounding:** Read [references/temporal-validation.md](../temporal-validation.md) before generating temporal hooks.

#### Step 4: Generate Report

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

## Needs Agent, Not Hook

| Skill | Directive | Recommended Agent | Why Not a Hook |
|-------|-----------|-------------------|----------------|
| /skill-name | "Never produce overbuilt prose" | Text Evaluation Pair | Requires judgment, not pattern matching |
| /skill-name | "Match vendor to category" | Matcher | Requires reasoning about best fit |

*Needs agent, not hook — flagged for the agents sub-command.*

## Recommended Actions
1. [Wire orphaned script X]
2. [Create hook for directive Y in /skill-name]
3. [Fix exit code in script Z]
4. [Create Text Evaluation agent pair for /skill-name (see above)]
```

### Execute Mode (`--execute`)

When running `/skill-builder hooks [skill] --execute`:

1. Run display mode analysis first (Steps 1-4 above)
2. **Generate task list from findings** using TaskCreate — one task per discrete action
3. Execute each task sequentially, marking complete via TaskUpdate as it goes

**Frontmatter-first strategy:** Embed hooks in the skill's SKILL.md frontmatter by default. Use `settings.local.json` only for:
- Global hooks that must apply across ALL skills (e.g., directive checksum protection)
- Command hooks that need shell scripts on disk

**For frontmatter hooks (prompt/agent/PostCompact):**
- Add `hooks:` section to the skill's YAML frontmatter
- Use `if` field to scope (e.g., `if: "Edit(**/SKILL.md)"`)
- Use `$ARGUMENTS` placeholder for hook input data

**For command hooks (grep-block, require-pattern, threshold):**
- Create the script in `.claude/skills/[skill]/hooks/[name].sh`
- Make executable: `chmod +x [script]`
- Wire in settings.local.json under appropriate event

**Template for command hooks (grep-block):**
```bash
#!/bin/bash
# Hook: [purpose] per /[skill] directive
# Scope: Project content files only (skips .claude/ infrastructure)
INPUT=$(cat 2>/dev/null) || exit 0

# Scope check: skip .claude/ infrastructure files
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')
if echo "$FILE_PATH" | grep -q '\.claude/' 2>/dev/null; then
  exit 0
fi

if echo "$INPUT" | grep -q "FORBIDDEN_VALUE" 2>/dev/null; then
  echo "BLOCKED: [reason] per /[skill] directive" >&2
  exit 2
fi
exit 0
```

**Template for prompt hooks (semantic enforcement):**
```yaml
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: prompt
          prompt: "[Describe what to check]: $ARGUMENTS. If [violation condition], DENY with explanation. Otherwise APPROVE."
          if: "[scope filter]"
          statusMessage: "[description]..."
```

**Template for agent hooks (multi-file verification):**
```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: agent
          prompt: "[Describe analysis task]: $ARGUMENTS. Scan [files/patterns]. If [violation], DENY. If [ok], APPROVE."
          if: "[scope filter]"
          statusMessage: "[description]..."
```

**Template for PostCompact hooks (drift re-injection):**
```yaml
hooks:
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: [critical rules to re-inject after compaction]\"}'"
          statusMessage: "Re-injecting [skill] awareness..."
```

**Grounding:** `references/enforcement.md`
