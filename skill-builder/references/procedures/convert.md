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
       - Every `<!-- origin: user[^>]*immutable: true[^>]*-->` ... `<!-- /origin -->` block is byte-identical between the two versions (sacred blocks unchanged). The trailing `[^>]*` keeps the match order-insensitive — `immutable: true` may sit in any token position within the marker.
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

### Hand-Written Skill Intake (wrap-time directive classification — sign-off required)

Fires whenever the target skill contains text outside any `<!-- origin: ... -->` markers (the common case for people-generated skills; a live census found 10 of 22 skills fully hand-written). **The "Critical distinction" above inverts here: in a fully hand-written skill, unmarked text has the STRONGEST claim to user origin** — it is not "unmarked legacy machinery." Until classification is ratified, convert may only APPEND (annotations, frontmatter keys); it may not rewrite a single unmarked line.

1. **Propose the classification.** Walk the body block-by-block and emit the FULL proposed inventory — every block quoted verbatim, labeled **SACRED** (will receive `origin: user | immutable: true` markers), **MACHINERY** (will receive `origin: skill-builder | modifiable: true` markers and become rewritable), or **UNSURE**.
2. **UNSURE blocks get the agent panel** (Non-Obvious Decision Gate — classification is judgment). The panel RECOMMENDS only; it never ratifies. Panel split → the block stays UNSURE.
3. **The user ratifies via AskUserQuestion** (batched). **The default for every UNSURE or unratified block is SACRED** — a wrongly-frozen block is recoverable (the user edits the markers); a wrongly-reworded user sentence is not. Nothing is marked MACHINERY without explicit ratification.
4. **Markers are additive.** Wrapping verbatim text in origin markers adds lines around it and changes nothing inside — attribution lines and nonstandard formatting INSIDE a SACRED block stay byte-exact (templates.md places attribution inside the block; a wrapper never "normalizes" it).
5. **Checksums are generated ONLY after ratification** (checksums.md Execute step 2), so the integrity baseline records consented state — never the converter's guess. The pre-ratification file has no sidecar to mislead the protect-directives hook.

### Legacy-Artifact Recognizer Table (previous-generation output)

Skills generated by earlier claude-enforcer versions carry artifacts current machinery no longer emits. The converter recognizes them EXPLICITLY — pattern-blindness is how user wording inside an old generated block gets destroyed. **Unrecognized generated-looking blocks are NEVER rewritten or deleted — they QUARANTINE to the report** for human decision.

| Legacy artifact | Recognition | Disposition |
|---|---|---|
| Prose-only route-consultation text (pre-ROUTE-EMBED) | "consult /route" guidance outside any START/END markers | **replace-with-family-block** — `route embed` inserts the canonical ROUTE-EMBED; the prose is removed only after the block lands (make-before-break) |
| Versioned `origin: skill-builder` blocks with retired family names | `origin: skill-builder \| version: <old>` wrapping machinery no current reconciler matches | **upgrade-in-place** per the current template for that content class; if no class matches → quarantine |
| Pre-LANE-AGENT delegation prose | "spawn a subagent pinned to..." outside markers | **replace-with-family-block** via `agents [skill]` (Bespoke Excursion-Agent Gate applies) |
| Agents missing `model:` / `contract-stamp:` | frontmatter scan | **upgrade-in-place** — stamp per the Audit Agent Model-Assignment Gate; contract-stamp via `agents [skill]` |
| Legacy standalone shell-safety remnants | `.claude/skills/shell-safety/` | already handled by the installer's cleanup; report if found |
| Old checksum sidecar formats | `.directives.sha` not matching checksums.md format | **upgrade-in-place** — regenerate after any ratified classification |
| **Foreign `MODEL-SWITCH-GATE` family** (the user's own legacy model-switch skill) | `<!-- MODEL-SWITCH-GATE START/END -->` markers | **harvest + delegate removal.** Parse the gate's mode list (`--modes`) into PROPOSED per-function lane rows (suggestions for the user to confirm — they seed, never auto-write). Removal is the OWNING skill's job (`/model-switch embed --remove`) or per-block user consent where the owner is gone — skill-builder never refreshes another tool's blocks. The legacy skill's own sacred directive block follows the strip immutable-block precheck (strip.md): user-ratified rehoming before any deletion is offered. |
| Inline user wording inside any old generated block | quoted user phrases predating origin markers | **extract verbatim into proper SACRED markers first**, then upgrade the husk |

### Lane-Gate Migration (make-before-break — per-skill atomic transactions)

Migrating a project onto the 2-Brain Harness (slim gates + door preflight) must never leave a skill less protected mid-stream. The invariant, enforced per skill: **at every intermediate state, the skill has exactly one live lane checkpoint — never zero, never two.**

1. **Parity first.** The slim MODEL-LANE-GATE (route.md § Step 8c) and the door preflight (Dispatch CHECKPOINT clause 2) must already be the canonical texts in the installed skill-builder BEFORE any legacy gate is touched. HARD STOP otherwise.
2. **One task per skill = one transaction** (mandatory TaskCreate list — audits always generate a plan and task list). Each transaction, in order: (a) write the skill's confirmed lane row(s) into declared storage (model-lanes.md table / frontmatter — user-confirmed, including any harvested per-function rows); (b) wire or REFRESH the slim gate via `route embed`; (c) ONLY THEN remove the legacy gate via its owner's `--remove` path; (d) drop any now-redundant `model-lane-gate: off` flag, with the change listed in the report.
3. **Abort safety.** A batch interrupted between transactions leaves every completed skill fully migrated and every untouched skill fully legacy — both states protected. Resumption follows the batch task list (same pattern as Batch Execute Mode above).
4. **Verification per transaction:** re-read the file; exactly one gate family present; lane resolves from declared storage; no `origin: user | immutable: true` content changed.
5. **Closing sweep:** zero legacy markers project-wide; `reconcile` reports no gate-family collisions; the project's carve-out documentation (if any) updated to describe the new single-system state; deliberate ledger-recorded overrides carried forward as explicit rows, never normalized away.

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
