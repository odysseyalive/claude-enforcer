# `model-map` Procedure — Standalone Lane→Model Picker
<!-- Enforcement: HIGH — read before running `/skill-builder model-map`. Reuses the canonical picker + fleet-rewrite spec; never restates it. -->

`model-map` lets the user choose the **creative** model and the **coding / everything-else** model
(the 2-brain harness Lane→Model mapping), applies every resulting change, and stops — **without
running a full `audit`**. It is the standalone door to the same machinery audit reaches at
[audit.md](audit.md) § Step 4f step 2-bis. It is a mapping refresh only; it never scans skills,
never assigns skills to lanes, and never switches the session model.

**This procedure reuses canonical specs by pointer — do NOT duplicate them here:**
- The picker (option list, the latest-model discovery ladder) → [lane-delegation.md](../lane-delegation.md) § Lane→Model Picker.
- The fleet rewrite (marker-filtered glob, `model:`-line-only edit, verification re-grep) → [lane-delegation.md](../lane-delegation.md) § Fleet Rewrite on Remap.
- Setup-state semantics, Active-Model Detection, blank-cell-to-disable → [model-lanes.md](../model-lanes.md).

This single picker implementation is shared with audit; if you change the picker behavior, change it
in lane-delegation.md so both callers stay in sync (audit § Step 4f step 2-bis is the other caller).

---

## Risk tier

Low-risk — **executes immediately**, no `--execute` flag. There is no meaningful display mode for an
interactive `AskUserQuestion`: the picker IS the plan and its answer IS the consent (the same
single-consent pattern audit's 4f-setup uses). An **unchanged** answer writes nothing.

## Dispatch preflight

This command takes **no skill target**. The Self-Exclusion Rule (SKILL.md) does not meaningfully
apply — `model-map` edits the project-wide `model-lanes.md` and rewrites `model:` lines on
`generated-by: skill-builder lane-excursion` agents *by marker*, never targeting the `skill-builder`
skill as a subject. `model-map` is in the known-command set, so the intent router never intercepts
it. No agent panel is required: every decision below is mechanical (marker read, picker answer,
marker-filtered glob) — none involves a guess (Non-Obvious Decision Gate clause 2).

---

## Procedure

### Step 1 — Read the mapping and setup state

Read the project's `references/model-lanes.md` (relative to the skill-builder install). Parse the
Lane→Model table, the Skill→Lane table, and the `<!-- model-lane-setup: <state> -->` marker
(missing = `unset`). See [model-lanes.md](../model-lanes.md) § Setup State.

### Step 2 — Headless guard (before any question)

IF the session is headless / non-interactive → **refuse cleanly** and STOP: print
"Lane→Model selection is interactive; run `/skill-builder model-map` in an interactive session."
Write nothing. Do NOT pick a default, do NOT switch the model. (An interactive picker cannot run
with no user — same suppression the audit picker declares.)

### Step 3 — Branch on setup state (lean: this command only ever asks the two model questions)

- **`model-lanes.md` absent entirely** → the install is incomplete. Report
  "references/model-lanes.md is missing — run `/skill-builder update` (or `audit`) to restore it,
  then re-run `model-map`." STOP. (Do not synthesize the file here; restoring shipped files is the
  installer's job.)
- **marker `declined`** → the user previously chose "Never ask in this project." Do NOT silently
  override it. Surface that the project is `declined` and ask ONE AskUserQuestion: **"This project
  previously opted out of model lanes. Set the creative + coding models now (re-enables lanes)?"**
  Options: **Set models now** / **Keep declined (cancel)**. On *Keep declined* → STOP, write
  nothing. On *Set models now* → continue to Step 4; the affirmative answer is the opt-in, and
  Step 5's write flips the marker to `configured`.
- **marker `unset`, OR `configured`, OR active Skill→Lane rows / a `lane:`-declaring skill exist**
  → continue to Step 4. (`model-map` never runs the per-skill lane-suggestion onboarding — that is
  audit-only. On a fresh `unset` project the picker still runs; Step 5 marks it `configured` with
  the Skill→Lane table left empty, honoring declared-never-inferred.)

### Step 4 — Build the picker option list

Build the candidate options EXACTLY per [lane-delegation.md](../lane-delegation.md) § Lane→Model
Picker: `claude-opus-4-6`, `claude-opus-4-8`, and the latest released model by official ID —
discovered fresh via that section's discovery ladder (`GET /v1/models` ~10s timeout → models-overview
docs fetch → on both failing, OMIT the "latest" option and print the one-line notice). **Never
fabricate a model ID from memory; never cache.** Dedupe "latest" against the two static IDs. The two
static IDs plus AskUserQuestion's auto-appended "Other" always survive a discovery failure.

