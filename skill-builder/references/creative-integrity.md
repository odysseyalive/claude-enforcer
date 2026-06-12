# Creative Integrity — Scrub Loops & AI-Tell Workflow Standards
<!-- Enforcement: HIGH — read by audit Step 4c-bis (Creative-Workflow Integrity Check) and by any command creating or modifying a creative-workflow skill. -->

This file is the canonical standard for **any skill that manages the detect / evaluate / revise
workflow for creative output** (text or images): AI-tell detection, voice validation, scrub loops,
and evaluator-driven regeneration. Audit checks qualifying skills against it **by equivalence**
and builds missing machinery **additively** (§ Audit Policy below); it is never a license to
rewrite hand-authored skills.

It exists because of the 2026-06-11 user directive (SKILL.md § Directives): *"build that scrub
loop for text and images.. and make sure we do research around these topics an explicitely update,
through audit, these mechanisms for any skill that manages this type of workflow"* — followed by
the nine principles preserved verbatim below.

---

<!-- origin: user | added: 2026-06-11 | immutable: true -->
## The Nine Scrub Principles (verbatim)

> **1. Detection philosophy: clustering, not signals**
>
> The single most important principle. Individual signals are not tells; only clustering is. One contrastive negation is craft. Three is a dead giveaway. A validator that flags every parallel construction produces >20% false positives and strips the author's voice (we learned this the hard way — an overcorrected revision destroyed an article's humanity). Severity must follow density, not detection. Enforce thresholds: e.g., contrastive negation MUST FIX at 3+ per piece, ignore at 1.

> **2. Three tiers of tells, three different detection mechanisms**
>
> - Surface tells (vocabulary: "delve," "tapestry," "pivotal"; filler: "it's worth noting"; structural narration: "in this article we'll explore") — grep-able. Put them in hooks/linters. Make them advisory, not blocking, because most words have legitimate uses.
> - Structural tells (four-part paragraph arc, uniform sentence length, bookend callbacks, formulaic paragraphing, symmetrical lists) — need whole-document analysis. An agent pass, not a regex.
> - Compositional tells (the hardest class) — detail latch, manufactured temporal specificity, premature resolution, subtext vacuum, epiphany machine. These require judgment about meaning, survive multiple review rounds, and are what humans actually notice. Budget most of your effort here.

> **3. The subtle tells that survive review**
>
> These slipped past multiple validation rounds in our work and were only caught by a human reading closely:
>
> - Detail latch: AI seizes a concrete noun ("Tuesday," "three") and threads it back 3-5x for fake narrative cohesion. A human varies the reference; AI repeats the literal token because it stays activated in attention.
> - Manufactured temporal specificity: "last Tuesday," "just yesterday" — arbitrary time anchors that simulate lived experience, add nothing to the argument, and expire on contact with a real reader. Test: delete the anchor; if the story still works, it was manufactured.
> - Bookend callbacks: closing that echoes the opening. Template move dressed as craft.
> - Redundant reintroduction: restating an established fact with emphasis words ("a single Tuesday") to disguise repetition as rhetorical weight.

> **4. Fixes introduce new tells**
>
> When we fixed one detail latch, the replacement phrase accidentally echoed a caption elsewhere in the piece. Every fix must be re-validated against the whole document, not just the changed sentence. Build the loop: fix → scan changed passage + grep document for new echoes → re-validate. Cap cycles (we use max 2) to prevent infinite churn.

> **5. Protect the voice, don't just hunt AI**
>
> Calibrate for humanity, not against AI. Optimizing for "doesn't sound like AI" produces worse writing than optimizing for "sounds like a person thinking." Concretely:
>
> - Maintain a documented voice profile. Any flagged pattern that matches a documented voice characteristic gets demoted to advisory — never blocking.
> - Check for positive human markers, not just AI absence: burstiness (sentence-length variance), hedging ("maybe," "I think"), texture words ("too," "actually," "also"), concrete specificity, productive digression, first-person discovery. Strong human markers should raise the threshold for flagging.
> - Never fake imperfections. Fabricated rough edges are themselves a tell (false vulnerability).

> **6. Context-isolated validation**
>
> The agent that evaluates content must not share context with the conversation that created it. The creating session is biased toward approving its own output. Spawn validators with clean context, give them the pattern library and the text, nothing else.

