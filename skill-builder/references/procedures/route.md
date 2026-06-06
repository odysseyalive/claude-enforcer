## Route Command Procedure

**Maintain the `/route` skill (a glorified, auto-generated index of all installed skills) and embed route-consultation hooks into other skills so the AI dispatches through the index instead of freelancing.**

The `/route` skill is the user-facing dispatcher: pass a task description and route picks the right skill+function. The `skill-builder route` subcommand maintains it.

### Why dispatch enforcement exists (read this once)

Earlier versions of `/route` defined dispatch as prose: Step 4 said "invoke the chosen skill with the Skill tool." That is soft guidance. On 2026-05-09 a real workflow announced `→ Routing to /nsayka-wawa debug label …` and then executed the dispatched skill's procedure manually with raw Edit/Bash calls. The announcement was emitted; the Skill tool was never called; the dispatched skill's CHECKPOINT-grade gates (asset-backup, frontend-design review, exit-tests, cascade) silently did not fire.

Two structural fixes prevent recurrence:

1. The `/route` SKILL.md template's Workflow now contains a CHECKPOINT block (Opus 4.7+ literal-execution gate) wrapped in `<!-- ROUTE-DISPATCH-CHECKPOINT START -->` / `<!-- ROUTE-DISPATCH-CHECKPOINT END -->` markers. The CHECKPOINT requires that the announcement and the `Skill(...)` tool call happen in the same response, refuses procedure-bypass, and overrides auto-mode pressure.
2. The Route Consultation embed block (injected into other skills' SKILL.md by `route embed`) carries the same dispatch-enforcement clauses, so a route consultation triggered from inside another skill cannot be answered with raw tool calls instead of a Skill invocation.

Both blocks are wrapped in machine-readable markers so a re-run of `route index` / `route embed` refreshes them idempotently. Old (prose-only) blocks self-correct on the next execute run.

### Modes

| Mode | Risk | Default | Purpose |
|------|------|---------|---------|
| `index` | low (regenerates auto-generated content inside the `/route` skill only) | execute | Scan all skills, regenerate `/route`'s catalog. Bootstraps `/route` if missing. Refreshes the dispatch CHECKPOINT inside `/route`'s SKILL.md when stale. |
| `embed` | high (modifies many skills' SKILL.md files) | display | Insert a Route Consultation Gate (with dispatch enforcement) into other skills' SKILL.md so workflow follow-ups consult `/route` instead of freelancing. |

### Preflight (both modes)

1. Detect dev mode. If invoked as `/skill-builder dev route …` → include `skill-builder` in the iterating skill set. Otherwise exclude `skill-builder`.
2. Always exclude the `/route` skill itself from iteration (it cannot embed in itself, and its index is regenerated separately by `index` mode).
3. The `/route` skill's directory is `.claude/skills/route/`. The embedded SKILL.md template lives at the bottom of this procedure (§ Route Skill Template).

---

## Mode: `index`

Default mode. Regenerates the `/route` skill's catalog from current skill files AND keeps the dispatch CHECKPOINT inside `/route`'s SKILL.md current.

### Step 1: Inventory Skills

1. Glob `.claude/skills/*/SKILL.md` (apply preflight exclusions).
2. For each match, read:
   - YAML frontmatter (`name`, `description`, `allowed-tools`, `paths`, `when_to_use`)
   - First H2 section after frontmatter (often a brief lead) — capture only the first paragraph
   - Any `## Modes`, `## Commands`, `## Quick Commands`, or similar table — extract command/mode rows verbatim
3. Build an in-memory list of catalog rows: `{name, description, modes[], when_to_use, allowed_tools, trigger_phrases[]}`.

**Zero-skill case is valid.** If the glob returns no skills (fresh project, only `skill-builder` exists and is excluded), the catalog is empty — that is NOT a failure. `index` mode still bootstraps `/route` so the dispatcher exists when the first user skill is created; the catalog file is written with an explicit "no skills installed yet" notice (see Step 3). Only `embed` mode skips when there are no candidates (nothing to embed into).

**Trigger-phrase derivation.** Trigger phrases are short keywords that map a freeform task to this skill. Extract them from:
- The skill's `description` (split on punctuation, take noun phrases)
- The skill's `when_to_use` field if present
- The first lead paragraph

Keep at most 8 trigger phrases per skill. Lowercase them. De-duplicate.

### Step 2: Detect Whether `/route` Exists and Read Prior Index

```
.claude/skills/route/SKILL.md
.claude/skills/route/references/index.md
```

- **SKILL.md exists** → leave hand-written content alone, but the auto-managed dispatch CHECKPOINT block (between `<!-- ROUTE-DISPATCH-CHECKPOINT START -->` and `<!-- ROUTE-DISPATCH-CHECKPOINT END -->` markers) is reconciled in Step 2d below. Content outside those markers is never auto-modified.
- **SKILL.md missing** → bootstrap. Create `.claude/skills/route/SKILL.md` from § Route Skill Template (which already contains the canonical CHECKPOINT block). Mark in the report.
- **index.md exists** → read it; parse out the prior catalog rows. Hold them as `prior_index`.
- **index.md missing** → `prior_index = empty`.

`prior_index` is used in Step 4 to compute a diff against the freshly-built catalog so the report can surface what changed since the last run.

### Step 2b: Reconcile With Prior Run

Diff the freshly-built catalog (Step 1) against `prior_index` (Step 2):

| Prior | Current | Action |
|-------|---------|--------|
| absent | present | **NEW** — skill added since last run |
| present | absent | **REMOVED** — skill no longer installed; drop from index |
| present (different description/modes/triggers) | present | **UPDATED** — refresh catalog row |
| present (identical) | present | **UNCHANGED** |

This diff feeds Step 4's display-mode output and Step 5's execute-mode summary so a repeat run is informative even when nothing has changed structurally. `index.md` is always rewritten in execute mode (it is auto-generated content); the diff is reporting, not gating.

If `prior_index` is empty (first run), every current row is **NEW** and there are no REMOVED rows.

### Step 2d: Reconcile Dispatch CHECKPOINT in `/route` SKILL.md

Only fires when `/route` SKILL.md exists (bootstrap case writes the canonical block from § Route Skill Template, so no reconciliation is needed for fresh bootstraps).

The dispatch CHECKPOINT inside `/route`'s SKILL.md is auto-managed content. The canonical text is § Canonical Dispatch CHECKPOINT below. Reconcile:

1. **Scan.** Read `.claude/skills/route/SKILL.md`. Search for `<!-- ROUTE-DISPATCH-CHECKPOINT START -->` and `<!-- ROUTE-DISPATCH-CHECKPOINT END -->`.
2. **Compute action:**

   | On-disk state | Canonical state | Action |
   |---------------|----------------|--------|
   | both markers present, content matches canonical byte-for-byte | matches | **NOOP** |
   | both markers present, content differs | matches | **REFRESH** — overwrite block in place |
   | markers missing entirely (legacy or hand-edited /route) | — | **INSERT** — add block at end of `## Workflow` section (or end of file if no Workflow heading) |
   | only one marker present (tampering / partial edit) | — | **REPORT** and SKIP — surface the malformed file to the user, do not auto-repair |

3. **Hand-edit warning.** Hand edits to the auto-generated block are NOT preserved; the START/END markers carry a `safe to replace` notice. The user can opt out by running `/skill-builder route embed --remove route` — but `route` itself is never an embed target, so the practical opt-out is to delete `.claude/skills/route/` and not regenerate.

This keeps existing `/route` installations enforceable without forcing users to delete and re-bootstrap when the canonical CHECKPOINT changes.

### Step 3: Generate the Index File Content

Write `.claude/skills/route/references/index.md` with this layout:

```markdown
# Route Index

<!-- AUTO-GENERATED by /skill-builder route index. Do not hand-edit. -->
<!-- Generated: YYYY-MM-DD -->

## Skill Catalog

| Skill | Description | Modes / Commands | Triggers |
|-------|-------------|------------------|----------|
| /skill-name | [description from frontmatter] | mode1, mode2, mode3 | trigger, words, here |
| ... | ... | ... | ... |

## Per-Skill Detail

### /skill-name
- **Description:** [verbatim from frontmatter]
- **When to use:** [from `when_to_use` field or lead paragraph]
- **Modes / commands:**
  - `mode1` — [mode description from skill's mode table]
  - `mode2` — [mode description]
- **Triggers:** trigger, words, here
- **Path:** .claude/skills/skill-name/SKILL.md

### /next-skill
...
```

**Rules:**
- Quote descriptions verbatim from frontmatter — do NOT summarize.
- The "Modes / Commands" column lists the keys from the skill's mode table, comma-separated. The "Per-Skill Detail" section repeats them with each row's description.
- Sort skills alphabetically.
- If a skill has no modes, list `—` in the Modes column and omit the modes block from the per-skill detail.

**Empty-catalog template.** If the inventory in Step 1 returned zero skills, write `references/index.md` with this exact content instead of the table-bearing layout above:

```markdown
# Route Index

<!-- AUTO-GENERATED by /skill-builder route index. Do not hand-edit. -->
<!-- Generated: YYYY-MM-DD -->

## Skill Catalog

_No skills installed yet._

`/route` was bootstrapped early so it is ready as soon as you create your first skill. After running `/skill-builder new <name>` (or any other command that produces a skill), re-run `/skill-builder route index` to populate this catalog.

## Per-Skill Detail

_(none — catalog is empty)_
```

In this state, `/route` invocations have nothing to dispatch to. The CHECKPOINT in `/route`'s SKILL.md (Step 7 "no catalog row plausibly fits") already covers the no-match case and reports it cleanly to the user.

### Step 4: Display Mode Output

If invoked WITHOUT `--execute` (or with `--dry-run`), do NOT write files. Print:

```
Route index — display mode

Skills detected: N
- Bootstrap needed: [yes/no — does /route SKILL.md exist?]
- Catalog rows: N
- Dispatch CHECKPOINT in /route SKILL.md: [bootstrap / NOOP / REFRESH / INSERT / REPORT-malformed]

Diff vs. prior index:
- NEW: [comma-separated skill names, or "none"]
- REMOVED: [comma-separated skill names, or "none"]
- UPDATED: [comma-separated skill names with one-word reason: desc/modes/triggers, or "none"]
- UNCHANGED: [count]

Use `/skill-builder route index --execute` to write the index.
```

### Step 5: Execute Mode

If invoked WITH `--execute` (default for `index` since it is low-risk):

1. If bootstrap needed, write `.claude/skills/route/SKILL.md` from § Route Skill Template (the template already contains the canonical CHECKPOINT block).
2. Else, apply the dispatch-CHECKPOINT action computed in Step 2d:
   - **NOOP** → no SKILL.md edit.
   - **REFRESH** → replace content between the START/END markers with § Canonical Dispatch CHECKPOINT. Do not touch any other content.
   - **INSERT** → append the canonical block (markers and all) at the end of the `## Workflow` section, or at end of file if no Workflow heading exists. Preserve any hand-written content in the rest of the file.
   - **REPORT** (malformed markers) → skip the SKILL.md edit; surface the malformed file in the report so the user can resolve.
3. Write `.claude/skills/route/references/index.md` with the generated catalog. The file is always overwritten — it is auto-generated content.
4. Report:

```
Route index regenerated.
- /route skill: [created / refreshed / unchanged]
- /route dispatch CHECKPOINT: [bootstrap / NOOP / REFRESH / INSERT / REPORT-malformed]
- Skills cataloged: N
- Diff vs. prior index:
  - NEW: [list or "none"]
  - REMOVED: [list or "none"]
  - UPDATED: [list with reason, or "none"]
- Index path: .claude/skills/route/references/index.md
```

### Step 6: Post-Generation Verification

After writing, verify:
- `/route` SKILL.md frontmatter is valid (re-read and parse it)
- The `<!-- ROUTE-DISPATCH-CHECKPOINT START -->` marker is present exactly once and is paired with exactly one END marker
- The text between the markers matches § Canonical Dispatch CHECKPOINT byte-for-byte (after a NOOP, REFRESH, INSERT, or fresh bootstrap)
- `references/index.md` is non-empty (must contain the header and either at least one catalog row OR the empty-catalog notice from Step 3). A genuinely empty file is a failure; a file containing the empty-catalog template is valid.
- If checks fail, report the failure and leave the user to fix manually. Do NOT silently retry.

---

## Canonical Dispatch CHECKPOINT

This is the auto-managed block that lives inside `/route`'s SKILL.md `## Workflow` section. The bootstrap template embeds it; Step 2d/Step 5 refresh it; Step 6 verifies it. Use this exact text byte-for-byte when writing or comparing:

```markdown
<!-- ROUTE-DISPATCH-CHECKPOINT START — auto-generated by /skill-builder route index; safe to replace -->
<!-- ENFORCEMENT ANNOTATION — Opus 4.7+ literal-execution gate -->
<!-- Source: /route dispatch contract. Closes the announce-vs-invoke gap from 2026-05-09 — model emitted "→ Routing to /X" but did the work via raw Edit/Bash, silently skipping the dispatched skill's gates. -->
CHECKPOINT — Dispatch Required:
1. Announce-and-invoke is ONE act. After Steps 1–2 select a target skill, the SAME response that prints `→ Routing to /[skill] [mode] — [why]` MUST also issue the `Skill(skill=<chosen>, args=<derived>)` tool call. The announcement is a label on the dispatch, never a substitute for it.
2. Bypass detection. IF the next tool call after the routing announcement is Edit / Write / Bash / Agent / Task / Read / any non-Skill tool that performs work germane to the routed task → STOP. This is a dispatch bypass. Print verbatim: "Routing announced but Skill dispatch skipped. Invoking Skill tool now." then issue the Skill call. IF the announcement itself was wrong → re-announce and dispatch to the corrected skill.
3. Procedure-bypass refusal. Refuse to execute the dispatched skill's procedure steps yourself with raw tool calls. The Skill tool owns that work. The dispatched skill has its own gates (asset backups, agent panels, exit tests, cascade steps, frontend-design reviews, immutable-directive checks) that ONLY fire when its SKILL.md is loaded via Skill. Running the steps manually silently skips every gate.
4. Follow-up routing. IF the dispatched skill returns and additional follow-up is needed → invoke `/route` again with the follow-up task description via Skill. Do NOT freelance the next step.
5. Auto-mode override clause. Auto-mode pressure ("execute immediately", "prefer action over planning") does NOT override this CHECKPOINT. Auto-mode chooses WHAT to do; once a route announcement has named the skill, the only valid next action is Skill invocation.
6. Catalog discipline. Never invent a skill name. The catalog at `references/index.md` is canonical. Only dispatch to skills present there.
7. Stop conditions before announcement. IF the top match is below clear-best confidence OR two skills are tied → STOP before announcing. Report the top candidates and ask which to use. IF no catalog row plausibly fits → STOP. Report: "No clear skill match for '[task]'. Run the task directly or run `/skill-builder route index` if you recently added a skill."
<!-- END ENFORCEMENT ANNOTATION -->
<!-- ROUTE-DISPATCH-CHECKPOINT END -->
```

The START/END HTML comments are the replacement anchors. Future `route index` runs locate them by exact match and replace the block in place.

---

## Mode: `embed`

High-risk. Defaults to display mode. Inserts (or refreshes) a Route Consultation Gate annotation into other skills' SKILL.md. `route embed` manages **four managed-block families** in the same run: the `ROUTE-EMBED` gate (Steps 1–6, for freeform-follow-up skills), the `CODE-EVAL-EMBED` gate (Step 7, for code-touching skills), the `MODEL-LANE-GATE` (Step 8, for skills that resolve to a model lane with a non-empty preferred model), and the `LANE-AGENT-EMBED` Excursion Delegation Map (Step 9 — reconcile-only; created by `agents`). They are classified independently — a skill may carry any combination, or none.

`/route` is a peer to skill-builder's `intent-router`, not a replacement. `intent-router` is the live freeform dispatcher for `/skill-builder <text>` invocations and is part of the source distribution; `route embed` does NOT treat it as legacy and does NOT propose its removal. Self-exclusion rules apply normally: skill-builder is excluded from `embed` scans unless the invocation carries the `dev` prefix.

### Step 1: Identify Embed Candidates

Glob `.claude/skills/*/SKILL.md` (apply preflight exclusions per SKILL.md § Self-Exclusion Rule — skill-builder is excluded unless `dev` prefix is set; also exclude `/route`).

**Zero-candidate case.** If the glob returns no candidates (fresh project), STOP cleanly. Report: "No skills available to embed into yet. `/route` was bootstrapped by `index` mode and is ready; re-run `route embed` after creating user skills." This is NOT a failure — `embed` operates on existing skills, so an empty target set is correctly a no-op.

For each candidate, classify:

- **Always-embed:** skills whose workflows include freeform follow-ups. Heuristic — at least one of:
  - Workflow contains the words `research`, `search`, `look up`, `lookup`, `investigate`, `follow-up`, `additional task`, `unblock`, `web search`
  - Workflow has steps that do not name a specific tool or skill ("verify the claim", "find more info", "if needed, …")
  - Skill description mentions `routing`, `dispatch`, `orchestrate` (these benefit from /route awareness)

- **Skip:** skills that are pure transforms/validators with no follow-up potential:
  - Pure CRUD or validation skills with explicit, fully-named tool calls in every step
  - Skills whose workflow is one or two deterministic steps

If classification is ambiguous (skill matches some always-embed signals but is mostly deterministic), defer to the agent panel in Step 1b.

### Step 1b: Agent panel — embed targeting (mandatory when ambiguous)

Per SKILL.md § Non-Obvious Decision Gate, embed targeting requires independent input when the heuristics are split. Trigger conditions (any one):
- ≥1 candidate matched some always-embed signals AND some skip signals
- The user passed `--deliberate`
- Strictness is `thorough` for one or more candidates

When triggered, spawn 3 individual agents in parallel via Task tool (`subagent_type: "general-purpose"`):

- **Agent 1** (persona: Workflow integrity inspector — reviews skills for steps that silently leak into freelancing). Read each ambiguous skill's SKILL.md. Identify steps where the AI would currently improvise a tool call instead of consulting a registered skill. Recommend EMBED or SKIP per skill with one-sentence reasoning.
- **Agent 2** (persona: Minimalist librarian — defends against annotation bloat in already-tight SKILL.md files). Review the candidate list. Recommend SKIP for any skill where a route consultation gate would add noise without changing observable behavior. EMBED only when the gate prevents a real freelancing risk.
- **Agent 3** (persona: Cross-skill mediator — checks whether the embed would conflict with existing in-skill grounding or with another skill's directives). For each ambiguous candidate, check whether the proposed gate contradicts an existing directive. Flag conflicts.

Synthesize:
- EMBED if Agents 1 AND 2 agree on EMBED AND Agent 3 reports no conflict
- SKIP otherwise (safe default)

### Step 1c: Reconcile With Prior Runs

Before generating any new block, compare the current candidate set against the existing state on disk. The embed routine MUST be idempotent and self-correcting:

1. **Scan existing embeds.** Glob `.claude/skills/*/SKILL.md` for the `<!-- ROUTE-EMBED START -->` marker. Build the set `prior_embedded = {skill names that currently have a route-embed block}`.
2. **Compute the action per skill** by intersecting `prior_embedded` with the new classification from Step 1 (and Step 1b synthesis if it ran):

   | Prior state | New classification | Action |
   |-------------|-------------------|--------|
   | not embedded | EMBED | **NEW** — insert a fresh block |
   | embedded | EMBED | **REFRESH** — replace block in place (only if the canonical block text below differs from what's on disk; otherwise NOOP) |
   | embedded | SKIP | **REMOVE** — the skill no longer needs the gate (workflow simplified, follow-up steps removed). Strip the block. |
   | not embedded | SKIP | **NOOP** |

3. **Detect drift.** For REFRESH candidates, diff the on-disk block against the canonical block (§ Step 2). If they match byte-for-byte → NOOP. If they differ (canonical updated, or someone hand-edited) → REFRESH overwrites with the canonical text. Hand edits to the auto-generated block are NOT preserved; the START/END markers warn against editing.
4. **Detect tampering.** If a START marker is found without a matching END marker (or vice versa), report it and SKIP that skill. Do not attempt repair — surface the malformed file to the user.

This reconciliation is what makes repeat runs intelligent: skills get added or dropped from the embed set automatically as their workflows evolve, and stale blocks self-correct on the next `route embed --execute`. When the canonical block in this procedure file is updated (e.g., to add new dispatch-enforcement clauses), every existing embed REFRESHes on the next run — propagation is automatic.

### Step 2: Generate the Embed Block

The block is auto-generated and machine-replaceable. Use these markers verbatim so subsequent re-runs can find and replace cleanly:

```markdown
<!-- ROUTE-EMBED START — auto-generated by /skill-builder route embed; safe to replace -->
<!-- origin: skill-builder | modifiable: true -->
## Route Consultation

<!-- ENFORCEMENT ANNOTATION — Opus 4.7+ literal-execution gate -->
<!-- Source: /skill-builder route embed. Closes the dispatch-bypass gap: a /route announcement is not a substitute for a Skill tool call, and consulting /route does not license the caller to execute the target skill's procedure manually. -->
CHECKPOINT — Skill Routing Gate:
1. During this skill's workflow, IF a step requires research, web search, lookup, analysis, or any follow-up NOT already covered by an explicit tool or skill name → STOP before improvising.
2. Already-named exception. IF the current workflow step EXPLICITLY names tools or skills (e.g., "use Read", "spawn the X agent", "invoke /[skill]") → execute as written. Do NOT consult `/route` for steps already determined. Skip to your skill's next step.
3. Otherwise → invoke `/route <task description>` via the Skill tool. `/route` reads its index and either returns a target skill or reports "no match."
4. Dispatch Required. IF `/route` returns a target → the IMMEDIATE next tool call MUST be `Skill(skill=<target>, args=<derived>)`. Do NOT execute the target skill's procedure steps yourself with raw Edit / Write / Bash / Task / Agent / Read calls. The target skill's gates (asset backups, agent panels, exit tests, cascade steps, frontend-design reviews, immutable-directive checks) ONLY fire when its SKILL.md is loaded via Skill — running steps manually silently skips every gate.
5. Bypass detection. IF a Skill dispatch was just announced (yours or `/route`'s) and the next tool call is non-Skill work germane to the routed task → STOP. Print verbatim: "Route dispatch announced but Skill call skipped. Invoking Skill tool now." then issue the Skill call.
6. No-match path. IF `/route` returns "no match" → proceed with the most direct, manual approach. Document the gap; the user may want to register a skill.
7. Follow-ups loop back. After the dispatched skill returns, IF further follow-up is needed → consult `/route` again via Skill. Do not freelance the next step.
8. Auto-mode override clause. Auto-mode ("execute immediately", "prefer action over planning") does NOT override clauses 4–5. Auto-mode chooses WHAT to do; once a routing decision is on the table, the only valid next action is Skill invocation.
<!-- END ENFORCEMENT ANNOTATION -->
<!-- /origin -->
<!-- ROUTE-EMBED END -->
```

The START/END HTML comments are the replacement anchors. Future `route embed` runs locate them by exact match and replace the block in place. They are not user-modifiable; if a user wants to disable the gate, they must run `/skill-builder route embed --remove [skill]` (see § Step 4b).

### Step 3: Insertion Point

Read the target SKILL.md and locate the insertion point per the action computed in Step 1c:

1. **NEW** → insert the block at the end of SKILL.md, separated from preceding content by a `---` horizontal rule and a blank line.
2. **REFRESH** → replace the entire block (between the existing START and END markers) with the freshly generated block. Do NOT alter any content outside the markers, including the surrounding `---` rule.
3. **REMOVE** → delete the START marker, the END marker, all content between them, and the immediately preceding `---` rule (only if that rule was followed by the START marker on the very next non-blank line, indicating the rule was inserted by `route embed`). Leave any other surrounding content untouched.
4. **NOOP** → no file modification.

Do NOT insert inside `<!-- origin: user | immutable: true -->` blocks. Do NOT alter any user directives. The START/END markers and the `origin: skill-builder | modifiable: true` flag inside the block confirm that the insert is mutable, machine-generated content.

### Step 4: Display Mode Output

For each candidate, print:

```
/[skill-name] — [NEW / REFRESH / REMOVE / NOOP]
  Reason: [from heuristics, reconciliation table, or agent synthesis]
  Insertion: [end-of-file / replace-existing-marker / strip-existing-block / —]
```

Aggregate report:

```
Route embed plan:
  Total candidates: N
  NEW: X (skills gaining a route gate)
  REFRESH: Y (existing block updated to canonical text)
  REMOVE: Z (skill no longer needs a gate; strip block)
  NOOP: W (already canonical or correctly absent)

Use `/skill-builder route embed --execute` to apply.
```

### Step 4b: Manual Remove Mode

`/skill-builder route embed --remove [skill]` removes the embed block from a single named skill, regardless of classification. It strips ALL managed-block families present — `ROUTE-EMBED`, `CODE-EVAL-EMBED`, `MODEL-LANE-GATE`, and `LANE-AGENT-EMBED`. Use when a user wants to opt a skill out even though heuristics say EMBED. Display by default; add `--execute` to apply.

If `[skill]` is omitted, list all skills currently containing any managed embed block and ask which to remove via AskUserQuestion.

### Step 5: Execute Mode

For each NEW, REFRESH, or REMOVE target (NOOP is silent):

1. Read the skill's SKILL.md.
2. Apply the change per Step 3.
3. Re-read the file and verify:
   - For NEW or REFRESH: the route embed block is present exactly once and matches the canonical text byte-for-byte.
   - For REMOVE: no `<!-- ROUTE-EMBED START -->` or `<!-- ROUTE-EMBED END -->` markers remain.
   - No user directive (`<!-- origin: user | immutable: true -->`) blocks were modified.
   - Frontmatter is intact and parses.
4. If verification fails, restore the file from the pre-edit content and report the failure. Do not move on to the next skill silently.

After all targets are processed, report:

```
Route embed applied.
- Skills modified: N
  - NEW: X
  - REFRESH: Y
  - REMOVE: Z
- NOOP (already canonical): W
- Failures: E (rolled back)
```

### Step 6: Post-Embed Index Refresh

After a successful `route embed --execute`, automatically run `route index --execute` to refresh the catalog (skill descriptions or modes may have changed indirectly) AND to refresh the dispatch CHECKPOINT in `/route`'s SKILL.md if its canonical text drifted. Report this as part of the same operation.

---

## Step 7: Code-Eval Gate (the `CODE-EVAL-EMBED` family — parallel to ROUTE-EMBED)

`route embed` manages **two independent managed-block families**. The `ROUTE-EMBED` block (Steps 1–6) goes into skills with freeform-follow-up potential. The `CODE-EVAL-EMBED` block defined here goes into skills that **write, edit, or debug code**, wiring in the `code-evaluator` skill's two thin pointers (pre-write advisor + post-write review). The two families are reconciled in the same `route embed` run but classified independently — a skill may carry one, both, or neither. This gate is a no-op unless the `code-evaluator` skill is installed (audit installs it automatically; see [audit.md](audit.md) § Step 4a-bis).

### Step 7a: Classify code-touching skills (authored heuristic)

Glob `.claude/skills/*/SKILL.md` (apply Self-Exclusion: skill-builder excluded unless `dev`; also exclude `/route` AND `code-evaluator` itself — a skill must not gate-consult itself). For each candidate, classify **CODE-TOUCHING** vs **NOT**:

- **CODE-TOUCHING** — at least one of:
  - `allowed-tools` includes `Edit`, `Write`, or `NotebookEdit` AND the workflow produces or modifies source files (not prose/content/config-only).
  - Name tokens (lowercased): `code`, `dev`, `build`, `run`, `debug`, `fix`, `refactor`, `simplify`, `implement`, `migrate`, `test`, `lint`, `compile`, `review`, `verify`, `init`.
  - Description/workflow verbs: `write code`, `implement`, `edit`/`modify`/`refactor` *code*, `debug`, `build a (component|feature|function|module)`, `fix the bug`, `compile`, `run the (app|tests)`, `frontend`/`component`/`API` implementation.
- **NOT code-touching** (SKIP) — content/creative skills (writing, voice, image, newsletter, present, edit-prose), pure validators/scanners with no source mutation, and skills whose only file writes target docs/data/config.

Lane cross-check: a skill that declares `lane: creative` (see [../model-lanes.md](../model-lanes.md)) is presumed NOT code-touching unless it also clearly mutates source; `lane: coding` reinforces CODE-TOUCHING. The lane is a tiebreaker, never the sole signal.

### Step 7b: Agent panel — ambiguous code-touching classification (mandatory when split)

Per SKILL.md § Non-Obvious Decision Gate, when a candidate matches some CODE-TOUCHING signals AND some SKIP signals (e.g. `frontend-design` emits code but is creatively-led), spawn a classification agent via Task tool (`subagent_type: "general-purpose"`, persona: **Build-vs-craft arbiter** — distinguishes skills that *engineer* code from skills that *compose* artifacts that happen to be code). It reads the ambiguous SKILL.md and recommends CODE-TOUCHING or SKIP with one-sentence reasoning. Default to SKIP on a tie (a missed gate is cheaper than annotation bloat in a creative skill).

### Step 7c: Reconcile (same NEW/REFRESH/REMOVE/NOOP logic)

Scan for the `<!-- CODE-EVAL-EMBED START -->` marker to build `prior_code_embedded`. Intersect with the Step 7a classification exactly as Step 1c does for ROUTE-EMBED (NEW / REFRESH / REMOVE / NOOP), with byte-for-byte drift detection and the same tampering guard. The two families never interfere — reconcile each against its own marker set.

### Step 7d: The CODE-EVAL-EMBED block (verbatim)

```markdown
<!-- CODE-EVAL-EMBED START — auto-generated by /skill-builder route embed; safe to replace -->
<!-- origin: skill-builder | modifiable: true -->
## Code Evaluation

<!-- ENFORCEMENT ANNOTATION — Opus 4.7+ literal-execution gate -->
<!-- Source: /skill-builder route embed (code-eval gate). Wires the code-evaluator skill's pre-write advisor and post-write review into this code-touching skill. Thin pointers only; the logic lives in /code-evaluator. -->
CHECKPOINT — Code Evaluation Gate (fires only while this skill writes/edits/debugs code):
1. PRE-WRITE. Before committing to a NON-OBVIOUS code approach (new abstraction, new helper, a structure with plausible alternatives), spawn the `code-design-advisor` agent (defined in the code-evaluator skill) via the Task tool. It checks — read-only — whether the thing already exists, whether the approach will rot, and whether it fits the surrounding idiom. Fold its recommendations into how you write. Skip for trivial/mechanical edits.
2. POST-WRITE. After writing or editing code, BEFORE declaring the code task done, invoke `/code-evaluator review <changed paths>` via the Skill tool. It evaluates the diff for dead code, duplication, and complexity, tiers the findings, and applies only HIGH-confidence, guard-cleared fixes.
3. SAFETY. Never let a grep-based "unused" verdict authorize a deletion: only HIGH-confidence, guard-cleared dead code is auto-fixed, through the build + full-test safety cycle. Duplication and complexity are reported for human decision.
4. NO-EVALUATOR PATH. IF the `code-evaluator` skill is not installed → skip this gate silently and proceed; do not block. (Run `/skill-builder code-eval create` to install it.)
<!-- END ENFORCEMENT ANNOTATION -->
<!-- /origin -->
<!-- CODE-EVAL-EMBED END -->
```

Insertion / removal follows Step 3's rules, anchored on the `CODE-EVAL-EMBED` markers. `route embed --remove [skill]` strips ALL managed-block families (ROUTE-EMBED, CODE-EVAL-EMBED, MODEL-LANE-GATE — see Step 8 — and LANE-AGENT-EMBED — see Step 9) from the named skill. `route index` lists `code-evaluator`'s `review` and `sweep` commands in the catalog like any other skill (no special handling needed — it is a normal installed skill).

---

## Step 8: Model-Lane Gate (the `MODEL-LANE-GATE` family — parallel to CODE-EVAL-EMBED)

`route embed` manages a **third independent managed-block family**. The `ROUTE-EMBED` block (Steps 1–6) goes into freeform-follow-up skills; the `CODE-EVAL-EMBED` block (Step 7) goes into code-touching skills; the `MODEL-LANE-GATE` block defined here goes into skills that **resolve to a model lane with a non-empty preferred model**, wiring in an invocation-time preflight that prompts the user to `/model`-switch when the active session model does not match the skill's lane. All four families (including `LANE-AGENT-EMBED`, Step 9) are reconciled in the same `route embed` run but classified independently — a skill may carry any combination, or none.

**Primary-lane scope (2026-06-06).** This gate governs the skill's **PRIMARY lane only** — cross-lane mid-workflow steps are handled by lane-pinned excursion delegation (Step 9 and [../lane-delegation.md](../lane-delegation.md)), never by re-prompting this gate mid-workflow.

**Why this gate exists (the gap it closes).** The model-lane directive (SKILL.md § Directives, 2026-06-01) asked for model-switch management that is "fluid… with prompting, or not." Audit Step 4f built only the *audit-time* half: it flags lane/model mismatches when the user explicitly runs `audit`. There was no check at **skill-invocation time** — so invoking a `creative`-lane skill while the session is on the `coding` model drafted content on the wrong model with no prompt. This gate is the invocation-time half: it fires at the TOP of a lane-declared skill's own workflow, before any generative step. Like Step 4f and the `update` command's permission-mode prompt, **the gate cannot switch the model itself — it only prompts the user to run `/model`.**

**Unconfigured → no embeds (correct).** This family depends entirely on `references/model-lanes.md`. IF that file is absent, OR the Skill→Lane table has no active (non-commented) rows AND no skill self-declares a `lane:` frontmatter key, OR every resolved lane's Preferred Model cell is empty → there are **zero candidates** and the family embeds nothing. An empty Skill→Lane table is a clean no-op, never an error (acceptance criterion).

### Step 8a: Classify lane-declared skills (concrete lookup — no agent)

Glob `.claude/skills/*/SKILL.md` (apply Self-Exclusion: skill-builder excluded unless `dev`; also exclude `/route`). Read `references/model-lanes.md` once and parse the Lane→Preferred Model table and the Skill→Lane table. For each candidate, classify **LANE-DECLARED** vs **NO-LANE**:

1. Resolve the skill's lane from a **DECLARED source only**: the skill's own `lane:` frontmatter key → the Skill→Lane table → **NO LANE**. A skill with no declared lane is **NO-LANE** — never auto-classified into a lane (this mirrors model-lanes.md's "lane assignment is declared, never inferred" principle; the advisory lane *suggestion* in model-lanes.md § Advisory Lane Suggestion is suggest-only and MUST NOT drive an embed).
2. IF a lane resolves, look up its Preferred Model. IF the cell is empty/absent → treat as **NO-LANE** for embed purposes (flagging disabled by an empty cell, per the "absence vs. gap" rule).
3. A candidate is **LANE-DECLARED** only when steps 1–2 yield a declared lane with a non-empty Preferred Model.

This is a deterministic read of declared frontmatter/table cells — **no judgment, so no agent panel** (per SKILL.md § Non-Obvious Decision Gate, a decision that matches a concrete, measurable criterion — `lane:` field present / table row present / cell non-empty — continues without an agent). Unlike Steps 1b and 7b, there is no ambiguous middle to adjudicate: a lane is either declared or it is not.

### Step 8b: Reconcile (same NEW/REFRESH/REMOVE/NOOP logic)

Scan `.claude/skills/*/SKILL.md` for the `<!-- MODEL-LANE-GATE START -->` marker to build `prior_lane_embedded`. Intersect with the Step 8a classification exactly as Step 1c does for ROUTE-EMBED:

| Prior state | New classification | Action |
|-------------|-------------------|--------|
| not embedded | LANE-DECLARED | **NEW** — insert a fresh block at top of workflow (Step 8d) |
| embedded | LANE-DECLARED | **REFRESH** — replace block in place only if it differs byte-for-byte from the canonical block (Step 8c); else **NOOP** |
| embedded | NO-LANE | **REMOVE** — the skill left its lane (table row deleted, `lane:` key removed, or its lane's preferred-model cell blanked). Strip the block. |
| not embedded | NO-LANE | **NOOP** |

Use the same byte-for-byte drift detection and the same tampering guard (a START marker without a matching END, or vice versa → report and SKIP that skill; do not auto-repair). The four families never interfere — reconcile each against its own marker set. **REMOVE is the acceptance-criterion behavior**: a skill that leaves a lane loses its gate on the next `route embed --execute`, idempotently.

### Step 8c: The MODEL-LANE-GATE block (verbatim)

```markdown
<!-- MODEL-LANE-GATE START — auto-generated by /skill-builder route embed; safe to replace -->
<!-- origin: skill-builder | modifiable: true -->
## Model-Lane Preflight

<!-- ENFORCEMENT ANNOTATION — Opus 4.7+ literal-execution gate -->
<!-- Source: /skill-builder route embed (model-lane gate). Closes the invocation-time half of the 2026-06-01 model-lane directive — audit Step 4f only checks at audit time, so a lane-declared skill invoked on the wrong model would do generative work with no prompt. This fires at THIS skill's invocation, before any generative step. The gate CANNOT switch the model; it only prompts the user to run /model. -->
CHECKPOINT — Model-Lane Preflight Gate (fires at the TOP of this skill's workflow, before any generative step):
1. Resolve this skill's lane: this skill's own `lane:` frontmatter key → the Skill→Lane table in `.claude/skills/skill-builder/references/model-lanes.md` → NO LANE. IF no lane resolves → silent no-op; skip this gate and proceed.
2. Look up the lane's Preferred Model in that file's Lane→Preferred Model table. IF the cell is empty or absent → silent no-op; skip this gate and proceed (an undeclared preference is correctly absent, not a gap).
3. Suppression ("or not"). Skip this gate silently IF ANY of: this skill's frontmatter sets `model-lane-gate: off`; the session is headless / non-interactive (a prompt would block or loop because the model never changes between re-invocations); OR the user already chose "skip once" or "continue anyway" for this skill earlier in THIS session.
4. Detect ACTIVE_MODEL: read the session system-context line "The exact model ID is …", strip any bracketed context-window suffix (`[1m]`, `[200k]`), lowercase, and keep the `claude-<family>-<major>-<minor>` shape verbatim — exactly as model-lanes.md § Active-Model Detection specifies. No env var, no Bash probe (there is nothing on disk to read; a shell call would only fail or fabricate).
5. Stale-ID self-check. IF the Preferred Model is not of `claude-<family>-<major>-<minor>` shape, or names a family the active model has clearly superseded → do NOT prompt to switch. Emit a one-line advisory instead: "Model-lane mapping for this skill may be stale — review .claude/skills/skill-builder/references/model-lanes.md." Then proceed. Never validate against a hardcoded "known-live" list — it rots.
6. Compare. IF `preferred_model == ACTIVE_MODEL` → silent no-op; proceed. IF `preferred_model != ACTIVE_MODEL` → STOP before any generative step and prompt (clause 7).
7. Prompt, never switch. A skill CANNOT change the session model. In an interactive session, ask via AskUserQuestion (fall back to plain text if AskUserQuestion is unavailable): "This skill is in the `<lane>` lane (preferred model `<preferred>`), but the active model is `<active>`. Run `/model` to switch before generative work?" Offer EXACTLY three options — **switched** (you ran /model; re-read and continue), **skip once** (proceed this once on the current model), **continue anyway** (proceed and don't ask again for this skill this session).
8. After acknowledgement: IF "switched" → re-read the system-context model line EXACTLY ONCE to confirm; if it now matches, proceed; if it still mismatches, say so once and proceed without looping. IF "skip once" or "continue anyway" → record the session opt-out per clause 3 and proceed. Never loop or re-prompt beyond that single re-read.
9. Primary-lane scope. This gate fires ONCE, for this skill's PRIMARY lane. Mid-workflow steps that belong to the OTHER lane do NOT re-trigger this prompt — they are delegated to lane-pinned subagents via this skill's LANE-AGENT-EMBED Delegation Map, when present (see .claude/skills/skill-builder/references/lane-delegation.md). Delegation is never a substitute for THIS gate: coding/analysis primary work must run on the coding main model — never a creative main session orchestrating coding-pinned agents to avoid a switch.
<!-- END ENFORCEMENT ANNOTATION -->
<!-- /origin -->
<!-- MODEL-LANE-GATE END -->
```

The START/END HTML comments are the replacement anchors; future `route embed` runs locate them by exact match and replace the block in place. They are not user-modifiable; to disable the gate for a skill, run `/skill-builder route embed --remove [skill]`, or set `model-lane-gate: off` in that skill's frontmatter (clause 3 honors it without removing the block).

### Step 8d: Insertion point (TOP of workflow — differs from Steps 3 and 7)

Unlike ROUTE-EMBED and CODE-EVAL-EMBED (appended at end-of-file), the model-lane gate must run **before any generative step**, so it is inserted at the **top of the skill's workflow**:

1. **NEW** → insert the block immediately after the `## Workflow` heading (before the first workflow step), separated by blank lines. IF the skill has no `## Workflow` heading, insert it after the frontmatter, the H1 title, and any `<!-- origin: user | immutable: true -->` directive blocks, but BEFORE the first procedural `##` section. The gate must precede the first step that could generate content.
2. **REFRESH** → replace the entire block (between the existing START and END markers) in place. Do NOT move it and do NOT alter any content outside the markers.
3. **REMOVE** → delete the START marker, the END marker, and all content between them, plus any blank-line padding that `route embed` added around it. Leave all other content untouched.
4. **NOOP** → no file modification.

**Never insert inside, before, or in a way that reorders an `<!-- origin: user | immutable: true -->` block.** The model-lane directive block and any other immutable user content stay verbatim — this gate is new machinery placed beneath/after them, never woven through them. The START/END markers and the `origin: skill-builder | modifiable: true` flag confirm the insert is mutable, machine-generated content.

Display-mode output, execute-mode verification, and the post-embed index refresh all follow Steps 4–6 with the `MODEL-LANE-GATE` markers substituted for `ROUTE-EMBED`. In the Step 4 aggregate report, add a `MODEL-LANE: A/B/C/D` line alongside the route and code-eval family counts.

---

## Step 9: Lane-Agent Embed (the `LANE-AGENT-EMBED` family — reconciliation only)

`route embed` reconciles a **fourth managed-block family**: the per-skill Excursion Delegation Map defined in [../lane-delegation.md](../lane-delegation.md) § The Delegation Map. Unlike the other three families, **`route embed` never CREATES this family** — placement requires reviewing the skill's full workflow under the Bespoke Excursion-Agent Gate (SKILL.md § Directives, 2026-06-06), which is `/skill-builder agents [skill]`'s job (agents.md § Step 4d). Step 9 only keeps existing blocks honest.

**Unconfigured → no-op (correct).** Same dependency as Step 8: lanes unconfigured, or every preferred-model cell empty → zero candidates, clean no-op.

### Step 9a: Scan

Glob `.claude/skills/*/SKILL.md` (Self-Exclusion applies; exclude `/route`) for `<!-- LANE-AGENT-EMBED START -->` markers to build `prior_excursion_embedded`. One map block per skill.

### Step 9b: Re-render the canonical block

For each embedded skill, read every lane-pinned agent it references (`.claude/skills/[skill]/agents/[name]/AGENT.md`) and re-render the canonical map block from those agents' frontmatter and Context Contracts per lane-delegation.md § The Delegation Map. Byte-compare against the on-disk block.

### Step 9c: Reconcile

| Condition | Action |
|---|---|
| On-disk block == re-render | **NOOP** |
| Differs (lane remapped, agent frontmatter updated, canonical template evolved) | **REFRESH** in place (replace between markers only) |
| Skill left its lane / lanes unconfigured / its lane's preferred-model cell blanked | **REMOVE** the block. The agent files are NOT auto-deleted — report them for deletion (destructive → display-first, explicit task). Never spawn an agent pinned to a model the user removed. |
| A referenced AGENT.md is missing | **REPORT-ORPHAN** — do not auto-strip the entry; recommend `agents [skill] --execute` (recreate) or `route embed --remove [skill]` (strip) |
| An entry's quoted anchor matches the file zero times or more than once | **STALE-ANCHOR** — report; never fuzzy-match. Re-anchoring is a judgment call → agent panel, conservative default "drop the entry, keep the workflow untouched" |
| One marker without its pair | **REPORT + SKIP** (tamper guard, same as Step 1c.4) |

**Uncovered-excursion recommendations:** while scanning, IF a lane-declared skill has cross-lane signals (per lane-delegation.md § Excursion Signal Vocabulary, heuristic pass only — no panel here) with no covering map entry → list "run `/skill-builder agents [skill]`" as a recommendation in the report. Step 9 itself never designs or inserts.

Display-mode output, execute-mode verification, and the post-embed index refresh follow Steps 4–6 with the `LANE-AGENT-EMBED` markers substituted. In the Step 4 aggregate report, add a `LANE-AGENT: refresh/remove/noop/orphan/stale` line alongside the other family counts. `route embed --remove [skill]` strips this family too.

---

## Audit Integration

Audit's task list includes these as the **final two items**, in this order:

1. `route index` — second-to-last task. Refreshes the catalog after any optimize/agents/hooks changes that may have altered descriptions, modes, or skill membership. Also reconciles the dispatch CHECKPOINT in `/route`'s SKILL.md.
2. `route embed` — last task. Surfaces (or refreshes) consultation gates after the catalog is current. Refreshes any out-of-date enforcement clauses in existing embeds. This single task reconciles **all four managed-block families** in one pass — `ROUTE-EMBED`, `CODE-EVAL-EMBED`, `MODEL-LANE-GATE` (Step 8), and `LANE-AGENT-EMBED` (Step 9, reconcile-only) — so the invocation-time model-lane preflight and the excursion delegation maps are wired/refreshed/removed across lane-declared skills as a terminal audit action without adding a separate menu item.

Both are presented in audit's Step 6 execution menu. The user can opt out by deselecting them, but they MUST appear last in the displayed task list. See [audit.md](audit.md) § Step 4g.

---

## Route Skill Template

When `route index --execute` bootstraps the `/route` skill (Step 5 of `index` mode), write this exact content to `.claude/skills/route/SKILL.md`. The CHECKPOINT block embedded in the Workflow section is the canonical dispatch CHECKPOINT (§ Canonical Dispatch CHECKPOINT) — keep it byte-for-byte identical so `route index` Step 2d sees NOOP on the next run.

```markdown
---
name: route
description: "Skill router. Pass a task description; route consults the index and dispatches to the right skill+function via the Skill tool. Usage: /route <task description>"
allowed-tools: Read, Glob, Grep, Task, Skill
minimum-effort-level: high
---

# Route

Glorified index of every installed skill. Pass a task description and route picks the right skill+function and invokes it via the Skill tool. Use `/route` for any follow-up the current workflow does not explicitly name — research, web search, lookup, additional analysis, unblock work — so the AI dispatches through registered skills instead of freelancing.

## Usage

```
/route <task description>
```

The task description is freeform. Examples:

- `/route find recent papers on transformer architecture`
- `/route summarize this URL: https://example.com/article`
- `/route audit the skills in this project`
- `/route deploy to staging`

---

<!-- origin: skill-builder | version: 1.1 | modifiable: true -->
## Workflow

1. **Read the index.** Read [references/index.md](references/index.md) — the auto-generated skill catalog. If the index is missing or empty, STOP and instruct the user: "Index not found. Run `/skill-builder route index` to generate it."
2. **Match.** Compare the task description to the catalog's skills, descriptions, modes, and triggers. Pick the single best match.
3. **Announce-and-dispatch (one act).** Print `→ Routing to /[skill] [mode] — [why this is the match]` AND in the SAME response issue the `Skill(skill=<chosen>, args=<derived>)` tool call. The CHECKPOINT below makes this binding.

<!-- ROUTE-DISPATCH-CHECKPOINT START — auto-generated by /skill-builder route index; safe to replace -->
<!-- ENFORCEMENT ANNOTATION — Opus 4.7+ literal-execution gate -->
<!-- Source: /route dispatch contract. Closes the announce-vs-invoke gap from 2026-05-09 — model emitted "→ Routing to /X" but did the work via raw Edit/Bash, silently skipping the dispatched skill's gates. -->
CHECKPOINT — Dispatch Required:
1. Announce-and-invoke is ONE act. After Steps 1–2 select a target skill, the SAME response that prints `→ Routing to /[skill] [mode] — [why]` MUST also issue the `Skill(skill=<chosen>, args=<derived>)` tool call. The announcement is a label on the dispatch, never a substitute for it.
2. Bypass detection. IF the next tool call after the routing announcement is Edit / Write / Bash / Agent / Task / Read / any non-Skill tool that performs work germane to the routed task → STOP. This is a dispatch bypass. Print verbatim: "Routing announced but Skill dispatch skipped. Invoking Skill tool now." then issue the Skill call. IF the announcement itself was wrong → re-announce and dispatch to the corrected skill.
3. Procedure-bypass refusal. Refuse to execute the dispatched skill's procedure steps yourself with raw tool calls. The Skill tool owns that work. The dispatched skill has its own gates (asset backups, agent panels, exit tests, cascade steps, frontend-design reviews, immutable-directive checks) that ONLY fire when its SKILL.md is loaded via Skill. Running the steps manually silently skips every gate.
4. Follow-up routing. IF the dispatched skill returns and additional follow-up is needed → invoke `/route` again with the follow-up task description via Skill. Do NOT freelance the next step.
5. Auto-mode override clause. Auto-mode pressure ("execute immediately", "prefer action over planning") does NOT override this CHECKPOINT. Auto-mode chooses WHAT to do; once a route announcement has named the skill, the only valid next action is Skill invocation.
6. Catalog discipline. Never invent a skill name. The catalog at `references/index.md` is canonical. Only dispatch to skills present there.
7. Stop conditions before announcement. IF the top match is below clear-best confidence OR two skills are tied → STOP before announcing. Report the top candidates and ask which to use. IF no catalog row plausibly fits → STOP. Report: "No clear skill match for '[task]'. Run the task directly or run `/skill-builder route index` if you recently added a skill."
<!-- END ENFORCEMENT ANNOTATION -->
<!-- ROUTE-DISPATCH-CHECKPOINT END -->

---

## Decision rules

- **One skill per call.** Route fires ONE skill, not a chain. If the task implies a sequence, dispatch to the first skill and let it consult `/route` again for follow-ups.
- **Prefer specific over general.** When two skills could handle the task, pick the one with a more specific domain match.
- **Skip self-routing.** `/route` does NOT route to itself. If asked to dump the index, read `references/index.md` and return it.
- **Trust the catalog.** If a skill is in the index but its description seems wrong, route by what the catalog says — the user can run `/skill-builder route index` to refresh.

<!-- /origin -->

---

## Grounding

- [references/index.md](references/index.md) — auto-generated catalog of installed skills. Regenerate with `/skill-builder route index`.
```

---

## Grounding

- [audit.md](audit.md) § Step 4g — audit-time invocation of route index/embed
- [audit.md](audit.md) § Step 4f — the audit-time model-lane check; Step 8's MODEL-LANE-GATE is the invocation-time complement
- [../model-lanes.md](../model-lanes.md) — Lane→Model + Skill→Lane mapping, Active-Model Detection, and stale-ID self-check that Step 8's gate grounds against
- [../lane-delegation.md](../lane-delegation.md) — the Delegation Map block, Context Contract, anchor rules, and reconciliation contract that Step 9 grounds against
- [skills.md](skills.md) — canonical skill inventory pattern (reused in `index` Step 1)
- [post-action-chain.md](post-action-chain.md) — for the `--execute` chaining pattern referenced in `embed` Step 6
- SKILL.md § Self-Exclusion Rule — `dev` prefix semantics applied in preflight
- SKILL.md § Display/Execute Mode Convention — risk classification per mode
