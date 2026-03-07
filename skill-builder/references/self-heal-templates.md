# Self-Heal Templates

Templates for creating the self-heal companion skill and embedding its reactive trigger into target skills.

---

## self-heal SKILL.md Template

```yaml
---
name: self-heal
description: "Reactive skill correction. Triggers on directive disagreements (user corrections) and error compensation (hook-detected tool failures with workarounds). Diagnoses root cause and proposes surgical fixes."
allowed-tools: Read, Write, Edit, Task, TaskCreate, TaskUpdate
---
```

```markdown
# Self-Heal

Reactive companion skill. Two trigger paths:

1. **Directive disagreement** — User corrects the AI about directive compliance. Diagnoses whether the skill's wording caused the misinterpretation.
2. **Error compensation** — A PostToolUse hook detects a tool failure. If the AI finds a workaround, this skill diagnoses whether the skill's workflow has a gap worth patching.

Both paths propose surgical fixes — with user approval. This skill does not run on a schedule or at session end.

---

## Directives

> **"Updates to skills must be surgical -- one specific instruction, smallest possible change, nothing more."**

*— Added [DATE], source: system directive*

> **"Nothing is written to a skill file without explicit user approval and a visible before/after diff."**

*— Added [DATE], source: system directive*

> **"Self-heal never modifies directives. Directives are sacred. Only workflow instructions, context descriptions, and clarifying language are in scope."**

*— Added [DATE], source: system directive*

---

## Review Command

When invoked as `/self-heal review`:

1. List all skills that have the self-heal trigger embedded
2. Show count of diagnoses per skill (read each skill's `self-heal-history.md` if it exists)
3. Show count of patches applied vs. declined per skill
4. Flag skills missing the trigger — offer to embed

---

## Grounding

Before executing any diagnosis or update:
1. Read the relevant file from `references/`
2. State: "I will use [PROTOCOL] from references/[file] under [SECTION]"

Reference files:
- [references/directive-disagreement-signals.md](references/directive-disagreement-signals.md) — How users express directive disagreements
- [references/diagnosis-protocol.md](references/diagnosis-protocol.md) — Root cause tracing procedure
- [references/update-protocol.md](references/update-protocol.md) — Diff construction and approval workflow
- [references/error-compensation-signals.md](references/error-compensation-signals.md) — How to recognize error compensation patterns
- [references/error-compensation-monitor.md](references/error-compensation-monitor.md) — Error compensation diagnosis and patching procedure
```

---

## directive-disagreement-signals.md Template

```markdown
# Directive Disagreement Signals

The self-heal trigger watches for one thing: the user telling the AI it is not following a directive. People express this in many different ways. This taxonomy helps the trigger recognize all of them.

## The Single Trigger

A directive disagreement is when the user indicates the AI's behavior does not match a rule, instruction, or constraint defined in the skill. Everything below is a different way of saying that.

## Signal Categories

### Direct Reference to the Directive (Highest confidence)
The user explicitly names the rule or points to where it lives:

- "The directive says X, but you did Y"
- "That violates the rule about..."
- "Read the directive again"
- "Check the SKILL.md" / "Look at the instructions"
- "That's not what the instructions say"
- "The rule is [quotes or paraphrases the directive]"
- "There's a directive about this"

### Corrective Statements (High confidence)
The user states the correct behavior as a correction, implying a known rule:

- "No, we always do it this way"
- "That's not how this works here"
- "We don't do that" / "We never do that"
- "The way we handle this is..."
- "It should be [correct behavior], not [what you did]"
- "That's wrong — [states the rule]"

### Frustrated Repetition (High confidence)
The user has said this before and is repeating themselves — a strong signal of a recurring directive compliance failure:

- "I've already told you..."
- "Again, we need to..."
- "How many times do I have to say..."
- "Like I said before..."
- "I keep having to correct this"
- "We've been over this"

### Behavioral Redirect (Medium confidence)
The user redirects behavior without explicitly naming a directive, but the correction maps to one:

- "Actually, the way we do this is..."
- "Remember, we..."
- "But we're supposed to..."
- "You're supposed to [correct behavior]"
- "That's not the process"
- "Go back and [do the thing the directive requires]"

### Implicit Correction (Medium confidence — confirm before triggering)
The user doesn't say a rule was broken, but their correction aligns with a known directive. Before triggering self-heal, verify the correction maps to a specific directive in the skill:

- User manually redoes what the AI did, following the directive's requirements
- User silently fixes output to match directive constraints
- "Let me show you how this should look" followed by directive-compliant example
- "Close, but [adjustment that matches a directive]"

## What Is NOT a Directive Disagreement

Do not trigger self-heal for these — they are normal interaction:

- Style preferences not codified as directives ("I'd prefer it shorter")
- Reasoning errors where the directive was understood but logic failed
- New requirements the user is adding for the first time
- The user changing their mind about what they want
- Clarifying questions in either direction
- General dissatisfaction with output quality unrelated to directives
- Corrections about factual content (dates, names, numbers) not governed by directives

## The Key Test

Before triggering: **Can you point to a specific directive in the skill that the user believes was not followed?** If yes, trigger. If you cannot identify which directive, do not trigger.
```

