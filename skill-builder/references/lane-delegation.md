# Lane-Pinned Excursion Delegation
<!-- Enforcement: HIGH — canonical spec for cross-lane delegation; read by agents.md § Step 4d, route.md § Step 9, and audit.md § Step 4f. Governed by the 2026-06-06 bespoke-excursion and audit-model-assignment sacred directives (SKILL.md § Directives). -->

This file is the canonical specification for **lane-pinned excursion delegation** — the second half
of the model-lane system. Where [model-lanes.md](model-lanes.md) handles a skill's **primary lane**
(prompting the user to `/model`-switch on mismatch), this spec handles **cross-lane excursion
steps** inside a skill's workflow: instead of prompting another switch, the step is delegated to a
bespoke subagent pinned to the other lane's model via `model:` frontmatter. The main model stays in
charge; the agent hands results back.

This file ships unconditionally (unlike model-lanes.md, which is install-if-absent to preserve user
mappings) — the normative rules live here so existing installs receive them on update.

---

## Principles

1. **The primary lane still switches.** A skill's declared lane determines what the main session
   model should be. The MODEL-LANE-GATE (route.md § Step 8) keeps prompting `/model` for
   primary-lane mismatch. Delegation is never an escape hatch for a primary mismatch.
2. **Hard rule — coding main stays coding.** Coding/analysis *primary* work runs on the coding main
   model. Never run a creative main session orchestrating a swarm of coding-pinned agents to avoid
   a switch. (Sacred directive, 2026-06-06 workshop.)
3. **Excursions delegate, symmetrically.** A mid-workflow step belonging to the OTHER lane —
   research inside a creative skill, prose inside a coding skill — is delegated to a lane-pinned
   agent in either direction. This mechanizes the 2026-06-06 research-precedence directive:
   research is performed by the coding model (a coding-pinned agent) before its results are handed
   to a creative main.
4. **Bespoke per skill; workflow preservation is the highest priority.** Agents are designed from
   the target skill's reviewed material — its full workflow, routing points, and constraints —
   never instantiated generically. Delegation replaces only a step's EXECUTOR; the workflow body is
   never edited, reordered, merged, or reworded. Token efficiency is a forbidden rationale
   everywhere in this flow. (Sacred directive; see SKILL.md § Directives → Bespoke Excursion-Agent
   Gate.)
5. **A skill cannot switch the session model.** Unchanged. Delegation does not switch anything
   either — it spawns a subagent whose own `model:` pin the harness honors (confirmed: subagent
   frontmatter accepts full model IDs; see code.claude.com/docs/en/sub-agents).

---

## Excursion Signal Vocabulary (per-step classification)

Apply [model-lanes.md](model-lanes.md) § Advisory Lane Suggestion's signal lists to **individual
workflow steps** instead of whole skills. A step is a cross-lane candidate when its own lane
differs from the skill's declared primary lane.

- **Research precedence fires first, always.** A research-shaped step (research, web search, source
  lookup, cite/verify, gather references) resolves to `coding`. Inside a `coding`-lane skill it is
  therefore NEVER an excursion — it runs natively. Inside a `creative`-lane skill it is a coding
  excursion.
- Coding-excursion signals inside creative skills: research/lookup/verify (above), run/test/build,
  parse/validate data, file or API inspection.
- Creative-excursion signals inside coding skills: draft release notes / announcements / copy,
  write user-facing prose, translate, evaluate text or voice, design copy or naming.
- Steps matching neither list, or matching both → AMBIGUOUS → the agent panel rule below.

## NON-DELEGABLE Hard-Stop List (mechanical — no agent needed)

A step is NON-DELEGABLE if ANY of the following holds. A non-delegated step simply runs in the main
session exactly as written — the status quo is always the safe fallback.

1. It uses AskUserQuestion or is a decision handoff (SKILL.md § Display/Execute Rule 8).
2. It references conversation-scoped state not on disk ("the draft above", "as discussed",
   session opt-outs, outputs of prior steps held only in context).
3. It mutates files that later steps read or edit (write-race).
4. It is part of a CHECKPOINT / enforcement annotation / sacred directive block — gates are never
   delegated.
