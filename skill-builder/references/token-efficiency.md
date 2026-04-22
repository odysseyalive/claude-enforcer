# Token Efficiency Reference

This file documents the token-intensive patterns that `/skill-builder optimize` scans for during Display Mode step 4e (Token Efficiency Scan), and the proposals and templates for each. On Opus 4.7 every tool call and every agent spawn has a material token cost, so patterns that looked reasonable under 4.6 can add up to substantial waste over many invocations. The scan is on-by-default inside `/skill-builder audit` and `/skill-builder optimize [skill]`.

## Detection Patterns

Each pattern below has three fields:

- **Detection rule.** Deterministic check performed during Display Mode. No agent spawn needed to detect the pattern.
- **Proposal.** What the optimize Execute Mode task will do to apply the fix.
- **Tradeoff.** What semantic capability is lost (if any) in exchange for the savings.

---

### P1: Agent-type hook doing mechanical work

**Detection rule.** In the skill's SKILL.md frontmatter or settings.local.json, find any `type: agent` hook entry. Read its `prompt` field. Flag as mechanical if the prompt is dominated by verbs such as: "extract X and compare", "grep for pattern Y", "check if field Z matches", "find all files matching glob", "read file and verify marker count". These are all pattern-match or byte-comparison operations that a shell script can do deterministically.

**Proposal.** Rewrite as `type: command` pointing at a shell script under `hooks/`. The script runs on every tool call (cheap), blocks via exit 2 for exact matches, and surfaces near-matches or judgment cases via `additionalContext` with a suggestion to run an explicit agent-driven audit (e.g., `/skill-builder agents --deliberate`).

**Tradeoff.** The agent catches paraphrase and semantic edge cases; the command does not. Paraphrase detection moves out of the always-on hot path into an explicit opt-in audit. For most skills this is a strict win because the hot path fires on every edit, while paraphrase audits happen once in a while.

**Template location.** See [shell-safety/templates.md](shell-safety/templates.md) § T2 (blocking) and § T1 (advisory). See also `skill-builder/hooks/check-persona-uniqueness.sh` and `skill-builder/hooks/verify-directive-integrity.sh` as worked examples.

---

### P2: `xhigh` effort level without a content-creation profile

**Detection rule.** The skill's frontmatter sets `minimum-effort-level: xhigh` AND the skill fails the content-creation profile check from [procedures/optimize.md](procedures/optimize.md) step 3 (none of the content-creation indicators fire: no voice/tone/style directives, no articles/posts/drafts output, not in the content-creation skill list).

**Proposal.** Downgrade to `minimum-effort-level: high`. On 4.7, `xhigh` costs roughly 2x to 3x the tokens of `high` per invocation. `high` is sufficient for skills that spawn agents, invoke hooks, or depend on grounding reads. `xhigh` is only justified for content-creation workflows where the output quality delta is observable.

**Tradeoff.** For lookup or format-check skills there is effectively no tradeoff. For borderline skills (e.g., analytical workflows that produce long structured output), the author may want to keep `xhigh` for parts of the flow; in that case Phase 6's `strictness: thorough` is a better signal than a skill-wide effort pin.

---

### P3: SKILL.md oversized with stable skill-builder machinery

**Detection rule.** The skill's SKILL.md exceeds 150 lines AND contains more than 30 lines of `<!-- origin: skill-builder | ... modifiable: true -->` content that does not reference user directives directly (i.e., stable machinery that documents skill-builder convention rather than user rules).

**Proposal.** Move the stable machinery into a single `references/principles.md` (or a domain-specific reference file) loaded only when high-risk commands run. Replace the moved content in SKILL.md with a one-paragraph pointer. See `skill-builder/references/principles.md` as the worked example from the 4.7 upgrade: it trimmed SKILL.md from 313 to 249 lines without changing any observable behavior.

**Tradeoff.** Content the always-loaded SKILL.md used to carry is now one file-read away. In practice this is fine because skill-builder's machinery is only consulted during high-risk command runs, and those commands already grounded against reference files.

---

### P4: Always-spawned validator with no precheck gate