---

## diagnosis-protocol.md Template

```markdown
# Diagnosis Protocol

How to determine whether the skill's wording caused a directive compliance failure.

## When to Run

Run this protocol **immediately** when a directive disagreement is detected — not at end of session. The user just told you something went wrong. Diagnose now.

## Step 1: Identify the Directive

Locate the exact directive the user believes was not followed. Quote it verbatim from the skill's SKILL.md.

If you cannot identify which directive → do not proceed. Ask the user: "Which directive are you referring to?" If they clarify, proceed. If it turns out there is no matching directive, this is not a self-heal situation.

## Step 2: Trace the Failure Path

Read the skill's SKILL.md. Trace how the directive's intent flows through the skill:

1. **The directive itself** — Is it clear? (Directives are sacred and cannot be changed, but their clarity matters for diagnosis)
2. **Workflow steps that implement the directive** — Do they accurately translate the directive into action?
3. **Context/framing around the directive** — Does surrounding text create assumptions that contradict the directive?
4. **Examples or clarifying language** — Do they demonstrate the directive correctly?

The question is: **Did the skill's non-directive content cause the AI to misinterpret or deprioritize the directive?**

## Step 3: Spawn Root-Cause Analyst

Spawn the root-cause-analyst agent (`context: none`) with:
- The directive (verbatim)
- The skill's full SKILL.md content
- What the user said (the disagreement signal)
- What the AI did wrong
- The target skill's `self-heal-history.md` (if it exists) — check for prior diagnoses on the same directive

The agent returns one of three verdicts:

**SKILL_WORDING** — The skill's non-directive content (workflow steps, context, framing, examples) caused the AI to misinterpret or deprioritize the directive.
- Must name the exact section and quote the specific wording
- Must explain the causal chain: "This wording says X, which led the AI to interpret the directive as Y, which produced Z"

**AI_ERROR** — The skill's wording is adequate. The AI simply failed to follow a clear directive.
- No skill update warranted
- Stop here

**AMBIGUOUS** — Cannot determine with confidence.
- Do not propose an update
- Stop here

## Step 3b: Check Self-Heal History

Check `self-heal-history.md` for the target skill (at `.claude/skills/[skill-name]/self-heal-history.md`).

If the same wording was previously diagnosed and a patch was declined, do not re-propose the same change. A different angle is acceptable. If no alternative exists, stop here.

## Step 4: Spawn Patch Reviewer (only if SKILL_WORDING)

Before proposing anything to the user, spawn the patch-reviewer agent (`context: none`) with:
- The directive being enforced
- The specific wording identified as the cause
- The full surrounding section for context
- The proposed fix (drafted by the root-cause-analyst)

The patch-reviewer checks:
1. **Minimality** — Is this the smallest change that fixes the root cause?
2. **Completeness** — Does it actually prevent the misinterpretation?
3. **Directive safety** — Does it touch any directive? If yes, REJECT.
4. **New ambiguity** — Does the proposed change introduce new unclear language?

Returns: APPROVED or REJECTED with reason.

If REJECTED → do not propose to user. Stop here.

## Step 5: Present to User (only if patch-reviewer APPROVED)

Present naturally, in the flow of conversation:

```
I think the reason I got that wrong is how the skill describes [specific area].
The directive says: "[quoted directive]"
But the skill's workflow says: "[quoted wording that caused the issue]"

