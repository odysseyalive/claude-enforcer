# Model Lanes — Lane→Model Routing
<!-- Enforcement: MEDIUM — read by audit Step 4f; flags only USER-DECLARED lane/model mismatches. -->

This file makes `skill-builder` model-aware. It splits work into two **lanes** and maps each
lane to a **preferred model**, so an audit can flag — as a report-only advisory, never a switch
prompt (No-Switch-Prompt directive, 2026-06-06) — when the active session model does not match
a skill's declared lane.

**Two principles keep this safe:**

1. **The mapping is yours to edit.** Model IDs change constantly. They live here — never inside a
   sacred `origin: user | immutable: true` directive block — precisely so you can change them
   freely without touching protected wording.
2. **Lane assignment is declared, never inferred.** Audit only flags a model mismatch for skills
   you have explicitly assigned to a lane (via the table below or a `lane:` frontmatter key). A
   skill with no declared lane is **silently skipped** — it is never auto-classified into a flag.
   (Audit *may* print a non-blocking advisory suggesting a lane for undeclared skills — see
   § Advisory Lane Suggestion — but a suggestion never produces anything beyond its own line.)

---

<!-- origin: user | added: 2026-06-01 | immutable: false | user-editable mapping -->
## Lane → Preferred Model  (EDIT THESE FREELY)

Use the **normalized exact model ID** form: `claude-<family>-<major>-<minor>`
(strip any context-window suffix like `[1m]` / `[200k]`).

| Lane       | Preferred Model     |
|------------|---------------------|
| `creative` | `claude-opus-4-6`   |
| `coding`   | `claude-opus-4-8`   |

- `coding` is the **default / everything-else** lane (includes testing **and research**).
- `creative` covers image generation, content generation, and design generation — plus
  communication, language translation, and text evaluation (per the 2026-06-06 directive).
- **Research precedence (2026-06-06 caveat):** anything that has to do with research is performed
  by the coding model *before* being handed off to creative. Research signals therefore always
  resolve to `coding` and take precedence over every creative signal in the suggestion heuristic
  below (§ Advisory Lane Suggestion step 1).
- **To DISABLE flagging for a lane**, blank out its Preferred Model cell (leave it empty).
  Audit never flags a lane whose preferred model is empty or absent. A blanked cell also disables
  excursion delegation in that direction (no agent is ever pinned to a removed model).
- **Changing a cell at audit time fans out** to every generated lane-pinned excursion agent's
  `model:` frontmatter — see [lane-delegation.md](lane-delegation.md) § Fleet Rewrite on Remap.

## Skill → Lane  (DECLARE YOUR SKILLS HERE)

<!-- model-lane-setup: unset -->
<!-- advisor-setup: unset -->

Only skills listed here (or self-declaring `lane:` in their own SKILL.md frontmatter) participate
in model-mismatch flagging. **On a fresh install this table is empty of real assignments** — the
rows below are commented-out examples, so the check is a no-op until you declare at least one skill.

The `<!-- model-lane-setup: … -->` line above is the **per-project setup-state marker** that `audit`
reads and writes (see § Setup State below). It is how each project remembers whether you have set up
model lanes, declined, or not yet been asked — it lives here, in your project's own (update-preserved)
copy of this file, so the decision is tracked per project.

| Skill | Lane |
|-------|------|
<!-- | image   | creative |  ← example: uncomment and edit to activate -->
<!-- | writing | creative |  ← example -->
<!-- | voice   | creative |  ← example -->
<!-- | verify  | coding   |  ← example -->

- A skill **not** listed here and **not** self-declaring a `lane:` resolves to **no lane** and is
  skipped — it is NOT auto-assigned to `coding` for flagging purposes.
- A skill's own `lane:` frontmatter key, if present, **wins** over this table.
- **Per-function rows (2-Brain Harness, 2026-06-06):** a multi-mode skill may declare
  `| skill:function | lane |` rows (e.g. `| study-prep:chat | creative |`) — or a `lanes:`
  frontmatter map (`lanes: {chat: creative, drill: coding}`) — for functions that pass the
  Mode-Detection Ladder (§ below). Resolution precedence is **specificity first**: frontmatter
  `lanes.<fn>` → table `skill:function` row → frontmatter `lane:` → table skill row → no lane.
  Unlisted functions inherit the skill-level lane silently (the default IS a declaration — not a
  gap); audit prints a non-blocking sub-coverage line only for skills that opted into function
  granularity. `lane: none` is a valid declaration meaning "deliberately not lane-managed" — it
  counts as accounted-for in coverage reporting, suppresses the advisory suggestion, and never
  receives a gate.
