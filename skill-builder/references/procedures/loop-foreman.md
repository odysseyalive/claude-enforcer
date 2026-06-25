# Loop-Foreman Command Procedure

Scaffold the `loop-foreman` skill — a companion that drives a large, well-specified task to
completion unattended, gating "done" behind a mechanical oracle AND a fresh-context reasoning grader,
and escalating only on genuinely consequential forks. This command is skill-builder *machinery*; the
`loop-foreman` skill it produces is what end users actually run (`/loop-foreman run`).

Design of record: ledger DEC-2026-06-25-loop-foreman-design. v1 is the lean increment — `create`
only; `sync` / auto-arm detection / the host-generated irreversible-action enforce hook are deferred.

**Subcommands:** `create`

```
/skill-builder loop-foreman create     # scaffold loop-foreman if absent (low-risk, executes)
```

---

## Preflight CHECKPOINT (fires every invocation)

1. **Self-exclusion / dev parse.** If the first argument is `dev`, set `dev_mode = true` and strip
   it. `loop-foreman` operates on the *user's* `loop-foreman` skill, never on `skill-builder` itself,
   so self-exclusion is a no-op here — but honor `dev_mode` for Phase 0 path discipline when
   maintaining skill-builder's own shipped references.
2. **Locate the shipped reference set.** The canonical intel lives at
   `<skill-builder-install>/references/loop-foreman/` (i.e.
   `.claude/skills/skill-builder/references/loop-foreman/`). If that directory is missing, STOP:
   "skill-builder's loop-foreman references are missing — run `/skill-builder update`."
3. **Ground before acting.** Read [../loop-foreman/version.md](../loop-foreman/version.md) for the
   current shipped `loop-foreman-ref-version`, and
   [../loop-foreman/skill-template.md](../loop-foreman/skill-template.md) for the generated-skill
   templates. State which subcommand will run.

---

## Subcommand: `create`  (low-risk — executes immediately)

Scaffold `.claude/skills/loop-foreman/` if it does not already exist. Modeled on
[code-eval.md](code-eval.md) § create and [new.md](new.md).

### Step 1 — Existence + name check
- If `.claude/skills/loop-foreman/SKILL.md` already exists → do NOT overwrite. First **repair any
  missing registration** (idempotent): for each of `loop-foreman-grader` and
  `loop-foreman-researcher`, if `.claude/agents/<name>.md` does not resolve to the installed
  AGENT.md, (re)create it per Step 3's registration rule. Then report: "loop-foreman already
  installed (ref version N)[; re-registered <names>]." STOP. (A future `sync` will refresh its
  references; v1 has none.)

### Step 2 — Persona-uniqueness gate (BLOCKING)
Per the user directive *"Each agent being created by this system always has to have an appropriate
persona that is not being used anywhere else,"* run the Persona Assignment Gate before writing either
AGENT.md:
1. Glob BOTH agent forms and read every `persona:` field:
   `.claude/skills/*/agents/*/AGENT.md` AND `.claude/skills/*/agents/*.md` (and `.claude/agents/*.md`,
   dereferencing symlinks and deduping by resolved target).
2. The template personas are `loop-foreman-grader` ("Commissioning engineer who refuses to sign off a
   building until they have watched every system run under real load…") and `loop-foreman-researcher`
   ("Investigative fact-checker who never lets a claim stand until it is traced to a primary
   source…"). If either collides verbatim or by paraphrase with an existing persona → choose a
   distinct alternative that still fits the role, and report the substitution. Do not proceed with a
   duplicate.

### Step 2-bis — Model assignment (sacred directive, 2026-06-06)
Both generated agents get an explicit `model:` field per SKILL.md § Directives → Audit Agent
Model-Assignment Gate: their work is analysis / research / validation → the everything-else (coding)
lane's full model ID from `references/model-lanes.md`. (Both ship stamped `claude-opus-4-8` against
this repo's configured mapping; a `create` on another host re-resolves from that host's table.) Lanes
unconfigured or the cell empty → leave `model:` absent and flag; never invent an ID.

### Step 3 — Write the skill
From [../loop-foreman/skill-template.md](../loop-foreman/skill-template.md), write:
- `.claude/skills/loop-foreman/SKILL.md` (§SKILL.md) — keep frontmatter `lane: coding` and
  `loop_foreman_ref_version: <shipped version>`.
- `.claude/skills/loop-foreman/agents/loop-foreman-grader/AGENT.md` (§GRADER AGENT).
- `.claude/skills/loop-foreman/agents/loop-foreman-researcher/AGENT.md` (§RESEARCH-ASSISTANT AGENT).

**Register both agents so they are spawnable via the Task tool.** Writing the AGENT.md under the
skill directory is NOT enough — Claude Code only resolves a `subagent_type` registered under
`.claude/agents/<name>.md` (DEC-2026-06-23-code-eval-agent-registration). After writing each
AGENT.md, create its registration:
- `.claude/agents/loop-foreman-grader.md` → the grader AGENT.md
- `.claude/agents/loop-foreman-researcher.md` → the researcher AGENT.md
Prefer a symlink; fall back to a copy where symlinks are unavailable (Windows) and report which was
used. **Without this, the workflow's "Spawn the loop-foreman-grader (Task)" step resolves to nothing
and the loop ships on the mechanical oracle alone — defeating the two-check gate.** These are NOT
lane-excursion minions: do NOT stamp `generated-by: skill-builder lane-excursion` or a
`contract-stamp:` on them (DEC-2026-06-08).

Then COPY the shipped intel references verbatim from `<skill-builder-install>/references/loop-foreman/`
into `.claude/skills/loop-foreman/references/`: `workflow-recipe.md`, `grader-rubric.md`. (Do NOT copy
`version.md` or `skill-template.md` — those are skill-builder-side only.) The copied files keep their
`<!-- loop-foreman-ref-version -->` and `<!-- origin: skill-builder | modifiable: true -->` headers.

### Step 4 — Report + chain
Report the created tree, the resolved personas, and the ref version. Then run `route index --execute`
(so `/route` lists the new skill, which may then *offer* loop-foreman for large multi-task endeavors —
offer, never auto-arm). Recommend `route embed` so `/route` can dispatch to it.

---

## Deferred to later increments (NOT in v1)

- `sync` — refresh an installed loop-foreman's references when the shipped `loop-foreman-ref-version`
  is newer (mirror `code-eval sync`).
- `route` **auto-arm detection** of a "large rollout" — arming stays the offered work order.
- A host-generated **irreversible-action enforce hook** — until it exists the stop on irreversible
  actions is best-effort prose (grader-rubric.md § 4.1) and the pre-authorized list stays
  conservative.
