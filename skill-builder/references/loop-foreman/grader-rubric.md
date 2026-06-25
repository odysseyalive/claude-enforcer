<!-- loop-foreman-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# loop-foreman — Work Order, Grader Composition & Stop Threshold

This is the reference the generated `loop-foreman` skill grounds against when it runs. It defines
**when a long task is allowed to run unattended**, **how "done" is decided**, and **when the loop
must stop and come back to the human**. Read it before driving the recipe in `workflow-recipe.md`.

The governing principle (ledger DEC-2026-06-25-loop-foreman-design): *the loop is only as
trustworthy as the thing that checks it, and markdown instructs but cannot enforce.* Everything
below is written so the trust comes from a **mechanical, external check** wherever one exists — not
from an LLM grading its own work.

---

## 1. The Work Order — the single up-front consent that earns "step away"

loop-foreman never auto-runs. Before any autonomous loop begins, it presents ONE consent question
(the "work order") — the analogue of the audit Step 0 disclaimer: one acceptance authorizes the
whole unattended run. The work order MUST carry three fields, and the loop **refuses to arm** if the
first is missing.

| Field | Required? | What it pins | If absent |
|-------|-----------|--------------|-----------|
| **Definition of done** | ◆ REQUIRED | At least one *checkable* condition — a command that exits 0 (test/build/lint), a `grep` that must come back clean, a file that must exist, a schema that must validate. NOT "looks complete." | **REFUSE to arm.** Report: "loop-foreman needs at least one executable done-condition to run unattended. With only a judgment-based goal it can bound the work and bank a best-so-far, but it cannot certify done — run it attended, or add a checkable check." |
| **Reach** | REQUIRED | The files / dirs / tools / context the loop may touch (the blast radius). | Ask once, here, before arming — never mid-run. |
| **Pre-authorized irreversible actions** | REQUIRED (may be empty) | An explicit allowlist of irreversible/outward-facing actions the loop may take unattended (e.g. "may run migrations and commit; may NOT push or deploy"). Empty = it may take none. | Empty list is valid and safe — anything irreversible then pauses and escalates. |

**Front-load everything.** The work order is the ONE place loop-foreman is allowed to interrupt the
human before it starts. Its job is to gather enough that, once running, the loop has no reason to
stop for missing information. Sufficiency cannot be *guaranteed* (see § 4 escalation), but the work
order is where it is maximized.

---

## 2. The Grader — one mechanical oracle + one fresh-context reasoning grader

The ship gate is an **AND** of two checks of *different kinds*. This is deliberate: two same-model
reasoning passes share blind spots (creative-integrity.md § Research Digest: models score their own
output higher; fresh-context, different-family validation is stronger). So the second check is not a
second persona — it is a **non-LLM oracle** that cannot be argued with.

```
SHIP  ⟺  mechanical_oracle == GREEN   AND   reasoning_grader.verdict == PASS
```

### 2a. The mechanical oracle (the convergence floor)

- Runs the checkable done-condition(s) from the work order: the test command, the build, the grep,
  the schema check. Its verdict is an **exit code or a match count** — deterministic, no judgment.
- It is the floor that breaks persona deadlock and stops the loop drifting into vibes. A loop with
  **no** mechanical oracle is exactly the un-anchored self-evaluated loop the repo forbids — which
  is why § 1 refuses to arm without one.
