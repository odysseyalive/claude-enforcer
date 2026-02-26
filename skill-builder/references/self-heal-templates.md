# Self-Heal Templates

Templates for creating the self-heal companion skill and embedding its observer into target skills.

---

## self-heal SKILL.md Template

```yaml
---
name: self-heal
description: "Ambient friction detection and surgical skill correction. Embeds into all skills. Triggers at task resolution when skill instructions caused friction."
allowed-tools: Read, Write, Edit, Task, TaskCreate, TaskUpdate
---
```

```markdown
# Self-Heal

Quiet companion skill. Watches for friction caused by skill instructions during live sessions. At task resolution, diagnoses root cause and proposes surgical fixes with user approval.

**This skill does not run on demand.** It is embedded into other skills as an observer. When it detects a fixable source of friction, it surfaces automatically.

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

1. List all skills that have the self-heal observer embedded
2. Show count of friction events logged per skill (read each skill's `self-heal-history.md` if it exists)
3. Show count of patches applied vs. declined per skill
4. Flag skills missing the observer — offer to embed

---

## Grounding

Before executing any diagnosis or update:
1. Read the relevant file from `references/`
2. State: "I will use [PROTOCOL] from references/[file] under [SECTION]"

Reference files:
- [references/friction-signals.md](references/friction-signals.md) — Complete friction signal taxonomy
- [references/diagnosis-protocol.md](references/diagnosis-protocol.md) — Root cause tracing procedure
- [references/update-protocol.md](references/update-protocol.md) — Diff construction and approval workflow
```

---

## friction-signals.md Template

```markdown
# Friction Signal Taxonomy

The self-heal observer watches for the following signals during live skill sessions.
These are drawn from conversation repair linguistics research (Albert & de Ruiter, 2018;
Dingemanse & Enfield, 2015) and adapted for AI-human skill interactions.

## Signal Categories

### Explicit Repair Signals (High confidence — always log)
User-initiated signals that directly indicate something went wrong:

- Direct corrections: "No, that's not right", "That's not what I meant", "You misunderstood"
- Reformulations: User restates the same request in different words after receiving a response
- Explicit clarification requests: "What did you mean by X?", "Can you explain why you did Y?"
- Rejection of output: "That's wrong", "Start over", "That's not what I asked for"
- Factual corrections: User provides the correct information after AI provided incorrect information

### Implicit Repair Signals (Medium confidence — log with note)
Subtle signals that suggest friction without explicit pushback:

- "Actually...": Either party uses this to introduce a correction or shift
- "I meant...": User clarifies intent after AI response suggests misalignment
- "Wait...": User pauses to reconsider or redirect
- Repeated clarifying questions: AI asks more than one clarifying question that a clearer skill would not have needed to ask
- Scope creep language: "Well, while we're at it..." suggests the original output didn't fully land
- Hedging by AI: "I think you might mean..." "If I'm understanding correctly..." when the skill should have provided enough context to avoid the guess

### Self-Initiated Repair Signals (Log as joint friction)
AI-initiated signals that indicate the AI recognized its own error:

- "Actually, I made a mistake..."
- "Let me correct that..."
- "I misread the requirement..."
- "Looking at this again..."

### Subtle Quality Signals (Low confidence — log only if combined with others)
Signals that something could be better, even if the output was accepted:

- "That works, but..." — accepted with reservation
- "Close enough" — settled rather than satisfied
- "I guess that'll do" — resigned acceptance
- A long silence followed by a new direction — possible unspoken dissatisfaction
- User manually fixes something in the output rather than asking AI to fix it

## What Is NOT a Friction Signal

Do not log these as friction — they are normal interaction:
- The user asking a follow-up question to go deeper (curiosity, not confusion)
- The user changing their mind about what they want (preference shift, not misrepresentation)
- The user providing new information that wasn't available earlier (context update, not failure)
- Normal back-and-forth in collaborative work (dialogue, not friction)

## Limitations

Context compression may lose some friction signals during very long sessions. The observer is best-effort — the most prominent friction signals (explicit corrections, reformulations, rejection of output) survive compression because they are embedded in the conversation itself as substantive exchanges. Subtle quality signals and brief hedging moments are most likely to be lost. This is acceptable: if a signal was subtle enough to be compressed away, it was likely too weak to drive a confident diagnosis anyway.

## Logging Format

When a signal is detected, the observer records internally:

```
Signal type: [Explicit / Implicit / Self-initiated / Quality]
Signal text: [Quoted excerpt — what was actually said]
Turn: [Approximate position in conversation — early / mid / late]
Source hypothesis: [Initial guess at whether this is skill-caused or reasoning-caused]
```

This log is held in working memory only. It is never written to disk during the session — only used at task resolution to inform diagnosis.
```

---