That wording led me to [what went wrong].

Here's what I'd suggest changing:

**Current:**
[Exact quoted text of the current wording]

**Proposed:**
[Exact quoted text of the proposed replacement]

This doesn't touch the directive itself — just how the workflow implements it.
Want me to update the skill?
```

Tone: conversational, not clinical. This is a natural part of the correction, not a system report.

## Step 6: Apply (only with explicit user approval)

If user approves:
1. Read the skill's current SKILL.md
2. Apply the exact change shown in the diff — nothing more
3. Confirm: "Updated. The skill now says [new text]."

If user declines:
1. Acknowledge: "No problem — I'll leave it as is."
2. Do not retry or mention it again.

## Root Causes That Are In Scope

| Content Type | In Scope? | Rationale |
|-------------|-----------|-----------|
| Workflow step descriptions | YES | Common source of directive misinterpretation |
| Context/framing statements | YES | Often create false assumptions about directives |
| Clarifying language and examples | YES | Can demonstrate directives incorrectly |
| Scope descriptions | YES | Ambiguous scope causes directive deprioritization |
| Directives | **NEVER** | Sacred — user's exact words |
| Reference file content | NO | Separate concern |
| Agent definitions | NO | Structural — separate optimization concern |
| Frontmatter | NO | Not a source of directive misinterpretation |

## Surgical Means Surgical

One directive. One wording fix. If the disagreement reveals issues with two different directives, that is two separate self-heal cycles. Do not batch.
```

---

## update-protocol.md Template

```markdown
# Update Protocol

How to construct the before/after diff and apply approved changes.

## Diff Construction Rules

The before/after diff must be:

1. **Exact** — Quote the current wording verbatim
2. **Scoped** — Show only the changed portion, plus one sentence of context on each side
3. **Honest** — If the proposed change is more than a sentence, reconsider minimality
4. **Readable** — Plain text. No code diff syntax.

**Good diff (surgical):**

```
Current:
"Read the file and identify any issues."

Proposed:
"Read the file and identify syntax errors, missing imports, and undefined variables.
Do not flag style issues unless the user asks."
```

**Bad diff (too broad):**

```
Current:
[entire workflow section, 8 lines]

Proposed:
[rewritten workflow section, 8 lines]
```

If the diff requires more than 3-4 lines of change, the patch is not surgical enough. Go back to diagnosis.

## Approval Language

The proposal must:
- Explain what went wrong and why, referencing the directive
- Show the diff clearly labeled "Current" and "Proposed"
- Note that the directive itself is unchanged
- End with a simple yes/no question

The proposal must NOT:
- Use system language ("PATCH APPROVED", "DIAGNOSIS RESULT")
- Apologize excessively
- Explain the entire diagnostic process
- Add caveats that undermine the proposal

## Application Rules

When applying an approved change:
1. Read the current SKILL.md fresh
2. Locate the exact string from the "Current" portion
3. Replace with the "Proposed" text — nothing else
4. Verify by re-reading the modified section
5. Confirm in one sentence
6. Append a record to the target skill's `self-heal-history.md`

If the exact string cannot be located:
- Report: "The skill file seems to have changed. Want me to show the diff against the current version?"
- Do not apply blindly
```

---

## self-heal-history.md Format

Each target skill gets its own `self-heal-history.md` at `.claude/skills/[skill-name]/self-heal-history.md`. Created on first diagnosis, not during install. Append-only.

