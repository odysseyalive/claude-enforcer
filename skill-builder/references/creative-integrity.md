# Creative Integrity — Scrub Loops & AI-Tell Workflow Standards
<!-- Enforcement: HIGH — read by audit Step 4c-bis (Creative-Workflow Integrity Check) and by any command creating or modifying a creative-workflow skill. -->

This file is the canonical standard for **any skill that manages the detect / evaluate / revise
workflow for creative output** (text or images): AI-tell detection, voice validation, scrub loops,
and evaluator-driven regeneration. Audit checks qualifying skills against it **by equivalence and
report-only** (§ Audit Policy below); it is never a license to rewrite hand-authored skills.

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
everything inferential, behavioral, or uncertain stays DEFER.

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
2. **New-skill scaffold.** Eligible only on **declared evidence**: the project has at least one
   skill with a DECLARED creative lane (frontmatter `lane:` or Skill→Lane table — declared,
   never inferred, per the Creative-Scope Classification Gate) that produces content, and no
   evaluator skill exists to chain to. Audit then scaffolds the evaluator from § Build Scaffolds
   (Persona Assignment Gate and Audit Agent Model-Assignment Gate apply in full; the terminal
   `route index`/`route embed` tasks register it). A project whose "creative" classification is
   only inferred → DEFER row with the exact `/skill-builder new` command, never an auto-build.
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

**Still DEFER:** equivalence-uncertain legs; inferred-only creative projects; anything requiring
the user's wording; behavioral changes to hand-authored workflows; incomplete builds.

**Research precedence:** pattern-library growth driven by research is coding-lane work
(research-precedence directive, 2026-06-06); drafting replacement prose stays creative-lane.

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

**4. Minimal evaluator-skill scaffold** (new-skill path) — a lean evaluator with: frontmatter
(`lane: creative`, read-only tools + Task), a directives section seeded as
`origin: skill-builder | modifiable: true` (NEVER seeded as `origin: user` — audit does not
author user directives; the user may ratify/inline their own later), one context-isolated
evaluator agent (unique persona; `model:` stamped from the configured creative lane), a starter
pattern library drawn from the generic entries of § Research Digest's candidate lists plus the
universal patterns (each with example + falsifiable test; voice-specific tests omitted until a
voice profile exists), the three-tier severity architecture, cluster-density severity, and the
human-presence check in advisory mode. The scaffold ships working but conservative; tightening
it into a blocking gate is a deliberate user act.

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

**Candidate text patterns** (intake per principle 9 — each needs example + falsifiable test when
added to a library): theme over-explanation; single-track tidy plotting; moral-ambiguity
flattening; negative parallelism (false-misconception framing); legacy/undue-emphasis framing;
listicle-in-disguise (uniform bold-header-colon rhythm); sentence-frame openers; knowledge-cutoff
disclaimers; **cross-document uniformity** (corpus-level: successive outputs converging to one
structural shape — single-document validators cannot see it; a sibling-comparison pass can).
Sources: StoryScope arXiv 2604.03136; Wikipedia WP:AI signs; UCC/Nature HSSC.

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
- [model-lanes.md](model-lanes.md) — lane declarations that feed § Scope signal 1
- [lane-delegation.md](lane-delegation.md) — research-precedence delegation for library growth
- [procedures/audit.md](procedures/audit.md) § Step 4c-bis — the audit consumer of this file
<!-- /origin -->
