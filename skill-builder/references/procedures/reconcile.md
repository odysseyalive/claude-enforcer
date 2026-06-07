## Reconcile Command Procedure

**Cross-skill conflict detection and integrity-preserving remediation.** Where `cascade` looks *inside* one skill for over-suppression, `reconcile` looks *across* skills for collisions that make a skill silently fail to run, misfire, or get overwritten — and resolves only the ones that are mechanically safe, routing everything else to a human.

**Governing directive (sacred — see SKILL.md § Directives):**

> *"It shouldn't make any decisions based on performance, but the full completion of integrity of skills expected to be performed by the user. Don't make decisions based on 'shortcut' mentality."*

What this means operationally, and overrides every step below:

- **Redundancy is NOT the target. Completion-breaking conflict is.** A duplicated-but-harmless overlap (a deliberate chain, a shared kernel, defense-in-depth) is LEFT ALONE. Cutting something because it merely *looks* redundant is the shortcut mentality this command forbids.
- **Integrity over performance, always.** Never remove, weaken, or merge a skill's machinery to save tokens or tidy up. The only acceptable change is one that lets a skill complete *as the user intended*.
- **When in doubt, keep both and flag.** The cost of a false "conflict" is a user deleting working machinery. The bar for touching anything is near-zero error, not "usually right."

---

## Preflight CHECKPOINT (fires every invocation)

