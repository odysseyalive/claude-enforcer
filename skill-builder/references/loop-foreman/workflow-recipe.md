<!-- loop-foreman-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# loop-foreman — Bounded Loop Recipe

This reference tells the generated `loop-foreman` skill **how to actually run the loop**. The skill
is markdown: it INSTRUCTS the model to drive a real loop engine; it does not itself loop (markdown
has no `while`). The bound — the cycle cap, the "both checks must pass" gate, the divergence abort —
lives in the **engine's control flow**, where it is genuinely enforced, not in prose the model may
drift past.

Read `grader-rubric.md` first: it defines the work order, the two-check ship gate, the bounds, and
the stop threshold this recipe executes.

---

## Which engine drives the loop

Pick the strongest engine the host actually exposes (the skill checks, in order):

1. **The `Workflow` tool (preferred).** A deterministic JS orchestrator: the `for`/`while`, the
   cycle counter, and the `if (oracleGreen && graderPass)` consensus gate are real program control
   flow — the model is invoked as a *stage inside* the loop, so the cap and the gate are guaranteed,
   not advisory. This is the only engine that makes the bound a hard guarantee. Use it when present.
2. **Background agent + Task queue (fallback).** A detached worker that re-invokes on completion,
   with the cycle counter and best-so-far verdict persisted in `TaskCreate`/`TaskUpdate` state
   outside the model's context. The host-driven re-invoke sustains the unattended loop; the bound is
   recorded in durable state and checked each pass.
3. **`/loop` interval (weakest).** Host re-runs the skill on an interval; the cap/convergence test
   still executes each pass but is the model's judgment, not enforced. Acceptable only for low-stakes
   runs; never for a run with pre-authorized irreversible actions.

If none of these is available, loop-foreman runs the cycles **attended** (reports after each pass)
rather than pretending to a bound it cannot hold.

---

## The recipe (one cycle)

Each cycle is: **work → check → decide**. Expressed as Workflow stages:

```
state = { cycle: 0, best: null }

while (state.cycle < CAP) {                      // ◆ cycle cap — enforced by the engine
  snapshot = snapshot(workTree)                  // ◆ best-so-far: bank before mutating

  // 1. WORK — the worker advances the task within the work order's REACH only.
  worker(workOrder, lastFeedback)                // a Task agent or the main session; never
                                                 //   touches anything outside the reach allowlist

  // 2. CHECK — the two-of-different-kinds ship gate (grader-rubric.md § 2)
  oracle  = runMechanicalOracle(workOrder.done)  // exit code / match count — deterministic
  grader  = agent(reasoningGraderPrompt, {context: 'none'})   // fresh context, advisory, never edits
  if (grader.suspectsKnowledgeGap)
      grader.feedback += researchAssistant(grader.hypothesis) // cited lookup, on demand only

  score = { openItems: grader.openRubricItems, green: oracle.green }

  // 3. DECIDE
  if (oracle.green && grader.verdict === 'PASS')
      return SHIP(workTree)                       // both checks pass → done
  if (regressed(score, state.best))               // ◆ divergence abort
      return ESCALATE('diverging', restore(state.best))
  if (hitsIrreversibleOutsideAllowlist(worker.plannedActions))
      return ESCALATE('irreversible-action', state.best)   // stop-threshold §4.1
  state.best = better(state.best, { snapshot, score })
  lastFeedback = grader.feedback                  // constructive, grounded, fold into next cycle
  state.cycle++
}

// cap reached without consensus → disagreement IS the stop signal (grader-rubric.md §4.2)
return ESCALATE('unresolved-after-cap', state.best)
```

### Notes that keep it honest and bounded

- **The gate is an AND of two *kinds*.** `oracle.green` is non-LLM; `grader.verdict` is reasoning.
  Never collapse them into two reasoning passes — that reintroduces the shared blind spot
  `grader-rubric.md` § 2 exists to avoid.
- **`return` always carries the best-so-far artifact.** No exit path — ship, escalate, or cap —
  ever leaves the human with nothing.
- **Escalation surfaces in the run report**, not a mid-run prompt: the human is away. The report
  names which trigger fired (§ 4) and hands back the best-so-far plus the unresolved item.
- **The worker is sandboxed to the reach.** Anything it wants to touch outside the work order's
  reach allowlist is itself an escalation, not a silent expansion.
- **Crew = a team → the research assistant is mandatory** (2026-02-23 directive): the reasoning
  grader and the RA are distinct personas; the RA is read-only with web tools; the worker and the
  mechanical oracle carry no persona (the oracle is a command, not an agent).

---

## What v1 deliberately does NOT do

- No `route` **auto-arm detection** of "large rollout" — arming is always the offered work order.
- No host-generated **irreversible-action enforcement hook** yet — the stop is best-effort prose
  (grader-rubric.md § 4.1 caveat); the pre-authorized list stays conservative because of it.
- No two-reasoning-grader (different-family) configuration — the v1 second check is the mechanical
  oracle, which is cheaper and strictly harder to fool.