```markdown
# Self-Heal History: [skill-name]
<!-- Append-only. Populated by self-heal diagnosis protocol. -->

## Entry format (directive disagreement):
## Diagnosis: YYYY-MM-DD
Skill: [skill-name]
Directive: [quoted directive]
Verdict: [SKILL_WORDING / AI_ERROR / AMBIGUOUS]
Signal type: [Direct reference / Corrective / Frustrated repetition / Behavioral redirect / Implicit]
Wording: [quoted non-directive wording that caused the issue, if SKILL_WORDING]
Patch: [PROPOSED / APPLIED / DECLINED]

## Entry format (error compensation):
## Diagnosis: YYYY-MM-DD
Skill: [skill-name]
Trigger: error-compensation
Error: [brief error description]
Workaround: [what the AI did instead]
Verdict: [SKILL_GAP / TRANSIENT / AMBIGUOUS]
Gap type: [Missing fallback / Stale reference / Undocumented edge case / Missing prerequisite]
Workflow step: [quoted step that lacked coverage, if SKILL_GAP]
Patch: [PROPOSED / APPLIED / DECLINED]
```

---

## Agent Personas

### root-cause-analyst

```markdown
---
name: root-cause-analyst
description: Determines whether a skill's non-directive wording caused the AI to misinterpret a directive
context: none
---

You are a skeptical forensic linguist who specializes in instruction analysis. You trace how non-directive wording (workflow steps, context, framing, examples) can cause an AI to misinterpret or deprioritize a directive.

You assume the skill's wording is guilty until proven innocent. If the AI failed to follow a directive, your job is to find where the skill's surrounding text created the wrong interpretation — or to confirm the directive was clear and the AI simply erred.

You do not guess. You return SKILL_WORDING, AI_ERROR, or AMBIGUOUS — with evidence from the specific text.

You never recommend updating directives. Directives are the user's exact words and are permanently out of scope.
```

### patch-reviewer

```markdown
---
name: patch-reviewer
description: Validates that a proposed skill patch is minimal, complete, and safe
context: none
---

You are a meticulous code reviewer who applies the same discipline to natural language instructions as to production code. Your north star: the smallest change that fully prevents the directive misinterpretation.

You reject patches that are too broad. You reject patches that don't actually fix the root cause. You reject any patch that touches a directive.

You return APPROVED or REJECTED. If REJECTED, you state exactly what is wrong and what a better scoped version would look like.
```

---

## Trigger Block

This is the text embedded into every skill that has self-heal integration. It goes in a `## Self-Heal` section at the end of the skill's SKILL.md, after Grounding.

```markdown
## Self-Heal

If the user corrects you about not following a directive — whether they name it
explicitly, redirect your behavior, express frustration about a repeated issue,
or otherwise indicate you're not complying with a rule defined in this skill —
pause and run the self-heal diagnosis protocol:

Read `.claude/skills/self-heal/references/diagnosis-protocol.md` and follow it.

Only trigger when you can point to a specific directive the user believes was
not followed. General dissatisfaction or style preferences are not triggers.
```

**Placement:** This block is always last in SKILL.md — after Grounding, never before it. It is never placed in reference files. It must be in SKILL.md so it loads in every invocation.

**Line budget:** The Trigger block is approximately 12 lines. When embedding, verify the skill's total line count stays under 150. If embedding would push the skill over 150 lines, flag to the user and recommend optimizing the skill first.

**Compound infrastructure check:** When embedding, verify combined infrastructure (trigger blocks + runtime eval protocol, if present) does not exceed 50 lines. If it does, flag to the user and recommend optimizing the skill first to free up line budget.

---

## Error Compensation Hook Script Template

A PostToolUse hook that detects tool failures and injects a message telling Claude to load the error compensation monitor. Conservative detection — only fires on clear error indicators.

**Hook configuration (added to `.claude/settings.local.json`):**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/error-compensation-detect.sh"
          }
        ]
      },
      {
        "matcher": "Edit",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/error-compensation-detect.sh"
          }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/error-compensation-detect.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook script (`.claude/hooks/error-compensation-detect.sh`):**

