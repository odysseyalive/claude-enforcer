# Code-Eval Command Procedure

Scaffold and maintain the `code-evaluator` skill — a language-agnostic code
quality evaluator that prevents common AI coding mistakes (dead code, duplication,
complexity hotspots, reinvented helpers, leftover scaffolding). This command is
skill-builder *machinery*; the `code-evaluator` skill it produces is what end
users actually run.

**Subcommands:** `create` · `review` · `sweep` · `sync`

```
/skill-builder code-eval create            # scaffold code-evaluator if absent (low-risk, executes)
/skill-builder code-eval review [path]     # post-write evaluation of a diff/path (high-risk, display default)
/skill-builder code-eval sweep             # full-codebase report (high-risk, display default)
/skill-builder code-eval sync              # refresh a user's code-evaluator references from shipped versions
```

---

## Preflight CHECKPOINT (fires every invocation)

1. **Self-exclusion / dev parse.** If the first argument is `dev`, set
   `dev_mode = true` and strip it. `code-eval` operates on the *user's*
   `code-evaluator` skill, never on `skill-builder` itself, so the self-exclusion
   rule is a no-op here — but honor `dev_mode` for path discipline if maintaining
   skill-builder's own shipped references (Phase 0).
2. **Locate the shipped reference set.** The canonical intel lives at
   `<skill-builder-install>/references/code-evaluator/` (i.e.
   `.claude/skills/skill-builder/references/code-evaluator/`). All subcommands
   read the shipped version + reference files from there. If that directory is
   missing, STOP: "skill-builder's code-evaluator references are missing — run
   `/skill-builder update`."
3. **Ground before acting.** Read
   [../code-evaluator/version.md](../code-evaluator/version.md) for the current
   shipped `code-eval-ref-version`, and
   [../code-evaluator/skill-template.md](../code-evaluator/skill-template.md) for
   the generated-skill templates. State which subcommand will run.

---

## Subcommand: `create`  (low-risk — executes immediately)

Scaffold `.claude/skills/code-evaluator/` if it does not already exist. Modeled on
[new.md](new.md).

### Step 1 — Existence + name check
- If `.claude/skills/code-evaluator/SKILL.md` already exists → do NOT overwrite.
  Report: "code-evaluator already installed (ref version N). Use
  `/skill-builder code-eval sync` to update its references." STOP.

### Step 2 — Persona-uniqueness gate (BLOCKING)
Per the user directive *"Each agent being created by this system always has to
have an appropriate persona that is not being used anywhere else,"* run the
Persona Assignment Gate before writing either AGENT.md:
1. Glob BOTH agent forms and read every `persona:` field:
   `.claude/skills/*/agents/*/AGENT.md` AND `.claude/skills/*/agents/*.md`.
