## Runtime Evaluation Protocol

**Self-healing evaluation embedded in skills. Runs every invocation, not on demand.**

This is not a command. It is a protocol that gets embedded into skills by the optimize and new commands. When a skill has the runtime eval protocol, it self-evaluates after every run, records findings, detects trends, and proposes improvements — then gets better over time through use.

---

### How It Works

```
Skill invoked →
  Pre-flight: read eval-history.md, apply known compensations →
  Execute skill workflow normally →
  Post-flight: context:none judge evaluates actual output →
  Record findings in eval-history.md →
  Compare against history → detect trends →
  If recurring issue: propose skill modification →
  User confirms → skill improves →
  Next invocation benefits from the fix
```

**The pre-flight step makes the skill smarter.** It reads what went wrong before and adjusts behavior for this run — applying extra scrutiny, avoiding known failure patterns, or following approaches that previously scored well.

**The post-flight step captures reality.** A `context: none` judge evaluates the actual output with no knowledge of the conversation that produced it, eliminating self-enhancement bias.

**The trend engine closes the loop.** Over multiple runs, the system detects chronic failures and proposes structural fixes (new directives, hooks, agents, workflow changes) — not just "try harder next time" but actual skill modifications.

---

### Protocol Template

This is what gets embedded in a skill's SKILL.md. Optimize recommends adding it; new includes it in generated skills.

```markdown
## Runtime Evaluation

### Pre-Flight: Check History

Before starting the workflow, check for `eval-history.md` in this skill's directory.
If it exists and has 2+ run entries:
1. Read the last 3 runs
2. Identify chronic issues (same criterion scored 1 for 3+ consecutive runs)
3. Identify recent regressions (score dropped since last run)
4. Skip compensations that have been promoted or retired (look for `Promoted:` or `Retired:` entries)
5. For each active issue, read the recorded compensation and apply it during this run
6. State: "Compensating for: [issue] — [approach]"

If no history exists, proceed normally without compensation.

### Post-Flight: Evaluate & Record

After completing the workflow:

1. **Spawn Eval Judge agent(s)** (Task tool, `context: none`, unique persona per criterion):
   - Read this skill's `eval.md` for rubric criteria
   - Read the actual output just produced
   - For each criterion: produce rationale first, then score (1/2/3), then one improvement action
   - Bias mitigations: assume failure until evidence proves otherwise, do not reward verbosity

2. **Record results** — append to `eval-history.md` per the format in
   `references/eval-history-format.md`:
   - Date, rubric scores with delta from prior run
   - What the skill was invoked to do and what it produced
   - Any issues encountered during execution

3. **Detect trends** — compare against history:
   - Chronic failure (scored 1 three times) → propose skill modification
   - Regression (score dropped) → flag what changed since last run
   - Win (improved to 3) → note what approach worked
   - Plateau (stuck at 2 for 3+ runs) → suggest specific improvement from rubric

4. **Lifecycle checks:**
   - If a compensation was applied for 3+ runs and score improved to 2+ → propose promotion to permanent skill change
   - If a compensation was applied for 3+ runs and score did NOT improve → propose retirement
   - If a criterion scored 3 for 5+ consecutive runs → propose retirement and replacement
   - If eval-history.md exceeds 10 runs → archive oldest run
   - If eval-archive.md exceeds 20 entries → compact archive into summary

5. **Report to user:**
   - If all criteria ≥ 2: one-line summary ("Eval: all criteria met")
   - If any criterion = 1: detailed findings + improvement proposal
   - If lifecycle action needed: propose promotion/retirement and ask to apply
```

---

### Generating eval.md

When a skill needs an `eval.md` (detected by optimize, or during new skill creation):

Read `references/eval-rubrics.md` for rubric templates and scoring anchor examples.

**Procedure:**