## diagnosis-protocol.md Template

```markdown
# Diagnosis Protocol

How to determine whether friction originated in the skill's own instructions.

## When to Run

Run this protocol at **natural task resolution** — the moment when:
- The user signals the task is done ("thanks", "perfect", "that's it", "okay we're good")
- The conversation reaches a clear stopping point
- The user moves to a new topic

Do NOT run mid-session. Do NOT run after every response. Wait for resolution.

## Step 1: Assess the Friction Log

Review the internally held friction log from the session.

If the log is empty → no diagnosis needed. Session was clean. Stop here.

If the log contains only Quality signals (low confidence) and no Explicit or Implicit signals → skip diagnosis. Single low-confidence signals do not warrant a skill update.

If the log contains at least one Explicit or Implicit signal → proceed to Step 2.

## Step 2: Spawn Root-Cause Analyst

Spawn the root-cause-analyst agent (`context: none`) with:
- The skill's full SKILL.md content
- The friction log (signal type, text, turn, hypothesis)
- The task summary (what was being accomplished)
- The target skill's `eval-history.md` (if it exists) — the analyst checks for pending compensations targeting the same instruction area and notes overlap in the verdict

The agent returns one of three verdicts:

**SKILL_CAUSED** — The friction traces to a specific instruction in the skill.
- Must name the exact section and approximate line
- Must quote the specific instruction that caused the misrepresentation
- Must explain the causal chain: "This instruction says X, which led the AI to assume Y, which produced Z"

**REASONING_CAUSED** — The friction was a reasoning error, not an instruction error.
- The skill's instructions were adequate; the AI simply reasoned incorrectly
- No skill update warranted
- Stop here

**AMBIGUOUS** — Cannot determine with confidence.
- If ambiguous: do not propose an update. Ambiguous diagnoses should not trigger skill changes.
- Stop here

## Step 2b: Check Self-Heal History

Check `self-heal-history.md` for the target skill (at `.claude/skills/[skill-name]/self-heal-history.md`).

If the same instruction was previously diagnosed and a patch was declined, do not re-propose the same change. A different angle or framing is acceptable, but the identical patch is not. If no alternative angle exists, stop here.

## Step 3: Spawn Patch Reviewer (only if SKILL_CAUSED)

Before proposing anything to the user, spawn the patch-reviewer agent (`context: none`) with:
- The specific instruction identified as the source
- The full surrounding section for context
- The proposed fix (drafted by the root-cause-analyst)

The patch-reviewer checks:
1. **Minimality** — Is this the smallest change that fixes the root cause? If a single sentence can be clarified, do not rewrite the paragraph.
2. **Completeness** — Does it actually fix the misrepresentation? A minimal fix that doesn't solve the problem is not a fix.
3. **Directive safety** — Does it touch any directive? If yes, REJECT — directives are out of scope.
4. **New ambiguity** — Does the proposed change introduce a new unclear term or edge case?

Patch-reviewer returns: APPROVED or REJECTED with reason.

If REJECTED → do not propose to user. The proposed patch was not good enough. Stop here.

## Step 4: Present to User (only if patch-reviewer APPROVED)

Present the proposal naturally, as part of the conversation — not as a system alert.

Format:

```
I noticed I had some trouble with [brief description of what went wrong] earlier.
I think it came from how this skill describes [specific area].

Here's what I'd suggest changing:

**Current:**
[Exact quoted text of the current instruction]

**Proposed:**
[Exact quoted text of the proposed replacement]

Would you like me to update the skill? This won't affect anything else — just this section.
```

Tone: conversational, not clinical. "I noticed" not "DIAGNOSIS RESULT:".
This is a natural offer, not a system report.

## Step 5: Apply (only with explicit user approval)

If user approves:
1. Read the skill's current SKILL.md
2. Apply the exact change shown in the diff — nothing more
3. Confirm: "Updated. The skill now says [new text]."

If user declines:
1. Acknowledge: "No problem — I'll leave it as is."
2. Do not log, do not retry, do not mention it again.

## Root Causes That Are In Scope

The following skill content can be updated by self-heal:

| Content Type | In Scope? | Rationale |
|-------------|-----------|-----------|
| Workflow step descriptions | YES | Common source of misrepresentation |
| Context/framing statements | YES | Often cause false assumptions |
| Clarifying language and examples | YES | Can be improved for precision |
| Scope descriptions | YES | Ambiguous scope causes overreach or underreach |
| Directives | **NEVER** | Sacred — user's exact words |
| Reference file content | NO | Separate concern — not in scope for self-heal |
| Agent definitions | NO | Too structural — separate optimization concern |
| Frontmatter | NO | Structural — not a source of session friction |

## Surgical Means Surgical

One instruction. One change. If the diagnosis points to two separate instructions as sources of friction, that is two separate sessions' worth of self-heal. Do not batch. Do not improve adjacent things. The task list is the contract.
```