5. It spawns agents or teams itself (no nested Task orchestration from inside an excursion).
6. Its quality depends on a persona/voice profile loaded earlier in the session (e.g. a `/voice`
   profile in context).

**Between candidate and non-delegable → the agent panel is MANDATORY** (Non-Obvious Decision Gate:
3 unique personas, e.g. workflow-integrity inspector / context-dependence auditor /
lane-classification specialist). Panel split or any conflict → **NO-DELEGATE**. The safe default
preserves the workflow as-is. No panel persona and no synthesis may justify delegation on
token-cost or speed grounds (Integrity-Over-Performance Gate parity).

---

## Context Contract (what crosses the bridge)

Subagents start with NO conversation context. Every lane-pinned agent carries a `## Context
Contract` section with two halves:

- **REQUIRES** — the enumerated inputs the spawner MUST serialize into the agent prompt: task
  statement, file paths to read, the relevant constraint set, acceptance criteria.
- **RETURNS** — the structured output format, with a mandatory failure sentinel
  (`INCOMPLETE: <missing input>`) so a starved agent fails loudly, never plausibly.

Rules:

1. **No partial handoff.** IF the main model cannot supply every REQUIRES item at invocation time →
   delegation is forbidden for that invocation; perform the step in the main session as written and
   say so. Never spawn with a gap "to see what comes back."
2. **Directive propagation by pointer, never copy.** An excursion touching content covered by the
   parent skill's sacred voice/style directives gets a grounding bullet "Read
   `.claude/skills/<skill>/SKILL.md` § Directives first" — directive text is never paraphrased into
   an AGENT.md (forked copies rot and violate the verbatim rule).
3. **Return verification.** The main model checks the return against RETURNS before continuing. On
   violation: retry exactly once, naming the gap. Second failure → fall back to main-session
   execution and report. Never loop (single-retry discipline, matching MODEL-LANE-GATE clause 8).
4. **Observable delegation.** Announce every spawn:
   `Excursion: step "<anchor>" delegated to <agent> (lane <x>, model <id>)` and surface the
   returned artifact in conversation. Invisible delegation is forbidden — the user must be able to
   inspect the trade they accepted.

---

## Lane-Pinned Agent Template

Default granularity: **one agent per (skill, direction)** — multiple same-direction excursions in
one skill share the agent via per-invocation prompts. The design panel may split into per-excursion
agents only when the contracts genuinely differ. Placement:
`.claude/skills/<skill>/agents/<name>/AGENT.md` plus a registration symlink
`.claude/agents/<name>.md` (copy fallback where symlinks are unavailable — report which was used).
Lane-pinned agents are generated on the host, never shipped.

```markdown
---
name: [skill]-[direction-or-excursion-slug]
description: "Lane-pinned excursion agent for /[skill]: [one-line purpose]"
persona: "[unique persona — composed scheme, verified via the Persona Assignment Gate before write]"
model: [FULL official model ID of the OTHER lane's preferred model, e.g. claude-opus-4-8]
lane-pinned: [coding|creative]        # fleet-membership marker — Fleet Rewrite targets this
generated-by: skill-builder lane-excursion
excursion-skill: [skill]              # must equal the containing skill directory
tools: [minimal excursion-appropriate list — see Tool Curation below]
---

# [Agent Title]

You are [persona]. You perform exactly ONE kind of excursion for the /[skill] workflow: [purpose].

## Context Contract
- REQUIRES: [enumerated inputs the spawner must provide]
- RETURNS: [structured output] — or `INCOMPLETE: <missing input>` if any REQUIRES item is absent.

You do NOT perform any other step of /[skill]'s workflow, do NOT route to other skills, and do NOT
modify files unless this excursion's RETURNS contract is explicitly a file.
```

**Tool Curation.** Start from the archetype, then trim to what the skill's reviewed material
actually requires:

| Archetype | Direction | tools |
|---|---|---|
| Researcher | creative skill → coding agent | Read, Grep, Glob, Bash, WebFetch, WebSearch |
| Analyst / validator | creative skill → coding agent | Read, Grep, Glob, Bash |
| Drafter / translator / text evaluator | coding skill → creative agent | Read, Grep, Glob (+ Write ONLY when RETURNS is a file) |

Never `Task`, never `Skill` (no nested dispatch, no gate-skipping side doors), never `Edit`.