- ◆ **Never optimize toward a detector score.** The oracle checks the real done-condition, never a
  proxy "quality score" the worker could game (the scrub-loop's standing rule).

### 2b. The reasoning grader (the ceiling)

- A **fresh-context** Task agent (context isolation — the only sanctioned delegation rationale here
  besides model-fit; never spawned for "more votes"). It judges what the oracle can't: completeness
  against the work order, quality, and an adversarial "what would make this fail?" pass.
- It grades against a **rubric derived from the work order's definition of done** — not its own
  taste. "Complete" means "meets the stated done-condition," or the two checks grade different
  targets and never converge.
- It is **advisory and never edits**. The grader produces a verdict + specific feedback; the worker
  applies fixes. The moment a grader edits, the worker/grader split that makes the loop trustworthy
  is gone (the scrub-loop's "the evaluator never triggers regeneration itself", generalized).

### 2c. Knowledge-gap research — the research assistant, on demand

When the reasoning grader's failure is a suspected **knowledge gap** (a stale API, a deprecated
call, an out-of-date best practice) rather than a quality defect, it does NOT research itself — it
**requests a cited lookup from the research-assistant teammate** (the 2026-02-23 team directive:
"other team members may make requests from the research assistant"). The RA is the only crew member
with web tools (`WebSearch` to discover → `web_fetch` to verify), runs on the coding model (research
precedence), and **returns a citation**. The grader folds the grounded correction into constructive
feedback for the worker. Guardrails:

- **Conditional, never speculative.** The RA fires only when the grader states a specific
  knowledge-gap hypothesis — not every cycle (token discipline).
- **Cite or it didn't happen.** Any web-grounded correction carries its source; an un-cited "I
  researched it" is rejected.
- **Read-only.** The RA gathers and cites; it never edits and never acts.

---

## 3. Bounds — imported from the Canonical Scrub-Loop Spec

The loop is bounded by the same ◆ guards the text/image scrub loops use
(`creative-integrity.md` § Canonical Scrub-Loop Spec), generalized from creative output to task
completion. These are non-negotiable — a loop missing any of them is not a loop-foreman loop:

- ◆ **Best-so-far snapshot.** Snapshot before each cycle, so a stall still leaves a shippable
  artifact.
- ◆ **Divergence abort.** Score each cycle by `(open rubric items, mechanical-oracle GREEN?)`. A
  cycle that regresses — more open items, the oracle goes red after being green, or the grader's
  objections stop shrinking — reverts to best-so-far and STOPS.
- ◆ **Cycle cap.** A hard maximum number of fix cycles (house default: small, like the scrub loop's
  cap of 2; raise only with a stated reason in the work order). The cap is the backstop against an
  unattended runaway.

---

## 4. The Stop Threshold — what "something really important" means

The loop runs autonomously on reversible work and **pauses + escalates to the human** on exactly
three triggers. Escalation is not failure — it is the loop doing its job.

1. **Irreversible action outside the pre-authorized list (§ 1).** Anything that moves money,
   deploys, deletes, publishes, or otherwise can't be undone, unless the work order cleared that
   category. *(Honest caveat: a markdown instruction to "stop here" is a prompt, not enforcement.
   The genuinely hard stop is a host-generated PreToolUse hook gating irreversible verbs — deferred
   to a later increment, fail-open, never shipped, per the No-Distribute-Hooks Gate and the
   code-eval-enforce honesty floor. Until that exists, the irreversible-action stop is best-effort,
   which is the load-bearing reason the pre-authorized list stays conservative.)*
2. **Grader disagreement after the cycle cap (§ 3).** When the cap or divergence-abort trips and the
   grader still won't pass, the loop does not loop again — it returns the **unresolved disagreement**
   to the human as the report, with the best-so-far artifact. Persistent disagreement IS the stop
   signal.
3. **Mid-run ambiguity the work order didn't cover.** If the task hits a genuine judgment call no
   field anticipated, the loop returns `AMBIGUOUS: <question>` to the human — it never guesses (the
   platoon `AMBIGUOUS:`-returns-to-orchestrator discipline). With the human away, this surfaces in
   the run report; the loop holds rather than fabricating intent.

---

## 5. Arming — offer, never seize

loop-foreman is **offered**, never auto-fired. `route` may *recommend* it when it sees a large
multi-task endeavor, and the skill's own description makes it available for big rollouts — but
entering autonomous mode always crosses the § 1 work order. Detection is not consent. (Auto-arm
detection of "large rollout" is deferred: there is no reliable harness signal for it, and a model
narrating "I detected a big task and armed it" is the empty-claim failure mode the companion-gate
inversion incident documented.)