---

## update-protocol.md Template

```markdown
# Update Protocol

How to construct the before/after diff and apply approved changes.

## Diff Construction Rules

The before/after diff must be:

1. **Exact** — Quote the current instruction verbatim, character for character
2. **Scoped** — Show only the changed portion, plus one sentence of context on each side for readability
3. **Honest** — If the proposed change is more than a sentence, reconsider minimality
4. **Readable** — Plain text diff. No code diff syntax. User is approving natural language changes.

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

If the diff requires showing more than 3-4 lines of change, the patch is not surgical enough. Go back to diagnosis and find a smaller scope.

## Approval Language

The proposal must:
- Identify what went wrong in plain language (not technical)
- Show the diff clearly labeled "Current" and "Proposed"
- End with a simple yes/no question
- Not oversell the change or express uncertainty about whether it's right

The proposal must NOT:
- Use system language ("PATCH APPROVED", "DIAGNOSIS RESULT")
- Apologize excessively
- Explain the entire diagnostic process
- Add caveats that undermine the proposal

## Application Rules

When applying an approved change:
1. Read the current SKILL.md fresh — do not use cached content
2. Locate the exact string from the "Current" portion of the diff
3. Replace it with the "Proposed" text — nothing else
4. Verify the change was applied correctly by re-reading the modified section
5. Report confirmation in one sentence
6. Append a record to the target skill's `self-heal-history.md` (create the file if it doesn't exist, using the format from § "self-heal-history.md Format" below)

If the exact string cannot be located (file was modified since the diff was shown):
- Report: "The skill file seems to have changed since I proposed this update.
  Would you like me to show the diff again against the current version?"
- Do not apply the change blindly
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
Verdict: [SKILL_CAUSED / REASONING_CAUSED / AMBIGUOUS]
Signal type: [Explicit / Implicit / Self-initiated]
Instruction: [quoted instruction, if SKILL_CAUSED]
Patch: [PROPOSED / APPLIED / DECLINED]
Eval overlap: [none / pending compensation on same area]
```

---

## Agent Personas

### root-cause-analyst

```markdown
---
name: root-cause-analyst
description: Determines whether session friction originated in skill instructions
context: none
---

You are a skeptical forensic linguist who specializes in instruction analysis. You have spent your career identifying exactly how ambiguous or misleading instructions produce predictable errors downstream. You assume the skill is guilty until proven innocent — if friction occurred, your job is to find where the instructions failed, not to defend them.

You do not guess. You do not hedge. You return SKILL_CAUSED, REASONING_CAUSED, or AMBIGUOUS — and you explain exactly why with evidence from the specific instruction text.

You never recommend updating directives. Directives are the user's exact words and are out of scope.
```

### patch-reviewer

```markdown
---
name: patch-reviewer
description: Validates that a proposed skill patch is minimal, complete, and safe
context: none
---

You are a meticulous code reviewer who applies the same discipline to natural language instructions as to production code. Your north star: the smallest change that fully solves the problem. You reject patches that are too broad. You reject patches that don't actually solve the root cause. You reject any patch that touches a directive.

You return APPROVED or REJECTED. If REJECTED, you state exactly what is wrong with the patch and what a better scoped version would look like.
```

---

## Observer Instruction Block

This is the text embedded into every skill that has self-heal integration. It goes in a `## Self-Heal Observer` section at the end of the skill's SKILL.md, after Grounding.

```markdown
## Self-Heal Observer

Throughout this session, quietly note any friction signals — corrections, reformulations,
clarifying questions, "actually" moments, or any subtle sign that this skill's instructions
may have led to a misrepresentation. Do not interrupt the session to address these.
Do not mention that you are observing.

At natural task resolution (when the task is complete and the user signals done),
if friction signals were noted, run the self-heal diagnosis protocol:

Read `.claude/skills/self-heal/references/diagnosis-protocol.md` and follow it exactly.

If no friction signals were noted, or if diagnosis finds no skill-caused issues,
end the session normally without mentioning self-heal.

The goal is efficiency: get it right permanently, rather than repeat the same
misrepresentation across future sessions.
```

**Placement:** This block is always last in SKILL.md — after Grounding, never before it. It is never placed in reference files. It must be in SKILL.md so it loads in every invocation.

**Line budget:** The Observer block is approximately 15 lines. When embedding, verify the skill's total line count stays under 150. If embedding would push the skill over 150 lines, flag to the user and recommend optimizing the skill first before embedding.

**Compound infrastructure check:** When embedding, verify combined infrastructure (observer block + runtime eval protocol, if present) does not exceed 50 lines. If it does, flag to the user and recommend optimizing the skill first to free up line budget.