<!-- /origin -->

---

## Setup State (per-project tracking, managed by audit)

The `<!-- model-lane-setup: <state> -->` marker inside the Skill→Lane block records this project's
decision about model lanes. Audit reads it to decide whether to offer setup, and writes it after you
respond. Three states:

| State | Meaning | Audit behavior |
|-------|---------|----------------|
| `unset` | You have never configured lanes and never declined. The fresh-install default. | On a full interactive `audit`, offer the one-time **setup prompt** (Set it up now / Not now / Never ask in this project). |
| `configured` | Lanes are set up. | Run the **Lane→Model picker** UP FRONT at audit [§ Step 0.4](procedures/audit.md) (re-confirm which model is creative and which is coding/everything-else, current values pre-selected as defaults — see [lane-delegation.md](lane-delegation.md) § Lane→Model Picker), then later the normal mismatch check at § Step 4f (§ Comparison Rule), reported as one-line advisories only — never a switch prompt. No *setup* offer. |
| `declined` | You chose "Never ask in this project." | Silent no-op. Audit never offers setup again (until you change this marker by hand). |

**Reconciliation (no nag for manual setups).** If the marker says `unset` (or is missing) BUT the
Skill→Lane table already has active rows OR a skill self-declares a `lane:` key, audit treats the
project as `configured` and upgrades the marker — so declaring lanes by hand never triggers the setup
offer. "Not now" leaves the marker `unset` (you will be asked again next full audit); "Never ask"
writes `declined`.

**Suppression.** The setup offer is made ONLY on a full, interactive `audit`. It is suppressed
in headless / non-interactive runs and in `audit --quick` — those runs never write the marker.
To re-enable the offer after declining, change `declined` back to `unset` (or just declare a lane).

**Audit-disclaimer marker (2026-06-06 sacred directive).** A second per-project marker lives beside
`model-lane-setup`: `<!-- audit-disclaimer: accepted -->`. Audit's Step 0 disclaimer gate
(audit.md § Step 0) writes it on the user's first interactive "Accept and proceed" and refreshes it
on each subsequent acceptance. Its ONLY consumer is headless/non-interactive audit: with the marker
present, a headless audit prints the disclaimer into its report and proceeds; with no marker, it
refuses ("Audit disclaimer not yet accepted — run one interactive audit first"). Interactive audits
always re-ask regardless of the marker. Delete the marker by hand to force headless runs to block
again.

**Advisor-setup marker (2026-07-08).** A third per-project marker lives beside `model-lane-setup`:
`<!-- advisor-setup: unset|configured|declined -->`. It tracks whether the Lane→Model picker's
global-advisor question has been answered: `unset` (or missing) → ask; `configured` → ask with the
current value pre-selected; `declined` → suppress the advisor question only (the lane questions
still run). The chosen model itself is NEVER stored in this file — it lives in Claude Code
settings (`advisorModel`, written host-locally to `.claude/settings.local.json`); this marker
records setup state only, so the two can never drift. Normative spec:
[lane-delegation.md](lane-delegation.md) § Global Advisor Model. This file is install-if-absent —
existing installs won't have this marker or this paragraph; the procedures treat a missing marker
as `unset` and insert the marker line surgically on first configure (never a wholesale rewrite).
To re-enable the question after declining, set the marker back to `unset`.

**2026-06-06 semantics change.** `configured` no longer means never-ask-again for the *mapping*:
every full interactive audit re-confirms the Lane→Model choices via the picker (one click when
nothing changes — current values are the pre-selected defaults). Only `declined` silences audit
entirely. The marker answers "does this project use lanes at all?"; the picker is a mapping
refresh that only exists once lanes exist. There is deliberately NO fourth marker state to opt out
of the re-ask. The picker never writes this marker.

---

## Companion Skills (per-project install/remove selection, managed by audit Step 0.3)

Audit force-installs a small set of evaluator/helper **companion skills**. Per the 2026-06-24
directive, audit's SECOND question (the Companion-Skill Selection Gate, audit.md § Step 0.3) is a
multi-select checkbox letting you opt in or out of each, so a project with its own intricate
evaluator set is never force-managed. Your choices are remembered here, per project, in a marker:

```
<!-- companion-skills: text-eval=on|off, code-evaluator=on|off, route=on|off, awareness-ledger=on|off -->
```