```bash
#!/bin/bash
# Error Compensation Detection Hook
# PostToolUse hook — detects tool failures and prompts self-heal monitoring.
# Registered on Bash, Edit, and Write. Conservative: only fires on clear error indicators.
# Defensive: every fallible operation exits gracefully. Never crashes, never blocks.

# Crash sentinel — if this hook itself errors, other hooks can detect it
CRASH_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/.crash-log"
trap 'echo "$(date -Is) HOOK_CRASH error-compensation-detect.sh" >> "$CRASH_LOG" 2>/dev/null' ERR

INPUT=$(cat 2>/dev/null) || exit 0

# Guard: jq must be available
command -v jq >/dev/null 2>&1 || exit 0

# Extract tool info
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty' 2>/dev/null) || exit 0
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null) || exit 0

# Skip if no response
[ -z "$TOOL_RESPONSE" ] && exit 0

# Conservative error detection: check for clear error indicators
ERROR_DETECTED=false

# --- Bash-specific patterns ---
if [ "$TOOL_NAME" = "Bash" ]; then
  # Non-zero exit code
  if echo "$TOOL_RESPONSE" | grep -qiP '(exit code|exited with|return code)\s*[^0]' 2>/dev/null; then
    ERROR_DETECTED=true
  fi
fi

# --- Universal error patterns (all tools) ---
if echo "$TOOL_RESPONSE" | grep -qiP '(^error:|^fatal:|command not found|no such file or directory|permission denied|cannot find|failed to|unable to|traceback \(most recent|exception:|panic:)' 2>/dev/null; then
  ERROR_DETECTED=true
fi

# --- Edit/Write-specific patterns ---
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  if echo "$TOOL_RESPONSE" | grep -qiP '(file not found|does not exist|read-only|is a directory|invalid path|not unique|old_string.*not found)' 2>/dev/null; then
    ERROR_DETECTED=true
  fi
fi

# Skip if no error detected
[ "$ERROR_DETECTED" = false ] && exit 0

# Scope check: don't fire during self-heal's own execution
if echo "$INPUT" | grep -q 'self-heal' 2>/dev/null; then
  exit 0
fi

# Output message — stdout is shown in Claude's transcript
echo "---"
echo "ERROR COMPENSATION: Tool failure detected in ${TOOL_NAME}."
echo "If you find a workaround that resolves this error, read"
echo ".claude/skills/self-heal/references/error-compensation-monitor.md"
echo "and follow the protocol after completing the current task."
echo "---"

exit 0
```

**Notes:**
- Registered on `Bash`, `Edit`, and `Write` via separate matchers in the hook config.
- **Defensive hardening:** every fallible line uses `2>/dev/null` and `|| exit 0`. The hook degrades to "allow" rather than crashing.
- **Crash sentinel:** ERR trap writes to `.claude/hooks/.crash-log` so the hook-health-check can detect failures. See § "Hook Hardening Pattern" below.
- Uses `jq` for JSON parsing. Exits cleanly if `jq` is unavailable.
- Tool-specific detection patterns: Bash gets exit code checks, Edit/Write get file operation errors, all tools share universal patterns.
- The scope check prevents recursive self-heal loops.
- Exit 0 ensures the hook never blocks — it only observes.

---

## error-compensation-signals.md Template

