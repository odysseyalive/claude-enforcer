<!-- code-eval-ref-version: 3 -->
<!-- origin: skill-builder | modifiable: true -->
# Mistake Taxonomy — what an AI coder commonly gets wrong

The checklist of issue classes the code-evaluator looks for. The first group is
the classic codebase-intelligence taxonomy (dead code, duplication, complexity)
restated language-agnostically; the second group is AI-specific anti-patterns —
the mistakes a language model tends to introduce that the post-write reviewer
(L2) and the pre-write advisor (L1) exist to catch.

For each: **what** it is, **why** it matters, and the **signal** to detect it.
Detection method lives in [cross-file-detection.md](cross-file-detection.md);
false-positive guards live in [guards.md](guards.md).

## Group 1 — Structural (the classic taxonomy)

| Class | What | Why it matters | Signal |
|-------|------|----------------|--------|
| **Unused files** | Files unreachable from any entry point | Dead weight; confuses readers; rots | no import of the file's module path (§2.3) after barrel resolution |
| **Unused exports/symbols** | Exported but never imported | False public surface; blocks refactors | 0 cross-file refs, guards cleared |
| **Unused types** | Type aliases/interfaces never referenced | Noise in the type surface | 0 refs in type positions |
| **Unused dependencies** | Declared in manifest, never imported | Slower installs, larger attack surface | package name absent from all imports (and from scripts) |
| **Unlisted dependencies** | Imported but missing from the manifest | Breaks on clean install | import of a package not in deps |
| **Unused members** | Enum values / class methods never used | Dead branches; misleading API | member name 0 refs (respect dynamic dispatch — [guards.md](guards.md) #7) |
| **Duplicate code** | Copy-pasted / near-identical logic | Bugs fixed in one copy, not the others | repeated literal/structural blocks (§4) |
| **Circular dependencies** | Import cycles in the module graph | Fragile init order; hard to test | A imports B imports A |
| **Re-export cycles** | Barrels re-exporting each other in a loop | Imports silently come up empty | barrel chain returns to itself |
| **Complexity hotspots** | High cyclomatic/cognitive functions | Bug-prone, untestable | decision-point density, nesting, length (§5) |
| **Complex × untested** | High complexity + low coverage (CRAP) | Where defects concentrate | complex function with no test reference |
| **Stale suppressions** | Ignore comments that no longer match | Hide issues that returned | suppression with no corresponding finding |

## Group 2 — AI-specific anti-patterns

| Class | What | Why it matters | Signal |
|-------|------|----------------|--------|
| **Reinvented helper** | New function duplicating an existing util | The codebase already solved this | before writing, grep for an existing symbol doing the same job |
| **Reinvented stdlib/native** | Hand-rolled what the standard library or platform already ships | Bugs + maintenance for an already-solved problem; flimsier than the builtin | a custom impl of a documented stdlib/native feature (date parse, dict-from-pairs, email check, `<input type="date">` over a picker lib, CSS over JS) |
| **Needless new dependency** | A new dependency added for what a few lines, an installed dep, or a native feature already cover | Install weight, attack surface, lock-file churn | a new manifest entry whose job stdlib / native / an existing dep already does (moment.js for one format call → `Intl.DateTimeFormat`) |
| **Speculative existence (YAGNI)** | Code written for a need that is not real yet | Dead flexibility; unreviewable scope; rots unused | a feature, branch, parameter, or config with no current caller or stated requirement — "for later" with no today |
| **Leftover scaffolding** | Debug prints, TODO stubs, commented-out code, unused locals from an abandoned approach | Ships noise and confusion | `console.log`/`print`/`dbg!`, `TODO`/`FIXME`, commented code blocks, unused vars |
| **Over-abstraction** | Premature generic/indirection for one caller | A wrong abstraction costs more than duplication | single-caller interface/factory/wrapper added "for flexibility" |
| **Pattern drift** | New code ignores the file's established idiom | Inconsistency erodes readability | the surrounding code does X one way; the new code does it another |
| **Unused imports** | Imports added then not used | Lint noise; misleads readers | imported name 0 refs in the file |
| **Dead export from new code** | Exported a symbol nothing imports | False API surface from the start | new export, 0 cross-file refs |
| **Silent breadth** | Broadened a change beyond the task (bonus edits) | Unreviewable diffs; scope creep | diff touches files unrelated to the stated task |
| **Copy-paste-and-tweak** | Cloned a block and edited a few tokens | The clones drift apart | near-identical sibling blocks/files (§4) |
| **Swallowed errors** | `catch {}` / bare `except: pass` added | Hides failures | empty catch/except introduced |

## The minimalism escalation ladder (prevention order — L1)

The three "reinvented / needless / speculative" classes above are best prevented,
not detected after the fact. Before writing code, the advisor walks an ordered
ladder and stops at the first rung that holds — but only *after* reading the task
and tracing the real flow the change touches (laziness shortens the solution,
never the comprehension):

1. **Does this need to exist at all?** Speculative need → skip it (YAGNI).
2. **Already in this codebase?** A helper/util/type/pattern → reuse, don't rewrite.
3. **Stdlib does it?** Use it.
4. **Native platform feature covers it?** Use it before a dependency.
5. **Already-installed dependency solves it?** Use it before adding a new one.
6. **Can it be one line?** One line.
7. **Only then:** the minimum code that works.

Two rungs work → take the higher one. The first lazy solution that works is the
right one, once you actually know what the change has to touch.

## Minimalism safety floor (NEVER on the chopping block)

Minimalism is about cutting what is *not needed*, never what is *necessary*. The
ladder and the over-engineering classes above MUST NOT recommend removing or
skipping any of these — flagging one of them as "over-built" is itself a defect:

- input validation at trust boundaries;
- error handling that prevents data loss;
- security measures;
- accessibility basics;
- anything the user explicitly requested.

A deliberate, knowingly-bounded simplification carries an intent marker naming its
ceiling and upgrade path (e.g. `// code-eval: global lock, per-account if
throughput matters`) — see [guards.md](guards.md) #21; do not re-flag a marked
shortcut as a finding.

## Over-engineering evaluation (rubric + self-calibration — L2/L3)

Dead code is a closed-world reference count; over-engineering is a *judgment*. So
the post-write reviewer and the sweep score it on a fixed rubric and
**self-calibrate before trusting their own read** — the discipline a measurement
harness gets from a validated judge, re-expressed as an in-skill gate (no external
tooling, no scoring scripts).

**Rubric — score each over-engineering candidate 0–3 on structure beyond what the
task needs** (ignore correctness, style, performance, security — those are other
passes):

- **0** — minimal, appropriate to the task.
- **1** — slightly more structure than needed.
- **2** — noticeably over-built: an unneeded class / abstraction / config / flexibility.
- **3** — clearly over-engineered: speculative generality, a framework for a one-off.

Every score ≥1 MUST name the single most unnecessary construct (`file:line`); a
clean read names **"none."** Forcing cite-or-"none" stops vague hedging and keeps
the finding actionable. Only scores ≥2 are reported (tagged
`delete/stdlib/native/yagni/shrink`); 0–1 pass silently.

**Never scored as over-engineering:** a test file, or a single runnable in-file
self-check (a `__main__` guard / `demo()` / one `test_*`). Writing a check is good
practice, not bloat — exclude it from the count, never flag it for deletion (this
is the safety floor applied to scoring).

**Self-calibration — score this known pair FIRST; your read is trustworthy only if
it separates them:**

- *minimal (expect 0):* `@lru_cache(maxsize=1000)` on the fetch function.
- *over-built (expect 3):* a hand-rolled `ComputeCache` class with TTL, LRU
  eviction, and hit/miss stats standing in for that one decorator.

If your scoring does not rank the over-built snippet strictly above the minimal
one, your read is miscalibrated — recheck the rubric before scoring the diff, and
down-tier anything you are unsure of (a false "over-built" on necessary structure
is worse than a missed cleanup).

## How the layers use this taxonomy

- **L1 advisor (pre-write):** focuses on Group 2 prevention — walks the
  minimalism escalation ladder above (YAGNI → reuse → stdlib → native → installed
  dep → one line), checks for an existing helper before a new one is written,
  warns about over-abstraction and pattern drift, flags would-be circular deps in
  the planned approach, and honors the minimalism safety floor.
- **L2 reviewer (post-write):** runs the full Group 1 + Group 2 checklist against
  the diff via [cross-file-detection.md](cross-file-detection.md), self-calibrates
  and scores over-engineering on the rubric above, tiers findings, and applies only
  HIGH-confidence, guard-cleared fixes (over-engineering is report-only, never
  auto-fixed).
- **Sweep (full codebase):** Group 1 across the whole tree, plus a report-only
  over-engineering pass on the same rubric, at scale.
