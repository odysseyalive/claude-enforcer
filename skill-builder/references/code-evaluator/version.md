<!-- code-eval-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# code-evaluator reference version

This file is the **drift anchor**. `skill-builder audit` reads the integer below
(skill-builder's *shipped* reference version) and compares it to the
`code_eval_ref_version` recorded in a user's generated `code-evaluator` skill
(its SKILL.md frontmatter). Shipped > recorded → the user's references are stale
→ audit's drift-sync refreshes the skill-builder-owned (`modifiable: true`)
reference blocks in the user's copy, preserving any `origin: user` seams.

```
code-eval-ref-version: 1
```

Bump this integer whenever ANY file under `references/code-evaluator/` changes in
a way users should receive. Every shipped reference file also carries a matching
`<!-- code-eval-ref-version: N -->` header on its first line; keep them in sync
with this number so a per-file check is possible.

## Changelog

- **v1** (2026-06-04) — Initial release. Language-agnostic cross-file dead-code,
  duplication, and complexity detection and an adversarial false-positive guard
  set. Three-layer model: pre-write advisor agent, post-write reviewer agent,
  full-codebase sweep.