1. **Self-exclusion / dev parse.** If the first argument is `dev`, set `dev_mode = true` and strip it.
   - Invoked as `/skill-builder reconcile skill-builder` without `dev` → REFUSE: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev reconcile skill-builder`". Do not proceed.
   - Invoked as `/skill-builder reconcile` (no target, all-skills mode) without `dev` → exclude `skill-builder` from the skill glob. With `dev` → include it.
   See SKILL.md § Self-Exclusion Rule.
2. **Risk tier.** `reconcile` is **high-risk → display mode by default.** It changes nothing without `--execute`, and even then `--execute` is bounded to the two mechanical auto-fixes in Step 6. Skill *deletion* is never performed here — it is delegated to `strip`.
3. **Ground before acting.** State that this run analyzes cross-skill collisions per the conflicts-only scope. Read this file's Step 2 class table before classifying anything.

---

## Step 1: Build the cross-skill inventory

Glob `.claude/skills/*/SKILL.md` (respecting self-exclusion). For each skill, record from a concrete read (no judgment):

| Field | Source |
|-------|--------|
| `name` / slash verb | frontmatter `name:`, else directory basename |
| Source tier | managed / user / project (path location) |
| `description` + `when_to_use` | frontmatter (the selection-time surface) |
| `paths` scoping | frontmatter `paths:` if present |
| Command verbs | the skill's Commands/Quick-Commands table |
| Hook entries | frontmatter `hooks:` + `settings.local.json` wiring → `(event, matcher, command)` tuples |
| Auto-chain targets | directive/body text naming `/X` to invoke after a step |
| Managed embed blocks | `<!-- ROUTE-EMBED START -->`, `<!-- CODE-EVAL-EMBED START -->`, `<!-- MODEL-LANE-GATE START -->`, `<!-- LANE-AGENT-EMBED START -->` marker counts |
| Agent personas | BOTH `agents/*.md` and `agents/*/AGENT.md` — union the two globs |
| Immutable directive text | spans inside `<!-- origin: user | immutable: true -->` |

This is reference-only reading. Per the AGENTS-ARE-MANDATORY directive, the *reading* needs no agent; the *judgment* classes in Step 5 do.

---

## Step 2: Detect collision classes

Evaluate each signal and tag it with its reliability tier. **MECHANICAL** = concrete equality/regex read, no judgment. **HEURISTIC** = statistical/fuzzy, over-flags by nature. **JUDGMENT** = semantic, requires reading what skills *do*.

| ID | Collision | How it breaks completion | Tier | Default disposition |
|----|-----------|--------------------------|------|---------------------|
| R1 | **Duplicate slash/skill `name`** (same normalized verb, same tier) | First-wins discovery → the shadowed skill is permanently unreachable | MECHANICAL | Flag loudly (never auto-rename) |
| R2 | **Duplicate machine-generated embed block** within one skill (two `ROUTE-EMBED`, `CODE-EVAL-EMBED`, `MODEL-LANE-GATE`, or `LANE-AGENT-EMBED` blocks) | Double-dispatch / drift | MECHANICAL | **AUTO-FIX** — collapse to one (skill-builder-owned content, idempotent) |
| R3 | **Byte-identical duplicate hook entry** (same `(event, matcher, command)` registered twice) | Redundant runtime execution | MECHANICAL | **AUTO-FIX** — JSON-aware dedupe, re-validate |
| R4 | **Conflicting hook matchers** (same `(event, matcher)`, *different* command) | Order-dependent; one can block/suppress the other | MECHANICAL detect / JUDGMENT verdict | FLAG-ONLY |
| R5 | **Selection-shadowing** — `description`/`when_to_use` trigger overlap between two skills meant to be mutually exclusive | Claude picks one at selection time; the other silently never loads | HEURISTIC | "Look here" evidence only — **never** a merge/delete recommendation; descriptions are never edited |
| R6 | **Dispatch collision** — circular auto-chain (A→B→A), or a route gate overriding an explicitly-named auto-chain on the same step | Loop guard silently stops one; or the named skill never loads | JUDGMENT | FLAG-ONLY (circular = real); route-gate + *named* target is ALLOWED (route.md clause 2) |
| R7 | **Wholly redundant / superseded skill** (one skill's coverage is a strict subset of another, with no distinct stage/medium) | The narrower skill is dead weight or shadowed | JUDGMENT | Agent panel → on confirmation, route to **`strip`** |
| R8 | **Contradicting or duplicated directives** across skills | Co-loaded, one sacred rule silently voids the other; or drift makes enforcement nondeterministic | JUDGMENT | **FLAG-ONLY — NEVER TOUCH** |
| R9 | **Same-region write race** — two skills in a declared chain both `Edit`/`Write` the same file region | Last-writer-wins; one skill's effect silently overwritten | JUDGMENT | FLAG-ONLY |
| R10 | **Duplicate / paraphrased persona** across skills | Violates persona-uniqueness directive | MECHANICAL detect | FLAG-ONLY (re-author through the persona gate; reconcile never renames) |

---

## Step 3: Apply the conflicts-only filter + complementary-overlap allow-list

This step is where the governing directive bites. **Discard any finding that does not threaten a skill's full completion**, and downgrade any overlap that a marker proves is intentional.

**Drop silently (not a finding):**
- Pure redundancy with no selection-shadow, dispatch-bypass, suppression, or mutation-race consequence.
- Any overlap covered by the allow-list below.

**Complementary-overlap allow-list — MUST NOT be flagged as conflicts:**
1. **Gateway → specifics.** A skill that deliberately matches broadly and chains into narrower ones (broad description is its job).
2. **One-directional, terminating auto-chain** (producer → evaluator). Only a *cycle* is a defect (R6).
3. **Shared-kernel load.** One skill explicitly loads another's content — co-presence is the design, not duplication.
4. **Layered evaluation by stage** (pre-write advisor / post-write review / sweep) — depth, not redundancy.
5. **Medium- or scope-disjoint** evaluators/routers (text vs image; freeform-within-a-skill vs cross-skill).
6. **Route-embed gate + an explicitly-named auto-chain** — safe by route.md's "already-named" exception.
7. **Mechanical hook + judgment agent that add *distinct* coverage** (deterministic backstop + LLM nuance) — defense-in-depth when they agree.

**General rule:** an overlap is a *collision* only when it produces selection-shadowing, dispatch-bypass, suppression, or a mutation race **AND** no marker (auto-chain naming the target, an embed block, a shared-kernel load statement, a distinct lane/stage/medium) declares the co-presence intentional. A marker downgrades the finding to "intentional-complementary" and it is dropped.

---

## Step 4: Classify each surviving finding to a remediation tier

Three tiers. The **directive-touch hard floor** overrides a finding's default tier: *if the remediating edit span would intersect an `<!-- origin: user | immutable: true -->` block, downgrade to FLAG-ONLY regardless of class.*

- **AUTO-FIX** (mechanical, `--execute` only): R2, R3 — deterministic, single-correct-answer transforms on skill-builder-owned (`modifiable: true`) or machine-generated content. Still gated behind `--execute`; never silent.
- **PROPOSE-AND-CONFIRM** (`--execute` + per-finding AskUserQuestion): reserved for future mechanical-but-ownership-ambiguous fixes on `modifiable: true` content. None of R1–R10 auto-apply text edits to authored content in v1 — R1 (name) is flag-only because *which* skill keeps the verb is the user's call.
- **FLAG-ONLY-NEVER-TOUCH**: R1, R4, R5, R6, R8, R9, R10, and every directive-intersecting span. Report with `file:line` evidence and a recommended manual action; the command never edits.

R7 (redundant skill) is its own path: never deleted here — **routed to `strip`** (Step 6).

---

## Step 5: Agent adjudication for JUDGMENT-class findings (MANDATORY)

Per the AGENTS-ARE-MANDATORY directive, no JUDGMENT-class finding (R4 verdict, R6, R7, R8, R9) is reported as a *conflict* on a solo call. For each candidate, spawn an adjudication panel (Task tool, individual agents — mirrors audit Step 4e). Per the team research-assistant directive, when the candidate set is large enough to assemble a panel, include a read-only research-assistant persona that supplies the actual workflow facts from the two skills.

Suggested panel per candidate (distinct, non-duplicated personas):
- one agent argues **the overlap is a real completion-breaking conflict** (and, for R7, which skill should win);
- one agent argues **the overlap is distinct / a deliberate chain / disjoint scope** (defends keeping both);
- a **read-only research assistant** persona reads both skills and reports their actual commands, workflows, and directive scopes — no write tools.

Synthesis: agents agree it is a conflict → report it. **Agents disagree → default to the conservative outcome: keep both, flag for human decision.** Never let a panel's split vote license a deletion or an edit.

**Audit-display exception:** when `reconcile` runs *inside* a full audit in display mode, its panels are suppressed (audit's only panel is its Step 4e priority ranking). Panels fire in standalone `reconcile` and under `--execute`, where the judgment has real consequences. See audit.md § Step 4d-bis.

---

## Step 6: Report, then bounded execution

Apply the **absence-vs-gap** rule: a class with zero findings is omitted entirely. A skill that overlaps another *by design* is correctly coupled — do not render it as a "clear/none" row that invites fixing a non-problem.

```markdown
## Cross-Skill Reconciliation

