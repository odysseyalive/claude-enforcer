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

Only skills listed here (or self-declaring `lane:` in their own SKILL.md frontmatter) participate
in model-mismatch flagging. **On a fresh install this table is empty of real assignments** — the
rows below are commented-out examples, so the check is a no-op until you declare at least one skill.

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

*Read by `references/procedures/audit.md` § Step 4f. Installed if-absent by the project installer
so your edits survive `/skill-builder update`. Excluded from `audit --quick`.*