> **7. Severity architecture**
>
> Three tiers (MUST FIX / SHOULD FIX / CONSIDER), with two non-obvious rules: report all blocking flags uncapped but cap advisory flags (3-5), or the agent buries the signal in noise; and any flag that reflects a hard directive is mandatory regardless of its severity tier — severity orders the work, it never excuses skipping it.

> **8. SEO/snippet text conflicts with voice**
>
> Definition sentences for featured snippets read like textbook drops inside personal narrative. The bridge: frame the definition through discovery voice ("That's dynamic model routing. Each task goes to...") rather than cold third-person ("Dynamic model routing sends each task to..."). Extractability survives; the voice break doesn't.

> **9. Keep the pattern library living**
>
> We're at 55 patterns and the user found new ones after two research waves and dozens of fixes. The library is never done. When a human flags something the system missed, the workflow is: name the mechanism, add it as a pattern with an example and a falsifiable test ("delete X; if nothing is lost, it was Y"), then fix the instance. Every pattern needs a test, not just a description — agents apply tests reliably, vibes unreliably.

*— Added 2026-06-11, source: user directive (the nine principles accompanying the scrub-loop build order; transcribed verbatim from the user's message, hard-wrap line breaks joined).*
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.0 | modifiable: true -->
## Scope — which skills qualify

A skill is a **creative-integrity workflow skill** when it manages any leg of the
detect / evaluate / revise cycle for creative output. Identification signals (any one suffices;
when classification is not overtly obvious, the Non-Obvious Decision Gate applies — spawn agents):

1. **Declared creative lane** (frontmatter `lane:` or Skill→Lane table) AND the workflow contains
   evaluation, validation, scrubbing, or generation-with-eval-chaining steps.
2. **Evaluator machinery:** the skill ships evaluator/validator agents (`context: none` Task
   agents) or grounds against an AI-tells / authenticity pattern library.
3. **Scrub machinery:** the skill contains or executes a finishing chain / scrub loop
   (eval → fix → re-validate) or an eval-driven regeneration loop.
4. **Voice machinery:** the skill documents or enforces a voice profile / human-presence markers.

Typical population: text evaluators (`text-eval`-class), image evaluators (`image-eval`-class),
revision gateways (`edit`-class), generators that chain to evaluators (`image`-class), voice and
writing protocol skills. Code evaluators are NOT in scope (they belong to `code-eval`).

## Compliance Checklist (equivalence-aware)

For each qualifying skill, audit checks the principles **by intent, not by canonical phrasing**.
A principle present in the skill's own wording — including inside its own immutable directive
blocks — counts as **SATISFIED**. A criterion the skill's role doesn't touch is **N/A**, not a gap
(an evaluator-only skill needs no regeneration loop; a generator needs no pattern library).

| # | Principle | Satisfied when the skill (in any wording)… |
|---|-----------|--------------------------------------------|
| 1 | Clustering, not signals | scales severity with signal density (single signal ≤ advisory; cluster threshold ≈3 → blocking) and never blocks on an isolated pattern |
| 2 | Three detection tiers | routes surface tells to grep/hooks (advisory), structural tells to whole-document agent passes, compositional tells to judgment-class agent evaluation |
| 3 | Subtle-tell coverage | its pattern library covers the compositional class (detail latch, manufactured temporal specificity, bookend callbacks, redundant reintroduction, premature resolution, subtext vacuum, epiphany machine — or equivalents) |
| 4 | Fix-then-rescan | any fix pass is atomic (all planned fixes in one edit), re-validates the WHOLE document (echo re-scan), and caps cycles (house cap: 2) |
| 5 | Voice protection | demotes flags matching a documented voice characteristic to advisory, checks positive human markers, and never fabricates imperfections |
| 6 | Context isolation | evaluators run as fresh-context subagents (never inline in the creating conversation) |
| 7 | Severity architecture | uses MUST FIX / SHOULD FIX / CONSIDER (or equivalent), reports blocking flags uncapped, caps advisory flags (3-5), and treats hard-directive flags as mandatory regardless of tier |
| 8 | SEO-voice bridge | where the skill produces snippet/definition text inside narrative, it frames definitions through discovery voice |
| 9 | Living pattern library | has an intake path: name the mechanism → add pattern with example + falsifiable test → fix the instance. Every pattern carries a test |

## Canonical Scrub-Loop Spec

The reference design for a compliant scrub loop. Skills may implement it in their own structure;
audit checks for the **non-negotiables** marked ◆ (a missing ◆ is a finding; everything else is
advisory guidance).

**Text (eval → atomic fix → echo re-scan → re-validate):**

1. ◆ **Entry provenance guard.** The loop auto-fixes only AI-drafted, in-session content. Unknown
   or human provenance → evaluate and report only. Never calibration/reference texts, never
   non-prose files.
2. Evaluate via the skill's context-isolated evaluators (principle 6).
3. ◆ **Severity policy.** Auto-fix MUST FIX and hard-directive flags only. SHOULD FIX and CONSIDER
   are presented as advisories (capped 3-5) — the human decides on the rest.
4. ◆ **Atomic fix pass.** Plan all fixes together, apply in one edit. Serial fixes compound drift.
5. ◆ **Echo re-scan.** After the fix pass, grep the whole document for tokens/phrases the fixes
   introduced (detail-latch echoes, caption collisions, new repetition). Fixes introduce new tells.
6. Re-validate (changed passages + document-level echo findings; agents need not re-read the
   unchanged bulk).
7. ◆ **Cycle cap: 2** fix cycles (cycle = eval → fix → re-eval; at most 3 evaluations total).
8. ◆ **Best-so-far + divergence abort.** Snapshot before each fix pass. Score each cycle by
   (blocking-flag count, human-presence score). A cycle with MORE flags or a LOWER human-presence
   score than the best → revert to best-so-far and STOP.
9. ◆ **Humanity floor.** Never ship a version whose human-presence density is below the input's
   baseline. Tell-count reduction never justifies voice-marker loss.
10. Present: before/after, fixes applied, advisories remaining, any abort with its reason.

**Image (generate → eval → targeted regenerate):**

1. ◆ **Fixability classifier.** Before any regeneration, classify each eval flag:
   regeneration-fixable vs NON-FIXABLE (provenance/watermark findings such as SynthID/C2PA, and
   any flag whose remedy is a pipeline change). NON-FIXABLE flags are surfaced to the human —
   never looped on.
2. ◆ **Targeted feedback folding.** Fold fixable flags into the next prompt as targeted
   re-description of the flawed element plus short, specific negatives — never broad negative
   lists. Preserve the eval's stated strengths verbatim in the prompt.
3. ◆ **Set integrity.** When regenerating one image of a set, pin the sibling images' palette
   assignments as constraints (palette lock) so regeneration cannot oscillate against the
   palette-variation rule.
4. ◆ **Cycle cap: 2** regeneration cycles per image; each regeneration is a real API spend.
5. ◆ **Best-so-far keeper.** Keep the best result across cycles and present THAT one — never
   "last output wins" (inter-cycle quality oscillates; verified AR(1) finding, § Research Digest).
6. The evaluator stays advisory and fresh-context; the GENERATOR owns the loop. An evaluator must
   never trigger regeneration itself.

**Both modalities:** ◆ never optimize toward an AI-detector score — detector-guided revision
measurably degrades quality (§ Research Digest). The loop's target is the human craft rubric.

## Audit Policy (Step 4c-bis) — equivalence-aware scan + additive build

Per the 2026-06-11 second clause ("build new skills or funciton within existing skills of the
project to facilitate all these points"), audit BUILDS missing scrub machinery instead of only
deferring it. The build tier is premortem-hardened: every build is strictly additive, and
everything inferential, behavioral, or uncertain stays DEFER. Amended by the 2026-06-12
install-on-absence directive (SKILL.md § Directives): the new-skill scaffold fires on absence
alone (tier 2 below), and pattern-library gap appends are APPLIED rather than deferred
(§ Pattern-Library Gap Check tier 4).

**Hard floors (unchanged by the build tier):**

- **FLAG-NEVER-TOUCH:** a finding whose remediation would intersect an
  `<!-- origin: user | immutable: true -->` block is reported verbatim for the human. Audit never
  edits, inserts into, reorders, or rewrites directive blocks to achieve "compliance."
- **Never reword hand-authored text.** A build adds new files and one dedicated machine-owned
  region; it never edits, reorders, or interleaves the hand-authored workflow body.
- **Equivalence is the bar.** Principle satisfied in different wording = SATISFIED. Mature skills
  predating this file are expected to pass on equivalence; flagging them for phrasing would be the
  shortcut mentality the integrity-over-performance directive forbids.

**BUILD tier (runs in audit's auto-execution phase under the Step 0 consent):**

1. **Build-into-existing.** Eligible only when a qualifying skill's loop leg is **demonstrably
   absent** — a true N/A→absent confirmed by a design panel that read the FULL skill (workflow
   preservation is the highest priority, per the Bespoke Excursion-Agent Gate precedent) — never
   merely when equivalence detection returned negative. **Equivalence-uncertain degrades to
   DEFER, never to BUILD** (a missed equivalence must cost one ignorable row, never a competing
   chain). The build writes: a scrub-chain reference file adapted per skill from § Build
   Scaffolds, plus ONE `CREATIVE-SCRUB-EMBED` pointer region (format below) — a grounding link,
   behaviorally inert until the user or dispatcher invokes the scrub function.
2. **New-skill scaffold (install-on-absence — 2026-06-12 directive, superseding newest-wins
   the 2026-06-11 declared-evidence precondition).** Eligible on **absence alone**: the
   signal-based existence test (§ Build Scaffolds pre-build guards) finds NO skill performing
   the evaluator function, no `text-eval` skill directory exists, and `model-lanes.md` carries
   no `<!-- creative-scrub-build: off -->` marker. Lane declarations do not gate the build —
   an all-coding project receives the evaluator too (the code-evaluator ensure-exists
   precedent, audit.md § Step 4a-bis). The scaffold authors its own `lane: creative`
   frontmatter and never touches the project's Skill→Lane table — declared-never-inferred
   governs classifying EXISTING skills and is untouched. Audit scaffolds the evaluator from
   § Build Scaffolds (Persona Assignment Gate and Audit Agent Model-Assignment Gate apply in
   full; lanes unconfigured → the evaluator agent ships with `model:` absent + flagged, never
   an invented ID; the terminal `route index`/`route embed` tasks register it).
3. **Voice-dependent gates in built scaffolds are advisory-only** when the project has no
   documented voice profile: the humanity floor reports human-presence evidence but never blocks,
   aborts, or reverts on its own (generic English-prose markers misjudge non-English and
   technical content; evidence, not proof, in both directions — § Research Digest).
4. **Atomic-or-absent.** A build that cannot complete its panel/anchor checks writes NOTHING —
   no orphan skill, no half-block — and becomes a DEFER row (matching optimize's
   FAIL→revert→Deferred discipline).
5. **Reconciliation & opt-out.** On later audits, 4c-bis reconciles only its own
   `origin: skill-builder | modifiable: true` regions and scaffold machine bytes — never a
   user-edited seam, never a whole scaffolded skill file (code-eval-grade seam discipline).
   `creative-scrub: off` in a skill's frontmatter opts it out of the build tier entirely.

**Still AUTO (machine-owned bytes):** grounding-link insertion, enforcement-annotation generation
beneath existing directives, and reference-sync of this file itself.

**Still DEFER:** equivalence-uncertain legs; anything requiring the user's wording; behavioral
changes to hand-authored workflows; incomplete builds; gap appends whose structural-fit or
live-grounding guard fails (§ Pattern-Library Gap Check tier 4).

**Research precedence:** pattern-library growth driven by research is coding-lane work
(research-precedence directive, 2026-06-06); drafting replacement prose stays creative-lane.

## Pattern-Library Gap Check (Step 4c-bis; portable-rules transfer, 2026-06-12)

Per the user's portable-text-evaluation request (2026-06-12): the rules for identifying
AI-generated content and overbuilt prose ship in
[creative-integrity/text-tells.md](creative-integrity/text-tells.md) so the same text
evaluation transfers across every project skill-builder is installed in. Audit Step 4c-bis
compares each qualifying skill's text pattern library against that shipped catalog and proposes
the missing pieces — additively, legibly, and once.

1. **Scope.** Fires only for qualifying skills (§ Scope) that carry a text AI-tells pattern
   library. Skills with `creative-scrub: off` frontmatter are excluded entirely. Image
   evaluators are out of scope (no shipped image catalog).
2. **Baseline & version.** Read the shipped anchor
   [creative-integrity/version.md](creative-integrity/version.md) (cheap integer read), then
   the catalog itself only when a comparison will actually run.
3. **Equivalence both directions, mechanism-keyed.** A shipped pattern counts as COVERED when
   ANY pattern already in the skill's library shares its underlying mechanism — different
   naming, wording, or grouping is still covered (catalog granularity must never manufacture
   gaps: e.g., a library carrying "contrastive negation" covers the shipped row even if it
   lacks the separate "contrastive inversion" name, unless the mechanisms demonstrably
   differ). Only a **demonstrably absent** mechanism produces a finding. Equivalence-uncertain
   → **silently skipped** — never a row, never an append (skipping a maybe-gap costs nothing;
   a false gap costs double-counting and over-correction, the exact harm principles 1 and 5
   guard against).
4. **Tiering (2026-06-12 install-on-absence directive, second clause: updates are APPLIED,
   never offered):**
   - **AUTO append** into the machine-owned (`origin: skill-builder | modifiable: true`)
     region of a scaffold-generated library — never into a user-edited seam. Appended rows
     carry the shipped example + falsifiable test and are re-deduped against the full library
     immediately before the write.
   - **Hand-authored libraries → AUTO append** into ONE machine-owned
     (`origin: skill-builder | modifiable: true`) appendix region at the END of the library
     file — existing bytes never modified, never reworded, never re-tiered; the hand-authored
     rows remain the authority and the appendix is additive candidates only. Three guards,
     each degrading to a paste-ready DEFER row (one per skill, quoting the exact proposed
     additions) — never a question, never a silent skip:
     - **(a) structural fit:** the appendix must match the library's own structure (same
       table shape, or a clearly delimited section in a prose library); no parseable fit →
       DEFER (atomic-or-absent applies to appends too).
     - **(b) live grounding:** the skill's evaluator must demonstrably ground against the
       full library file, so the appendix is read rather than an inert supplement (the
       inert-sidecar lesson, DEC-2026-06-08); an evaluator grounding against a fixed
       structure that excludes the appendix → DEFER.
     - **(c) sole dedup authority:** `.scrub-gaps.acked` governs — an acked slug is never
       re-appended, even when mechanism-equivalence misses a user-moved or user-renamed row
       (re-append loops would inflate cluster density, the exact harm principle 1 guards
       against).
5. **Report-once semantics (ack sidecar).** After surfacing a skill's gap findings once, write
   or refresh a machine-owned `.scrub-gaps.acked` sidecar in that skill's directory listing the
   surfaced pattern slugs and the shipped version they were surfaced at. Subsequent audits
   suppress every acked slug until the shipped catalog's entry for it materially changes in a
   newer version. The gap check must never become a permanent row the user trains themselves
   to skip.
6. **Additive only, defaults never override directives.** The check proposes additions FROM
   the shipped catalog only. It never proposes removals, rewording, re-tiering, or demotions of
   a project's patterns — in particular it never suggests relaxing a project's hard-directive
   elevations (em-dashes, rhetorical colons, client language) toward the catalog's
   cluster-density defaults.
7. **Reverse flow is intake, not sync.** Patterns a project adds locally (principle 9) are the
   project's own. Promoting one INTO the shipped catalog is maintainer work in this repo (a
   `dev` edit + version bump), never an audit action in a user project.
8. **Forced upgrade on catalog growth (2026-06-12 directive, third clause: "we may be adding
   more 'signs' to flag in the future, so everything will need to be forceably upgraded").**
   The shipped catalog is a living, growing rule set, and growth propagates forcibly: whenever
   the shipped version anchor is newer than the version a qualifying skill's library was last
   checked against (the version recorded in its `.scrub-gaps.acked` sidecar, or the
   `creative_scrub_ref_version:` stamp of a scaffold-generated skill), audit MUST run the gap
   comparison and apply its AUTO tiers in that same run — never skipped, never offered as
   optional work, never a question. Scaffold-generated libraries' machine-owned regions are
   additionally version-synced to the current catalog (the code-eval `sync` discipline:
   machine bytes refresh, user-edited seams preserved). The ack sidecar suppresses ONLY slugs
   whose shipped entry is unchanged — a new sign is never acked, so it always lands; a
   materially-changed acked entry re-surfaces per tier 5. The three guards of tier 4 still
   apply per append; a guard failure still degrades to a paste-ready DEFER row, refreshed with
   the new catalog content.

## Build Scaffolds (used by the BUILD tier; panel-adapted per skill, never copied blind)

**1. CREATIVE-SCRUB-EMBED pointer region** — the ONLY thing a build inserts into an existing
SKILL.md, placed after the skill's directives/annotations, never inside the workflow body:

```markdown
<!-- CREATIVE-SCRUB-EMBED START — auto-generated by /skill-builder audit (Step 4c-bis); safe to replace -->
<!-- origin: skill-builder | modifiable: true -->
## Scrub Loop (pointer)

This skill participates in the bounded AI-tell scrub loop (Nine Scrub Principles,
`.claude/skills/skill-builder/references/creative-integrity.md`). When a scrub is requested,
the calling session executes [references/<scrub-chain-file>.md](references/<scrub-chain-file>.md).
Scrubbing is invoked, never automatic: this pointer adds no gate to the workflow above.
<!-- /origin -->
<!-- CREATIVE-SCRUB-EMBED END -->
```

**2. Text scrub-chain reference scaffold** — written into the target skill's `references/` as a
new file; the panel adapts names/anchors to the skill's own evaluators and content types. It MUST
carry every ◆ item of § Canonical Scrub-Loop Spec (text): entry provenance guard → evaluate via
the project's context-isolated evaluators → triage (auto-fix MUST FIX + hard-directive only;
advisories human-decided) → snapshot → ONE atomic fix pass → whole-document echo re-scan →
re-validate → divergence abort to best-so-far → humanity floor (advisory-only absent a voice
profile, per Build Policy 3) → cycle cap 2 → present with cycle history. The reference
implementation to adapt is this repo's `text-eval/references/finishing-chain.md`.

**3. Image scrub-chain scaffold** — for generator skills chaining to an image evaluator: the
◆ items of § Canonical Scrub-Loop Spec (image): fixability classifier (provenance/watermark =
NON-FIXABLE, surfaced never looped) → targeted feedback folding (strengths preserved verbatim,
short specific negatives, palette/set lock) → regenerate → re-eval → best-so-far keeper → cap 2.

**4. Evaluator-skill scaffold** (new-skill path; default name **`text-eval`**) — a lean
evaluator with: frontmatter (`lane: creative`, read-only tools + Task, and a
`creative_scrub_ref_version:` stamp matching the shipped anchor in
[creative-integrity/version.md](creative-integrity/version.md)), a directives section seeded as
`origin: skill-builder | modifiable: true` (NEVER seeded as `origin: user` — audit does not
author user directives; the user may ratify/inline their own later), one context-isolated
evaluator agent (unique persona; `model:` stamped from the configured creative lane — lanes
unconfigured → `model:` absent + flagged, never an invented ID, per the Audit Agent
Model-Assignment Gate), a pattern
library seeded from the shipped portable catalog
[creative-integrity/text-tells.md](creative-integrity/text-tells.md) (the catalog's `[hard]`
rows keep their blocking defaults — mechanical defects and factual-integrity failures; every
other seeded severity is advisory until a documented voice profile exists, extending Build
Policy 3 to the whole seeded library), the three-tier severity architecture, cluster-density
severity with dedupe-by-mechanism, and the human-presence check in advisory mode. The scaffold
ships working but conservative; tightening it into a blocking gate is a deliberate user act.

**Pre-build guards (all mandatory; atomic-or-absent applies):** (a) the "no evaluator skill
exists" eligibility test is **signal-based, never name-based** — any skill tripping a § Scope
signal (evaluator agents, AI-tells pattern library, scrub/finishing-chain machinery) counts as
the project's evaluator regardless of its name, and suppresses the build; (b) **name-collision
guard** — if a skill directory named `text-eval` already exists, never build; the project
already has one, so the finding degrades to a DEFER row, never a second skill (duplicate skill
names are a completion-breaking conflict per reconcile's collision table); (c) **project
opt-out** — a `<!-- creative-scrub-build: off -->` marker in `references/model-lanes.md` (the
same update-preserved, per-project mechanism as the setup-state markers) silently suppresses
the new-skill build: a declarative opt-out, never a question (2026-06-12 directive's
panel-adopted guard).

## Research Digest (2026-06-11 — coding-lane research waves)

Parameters and findings the canonical spec encodes. Sources verified at research time; re-verify
before treating any number as current.

**Loop dynamics:** Self-refinement gains front-load in cycles 0-1 and plateau by ~3-4
(Self-Refine, arXiv 2303.17651; HITL convergence study, arXiv 2603.09995: ~90% of items converge
by iteration 1). Uncapped self-evaluated loops overcorrect against the model's own criteria.
Image iteration quality oscillates between cycles (negative AR(1); IJCAI 2025, arXiv 2504.20340)
— hence best-so-far keepers, divergence aborts, and the cap of 2.

**Validator bias:** Models score their own output higher (self-preference scales with
self-recognition; arXiv 2404.13076, 2410.21819) — fresh-context validation is necessary;
different-family validation is stronger where affordable. Models repair errors whose location is
supplied but cannot reliably find locations themselves — pin the flaw inventory externally across
cycles instead of re-finding from scratch.

**False positives:** Detectors false-flag plain human voice (61.3% → 11.6% by vocabulary
elaboration, Liang et al.) — burstiness/hedging are evidence, not proof, in BOTH directions.
Detector-guided paraphrasing evades detection (~88%) at measured quality cost (NeurIPS 2025,
arXiv 2506.07001) — never tune toward a detector score.

**Text patterns: graduated to the shipped catalog** (2026-06-12). The candidate text-pattern
list that previously lived here — and the 2026-06-12 research wave's additions (markdown/heading
tells, pipeline-artifact residue, chat-frame/sycophancy leakage, corpus-level tells such as
elegant variation, generic-name default, source-count inflation, intra-author style shift) — is
curated, each entry with example + falsifiable test, in
[creative-integrity/text-tells.md](creative-integrity/text-tells.md). That catalog is the single
seed source for evaluator scaffolds and the baseline for § Pattern-Library Gap Check; this
digest holds research findings, not the library. Sources: StoryScope arXiv 2604.03136; Wikipedia
WP:AISIGNS (fetched 2026-06-12); Pangram "Spotting AI Writing Patterns" (fetched 2026-06-12);
UCC/Nature HSSC; IEEE Spectrum / Nature on sycophancy (2025).

**Candidate image tells:** waxy/plastic surface sheen; object-boundary bleed at semantic
boundaries (never within a wash — watercolor wet-in-wet is authentic); reflection/mirror
inconsistency; functional implausibility (slack strings, impossible grips); non-extremity body
proportion errors; missing/unlocatable light source (distinct from contradictory light);
architectural perspective failure; sociocultural implausibility; SynthID/C2PA provenance
(NON-FIXABLE class). Source: CHI 2025, arXiv 2502.11989; DeepMind SynthID.

## Pattern-Intake Protocol (principle 9, operationalized)

When a human flags a miss:

1. **Name the mechanism** — why the model produces it, not just what it looks like.
2. **Add the pattern** to the owning skill's library: name | example | mechanism | falsifiable
   test ("delete X; if nothing is lost, it was Y" style). A pattern without a test is not done.
3. **Fix the instance** that prompted the report.
4. **Re-check the cluster rule** — new patterns enter as signals; only clustering changes severity.

## Grounding

- SKILL.md § Directives → the 2026-06-11 scrub-loop directive and Creative-Integrity Gate
- [creative-integrity/text-tells.md](creative-integrity/text-tells.md) — the shipped portable
  AI-text-signature catalog (seed source for evaluator scaffolds; baseline for § Pattern-Library
  Gap Check)
- [creative-integrity/version.md](creative-integrity/version.md) — drift anchor for the shipped
  creative-integrity reference set
- [model-lanes.md](model-lanes.md) — lane declarations that feed § Scope signal 1
- [lane-delegation.md](lane-delegation.md) — research-precedence delegation for library growth
- [procedures/audit.md](procedures/audit.md) § Step 4c-bis — the audit consumer of this file
<!-- /origin -->