1. Read the skill's SKILL.md fully
2. Identify the skill's primary function — what does it produce when it works correctly?
3. Check `eval-history.md` from similar skills in the project (if any exist) for commonly-failing dimensions — pre-weight the rubric toward known problem areas
4. Select 2–4 behavioral criteria focused on **output quality and directive adherence**, not structural completeness (that's optimize/verify territory)
5. For each criterion, write a rubric entry using the template in `references/eval-rubrics.md`
6. Add calibration comment: `<!-- calibrated: YYYY-MM-DD -->`
7. Write to `.claude/skills/[skill]/eval.md`
8. Create empty `eval-history.md` with header from `references/eval-history-format.md`
9. Report: "Generated eval.md for /[skill] with [N] criteria."

**Criterion selection for runtime eval** — pick criteria that evaluate what the skill *does*, not what it *is*:

| Criterion type | Use when... | Example criterion name |
|---------------|-------------|----------------------|
| Directive adherence | Skill has directives that must be followed in output | "Directives followed in output" |
| Output completeness | Skill produces deliverables with required components | "Output contains all required elements" |
| Workflow execution | Skill has multi-step procedures | "Workflow steps executed correctly" |
| Enforcement effectiveness | Skill has hooks/agents that should fire | "Enforcement mechanisms activated" |
| Scope discipline | Skill must stay within defined boundaries | "Output stays within defined scope" |
| Quality standard | Skill produces content with quality requirements | "Output meets quality standard" |
| Voice/style compliance | Content-creation skill with voice directives | "Output follows voice directives" |

**Limits:** Minimum 2 criteria, maximum 4. More than 4 criteria dilutes focus.

---

### Trend Detection

Computed from `eval-history.md` during the pre-flight step. Read the last 10 runs.

**Recurring failure:** Same criterion scored 1 for 3+ consecutive runs → "chronic." Generate a compensation proposal.

**Regression:** Score dropped since last run → flag with context (what was different about this invocation?).

**Win:** Score improved to 3 → note what approach worked. If a previous compensation was applied and the score improved, the compensation is validated.

**Plateau:** Score stuck at 2 for 3+ runs → the skill is adequate but not excellent. Surface the rubric's "what a 3 looks like" as a specific target.

---

### Compensation Proposals

When trend detection identifies a chronic issue, generate a typed proposal for modifying the skill:

| Trend | Compensation Type | Example |
|-------|------------------|---------|
| Chronic failure on directive adherence | Directive reinforcement or hook | "Directive X has been violated in 4 consecutive runs. Propose: add PreToolUse hook to block violations." |
| Chronic failure on output quality | Agent or workflow step | "Output quality scored 1 three times. Propose: add a `context: none` evaluation agent before delivery." |
| Chronic failure on scope | Scope statement or grounding | "Output exceeded scope in 3 runs. Propose: add explicit exclusion list to SKILL.md." |
| Regression after modification | Rollback or adjustment | "Quality dropped from 3 to 1 after last optimize. The modification may have removed load-bearing content." |
| Win after adding hook | Pattern capture | "Directive adherence improved 1→3 after adding hook X. Record as PAT in awareness ledger." |

**Proposals are always user-confirmed.** Present the proposal after post-flight evaluation. If the user agrees, apply the modification immediately. Record the compensation in eval-history.md so its effectiveness can be tracked in future runs.

---

### Compensation Lifecycle

Compensations are temporary by design. They exist in pre-flight as behavioral adjustments until they can be promoted to permanent skill modifications or retired as ineffective. Without this lifecycle, pre-flight accumulates instructions forever and the skill bloats.

**Lifecycle stages:**

```
Proposed → Applied → Validated → Promoted (permanent) → Retired from pre-flight
                   → Failed → Retired from pre-flight
```

**Promotion (compensation → permanent):** When a compensation has been applied for 3+ consecutive runs and the criterion score improved and held at 2+:
1. The compensation worked — promote it to a permanent skill modification:
   - Behavioral adjustment → becomes a workflow step or grounding statement in SKILL.md
   - "Add hook" proposal → becomes an actual hook (via `/skill-builder hooks`)
   - "Add agent" proposal → becomes an actual agent (via `/skill-builder agents`)
   - "Add directive" proposal → becomes a directive in SKILL.md
2. Remove the compensation from pre-flight — it's baked into the skill now
3. Record the promotion in eval-history.md: `Promoted: [compensation] → [permanent change]`
4. The criterion that triggered it continues to be evaluated — the permanent change is now what gets scored

**Retirement (compensation failed):** When a compensation has been applied for 3+ consecutive runs and the criterion score did NOT improve:
1. The compensation didn't work — retire it
2. Remove from pre-flight
3. Record: `Retired: [compensation] — ineffective after [N] runs`
4. The trend engine will propose a different compensation type on the next failure

**Pre-flight should only contain active compensations.** During pre-flight, if a compensation has been promoted or retired (check eval-history.md for `Promoted:` or `Retired:` entries), skip it.

---

### Criteria Lifecycle

Rubric criteria in eval.md are not permanent. They should evolve as the skill matures.

**Criteria retirement:** When a criterion has scored 3 for 5+ consecutive runs, it's stable. During post-flight:
1. Note: "[Criterion] has scored 3 for [N] consecutive runs — consider retiring"
2. If the user agrees, remove the criterion from eval.md and add a replacement focused on a weaker area
3. Record: `Criterion retired: [name] — stable at 3 for [N] runs`
4. Minimum 2 criteria must remain — never retire below the floor

**Criteria replacement:** When retiring a criterion, scan the most recent run findings for areas that scored lowest or had the most findings. Propose a new criterion targeting that area using the taxonomy in § "Generating eval.md."

This ensures eval.md stays focused on the skill's actual weak spots, not on areas it has already mastered.

---

### Eval-to-Ledger Bridge

When `.claude/skills/awareness-ledger/` exists, connect runtime eval findings to the ledger:

- **Chronic failures** → suggest PAT record ("Skill X consistently fails on Y because Z")
- **Successful compensations** → suggest DEC record ("Added hook X because runtime eval showed recurring failures on Y")
- **Eval trigger patterns** for the capture-reminder hook: "scored 1 on," "recurring eval failure," "eval regression"

---

### Integration Points

This protocol is consumed by three commands:

**optimize** — Detects skills without the runtime eval protocol. Recommends adding it. In execute mode, embeds the protocol sections and generates eval.md + eval-history.md.

**audit** — Surfaces skills missing the runtime eval protocol in the skills summary table. Shows trend data for skills that have it.

**new** — Includes the runtime eval protocol in generated skills from the start. Every new skill ships with eval.md, eval-history.md, and the pre-flight/post-flight workflow sections.

---

### Rubric Staleness

The rubric carries a `<!-- calibrated: YYYY-MM-DD -->` comment. During pre-flight, if the skill's SKILL.md has been modified since calibration (check via git log or file modification time), note: "Rubric may be stale — eval.md calibrated [date], SKILL.md modified [date]. Consider reviewing criteria."

During optimize in execute mode, if eval.md exists and is stale, flag for criterion review.
