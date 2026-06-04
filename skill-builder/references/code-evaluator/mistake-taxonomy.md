<!-- code-eval-ref-version: 1 -->
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
| **Leftover scaffolding** | Debug prints, TODO stubs, commented-out code, unused locals from an abandoned approach | Ships noise and confusion | `console.log`/`print`/`dbg!`, `TODO`/`FIXME`, commented code blocks, unused vars |
| **Over-abstraction** | Premature generic/indirection for one caller | A wrong abstraction costs more than duplication | single-caller interface/factory/wrapper added "for flexibility" |
| **Pattern drift** | New code ignores the file's established idiom | Inconsistency erodes readability | the surrounding code does X one way; the new code does it another |
| **Unused imports** | Imports added then not used | Lint noise; misleads readers | imported name 0 refs in the file |
| **Dead export from new code** | Exported a symbol nothing imports | False API surface from the start | new export, 0 cross-file refs |
| **Silent breadth** | Broadened a change beyond the task (bonus edits) | Unreviewable diffs; scope creep | diff touches files unrelated to the stated task |
| **Copy-paste-and-tweak** | Cloned a block and edited a few tokens | The clones drift apart | near-identical sibling blocks/files (§4) |
| **Swallowed errors** | `catch {}` / bare `except: pass` added | Hides failures | empty catch/except introduced |

## How the layers use this taxonomy

- **L1 advisor (pre-write):** focuses on Group 2 prevention — checks for an
  existing helper before a new one is written, warns about over-abstraction and
  pattern drift, flags would-be circular deps in the planned approach.
- **L2 reviewer (post-write):** runs the full Group 1 + Group 2 checklist against
  the diff via [cross-file-detection.md](cross-file-detection.md), tiers findings,
  and applies only HIGH-confidence, guard-cleared fixes.
- **Sweep (full codebase):** Group 1 across the whole tree, report-only at scale.