(The `on|off` above is a template; the active marker — written beside `model-lane-setup` with each
key resolved to a single `on` or `off` — is what audit reads. Audit ignores this fenced example.)

The gate renders as **two grouped multi-selects in one `AskUserQuestion` call** (still one question
slot): **Evaluators** (`text-eval`, `code-evaluator`) and **Helpers** (`route`, `awareness-ledger`)
— the sanctioned-question count is unchanged.

| Key | Companion | Install on absence? | `on` | `off` |
|-----|-----------|---------------------|------|-------|
| `text-eval` | text AI-tells evaluator | yes | install-on-absence scaffold authorized | scaffold suppressed; if present + skill-builder-scaffolded, removal DEFERS to `strip` |
| `code-evaluator` | code-quality evaluator | yes | `code-eval create` authorized | create suppressed; removal DEFERS to `strip` |
| `route` | the `/route` dispatcher | yes | `route index`/embed terminal tasks run | bootstrap suppressed when absent; removal DEFERS to `strip --confirm-breaking` when present |
| `awareness-ledger` | institutional-memory ledger | yes | `ledger --execute` authorized | install suppressed; removal DEFERS to `strip` |

**How the gate uses this marker (INVERTED widget — a check means *opt out*):**

`AskUserQuestion` cannot pre-check boxes (it has no `selected`/`default` field), so the gate **inverts**
the checkbox meaning rather than rendering a checkmark: an **unchecked** box keeps/installs the
companion, a **checked** box opts it out. Presence is computed by a **signal-based** test (a skill
performing the function counts under any directory name) and shown in each row's label as
**PRESENT/ABSENT** — never as a pre-check. Leaving every box unchecked is the safe default: keep all
present companions, install the absent **install-on-absence** ones — all four (`route`,
`awareness-ledger`, `text-eval`, `code-evaluator`). **No "(recommended)" wording is shown** — that
mechanic is superseded (2026-06-24) because a "(recommended)" tag next to a remove-checkbox reads as
"recommended to remove"; `route` and `awareness-ledger` are simply install-on-absence defaults like
the rest, kept unless checked out.

- **Unchecked + present** → kept; marker `=on`; no action.
- **Unchecked + absent** → the companion's install task is authorized (it does NOT run
  unconditionally anymore — the empty box is its authorization); marker `=on`. All four companions
  are install-on-absence: yes.