**Persona scheme.** Compose `<discipline expert> + <skill-domain qualifier>` (e.g. "Investigative
research librarian specializing in [skill-domain] source verification"). The qualifier guarantees
verbatim uniqueness; the paraphrase check still runs — same discipline with a different domain
qualifier is NOT a paraphrase collision (see agents-personas.md).

---

## The Delegation Map (`LANE-AGENT-EMBED` block)

ONE contiguous block per skill, inserted **immediately after the skill's MODEL-LANE-GATE block**
(or at route.md § Step 8d's insertion point if no gate exists). The workflow body stays
byte-identical — entries reference steps by **stable anchors** (the step's heading text plus a
short verbatim quoted phrase), never line numbers, never inline markers inside the steps.

```markdown
<!-- LANE-AGENT-EMBED START — auto-generated by /skill-builder agents; reconciled by route embed; safe to replace -->
<!-- origin: skill-builder | modifiable: true -->
<!-- Source: lane-pinned excursion delegation (skill-builder SKILL.md § Directives, 2026-06-06). Cross-lane steps delegate to lane-pinned agents instead of prompting a mid-workflow /model switch. The Model-Lane Preflight above governs the PRIMARY lane; this map governs excursions. -->
CHECKPOINT — Excursion Delegation Map:
[One entry per excursion:]
1. When you reach the workflow step matching anchor "[quoted phrase from the step]" ([other-lane]-lane work):
   do NOT perform it in the main session and do NOT prompt for a /model switch. Spawn the lane-pinned
   agent via the Task tool: subagent_type "[agent-name]" (agents/[agent-name]/AGENT.md, model-pinned via
   its frontmatter). Provide every REQUIRES item from its Context Contract; announce the delegation.
   The agent RETURNS [output]; verify against the contract (one retry max), then resume the workflow at
   the same step's position — order, gates, and routing points preserved exactly.
2. IF the agent file is missing or the spawn fails → report "Lane-pinned agent [agent-name] missing — run
   /skill-builder agents [skill] --execute", then perform the step in the main session AS WRITTEN
   (degraded path; never silently skip the step, never block, never loop).
3. Workflow preservation overrides everything: no shortcut, no token-efficiency reasoning, no merging
   an excursion into other steps (sacred directive, 2026-06-06).
<!-- END ENFORCEMENT ANNOTATION -->
<!-- LANE-AGENT-EMBED END -->
```

**Insertion rules:** never inside, before, or reordering an `origin: user | immutable: true` block;
never between another family's START/END markers; never inside a fenced code block; never
renumbering, rewording, merging, or moving any workflow step. Blank-line padded.

**Anchor verification (every reconcile):** each anchor phrase must match exactly once in the file.
Zero matches (user reworded the step) or more than one → that entry downgrades to a reported
`STALE-ANCHOR` finding. Never fuzzy-match; re-anchoring is a judgment call → agent panel, with the
conservative default "drop the entry, keep the workflow untouched."

**Headless behavior:** delegation runs identically in headless sessions — it does not prompt, so it
has nothing to suppress (the primary-lane gate remains headless-suppressed, unchanged). The
degraded path (clause 2) never prompts, never loops, never aborts the workflow. Delegation
announcements still print, so headless runs keep an auditable trail.

---

## Lane→Model Picker (consumed by audit.md § Step 4f Step 2-bis)

On **every full interactive audit** (suppressed: headless/non-interactive, `audit --quick`,
`--no-model-prompt`), the user is asked which model handles each lane. ONE batched AskUserQuestion,
current mapping pre-selected as the default. Options per lane, EXACTLY:

1. `claude-opus-4-6`
2. `claude-opus-4-8`
3. The **latest released model by official ID** — discovered fresh each audit via the ladder below.

(AskUserQuestion's auto-appended "Other" preserves manual entry; dedupe the "latest" option when it
equals a static one. Leaving a cell blank disables flagging for that lane, per model-lanes.md.)

**Latest-model discovery ladder:**

1. `GET https://api.anthropic.com/v1/models` with headers `x-api-key: $ANTHROPIC_API_KEY` and
   `anthropic-version: 2023-06-01`, hard timeout ~10s. Most recently released is listed first →
   take the first `id`, normalize per model-lanes.md § Active-Model Detection.
2. On any failure (no key, offline, non-200, unparseable) → fetch the official Anthropic
   models-overview docs page via available web tools and take the newest model's official ID.
3. Both fail → OMIT the "latest released" option entirely and print one line: "latest-model
   discovery unavailable (offline / no API key); choose from known IDs or edit model-lanes.md by
   hand." **Never fabricate a model ID from memory** — the same philosophy as the stale-ID rule.
4. Discovery results are never cached or persisted — re-discover each audit. Discovery failure
   never blocks or degrades the rest of Step 4f; it only narrows the option list.

A changed answer → the consented Lane→Model write into model-lanes.md (same single-write discipline
as audit's 4f-setup), then the Fleet Rewrite below. The picker never writes the
`model-lane-setup` marker and never switches the session model.

---

## Fleet Rewrite on Remap

When the picker changes a lane's preferred model, every generated lane-pinned agent of that lane is
rewritten:

1. **Identify the fleet:** glob all agent forms (`.claude/skills/*/agents/*.md`,
   `.claude/skills/*/agents/*/AGENT.md`, `.claude/agents/*.md` — dereference symlinks, dedupe) and
   filter on `generated-by: skill-builder lane-excursion` AND `lane-pinned: <remapped lane>`.
   Files without the `generated-by` marker are user property — never touched.
2. **Task-list operation:** TaskCreate one task per file; display the plan; apply on consent (the
   picker's confirmation IS the consent). The rewrite touches the **`model:` line only** — AGENT.md
   bodies follow move-don't-rewrite discipline.
3. **Verification pass:** re-grep every lane-pinned agent's `model:` against the new mapping; emit
   a mismatch table; any leftover is an explicit Priority Fixes entry, never silent.
4. Incomplete marker sets (e.g. `generated-by` present, `lane-pinned` missing) → skip + report, no
   auto-repair (tamper-guard parity). `excursion-skill` must equal the containing skill directory —
   mismatch is a flag.
5. **Never spawn an agent pinned to a model the user has removed from the mapping** — a blanked
   cell disables that excursion direction entirely (route embed Step 9 strips the map entries on
   its next run).

## Audit Model-Assignment Rule (sacred directive, 2026-06-06)

"All agents created or modified during the audit should have a model specified, per the user's
choice of creativity model and everything else model." Mechanics (see SKILL.md § Directives → Audit
Agent Model-Assignment Gate):

- Every AGENT.md that audit — or any command running under audit (`agents`, `code-eval create`/
  `sync`, `ledger`) — creates or modifies gets `model:` stamped with the full ID of the lane
  matching the agent's own work (creative vs everything-else; research → everything-else).
- Lanes unconfigured or cell empty → never invent an ID; leave `model:` absent and flag.
- Audit's scan: existing agents missing `model:` while lanes are configured → flagged in the Model
  Lane report with a fix task (stamp on `--execute`).

---

## Reconciliation Contract

| Action | Owner | Notes |
|---|---|---|
| **NEW** (design agent + insert map block) | `/skill-builder agents [skill]` (§ Step 4d) | Judgment-gated: Bespoke Excursion-Agent Gate + panel rules. `route embed` never creates this family — it lists uncovered excursions as "run `agents [skill]`" recommendations. |
| **REFRESH / REMOVE / NOOP / REPORT-ORPHAN / STALE-ANCHOR** | `route embed` (route.md § Step 9) | Re-renders the canonical block from the agents' frontmatter + contract; byte-compare; skill left its lane or cell blanked → REMOVE block, report agents for deletion (display-first). Missing AGENT.md → REPORT-ORPHAN, never auto-strip. |
| Duplicate map block | `reconcile` (mechanical auto-fix class) | Same collapse rule as the other managed families. |
| Skill deletion | `strip` | Lane-pinned agent dirs + map entries are cross-reference patterns swept before deletion. |

---

*Read by `references/procedures/agents.md` § Step 4d (design + placement), `references/procedures/route.md` § Step 9 (reconciliation), and `references/procedures/audit.md` § Step 4f (picker, fleet rewrite, coverage + model-assignment scans). Shipped unconditionally by the installer.*
