<!-- origin: skill-builder | modifiable: true -->
# skill-builder / claude-enforcer version

This file is the **authoritative, shipped version anchor** for the whole
skill-builder distribution (claude-enforcer). It answers one question: *which
release of skill-builder is installed?* The `/skill-builder version` command
reads the string below and prints it; `/skill-builder version --check` compares
it against the copy on `main` to report whether the install is behind.

Unlike the per-set drift anchors (`references/creative-integrity/version.md`,
`references/code-evaluator/version.md`), which carry monotonic **integers** for
audit drift-sync of one reference set, this file carries the **semver product
version** of the entire distribution.

```
version: 1.8.0
released: 2026-07-22
```

`plugin.json`'s `version` field MIRRORS this string for the marketplace. Bump
BOTH together. See CLAUDE.md "Versioning" for the release ritual.

## Changelog

- **1.8.0** (2026-07-22). DEFER tier eliminated from audit's AUTO/DEFER
  classification per user directive: every item that previously deferred to a
  manual follow-up command now auto-executes under the Step 0 disclaimer consent.
  Agent panels provide judgment where procedures demand it; the Step 0.2 backup
  is the recovery mechanism; failed tasks land as checkmark-X items in the
  Execution Summary, never as deferred commands. The "Deferred Items" report
  section becomes "Advisory Notes" (informational, no runnable commands). 12
  source files updated across SKILL.md, creative-integrity, lane-delegation,
  audit, backup, code-eval, hooks, optimize, post-action-chain, quick-audit,
  reconcile, and verify procedures. Follow-up pass (same directive): the three
  SCAN-phase panel suppressions that still handed work back as commands now
  queue into Step 6 instead — reconcile judgment-class adjudication, the
  creative-integrity classification panel, and excursion coverage
  (`agents --execute`) — and a new Audit Autonomy Gate clause 4a forbids ANY
  report line from naming a skill-builder command as work the user must run
  (exceptions: user-initiated `strip`, `restore`, and a companion the user
  declined at Step 0.3). `route embed` and `reconcile` suppress their standalone
  recommendation lines under audit; `principles.md` rule 3 drops its reference
  to the abolished execution menu.
- **1.7.0** (2026-07-17). Companion-Skill Selection Gate (audit Step 0.3)
  reshaped to a natural **install-only** widget per user directive: a checked
  box installs an absent companion; unchecked means nothing happens; **the gate
  never uninstalls** — removal is exclusively a manual `/skill-builder strip
  <name>`. Only absent companions render as options ("(recommended)" restored
  on `route`/`awareness-ledger`); installed companions are listed
  informationally with the exact strip command, and their unconditional
  updates (code-eval sync, catalog propagation, route index/embed) are
  untouched. The empty default is inert symmetrically: interactive empty
  submissions and headless marker-absent runs both install nothing (supersedes
  the install-on-absence fallback); a persisted `<name>=on` still authorizes
  headless installs, and a prior `off` on a present companion is preserved,
  never silently flipped. Also unified the model-selection pool: the advisor
  question everywhere references the ONE Lane→Model Picker pool (fixed stale
  "alias options" echoes in `procedures/audit.md` § 4f-setup and
  `procedures/model-map.md`, and the outdated four-static list in SKILL.md
  Rule 7), so `claude-fable-5` is always offered. Touches `procedures/audit.md`,
  `procedures/model-map.md`, `model-lanes.md`, `creative-integrity.md`,
  `SKILL.md`.
- **1.6.2** (2026-07-15). Advisor/lane picker static option list reordered
  **newest-first** and trimmed to three IDs: `claude-fable-5` /
  `claude-opus-4-8` / `claude-opus-4-6` (dropped `claude-sonnet-5`, still
  reachable via "Other"). The advisor question spends one of its four slots on
  "No advisor", leaving room for three models, so the latest (`claude-fable-5`)
  now leads and the four-option ceiling only ever peels an oldest static off the
  tail — the latest model is never the one dropped. The live-latest discovery
  ladder is unchanged, so a newer release takes the lead slot and `opus-4-6`
  peels off. Touches `lane-delegation.md`, `procedures/model-map.md`,
  `procedures/audit.md`.
- **1.6.1** (2026-07-08). Advisor picker now emits FULL official model IDs
  instead of the `fable`/`opus`/`sonnet` aliases: options mirror the Lane→Model
  Picker's static IDs plus the live-discovered latest, the `advisorModel`
  settings write and the `/advisor` advisory both name the full ID, and the
  pairing filter is restated in full-ID/family terms. Agent `model:` override
  examples in `templates.md` switched to full IDs to match. Reverses the
  deliberate-alias choice in `DEC-2026-07-08-global-advisor-in-picker` (project
  policy: models are always referenced by full official ID).
- **1.6.0** (2026-07-08). Added the `version` command (`/skill-builder version`
  prints the installed version and release date; `--check` reports whether `main`
  is newer). Introduced this authoritative shipped version anchor, and corrected
  the long-stale `plugin.json` version (1.0.0 to 1.6.0) so it now mirrors this
  file.
<!-- /origin -->