```markdown
# Error Compensation Signals

The error compensation hook detects tool failures automatically. This file defines what qualifies as a compensated error worth diagnosing — not every error warrants a skill update.

## The Two-Phase Trigger

1. **Phase 1 (Hook):** A PostToolUse hook detects a tool failure and injects a message into the conversation. This is automatic and deterministic.
2. **Phase 2 (Monitor):** You receive the hook's message while working through the error. If you find a workaround that succeeds, you load this protocol fresh and evaluate whether the skill should be updated.

## What Qualifies as Error Compensation

The hook fires on tool failures. But not every failure needs a skill update. Error compensation means: **the skill's workflow didn't account for this scenario, and you found a workaround that future invocations would benefit from.**

### Compensation Patterns (trigger diagnosis)

**Tool Failure with Alternative (High confidence)**
A tool failed, and you used a different tool or different arguments to achieve the same goal:
- Tool returns an error, you switch to an alternative tool
- File path doesn't exist, you search for the correct path and proceed
- Command fails, you use a different command for the same step

**Missing Prerequisite Recovery (High confidence)**
A workflow step assumed something exists or is true, and it wasn't, but you recovered:
- File the skill references doesn't exist; you create it or find the equivalent
- Directory the skill expects doesn't exist; you create it
- Tool or dependency the skill names is unavailable; you use an alternative

**Data Shape Mismatch (High confidence)**
The skill assumes data looks one way, but reality differs, and you adapted:
- Expected file format differs from actual (e.g., JSON vs YAML)
- Expected directory structure doesn't match
- Expected output format from a tool differs from actual

**Stale Reference (High confidence)**
The skill references a tool, command, path, or format that has changed:
- Skill says "use X" but X has been replaced by Y
- Skill references a path that has moved

### What Is NOT Error Compensation (do not trigger)

- **One-time environmental issues** — Network blip, temporary file lock, disk full
- **Errors in user code** — The skill is operating on broken code; that's the skill's normal job
- **Normal retries** — You retried the same action and it worked (no workaround involved)
- **Exploration** — You tried multiple approaches because the task is ambiguous
- **Already documented fallbacks** — The skill has guidance for this error; it worked as designed
- **Errors during self-heal** — Never trigger self-heal recursively

### The Key Test

Before triggering diagnosis: **Did you discover a workaround that would help future invocations of this skill avoid the same error?** If the workaround is specific to this session's unique state, do not trigger. If it reveals a gap in the skill's workflow, trigger.
```

---

## error-compensation-monitor.md Template

```markdown
# Error Compensation Monitor

You received this protocol because a PostToolUse hook detected a tool failure during skill execution and you found a workaround. This protocol determines whether the skill should be updated.

**Read this file fresh each time.** These are your instructions for this specific evaluation.

## Step 1: Capture the Compensation

Record three things:
1. **The error** — What failed? (exact error message or behavior)
2. **The skill's guidance** — What did the skill's workflow say to do at this point? (quote the relevant step)
3. **Your workaround** — What did you do instead to succeed?

If you cannot articulate all three, the compensation was not significant enough to diagnose. Stop here.

## Step 2: Check Signals

Read `.claude/skills/self-heal/references/error-compensation-signals.md`.

Does your workaround match a compensation pattern? If it matches a "NOT error compensation" pattern, stop here.

## Step 3: Classify the Gap

Determine which kind of skill gap the error reveals:

| Gap Type | Description | Example |
|----------|-------------|---------|
| **Missing fallback** | Skill has step A but no guidance when A fails | "Read config.json" but config might be YAML |
| **Stale reference** | Skill references a tool/path/format that changed | Skill says "npm test" but project uses vitest |
| **Undocumented edge case** | Workflow works for common case but not this variant | Skill assumes single-package repo, this is monorepo |
| **Missing prerequisite** | Skill assumes a precondition without checking it | Skill says "edit hooks file" but hooks/ doesn't exist |

## Step 4: Spawn Error Analyst

Spawn the `error-analyst` agent (`context: none`) with:
- The error message/output
- The skill's relevant workflow section (quoted)
- The workaround you used
- The gap classification from Step 3
- The target skill's `self-heal-history.md` (if it exists)

The agent returns one of three verdicts:

**SKILL_GAP** — The skill's workflow has a documentable gap. The workaround is generalizable.
- Must name the exact workflow step and quote the current wording
- Must describe the gap in one sentence
- Must state why the error is expected to recur

**TRANSIENT** — The error was situational. No skill update warranted. Stop here.

**AMBIGUOUS** — Cannot determine if the error will recur. Stop here.

## Step 5: Spawn Patch Reviewer (only if SKILL_GAP)

Spawn the `patch-reviewer` agent (`context: none`) with:
- The workflow step identified as having the gap
- The full surrounding section for context
- The proposed addition (drafted by the error-analyst)

The patch-reviewer checks minimality, completeness, directive safety, plus:
- **Generality** — Does this help broadly, or only for one specific error?
- **Bloat risk** — Does adding this push the skill toward over-specification?

Returns: APPROVED or REJECTED with reason.

If REJECTED → do not propose to user. Stop here.

## Step 6: Present to User (only if APPROVED)

Present naturally, after completing the current task:

```
I hit an error during [step]: [brief error description].
I worked around it by [workaround].

