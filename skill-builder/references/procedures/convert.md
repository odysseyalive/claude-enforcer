## Convert Command Procedure

**Convert an existing Opus 4.6-era skill to be fully Opus 4.7-compatible while preserving all user directives verbatim.**

This procedure is the 4.6 → 4.7 migration counterpart to `optimize`. Where `optimize` restructures for context efficiency, `convert` restructures for *literal-execution correctness* on Opus 4.7+. It never rewords user directives — those stay verbatim and receive enforcement annotations. It rewrites skill-builder-owned workflow steps, grounding statements, and machinery language in-place for explicit execution.

**Critical distinction:**
- **Directives** (marked `<!-- origin: user | immutable: true -->`) are SACRED. They get enforcement annotations only. The directive text never changes.
- **Workflow steps, grounding, machinery** (marked `<!-- origin: skill-builder | modifiable: true -->` or unmarked legacy content in skill-builder-generated sections) ARE rewritten in-place. The test: same observable behavior on 4.7 as the original on 4.6.

### Display Mode (default)

When running `/skill-builder convert [skill]`:

1. **Read the target skill's SKILL.md and all associated files** — including every file referenced from frontmatter, every grounded reference file, every AGENT.md under `agents/`, and every hook script under `hooks/`.
2. **Classify each directive** using the criteria in [optimize.md](optimize.md) step 4d ("Directive Annotation Scan"), then apply the agent panel in [optimize.md](optimize.md) step 4d' ("Agent panel: directive classification") when its auto-trigger conditions are met (directive matches both HARD and SOFT markers, matches neither cleanly, or skill frontmatter sets `strictness: thorough`). The panel is opt-in and gated by the same `--deliberate` / precheck pattern used by steps 4b and 5b.
3. **Scan workflow steps** for soft phrasing that 4.7 would under-execute:
   - Conversational phrases ("keep it X", "organize around Y", "when it makes sense")
   - Subjective gates without criteria ("if applicable", "when warranted", "as needed")
   - Implicit cross-file references without explicit "Read X before Y" instruction
   - Classification steps that rely on semantic judgment without pattern/keyword criteria
   - Agent-spawn triggers that say "judgment call" or "guessing is involved" without an explicit IF/THEN gate
4. **Scan grounding statements** for missing explicit read instructions:
   - "See X for details" → SOFT (no read instruction)
   - "Read X before Y" → HARD
   - "Consult X" → SOFT
5. **Check frontmatter for `minimum-effort-level`.** If missing, recommend based on skill profile:
   - Content-creation skills → `xhigh`
   - Skills that spawn agents, invoke hooks, or rely on grounding reads → `high`
   - Lookup-only or format-check skills → `medium` is acceptable
6. **Check for Analytical Phase (Phase 0).** If the skill accepts conversational/exploratory input and has no explicit Phase 0 Assessment step, flag it.
7. **Produce the Conversion Report:**

```
## Conversion Report: /skill-name

**Directives:**
- Total: [N]
- Already 4.7-compatible (HARD): [N] — no changes needed
- Need enforcement annotations (SOFT): [N]
  - "[directive text, first 60 chars]" → annotation needed because: [one-line reason]
  - "[directive text, first 60 chars]" → annotation needed because: [one-line reason]
- Existing annotations: [N] (current: [N], stale: [N])

**Workflow Steps:**
- Total: [N]
- Explicit (4.7-safe): [N]
- Vague (need rewrite): [N]
  - Step [section:line]: "[current text, first 80 chars]" → 4.7 risk: [what literal execution would do wrong]
    Proposed: "[explicit replacement text]"

**Grounding Statements:**
- Total: [N]
- With explicit read instructions: [N]
- Missing explicit read instructions: [N]
  - [file:line]: "[current statement]" → Proposed: "Read [file] § [section] before [action]"

**Effort Level:**
- Current frontmatter value: [high / xhigh / missing]
- Recommended minimum: [medium / high / xhigh]
- Reason: [e.g., "skill spawns agents requiring tool calls", "content-creation skill", "lookup only"]

**Analytical Phase:**
- Skill handles vague/exploratory input: [yes/no]
- Has explicit Phase 0 assessment: [yes/no]
- Recommendation: [Add Phase 0 / Not needed because: ...]

**Estimated token impact:**
- Annotation additions: ~[N] tokens ([count] directives × ~[avg] tokens each)
- Workflow clarifications: ~[N] tokens
- Phase 0 addition: ~[N] tokens (if applicable)
- Net change: +[N] tokens
- Justified by: [reliable execution on 4.7 / eliminated re-prompt overhead / reduced thinking budget per invocation]

**Status:** [4.7-READY / NEEDS CONVERSION]

Run `/skill-builder convert [skill] --execute` to apply changes.
```

