# Model Lanes — Lane→Model Routing
<!-- Enforcement: MEDIUM — read by audit Step 4f; flags only USER-DECLARED lane/model mismatches. -->

This file makes `skill-builder` model-aware. It splits work into two **lanes** and maps each
lane to a **preferred model**, so an audit can flag (and optionally prompt) when the active
session model does not match a skill's declared lane.

**Two principles keep this safe:**

1. **The mapping is yours to edit.** Model IDs change constantly. They live here — never inside a
   sacred `origin: user | immutable: true` directive block — precisely so you can change them
   freely without touching protected wording.
2. **Lane assignment is declared, never inferred.** Audit only flags a model mismatch for skills
   you have explicitly assigned to a lane (via the table below or a `lane:` frontmatter key). A
   skill with no declared lane is **silently skipped** — it is never auto-classified into a flag.
   (Audit *may* print a non-blocking advisory suggesting a lane for undeclared skills — see
   § Advisory Lane Suggestion — but a suggestion never triggers a switch prompt.)

---

<!-- origin: user | added: 2026-06-01 | immutable: false | user-editable mapping -->
## Lane → Preferred Model  (EDIT THESE FREELY)

Use the **normalized exact model ID** form: `claude-<family>-<major>-<minor>`
(strip any context-window suffix like `[1m]` / `[200k]`).

| Lane       | Preferred Model     |
|------------|---------------------|
| `creative` | `claude-opus-4-6`   |
| `coding`   | `claude-opus-4-8`   |

- `coding` is the **default / everything-else** lane (includes testing).
- `creative` covers image generation, content generation, and design generation.
- **To DISABLE flagging for a lane**, blank out its Preferred Model cell (leave it empty).
  Audit never flags a lane whose preferred model is empty or absent.

## Skill → Lane  (DECLARE YOUR SKILLS HERE)

<!-- model-lane-setup: unset -->

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
<!-- /origin -->

---

## Setup State (per-project tracking, managed by audit)

The `<!-- model-lane-setup: <state> -->` marker inside the Skill→Lane block records this project's
decision about model lanes. Audit reads it to decide whether to offer setup, and writes it after you
respond. Three states:

| State | Meaning | Audit behavior |
|-------|---------|----------------|
| `unset` | You have never configured lanes and never declined. The fresh-install default. | On a full interactive `audit`, offer the one-time **setup prompt** (Set it up now / Not now / Never ask in this project). |
| `configured` | Lanes are set up. | Run the normal mismatch check (§ Comparison Rule) and the suppressible switch prompt. No setup offer. |
| `declined` | You chose "Never ask in this project." | Silent no-op. Audit never offers setup again (until you change this marker by hand). |

**Reconciliation (no nag for manual setups).** If the marker says `unset` (or is missing) BUT the
Skill→Lane table already has active rows OR a skill self-declares a `lane:` key, audit treats the
project as `configured` and upgrades the marker — so declaring lanes by hand never triggers the setup
offer. "Not now" leaves the marker `unset` (you will be asked again next full audit); "Never ask"
writes `declined`.

**Suppression.** The setup prompt is offered ONLY on a full, interactive `audit`. It is suppressed
in headless / non-interactive runs and in `audit --quick`, exactly like the switch prompt — those
runs never write the marker. To re-enable the offer after declining, change `declined` back to
`unset` (or just declare a lane).

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
has clearly superseded), downgrade the finding from a switch prompt to a one-line advisory:
"mapping may be stale — review `references/model-lanes.md`". Never validate IDs against a hardcoded
"known-live" list — that list rots too.

---

## Invocation-Time Preflight Gate (the other half of "with prompting, or not")

The Comparison Rule above is consumed in **two** places, not one:

1. **Audit-time** — `audit` Step 4f scans every skill and prompts on mismatch, but only when the user explicitly runs `audit`.
2. **Invocation-time** — a `MODEL-LANE-GATE` CHECKPOINT block embedded near the **top of each lane-declared skill's own workflow**, so the mismatch prompt fires *before that skill does generative work*, the moment it is invoked. This closes the gap where a `creative`-lane skill invoked on the `coding` model would draft content with no prompt.