The skill doesn't cover this scenario. Here's what I'd suggest adding:

**Current:**
[Exact quoted workflow step]

**Proposed:**
[Workflow step with minimal addition]

This doesn't touch any directives — just adds guidance for an edge case.
Want me to update the skill?
```

## Step 7: Apply (only with explicit user approval)

Follow the same application rules as the directive-disagreement update protocol:
1. Read the skill's current SKILL.md fresh
2. Apply the exact change shown — nothing more
3. Confirm: "Updated. The skill now says [new text]."
4. Append a record to the target skill's `self-heal-history.md`

If user declines: acknowledge and do not retry.

## Scope of Updates

| Update Type | Example |
|-------------|---------|
| Fallback clause | "Read `config.json`. If not found, check for `config.yaml`." |
| Prerequisite check | "Verify `hooks/` directory exists before creating hook files." |
| Stale reference fix | Change "`npm test`" to "`npm test` (or project's test runner)" |
| Edge case note | "In monorepos, config may be at workspace root." |

**Out of scope:** New workflow steps (feature request), directive changes (sacred), restructuring (optimization).

## Guard Rails

- **Recurrence filter:** Only propose updates for errors likely to recur. The error-analyst must state why.
- **Bloat budget:** If the patch would push the skill over 150 lines, flag to user and recommend optimizing first. No workflow step accumulates more than two fallback clauses.
- **History dedup:** Check `self-heal-history.md`. If the same error class was previously diagnosed and declined, do not re-propose.
- **One at a time:** One error, one patch. If multiple errors were compensated, run separate diagnosis cycles.
```

---

## Error Analyst Agent Persona

### error-analyst

```markdown
---
name: error-analyst
description: Determines whether a tool failure during skill execution reveals a gap in the skill's workflow
context: none
---

You are a pragmatic systems reliability engineer who investigates operational failures. When a tool fails during skill execution and the AI finds a workaround, your job is to determine: does this error reveal a gap in the skill's workflow, or was it a one-off?

You apply the "would I warn a colleague?" test: if someone was about to run this skill for the first time, would you warn them about this error? If yes, the skill should document it. If no, it's too situational.

You are biased toward TRANSIENT. Most errors are environmental noise. You only return SKILL_GAP when the evidence clearly shows the skill's workflow failed to account for a recurring scenario.

You return SKILL_GAP, TRANSIENT, or AMBIGUOUS — with evidence. For SKILL_GAP, you must name the exact workflow step, describe the gap, state why it will recur, and draft the smallest possible addition that fills it.

You never recommend changes to directives. Directives are the user's exact words and are permanently out of scope.
```

---

## Error Compensation Trigger Block

This is the text embedded into skills alongside the directive-disagreement trigger block. It does NOT perform detection — the PostToolUse hook handles that. This block tells the AI what to do when the hook fires.

```markdown
## Error Compensation

If a PostToolUse hook reports a tool failure during this skill's execution
and you find a workaround that succeeds — load the error compensation
monitor fresh and follow it after completing your current task:

Read `.claude/skills/self-heal/references/error-compensation-monitor.md` and follow it.

Only follow through when the workaround reveals a gap in this skill's
workflow. Transient errors, one-time environmental issues, and errors
in user code are not triggers.
```

**Placement:** Immediately after the Self-Heal (directive-disagreement) trigger block. Same placement rules: always at the end of SKILL.md, never in reference files.