- **Checked + absent** → install suppressed (the opt-out); marker `=off` — uniform across all four.
- **Checked + present + skill-builder-scaffolded** → removal is **DEFERRED** to a ready-to-run
  `/skill-builder strip <key> --execute` command (audit never auto-deletes; "Always defer to
  strip"). Strip performs the complete cross-reference disconnection plus the `route index`/embed
  refresh; marker `=off`.
- **Checked + present + your own hand-authored skill** → never removed (provenance guard); the
  gate only notes that your own skill serves the function; marker `=off`.

**Back-compat.** A legacy `<!-- creative-scrub-build: off -->` marker (the 2026-06-12 text-eval
build opt-out) reads as `text-eval=off` for the purpose of suppressing the text-eval scaffold.

**Suppression.** The gate is interactive-only: headless / non-interactive runs and `audit --quick`
render no checkbox, write no marker, and **remove nothing** — they honor an existing marker, or, with
no marker, fall back to the pre-2026-06-24 install-on-absence defaults. Absence of an answer never
means remove. A missing marker means "never configured" — the first full interactive audit asks and
writes it. Hand-edit the marker any time to change your selection; delete it to be re-asked fresh.

---

## Active-Model Detection (how audit reads the current model)

There is **no environment variable or settings field** that reports the active session model.
The single authoritative runtime source is the session's own system context line, e.g.:

> "You are powered by the model named Opus 4.8. The exact model ID is `claude-opus-4-8[1m]`."

To produce `ACTIVE_MODEL` for comparison (deterministic — no judgment, so no agent required):

1. Take the string after "The exact model ID is".
2. Strip any bracketed context-window suffix: `[1m]`, `[200k]`, etc. → `claude-opus-4-8`.
3. Lowercase; keep the `claude-<family>-<major>-<minor>` shape verbatim. Do not rewrite it.
4. If the exact-ID phrase is somehow absent, fall back to slugging the friendly name
   ("Opus 4.8" → `claude-opus-4-8`). The bracket-stripped exact ID is primary; the slug is fallback.

Do **not** attempt a Bash/`env` probe — there is nothing on disk to read; a shell call would only
fail or fabricate.

---

## Comparison Rule (what counts as a mismatch)

For each audited skill:

1. Resolve its lane: `lane:` frontmatter → Skill→Lane table → **no lane** (skip).
2. Look up the lane's Preferred Model in the Lane→Model table.
3. **If the preferred model is empty/absent → no preferred model declared → do NOT flag, do NOT
   prompt.** Skip silently (per audit's "absence vs. gap" rule — an undeclared preference is
   correctly absent, not a gap).
4. **Only when** the preferred model is non-empty **AND** `preferred_model != ACTIVE_MODEL` → flag
   the skill as a model mismatch.

### Stale-ID self-check

If a non-empty preferred model does **not** match the active session model's family format
(e.g. it isn't of the shape `claude-<family>-<major>-<minor>`, or names a family the active model
has clearly superseded), downgrade the finding from a mismatch advisory to a one-line stale-mapping advisory:
"mapping may be stale — review `references/model-lanes.md`". Never validate IDs against a hardcoded
"known-live" list — that list rots too.

---

## Invocation-Time Preflight Gate (advisory-only)

The Comparison Rule above is consumed in **two** places, not one — and per the No-Switch-Prompt
directive (2026-06-06), BOTH are report-only: no function of skill-builder ever asks the user to
switch models.

1. **Audit-time** — `audit` Step 4f scans every skill and reports mismatches as one-line advisories, but only when the user explicitly runs `audit`.
2. **Invocation-time** — a `MODEL-LANE-GATE` CHECKPOINT block embedded near the **top of each lane-declared skill's own workflow**, so the mismatch advisory prints *before that skill does generative work*, the moment it is invoked. This closes the gap where a `creative`-lane skill invoked on the `coding` model would draft content with no signal at all.

The invocation-time gate uses the **same** detection and rules defined here: lane resolution (§ Comparison Rule step 1), empty-cell no-op (step 3), Active-Model Detection (§ Active-Model Detection), and the stale-ID self-check (§ Comparison Rule → Stale-ID self-check). **The gate's entire output is one advisory line that names the exact remedy informationally — "to align, run `/model <preferred>` and re-invoke; proceeding as-is" (named-command advisory directive, 2026-06-11) — it never blocks, never emits an AskUserQuestion, and a skill cannot switch the session model itself.**

The gate is wired into skills by `/skill-builder route embed` as a managed-block family (see [procedures/route.md](procedures/route.md) § Step 8). It is embedded ONLY into skills that resolve to a lane with a non-empty preferred model, and `route embed` removes it automatically from any skill that later leaves a lane. **Suppression:** the gate is a silent no-op in headless / non-interactive sessions, and a skill can opt out by setting `model-lane-gate: off` in its own frontmatter.

---

## Excursion Delegation (pointer)

The two checks above govern a skill's **primary lane**. Cross-lane steps *inside* a skill's
workflow (a creative skill's research step; a coding skill's prose step) do **not** re-prompt for a
switch — they are delegated to bespoke, lane-pinned subagents whose `model:` frontmatter carries
the other lane's full model ID, returning results to the main model. Research precedence holds:
research is always coding-lane work, so it is delegated *from* creative skills and runs natively in
coding skills. The full specification — excursion classification, the NON-DELEGABLE hard-stop list,
the Context Contract, the per-skill Delegation Map block, the Lane→Model picker, and the fleet
rewrite on remap — lives in [lane-delegation.md](lane-delegation.md). Designed and placed by
`/skill-builder agents` (agents.md § Step 4d); reconciled by `route embed` (route.md § Step 9).

---

## Advisory Lane Suggestion (suggest-only; never flags)

For skills with **no declared lane**, audit MAY emit a non-blocking suggestion so you can decide
whether to declare them. This is advisory text in the report only — it NEVER triggers a switch
prompt and NEVER assigns a lane on its own. Resolve signals in this exact order; **stop at the
first that fires** and emit `<lane> (suggested, <confidence>)`:

1. **Research precedence → `coding`, HIGH.** Per the 2026-06-06 caveat (research is performed by
   the coding model before being handed off to creative), this fires BEFORE every creative signal:
   IF the lowercase `name` contains the token `research`, OR the lowercase `description` + H1 title
   contains `research` or `cited` → suggest `coding` and STOP.
2. **Generative-media tool signal → `creative`, HIGH.** Scan `allowed-tools` and any `mcp__*` tool
   names in the SKILL.md body (case-insensitive) for: `nanobanana`, `generate_image`,
   `gemini_generate_image`, `gemini_edit_image`, `text_to_image`, `elevenlabs`, `text_to_speech`,
   `text_to_sound`, `text_to_voice`, `voice_clone`, `compose_music`, `speech_to_speech`,
   `speech_to_text`, `translate_text`, `transcribe`, `deepl`.
   Generic tools (`Read`/`Glob`/`Grep`/`Bash`/`Task`/`Skill`/`ToolSearch`) are **never** a signal.
3. **Name token → HIGH.** Lowercase `name`, split on `-`/`_` — tokens match whole name segments,
   never raw substrings (so `text` matches `text-eval` but not `context-manager`). Creative tokens:
   `image`, `img`, `voice`, `audio`,
   `music`, `writing`, `write`, `copy`, `content`, `edit`, `prose`, `design`, `frontend`, `ui`,
   `ux`, `style`, `newsletter`, `present`, `slide`, `text`, `translate`, `translation`, `language`,
   `communication`, `email`, `message`, `correspondence`, `speech`. Coding tokens: `review`,
   `security`, `verify`,
   `test`, `lint`, `build`, `run`, `init`, `deploy`, `refactor`, `simplify`, `debug`, `audit`,
   `migrate`, `research`, `ledger`, `hook`, `agent`, `mcp`, `config`, `server`, `commit`. Match
   exactly one list → that
   lane. Match both or neither → fall through.
4. **Description verbs → HIGH/MEDIUM.** Lowercase `description` + H1 title. Count hits:
   - creative: `generate`, `image`, `watercolor`, `illustration`, `voice`, `tone`, `aesthetic`,
     `design`, `distinctive`, `polished`, `creative`, `prose`, `copy`, `content`, `draft`,
     `narrative`, `caption`, `tells`, `authenticity`, `style`, `palette`, `frontend interface`,
     `communication`, `correspondence`, `translate`, `translation`, `email`, `speech`,
     `evaluate text`, `language translation`, `proofread`.
   - coding: `code`, `bug`, `correctness`, `test`, `lint`, `compile`, `build`, `run`, `deploy`,
     `refactor`, `simplify`, `security`, `vulnerability`, `audit`, `verify`, `validate`,
     `frontmatter`, `hook`, `agent`, `skill`, `research`, `cited`, `migrate`, `API`, `config`,
     `commit`.
   - `creative_hits ≥ coding_hits + 2` → `creative` HIGH; `coding_hits ≥ creative_hits + 2` →
     `coding` HIGH; difference of 1 → leading lane at MEDIUM; tie → `AMBIGUOUS`.
   - Bare `language` and bare `text`/`message` are deliberately NOT description terms (they are
     name tokens only): "language-agnostic", "plain text", and "commit message" are routine coding
     phrasing and would misfire here. Use the multiword forms above instead.
5. **AMBIGUOUS** → do not guess a suggestion. Per the repo directive *"When a decision needs to be
   made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY"*, only spawn a
   classification agent if the user explicitly asks audit to auto-assign lanes. For a passive audit
   suggestion, simply print `lane undetermined — declare manually` and move on.

The `+2` margin keeps genuinely code-emitting-but-creative skills (e.g. `frontend-design`) on the
creative side while leaving true 1-apart cases at MEDIUM for human spot-check.

---

## Mode-Detection Ladder (pointer)

Per-function lane rows are permitted only for functions that pass the **Mode-Detection Ladder** —
the normative spec lives in [lane-delegation.md](lane-delegation.md) § Mode-Detection Ladder
(shipped unconditionally, so existing installs receive updates; this file is install-if-absent and
holds only your editable mappings). Summary: explicit mode table or cross-checked frontmatter
"Modes:" list are authoritative; heading patterns are panel-gated candidates needing your
confirmation; prose-only skills are single-function for lane purposes. `route index` re-checks on
every regeneration and reports `STALE-FUNCTION` rows; it never invents or auto-deletes a mode.

---

*Read by `references/procedures/audit.md` § Step 0.4 (the every-audit Lane→Model picker) and § Step 4f (audit-time mismatch check + one-time setup onboarding), by the
`MODEL-LANE-GATE` preflight that `references/procedures/route.md` § Step 8 embeds into
lane-declared skills (invocation-time check), and by the excursion-delegation machinery in
`references/lane-delegation.md` / `references/procedures/agents.md` § Step 4d. Installed if-absent
by the project installer so your edits survive `/skill-builder update` — normative delegation rules
therefore live in lane-delegation.md (shipped unconditionally), not here. Excluded from
`audit --quick`.*