The invocation-time gate uses the **same** detection and rules defined here: lane resolution (§ Comparison Rule step 1), empty-cell no-op (step 3), Active-Model Detection (§ Active-Model Detection), and the stale-ID self-check (§ Comparison Rule → Stale-ID self-check). Like the audit prompt and the `update` command's permission-mode prompt, **the gate only prompts the user to run `/model` — a skill cannot switch the session model itself.**

The gate is wired into skills by `/skill-builder route embed` as a managed-block family (see [procedures/route.md](procedures/route.md) § Step 8). It is embedded ONLY into skills that resolve to a lane with a non-empty preferred model, and `route embed` removes it automatically from any skill that later leaves a lane. **Suppression ("or not"):** the gate is a silent no-op in headless / non-interactive sessions, and a skill can opt out by setting `model-lane-gate: off` in its own frontmatter.

---

## Advisory Lane Suggestion (suggest-only; never flags)

For skills with **no declared lane**, audit MAY emit a non-blocking suggestion so you can decide
whether to declare them. This is advisory text in the report only — it NEVER triggers a switch
prompt and NEVER assigns a lane on its own. Resolve signals in this exact order; **stop at the
first that fires** and emit `<lane> (suggested, <confidence>)`:

1. **Generative-media tool signal → `creative`, HIGH.** Scan `allowed-tools` and any `mcp__*` tool
   names in the SKILL.md body (case-insensitive) for: `nanobanana`, `generate_image`,
   `gemini_generate_image`, `gemini_edit_image`, `text_to_image`, `elevenlabs`, `text_to_speech`,
   `text_to_sound`, `text_to_voice`, `voice_clone`, `compose_music`, `speech_to_speech`.
   Generic tools (`Read`/`Glob`/`Grep`/`Bash`/`Task`/`Skill`/`ToolSearch`) are **never** a signal.
2. **Name token → HIGH.** Lowercase `name`. Creative tokens: `image`, `img`, `voice`, `audio`,
   `music`, `writing`, `write`, `copy`, `content`, `edit`, `prose`, `design`, `frontend`, `ui`,
   `ux`, `style`, `newsletter`, `present`, `slide`. Coding tokens: `review`, `security`, `verify`,
   `test`, `lint`, `build`, `run`, `init`, `deploy`, `refactor`, `simplify`, `debug`, `audit`,
   `migrate`, `research`, `ledger`, `hook`, `agent`, `mcp`, `config`. Match exactly one list → that
   lane. Match both or neither → fall through.
3. **Description verbs → HIGH/MEDIUM.** Lowercase `description` + H1 title. Count hits:
   - creative: `generate`, `image`, `watercolor`, `illustration`, `voice`, `tone`, `aesthetic`,
     `design`, `distinctive`, `polished`, `creative`, `prose`, `copy`, `content`, `draft`,
     `narrative`, `caption`, `tells`, `authenticity`, `style`, `palette`, `frontend interface`.
   - coding: `code`, `bug`, `correctness`, `test`, `lint`, `compile`, `build`, `run`, `deploy`,
     `refactor`, `simplify`, `security`, `vulnerability`, `audit`, `verify`, `validate`,
     `frontmatter`, `hook`, `agent`, `skill`, `research`, `cited`, `migrate`, `API`, `config`.
   - `creative_hits ≥ coding_hits + 2` → `creative` HIGH; `coding_hits ≥ creative_hits + 2` →
     `coding` HIGH; difference of 1 → leading lane at MEDIUM; tie → `AMBIGUOUS`.
4. **AMBIGUOUS** → do not guess a suggestion. Per the repo directive *"When a decision needs to be
   made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY"*, only spawn a
   classification agent if the user explicitly asks audit to auto-assign lanes. For a passive audit
   suggestion, simply print `lane undetermined — declare manually` and move on.

The `+2` margin keeps genuinely code-emitting-but-creative skills (e.g. `frontend-design`) on the
creative side while leaving true 1-apart cases at MEDIUM for human spot-check.

---

*Read by `references/procedures/audit.md` § Step 4f (audit-time check) and by the `MODEL-LANE-GATE`
preflight that `references/procedures/route.md` § Step 8 embeds into lane-declared skills
(invocation-time check). Installed if-absent by the project installer so your edits survive
`/skill-builder update`. Excluded from `audit --quick`.*
