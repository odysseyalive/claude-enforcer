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

#### Step 3: Identify New Opportunities

Scan each skill's SKILL.md for directive patterns that can be enforced with hooks:

| Directive Pattern | Hook Type | Example |
|-------------------|-----------|---------|
| "Never use X" / "Never assign to X" | **Grep-block** | Block forbidden IDs/values |
| "Always use script Y" | **Require-pattern** | Block direct API calls, require helper |
| "Never call Z directly" | **Grep-block** | Block forbidden endpoints |
| "Must include X" | **Require-pattern** | Ensure required fields present |
| "Never exceed N" | **Threshold** | Block values above limit |

**Cannot be hooks — recommend agents instead:**
- "Choose the best X" → judgment call → **Matcher Agent**
- "If unclear, ask" → context-dependent → **Triage Agent**
- "Match X to Y" → reasoning required → **Matcher Agent**
- "Never produce overbuilt/AI prose" → style judgment → **Voice Validator Agent**
- "Conversational tone" / "No promotional language" → voice enforcement → **Voice Validator Agent**
- "Plain language" / "Natural writing" → style constraint → **Voice Validator Agent**

These MUST appear in the hooks report under a **"Needs Agent, Not Hook"** section (see report template below) so the recommendation isn't lost.

**Scoping requirement:** Hooks that enforce writing/voice style rules must skip `.claude/` infrastructure files. Style hooks apply to project content output, not skill machinery. Use the scope check pattern from the grep-block template above.

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

#### Step 3b: Agent panel — enforcement boundary decisions

Some directives sit at the boundary between hook-enforceable and agent-required. "Never use informal language" — is that a grep pattern or a judgment call? "Always validate inputs" — is that a pre-flight check or a simple pattern match? Per directive: agents are mandatory when guessing is involved.

For directives that aren't clearly in the "hook" or "agent" column, spawn 2 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

- **Agent 1** (persona: Shell scripting pragmatist — writes hooks that catch 80% of violations with zero false positives) — Review the ambiguous directives. Which can be reliably enforced with grep/pattern matching? What specific patterns would the hook check? What's the false positive risk?
- **Agent 2** (persona: AI evaluation specialist — designs agent-based validation for nuanced rules) — Review the same directives. Which require reasoning, context, or judgment that a shell script can't provide? What would the agent need to read and evaluate?

Synthesize:
- Directives both agree are hook-enforceable → hooks section
- Directives both agree need agents → "Needs Agent, Not Hook" section
- Disagreements → present in the report with both arguments; let the user decide

Skip this panel when all directives are clearly one category or the other (e.g., "Never use account ID X" is obviously a grep-block hook).

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
| /skill-name | "Never produce overbuilt prose" | Voice Validator | Requires judgment, not pattern matching |
| /skill-name | "Match vendor to category" | Matcher | Requires reasoning about best fit |

*Run `/skill-builder agents [skill]` to create these.*

## Recommended Actions
1. [Wire orphaned script X]
2. [Create hook for directive Y in /skill-name]
3. [Fix exit code in script Z]
4. [Create Voice Validator agent for /skill-name (see above)]
```

### Execute Mode (`--execute`)

When running `/skill-builder hooks [skill] --execute`:

1. Run display mode analysis first (Steps 1-4 above)
2. **Generate task list from findings** using TaskCreate — one task per discrete action (e.g., "Create no-uncategorized.sh hook", "Wire hook in settings.local.json", "Fix exit code in validate-org-id.sh")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. Each task for new hooks:
   - Create the script in `.claude/skills/[skill]/hooks/[name].sh`
   - Make executable: `chmod +x [script]`
   - Wire in settings.local.json under `hooks.PreToolUse`

**Template for grep-block hooks:**
```bash
#!/bin/bash
# Hook: [purpose] per /[skill] directive
# Scope: Project content files only (skips .claude/ infrastructure)
INPUT=$(cat)

# Scope check: skip .claude/ infrastructure files
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')
if echo "$FILE_PATH" | grep -q '\.claude/'; then
  exit 0
fi

if echo "$INPUT" | grep -q "FORBIDDEN_VALUE"; then
  echo "BLOCKED: [reason] per /[skill] directive" >&2
  exit 2
fi
exit 0
```

**Grounding:** `references/enforcement.md`
