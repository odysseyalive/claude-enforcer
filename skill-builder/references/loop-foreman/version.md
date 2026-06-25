<!-- loop-foreman-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# loop-foreman reference set — drift anchor

This file is the version anchor for the shipped `loop-foreman` intel set
(`skill-template.md`, `workflow-recipe.md`, `grader-rubric.md`). When `loop-foreman create`
scaffolds the companion skill it copies those references verbatim and stamps the generated
SKILL.md frontmatter with `loop_foreman_ref_version: 1`. A future `loop-foreman sync` (deferred to
a later increment) compares this integer against the installed copy's frontmatter and refreshes
the `origin: skill-builder | modifiable: true` regions when this number is higher — the same
drift-sync discipline `code-eval sync` uses.

Bump this integer whenever any shipped loop-foreman reference changes in a way installed copies
should pick up.

## Changelog

- **1** (2026-06-25): initial ship. Work-order entry gate, dual-check grader (mechanical oracle +
  fresh-context reasoning grader), research-assistant-on-demand for knowledge-gap feedback, and the
  bounded worker→grader→consensus recipe importing the Canonical Scrub-Loop ◆ bounds (cycle cap,
  best-so-far + divergence abort, escalate-the-disagreement). See ledger
  DEC-2026-06-25-loop-foreman-design.