2. The template personas are `code-design-advisor` ("Staff engineer who reads the
   whiteboard sketch…") and `deadcode-gardener` ("Codebase gardener who walks the
   tree…"). If either collides verbatim or by paraphrase with an existing persona
   → choose a distinct alternative persona that still fits the role, and report
   the substitution. Do not proceed with a duplicate.

### Step 2-bis — Model assignment (sacred directive, 2026-06-06)
When `create` (or `sync` touching an agent) runs during an audit, both generated
agents get an explicit `model:` field per SKILL.md § Directives → Audit Agent
Model-Assignment Gate: their work is code analysis/review → the everything-else
(coding) lane's full model ID from `references/model-lanes.md`. Lanes
unconfigured or the cell empty → leave `model:` absent and flag; never invent an
ID. Standalone (non-audit) runs apply the same rule when lanes are configured.

### Step 3 — Write the skill
From [../code-evaluator/skill-template.md](../code-evaluator/skill-template.md),
write:
- `.claude/skills/code-evaluator/SKILL.md` (§SKILL.md) — keep frontmatter
  `lane: coding` and `code_eval_ref_version: <shipped version>`.
- `.claude/skills/code-evaluator/agents/code-design-advisor/AGENT.md` (§ADVISOR AGENT).
- `.claude/skills/code-evaluator/agents/deadcode-gardener/AGENT.md` (§REVIEWER AGENT).

Then COPY the shipped intel references verbatim from
`<skill-builder-install>/references/code-evaluator/` into
`.claude/skills/code-evaluator/references/`:
`cross-file-detection.md`, `mistake-taxonomy.md`, `native-tool-map.md`,
`guards.md`, `gotchas.md`. (Do NOT copy `version.md` or `skill-template.md` — those
are skill-builder-side only.) The copied files keep their
`<!-- code-eval-ref-version -->` and `<!-- origin: skill-builder | modifiable: true -->`
headers — that is how `sync` recognizes them later.

### Step 4 — Report + chain
Report the created tree, the resolved personas, and the ref version. Then run
`route index --execute` (so `/route` lists the new skill) and recommend
`route embed` so code-touching skills pick up the gates. (Audit does this
automatically; a standalone `create` offers it.)

---

## Subcommand: `review [path]`  (high-risk — display default, `--execute` to fix)

Post-write evaluation (Layer 2). If `code-evaluator` is not installed, run
`create` first.

1. Determine the candidate set: `path` if given, else the working diff
   (`git diff --name-only HEAD`, or `origin/main...HEAD` for a PR).
2. **Per the AGENTS-ARE-MANDATORY directive,** spawn the `deadcode-gardener`
   agent (defined in the code-evaluator skill) for an unbiased read in a clean
   context. Pass it the candidate set and the display/execute flag.
3. The agent grounds on the code-evaluator references, runs the native-tool gate
   then the ripgrep pipeline, tiers findings, and returns the output contract.
4. Display mode (default): present the tiered plan; change nothing. `--execute`:
   the agent applies ONLY HIGH-confidence, guard-cleared dead-code fixes through
   the safety cycle (baseline → atomic remove → build → full tests → revert on
   failure). Duplication/complexity stay human-decide.

## Subcommand: `sweep`  (high-risk — display default)

Full-codebase report (Layer 3), report-only at scale.
1. Identify top-level source directories.
2. Fan out one `deadcode-gardener` agent per directory (or per workspace package
   in a monorepo); each returns its tiered findings.
3. Aggregate into a single ranked report grouped by confidence tier and kind.
   Do not auto-fix in `sweep` — it is a survey; route confirmed HIGH items
   through `review --execute` on a scoped path.

---

## Subcommand: `sync`  (the drift updater — also called automatically by audit)

Refresh a user's installed `code-evaluator` references when skill-builder ships a
newer version. No network: both copies are local after `/skill-builder update`.

### Step 1 — Compare versions
- `shipped` = the integer in `<skill-builder-install>/references/code-evaluator/version.md`.
- `recorded` = `code_eval_ref_version` in
  `.claude/skills/code-evaluator/SKILL.md` frontmatter.
- If `code-evaluator` is not installed → nothing to sync (audit handles creation
  separately). If `recorded >= shipped` → report "up to date (vN)"; STOP.

### Step 2 — Refresh (block-aware)
For each shipped reference file (`cross-file-detection.md`, `mistake-taxonomy.md`,
`native-tool-map.md`, `guards.md`, `gotchas.md`):
- Overwrite every `<!-- origin: skill-builder | modifiable: true -->` block in the
  user's copy with the shipped version.
- **Preserve** any `<!-- origin: user | immutable: true -->` blocks the user added
  (verbatim — move-don't-rewrite). In v1 the shipped files contain no user blocks,
  so this is a wholesale refresh; the block-aware merge protects future user edits.
- Also refresh the two AGENT.md files and the non-frontmatter body of SKILL.md the
  same way, preserving any user-origin blocks and the user's chosen personas.

### Step 3 — Stamp + report
Update the user SKILL.md frontmatter `code_eval_ref_version` to `shipped`. Report:
"code-evaluator references updated vRECORDED → vSHIPPED" with the changed files
and the version.md changelog entries between the two versions.

### Display vs execute
Standalone `sync` executes (low-risk refresh of skill-builder-owned content).
When invoked from audit, it follows audit's mode: display mode reports the pending
update; execute mode applies it (see [audit.md](audit.md) § code-evaluator steps).

---

## Grounding

- [../code-evaluator/version.md](../code-evaluator/version.md) — drift anchor (shipped version + changelog)
- [../code-evaluator/skill-template.md](../code-evaluator/skill-template.md) — generated SKILL.md + advisor/reviewer AGENT.md templates
- [../code-evaluator/cross-file-detection.md](../code-evaluator/cross-file-detection.md), [guards.md](../code-evaluator/guards.md), [mistake-taxonomy.md](../code-evaluator/mistake-taxonomy.md), [native-tool-map.md](../code-evaluator/native-tool-map.md), [gotchas.md](../code-evaluator/gotchas.md) — the shipped intel set
- [new.md](new.md) — scaffolding contract `create` mirrors
- [route.md](route.md) — the embed gates that wire the advisor/reviewer into code-touching skills
- [audit.md](audit.md) — automatic ensure-exists + sync integration