**Detection rule.** In the skill's Execute Mode procedures, find any step that unconditionally spawns a validator agent (Task tool, `context: none` agent, or similar) without a deterministic precheck step immediately before it. Typical shape: "After all tasks complete, spawn the X-auditor agent to verify Y."

**Proposal.** Insert a precheck step that compares pre/post state deterministically (git show, byte-compare, line-count delta, regex presence). If the precheck passes, mark PASS and skip the agent spawn. The agent fires only when the precheck is inconclusive (ambiguous diff, semantic judgment needed, mixed-content operation).

**Template.** See [procedures/optimize.md](procedures/optimize.md) step 5b and [procedures/convert.md](procedures/convert.md) step 11 as worked examples. Both convert a previously unconditional spawn into a precheck-gated spawn.

**Tradeoff.** For trivial diffs (annotations appended outside sacred blocks, frontmatter additions), the agent verification becomes redundant with the precheck. No semantic coverage is lost because the agent still runs on genuinely ambiguous diffs.

---

### P5: Missing `strictness` frontmatter field

**Detection rule.** (Applies once Phase 6 of the 4.7 upgrade lands.) The skill's frontmatter lacks a `strictness:` field.

**Proposal.** Add `strictness: standard` as the default. Note to the skill author that `minimal` (command hooks only, no agent panels, precheck-gated diff auditor) is appropriate for token-sensitive projects; `thorough` (always-spawn diff auditor, mandatory agent panels) is appropriate for correctness-sensitive skill-builder work against sensitive skills.

**Tradeoff.** None at the default. The field lets users opt up or down per-skill; its absence is silently equivalent to `standard` today, so adding it is additive.

---

## Scan Output Template

When step 4e runs, append this block to the per-skill audit output:

```
**Token Efficiency:**
- Hooks: [N] agent-type, [N] command-type
  Downshift candidates: [list each agent hook with a one-line characterization of what it checks and whether the check is mechanical]
- Effort: [current level] (profile: [content-creation / analytical / lookup]; recommended: [level])
- Always-loaded SKILL.md size: [N] lines (stable-machinery content: [N] lines; target: <150 total, <30 machinery)
- Always-spawned validators: [list each validator with its procedure step]
- Strictness field: [present with value / missing]
- Estimated per-invocation savings if all applied: ~[N] tokens
```

If no patterns fire, emit a single line: `Token efficiency: clean (no patterns flagged).`

---

## Execute Mode Task Generation

When `/skill-builder optimize [skill] --execute` runs, convert each flagged pattern into a task on the list:

- **P1 task.** One task per agent hook flagged. Task title: `Downshift agent hook [hook-name] to command-type`. Body: the script template to write plus the frontmatter edit.
- **P2 task.** Single task: `Downgrade minimum-effort-level from xhigh to high`. Applies to the frontmatter edit.
- **P3 task.** Single task: `Move stable machinery sections [list] to references/principles.md`. Body mirrors the principles.md-extraction pattern from the 4.7 upgrade.
- **P4 task.** One task per always-spawned validator. Task title: `Add mechanical precheck gate to [step reference]`. Body: the precheck template from [procedures/convert.md](procedures/convert.md) step 11.
- **P5 task.** Single task: `Add strictness: standard to frontmatter`. One-line insert.

Execute-mode scope discipline still applies: do only the tasks on the list, note additional opportunities in the completion report rather than acting on them.

---

## Grounding

- [shell-safety/templates.md](shell-safety/templates.md) — hook script templates for P1 downshifts
- [procedures/optimize.md](procedures/optimize.md) step 3 — content-creation profile indicators used by P2
- [procedures/principles.md](principles.md) — worked example for P3 slim-down
- [procedures/optimize.md](procedures/optimize.md) step 5b and [procedures/convert.md](procedures/convert.md) step 11 — worked examples for P4 precheck gating
- [templates.md](templates.md) § "Frontmatter Requirements" — strictness field definition (Phase 6)
- [patterns.md](patterns.md) § "Token efficiency as an optimization target" — rationale and lessons learned