Display mode makes no file modifications.

### Execute Mode (`--execute`)

When running `/skill-builder convert [skill] --execute`:

1. **Run display analysis first.** Report must be generated before any task list.
2. **Generate task list via TaskCreate** — one task per discrete action:
   - One task per SOFT directive needing annotation: "Generate enforcement annotation for directive '[first few words]'"
   - One task per vague workflow step: "Rewrite workflow step [section:line] for 4.7 explicit execution"
   - One task per grounding statement missing a read instruction: "Add explicit read instruction to grounding at [file:line]"
   - One task for frontmatter `minimum-effort-level` if missing: "Add minimum-effort-level to frontmatter"
   - One task for Phase 0 if recommended: "Insert Phase 0 — Assessment before Workflow step 1"
3. **Execute each task sequentially**, marking status via TaskUpdate (`pending` → `in_progress` → `completed`).
4. **Annotation tasks** — write the CHECKPOINT block directly beneath the sacred `<!-- /origin -->` close marker of the directive. Do NOT touch the directive text. Follow [templates.md](../templates.md) § "Enforcement Annotation Template" for format. Include the `<!-- Source directive: "..." -->` comment with the verbatim original.
5. **Workflow rewrite tasks** — replace vague text with explicit 4.7-compatible language. The test: would the step produce identical behavior on 4.7 as the original did on 4.6? Keep step numbering intact. Do not rewrite content inside `<!-- origin: user | immutable: true -->` markers — if the soft content is a user directive, it gets an annotation, not a rewrite.
6. **Grounding rewrite tasks** — convert "see X", "consult X", "refer to X" into "Read X § [specific section] before [specific action]".
7. **Frontmatter tasks** — insert `minimum-effort-level` in the YAML block. Use `high` as default; use `xhigh` for content-creation skills (detected via the content-creation indicators in [new.md](new.md) step 2 or the skill's existing domain classification).
8. **Phase 0 tasks** — insert the Phase 0 Assessment block from [enforcement.md](../enforcement.md) § "Analytical Phase Prompting" as a new numbered section before the existing Workflow. Customize the analysis step based on what the skill's inputs are.
9. **Scope discipline.** Execute ONLY the tasks in the list. Do not discover and act on additional opportunities — note them in the completion report instead.
10. **Report before/after line counts and token estimates** once all tasks complete.
11. **Post-convert: Semantic equivalence verification (precheck first).**
    1. **Mechanical precheck.** Compare the pre-convert SKILL.md (`git show HEAD:<path>`) against the current file. Verify every one of these deterministic conditions:
       - Every `<!-- origin: user[^>]* immutable: true -->` ... `<!-- /origin -->` block is byte-identical between the two versions (sacred blocks unchanged).
       - No lines were removed between HEAD and current (only additions plus one-for-one in-place line rewrites are permitted).
       - The set of numbered workflow step headers (`^\d+\. `, `^N\+\d\. `, etc.) appears in the same relative order.
       - The count of top-level `## ` headers in the file did not shrink.
       - Line-count delta matches the sum of: (annotation tasks run × ~15 lines each) plus (frontmatter tasks × 1 line) plus (Phase 0 task × ~4 lines) plus (workflow-rewrite tasks × current delta).
    2. IF all precheck conditions pass AND the skill's frontmatter does not set `strictness: thorough`, mark PASS and skip the agent spawn. Proceed to step 12.
    3. IF any precheck condition fails, OR the convert run did in-place rewrites inside modifiable blocks (workflow-step rewrites) that need semantic-equivalence judgment, OR the skill frontmatter sets `strictness: thorough`, spawn the optimize-diff-auditor agent (`context: none`, see `.claude/skills/skill-builder/agents/optimize-diff-auditor/AGENT.md`).
    4. If the agent returns FAIL, present violations with revert option (`git checkout`). If PASS, proceed to step 12.
12. **Post-convert: Regenerate directive checksums** per [checksums.md](checksums.md) § "Execute Mode" step 2. The directives themselves are unchanged (sacred), but the sidecar update confirms the annotation additions did not disturb the sacred blocks.

### Batch Display Mode (`--all`)

`/skill-builder convert --all` runs display mode for every skill under `.claude/skills/` (excluding skill-builder unless `dev` prefix is used). It produces a summary table:

```
## Batch Conversion Report

| Skill | Directives | Annotations Needed | Workflow Rewrites | Effort Level | Phase 0 | Status |
|-------|------------|--------------------|--------------------|--------------|---------|--------|
| voice | 4 | 2 | 1 | missing (needs xhigh) | needed | NEEDS CONVERSION |
| text-eval | 3 | 0 | 0 | high | not needed | 4.7-READY |
| ... | ... | ... | ... | ... | ... | ... |

**Summary:**
- Total skills: [N]
- 4.7-READY: [N]
- NEEDS CONVERSION: [N]

To convert a specific skill: `/skill-builder convert [skill] --execute`
To convert every skill in sequence: `/skill-builder convert --all --execute`
```

Batch display mode makes no file modifications.

### Batch Execute Mode (`--all --execute`)

`/skill-builder convert --all --execute` chains per-skill `convert <skill> --execute` invocations across every skill under `.claude/skills/` (excluding skill-builder unless `dev` prefix is used).

**The batch-level plan is intentionally thin.** It contains only (a) the discovered skill list and (b) one task per skill. It does NOT enumerate per-skill directive annotations, workflow rewrites, or grounding changes — those are produced by each per-skill execute when its task runs. The task list is what persists through context compaction, not a change dialogue.

1. **Discover skills.** Glob `.claude/skills/*/SKILL.md` and collect skill names. Exclude `skill-builder` unless invoked as `/skill-builder dev convert --all --execute`.
2. **Print the batch plan.** List the discovered skills in the order they will be converted. Example:

    ```
    ## Batch Convert Plan

    Discovered skills (N):
    - voice
    - edit
    - email
    - ...

    Each skill will run through `/skill-builder convert <skill> --execute` in order.
    Tasks are created per-skill so progress survives context compaction.
    ```

3. **Create the batch task list via TaskCreate.** One task per discovered skill. Task title: `Convert <skill>`. Task body: the invocation string `/skill-builder convert <skill> --execute`. Do NOT expand each task with directive/workflow details — those belong to the per-skill execute, not the batch plan.
4. **Execute tasks sequentially.** For each batch task in order:
   - Mark `in_progress` via TaskUpdate.
   - Run the full per-skill Execute Mode procedure (steps 1–12 above) for that skill. The per-skill procedure manages its own inner TaskCreate list — those inner tasks are separate from the batch task list.
   - On successful per-skill completion, mark the batch task `completed` and proceed to the next skill.
   - If the per-skill diff auditor FAILs, follow the per-skill execute's existing revert-or-keep prompt. After the user decides, mark the batch task `completed` (annotate if reverted) and continue to the next skill. Do not abort the batch on a single failure.
5. **Emit a batch completion report.** Summarize skills converted, skills reverted, and totals (annotations, rewrites) applied across the batch.

**Resumption after compaction.** The batch TaskList survives context compaction. If the conversation compacts mid-batch, the next `pending` (or in-flight `in_progress`) batch task identifies which skill to convert next — re-invoke that per-skill conversion and continue. No re-discovery of the skill set is needed.

### Self-Exclusion

`/skill-builder convert skill-builder` is REFUSED. Respond: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev convert skill-builder`"

`/skill-builder convert --all` and `/skill-builder convert --all --execute` skip skill-builder from the iteration unless invoked as `/skill-builder dev convert --all` or `/skill-builder dev convert --all --execute`.

### Grounding

- [templates.md](../templates.md) § "Enforcement Annotation Template" — annotation format
- [templates.md](../templates.md) § "Frontmatter Requirements" — `minimum-effort-level` field
- [enforcement.md](../enforcement.md) § "Opus 4.7 Behavioral Contract" — literal-execution model
- [enforcement.md](../enforcement.md) § "Analytical Phase Prompting" — Phase 0 pattern
- [patterns.md](../patterns.md) §§ "Opus 4.7 literal execution breaks soft directives", "Enforcement annotations preserve directive sanctity", "Analytical phases for vague input", "Effort level is load-bearing on 4.7"
- [optimize.md](optimize.md) step 4d — Directive Annotation Scan (shared classification logic)
- [checksums.md](checksums.md) § "Execute Mode" — post-convert checksum regeneration