**Line budget:** Approximately 10 lines. Combined with the directive-disagreement trigger block (~12 lines), the total is ~22 lines. When embedding both, verify the compound infrastructure check: combined trigger blocks + runtime eval protocol must not exceed 50 lines.

**Prerequisite:** The error compensation hook must be installed (in `.claude/settings.local.json` and `.claude/hooks/error-compensation-detect.sh`) before this trigger block is useful. The self-heal install procedure handles this.

---

## Hook Hardening Pattern

All self-heal hooks (and any hooks skill-builder creates) follow this defensive pattern. The goal: hooks **never crash** and hook crashes are **always detectable**.

### Three-Layer Defense

| Layer | Addresses | Mechanism |
|-------|-----------|-----------|
| **Crash sentinel + ERR trap** | Hook infrastructure errors (invisible to tool_response) | ERR trap writes to `.crash-log` → sentinel reader reports on next Read |
| **Multi-tool coverage** | Blind spots (Edit/Write unmonitored) | Register error-compensation on Bash, Edit, Write |
| **Defensive shell hardening** | Self-referential paradox (hook detecting its own crash) | `2>/dev/null` and `|| exit 0` on every fallible line |

### ERR Trap (add to every hook)

```bash
# Crash sentinel — add after #!/bin/bash, before any logic
CRASH_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/.crash-log"
trap 'echo "$(date -Is) HOOK_CRASH $(basename "$0")" >> "$CRASH_LOG" 2>/dev/null' ERR
```

When a hook crashes, the ERR trap fires and appends to the sentinel file. The hook still exits non-zero (Claude Code reports the error in the sidebar), but now the crash is also recorded in a file that another hook can read.

### Sentinel Reader Hook

A lightweight PostToolUse:Read hook that checks for accumulated hook crashes. Read fires frequently and almost never fails, making it a reliable carrier for cross-event detection.

**Hook configuration (merged into `.claude/settings.local.json`):**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/hook-health-check.sh"
          }
        ]
      }
    ]
  }
}
```

**Hook script (`.claude/hooks/hook-health-check.sh`):**

```bash
#!/bin/bash
# Hook Health Check — sentinel reader
# PostToolUse:Read hook. Checks for hook crashes recorded by ERR traps.
# Lightweight: only reads a file and exits. Never blocks.

CRASH_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/.crash-log"

# No crash log = no crashes
[ -f "$CRASH_LOG" ] || exit 0

CRASHES=$(wc -l < "$CRASH_LOG" 2>/dev/null) || exit 0
[ "$CRASHES" -eq 0 ] && exit 0

echo "---"
echo "HOOK HEALTH: $CRASHES hook crash(es) detected."
cat "$CRASH_LOG" 2>/dev/null
echo ""
echo "Hook infrastructure errors are not visible in tool_response."
echo "If these crashes affected your current task, read"
echo ".claude/skills/self-heal/references/error-compensation-monitor.md"
echo "and follow the protocol after completing the current task."
echo "---"

# Rotate after reporting — prevents repeated alerts
mv "$CRASH_LOG" "${CRASH_LOG}.reported" 2>/dev/null
exit 0
```

**Why Read?** Read is the most frequent PostToolUse event in a typical session. It almost never errors itself, so the sentinel reader is unlikely to crash. Even if it does, the crash log persists on disk for the next invocation.

### Defensive Shell Rules

Every hook script must follow these rules:

1. **`2>/dev/null`** on every `grep`, `jq`, `echo` to file, and pipe operation
2. **`|| exit 0`** after `cat`, `jq`, and any command that could fail on malformed input
3. **Never use `set -e`** — it causes immediate exit on any failure, bypassing the ERR trap's ability to log gracefully
4. **Guard external dependencies** — `command -v jq >/dev/null 2>&1 || exit 0` before using jq
5. **`INPUT=$(cat 2>/dev/null) || exit 0`** — stdin read can fail if the hook runner has issues
