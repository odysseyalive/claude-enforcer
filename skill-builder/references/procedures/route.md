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

High-risk. Defaults to display mode. Inserts (or refreshes) a Route Consultation Gate annotation into other skills' SKILL.md.

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

`/skill-builder route embed --remove [skill]` removes the embed block from a single named skill, regardless of classification. Use when a user wants to opt a skill out even though heuristics say EMBED. Display by default; add `--execute` to apply.

If `[skill]` is omitted, list all skills currently containing a route embed and ask which to remove via AskUserQuestion.

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

## Audit Integration

Audit's task list includes these as the **final two items**, in this order:

1. `route index` — second-to-last task. Refreshes the catalog after any optimize/agents/hooks changes that may have altered descriptions, modes, or skill membership. Also reconciles the dispatch CHECKPOINT in `/route`'s SKILL.md.
2. `route embed` — last task. Surfaces (or refreshes) consultation gates after the catalog is current. Refreshes any out-of-date enforcement clauses in existing embeds.

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
- [skills.md](skills.md) — canonical skill inventory pattern (reused in `index` Step 1)
- [post-action-chain.md](post-action-chain.md) — for the `--execute` chaining pattern referenced in `embed` Step 6
- SKILL.md § Self-Exclusion Rule — `dev` prefix semantics applied in preflight
- SKILL.md § Display/Execute Mode Convention — risk classification per mode
