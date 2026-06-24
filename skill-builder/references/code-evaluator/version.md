<!-- code-eval-ref-version: 4 -->
<!-- origin: skill-builder | modifiable: true -->
# code-evaluator reference version

This file is the **drift anchor**. `skill-builder audit` reads the integer below
(skill-builder's *shipped* reference version) and compares it to the
`code_eval_ref_version` recorded in a user's generated `code-evaluator` skill
(its SKILL.md frontmatter). Shipped > recorded → the user's references are stale
→ audit's drift-sync refreshes the skill-builder-owned (`modifiable: true`)
reference blocks in the user's copy, preserving any `origin: user` seams.

```
code-eval-ref-version: 4
```

Bump this integer whenever ANY file under `references/code-evaluator/` changes in
a way users should receive. Every shipped reference file also carries a matching
`<!-- code-eval-ref-version: N -->` header on its first line; keep them in sync
with this number so a per-file check is possible.

## Changelog

- **v4** (2026-06-23) — Native-tool gate gains a **binary-presence probe**. A
  matched marker file (`package.json`, `Cargo.toml`, …) now only proves the
  ecosystem; `cross-file-detection.md` § 1 adds `have`/`have_npx`/`have_cargo`
  helpers so a tool counts as present only when its marker matched AND its binary
  resolves. Marker-but-no-binary degrades to the ripgrep fallback with a one-line
  "install for AST-accurate results" note — never an auto-install, never a silent
  skip. `native-tool-map.md` § Detection points at the probe. `guards.md`,
  `mistake-taxonomy.md`, and `gotchas.md` are unchanged from their prior versions.
  `sync` pushes the new content to existing installs.
- **v3** (2026-06-23) — Prevention-first minimalism, ported from the `ponytail`
  laziness-ladder skill. `mistake-taxonomy.md` Group 2 gains three classes
  (reinvented stdlib/native, needless new dependency, speculative existence/YAGNI),
  the minimalism escalation ladder (YAGNI → reuse → stdlib → native → installed
  dep → one line), and a safety floor (never minimize away validation, error
  handling, security, accessibility, or requested features). The L1
  `code-design-advisor` now walks the ladder, honors the floor, and answers with
  ponytail's payload-first output discipline (the actionable rung first,
  rationale never longer than the recommendation, a clean verdict in one line);
  the L2 `deadcode-gardener` gains a report-only over-engineering tag vocabulary
  (`delete/stdlib/native/yagni/shrink`, one line per finding — the same
  discipline). Over-engineering is scored on a fixed **0–3 rubric** with a
  cite-or-"none" requirement and an in-skill **self-calibration** gate (rank a
  known over-built snippet above a minimal one before trusting the read; tests and
  a single self-check are never scored as bloat) — ponytail's validated-judge
  measurement mechanism re-expressed as markdown agent logic, no harness shipped.
  The L3 `sweep` adds a report-only over-engineering pass on the same rubric. `guards.md` adds guard #21
  (intent-marker-respect) so a deliberate, intent-commented shortcut is not
  re-flagged. `cross-file-detection.md`, `native-tool-map.md`, and `gotchas.md`
  are unchanged from v1. `sync` pushes the new content to existing installs.
- **v2** (2026-06-23) — Generated SKILL.md gains the `CODE-EVAL-ENFORCE`
  coordination block (no-op unless `/skill-builder code-eval enforce` is wired):
  review sets/clears the `.code-eval-active` loop guard, stamps `.code-eval-reviewed`
  and clears `.code-eval-pending` / `.code-eval-advised` on a clean pass. The five
  intel files are unchanged from v1. `sync` pushes the new block to existing installs.
- **v1** (2026-06-04) — Initial release. Language-agnostic cross-file dead-code,
  duplication, and complexity detection and an adversarial false-positive guard
  set. Three-layer model: pre-write advisor agent, post-write reviewer agent,
  full-codebase sweep.
