# Self-Heal Templates

Templates for creating the self-heal companion skill and embedding its reactive trigger into target skills.

---

## self-heal SKILL.md Template

```yaml
---
name: self-heal
description: "Reactive skill correction. Triggers on directive disagreements (user corrections). Diagnoses root cause and proposes surgical fixes."
allowed-tools: Read, Write, Edit, Task, TaskCreate, TaskUpdate
---
```

```markdown
# Self-Heal

Reactive companion skill. When the user corrects the AI about directive compliance, self-heal diagnoses whether the skill's wording caused the misinterpretation and proposes a surgical fix — with user approval.

This skill does not run on a schedule or at session end. It triggers from conversation signals only.

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

## Gap Types

When the user reports a workaround that should be documented (a workflow omission rather than a directive misinterpretation), classify the gap:

| Gap Type | Description | Example |
|----------|-------------|---------|
| **Missing fallback** | Skill has step A but no guidance when A fails | "Read config.json" but config might be YAML |
| **Stale reference** | Skill references a tool/path/format that changed | Skill says "npm test" but project uses vitest |
| **Undocumented edge case** | Workflow works for common case but not this variant | Skill assumes single-package repo, this is monorepo |
| **Missing prerequisite** | Skill assumes a precondition without checking it | Skill says "edit hooks file" but hooks/ doesn't exist |

These follow the same diagnosis flow: SKILL_WORDING verdict → patch-reviewer → user approval.

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

## Entry format:
## Diagnosis: YYYY-MM-DD
Skill: [skill-name]
Directive: [quoted directive]
Verdict: [SKILL_WORDING / AI_ERROR / AMBIGUOUS]
Signal type: [Direct reference / Corrective / Frustrated repetition / Behavioral redirect / Implicit]
Wording: [quoted non-directive wording that caused the issue, if SKILL_WORDING]
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

**Compound infrastructure check:** When embedding, verify combined infrastructure (trigger block + runtime eval protocol, if present) does not exceed 50 lines. If it does, flag to the user and recommend optimizing the skill first to free up line budget.

---

## Hook Hardening Pattern

All hooks skill-builder creates follow this defensive pattern. The goal: hooks **never crash** and hook crashes are **detectable**.

### Two-Layer Defense

| Layer | Addresses | Mechanism |
|-------|-----------|-----------|
| **Crash sentinel + ERR trap** | Hook infrastructure errors (invisible to tool_response) | ERR trap writes to `.crash-log` for forensic review |
| **Defensive shell hardening** | Hook self-crashes | `2>/dev/null` and `|| exit 0` on every fallible line |

### ERR Trap (add to every hook)

```bash
# Crash sentinel — add after #!/bin/bash, before any logic
CRASH_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/.crash-log"
trap 'echo "$(date -Is) HOOK_CRASH $(basename "$0")" >> "$CRASH_LOG" 2>/dev/null' ERR
```

When a hook crashes, the ERR trap fires and appends to the sentinel file. The hook still exits non-zero (Claude Code reports the error in the sidebar), and the crash is recorded in `.crash-log` for forensic review.

### Defensive Shell Rules

Every hook script must follow these rules:

1. **`2>/dev/null`** on every `grep`, `jq`, `echo` to file, and pipe operation
2. **`|| exit 0`** after `cat`, `jq`, and any command that could fail on malformed input
3. **Never use `set -e`** — it causes immediate exit on any failure, bypassing the ERR trap's ability to log gracefully
4. **Guard external dependencies** — `command -v jq >/dev/null 2>&1 || exit 0` before using jq
5. **`INPUT=$(cat 2>/dev/null) || exit 0`** — stdin read can fail if the hook runner has issues