### Step 5 — The picker (one batched AskUserQuestion) and the single consented write

Emit ONE batched `AskUserQuestion` with two questions — **"Creative lane model"** and
**"Coding (everything-else) lane model"** — each defaulting to the current mapping value
(confirming is one click; "Other" preserves manual entry; leaving a cell blank disables flagging for
that lane per [model-lanes.md](../model-lanes.md) § Comparison Rule).

This is a **configuration** question, not a switch request — it never instructs the user to run
`/model` and `model-map` never switches the session model (No-Switch-Prompt directive; the picker is
the sanctioned carve-out).

Apply the answer (the answer IS the consent — single-write discipline):
- **Unchanged** → write nothing for the mapping. (Still continue to Steps 6–7 only if a cell was
  blanked this run; otherwise report no-change and STOP.)
- **Changed** → edit ONLY the changed Lane→Model **preferred-model cells** in `model-lanes.md`.
  These live in the `immutable: false` user-editable mapping block — **never touch any
  `origin: user | immutable: true` content, never rewrite the file wholesale.** Preserve the
  `model-lane-setup` marker exactly, EXCEPT the two opt-in cases above (a prior `unset` or the
  `declined`→opt-in path), where you set it to `configured` as the user's affirmative consent.
  Re-read the file once to confirm it parses.

### Step 6 — Fleet Rewrite (fan the new IDs out to generated agents)

For every lane whose preferred model **changed** to a non-empty value, run the Fleet Rewrite exactly
per [lane-delegation.md](../lane-delegation.md) § Fleet Rewrite on Remap:
1. Glob all agent forms and filter on `generated-by: skill-builder lane-excursion` **AND**
   `lane-pinned: <remapped lane>`. **Files without `generated-by` are user property — never touched.**
2. `TaskCreate` one task per matching file; rewrite the **`model:` line only** (move-don't-rewrite
   on the body).
3. **Verification pass (own it — there is no enclosing audit report here):** re-grep every
   lane-pinned agent's `model:` against the new mapping and emit a mismatch table. Any leftover, any
   read-only/write failure, is an explicit reported finding — never silent.
4. Incomplete marker sets (`generated-by` present, `lane-pinned` missing, or `excursion-skill` ≠
   containing directory) → **skip + report, no auto-repair** (tamper-guard parity).
5. **Zero matching agents is a no-op success**, not an error — most projects have none. Report
   "0 lane-pinned agents to update" and continue.
6. Never spawn or keep an agent pinned to a model the user has removed (blanked) — see Step 7.

### Step 7 — Blank-cell cleanup (chain `route embed` only when a cell was disabled)

- **Pure model swap (no cell blanked)** → no chaining. Remapping which model a lane prefers changes
  no skill's lane membership or gate (the `MODEL-LANE-GATE` reads the active model at runtime), so a
  `route embed` pass would be no-op churn. STOP after the report.
- **A cell transitioned non-empty → empty (lane disabled)** → that lane's invocation-time gates and
  `LANE-AGENT-EMBED` excursion maps are now orphaned. Chain `route embed --execute` (its Step 8/9
  reconciliation owns gate removal + map-entry stripping + REPORT-ORPHAN) so the wiring is not left
  stale. If `/route` is not installed, instead report: "lane `<lane>` disabled — run
  `/skill-builder route embed --execute` to strip its now-orphaned gates and excursion maps."

### Step 8 — Report

Print a short summary (no terminal question — this is informational prose):
- Lane→Model result: `confirmed unchanged` / `remapped <lane>: <old> → <new>` / `<lane> disabled` /
  discovery-unavailable notice if it fired.
- Fleet Rewrite: N agents rewritten, plus any skip/mismatch findings from Step 6's verification.
- Any `route embed` chain triggered by Step 7.

---

## Suppression summary

| Condition | Behavior |
|-----------|----------|
| Headless / non-interactive | Refuse cleanly, write nothing (Step 2). |
| `model-lanes.md` absent | Report + STOP (restore via installer). |
| marker `declined` | Explicit opt-in question first; never silently overridden. |
| Unchanged picker answer, no blank | Report no-change, no write, no fleet rewrite. |
| Zero lane-pinned agents | No-op success. |

**Grounding:** [lane-delegation.md](../lane-delegation.md) § Lane→Model Picker + § Fleet Rewrite on
Remap (canonical picker + fleet mechanics), [model-lanes.md](../model-lanes.md) § Setup State /
§ Active-Model Detection / § Comparison Rule, [audit.md](audit.md) § Step 4f step 2-bis (the other
caller of the same picker), SKILL.md § Directives (No-Switch-Prompt Gate, Audit Agent
Model-Assignment Gate, Non-Obvious Decision Gate).