**Skills scanned:** [N]   **Conflicts found:** [M]   (redundancy-only overlaps are not reported)

### Findings
| ID | Class | Skills involved | Evidence (file:line) | Tier | Recommended action |
|----|-------|-----------------|----------------------|------|--------------------|
| R1 | Duplicate name | /a, /b | ... | FLAG | You choose which keeps `/x`; rename the other |
| R8 | Contradicting directives | /c, /d | ... | FLAG-NEVER-TOUCH | Verbatim text of both; you resolve |
| R3 | Duplicate hook entry | settings.local.json | ... | AUTO-FIX | Drop byte-identical dupe (--execute) |

### Directives surfaced verbatim (never edited)
[For each R8: quote both directive blocks exactly, with their origin markers and the alleged overlapping scope.]
```

**Standalone display mode** (default): output the report; change nothing.

**`--execute`** — strictly bounded:
1. Produce a TaskCreate list, one task per confirmed action.
2. Apply **AUTO-FIX only** (R2 duplicate embed collapse; R3 byte-identical hook dedupe). R2/R3 operate on machine-generated or `modifiable: true` content only; re-validate JSON after any `settings.local.json` edit.
3. For a confirmed **R7** redundant skill: dispatch `/skill-builder strip <skill>` (display first; it carries its own BREAKING detection and `--confirm-breaking` gate). `reconcile` performs no deletion itself.
4. Everything else stays in the report as FLAG-ONLY — `--execute` does **not** edit directives, descriptions, personas, conflicting hooks, or chains.

**`--execute` is NEVER allowed to:** edit/reorder/delete any `origin: user | immutable: true` content; reword a description or `when_to_use`; rename a persona; auto-pick a winner for a conflicting hook matcher (R4); delete a skill directly.

---

## Audit integration

`reconcile` runs as **audit Step 4d-bis** (between cascade 4d and the priority panel 4e), in display mode, panels suppressed. Findings feed the aggregate report's "Cross-Skill Reconciliation" section; R1/R4/R6/R7/R8 (completion-breaking) elevate into Priority Fixes. **Skipped in `audit --quick`** (structural scan, not a checklist item). R2/R3 mechanical auto-fixes run in audit's auto-execution phase (AUTO tier — machine-owned bytes only); confirmed R7 deletions DEFER into the audit's Deferred Items table as `/skill-builder strip <skill>` (Audit Autonomy Gate, 2026-06-06). See audit.md § Step 4d-bis.

---

## Grounding

- [cascade.md](cascade.md) — the within-skill counterpart (scope boundary: intra-skill suppression vs cross-skill collision)
- [strip.md](strip.md) — the destructive skill-removal command R7 delegates to (BREAKING detection, `--confirm-breaking`)
- [route.md](route.md) — ROUTE-EMBED / CODE-EVAL-EMBED / MODEL-LANE-GATE / LANE-AGENT-EMBED marker families (R2) and the "already-named" auto-chain exception (R6)
- [audit.md](audit.md) — Step 4d-bis integration, agent-budget rule, absence-vs-gap reporting
- SKILL.md § Directives — the governing integrity-over-performance directive; § Core Principles — move-don't-rewrite, directives are sacred; § Display/Execute Mode Convention — high-risk default
