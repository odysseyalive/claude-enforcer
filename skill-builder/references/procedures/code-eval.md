# Code-Eval Command Procedure

<!-- Relocated verbatim from SKILL.md (2026-07-01 optimize): this command's always-loaded overview now lives here, one file-read away per the grounding pattern. -->
<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `code-eval` Command

Scaffold and maintain the `code-evaluator` skill — a language-agnostic code quality evaluator that prevents common AI coding mistakes (dead code, duplication, complexity hotspots, reinvented helpers, leftover scaffolding). This command is skill-builder machinery; the `code-evaluator` skill it produces is what end users run. The evaluator is AI-driven (ripgrep + opportunistic native tools, no compiled analyzer), built on a strict safety model: grep proposes candidates, the compiler and the test suite decide.

The created skill has a **three-layer model**, all owned by `code-evaluator`:
- **L1 — pre-write advisor:** the `code-design-advisor` agent, spawned by *other* code-touching skills at non-obvious code decisions (wired in by `route embed`), to evaluate a planned approach before code is written.
- **L2 — post-write review:** `/code-evaluator review [path]` runs the `deadcode-gardener` agent over a diff; only HIGH-confidence, guard-cleared dead code is auto-fixed.
- **L3 — full sweep:** `/code-evaluator sweep` fans out a whole-codebase report (report-only at scale).

Subcommands of `code-eval`:
- `/skill-builder code-eval create` — scaffold `code-evaluator` if absent (low-risk; executes). Copies the shipped intel references and writes the two agents after a persona-uniqueness check.
- `/skill-builder code-eval review [path]` — post-write evaluation (high-risk; display default, `--execute` to apply HIGH-tier fixes).
- `/skill-builder code-eval sweep` — full-codebase report (high-risk; display default).
- `/skill-builder code-eval sync` — refresh a user's `code-evaluator` references from skill-builder's shipped versions when the shipped `code-eval-ref-version` is newer (block-aware; preserves user-origin seams).
- `/skill-builder code-eval enforce` — host-generate the always-on enforcement hooks (high-risk; display default, `--execute` to wire). Three write-keyed phases — **before write** (PreToolUse hard block until the design-advisor gave direction), **at write** (PostToolUse review reminder), and a **commit gate** (PreToolUse hard block on `git commit`/`push` until the tree matches the last clean review — catches Bash-written code too). Closes the "code written with no skill loaded" gap that the shipped `CODE-EVAL-EMBED` gate cannot reach. Host-generated, NEVER shipped (No-Distribute-Hooks Gate); atomic generate-and-wire; fail-open; audit DEFER-recommends it but never auto-wires (DEC-2026-06-08, deliberate host act). "No exceptions" is the strongest honest backstop, not a literal guarantee — a hook nudges/blocks the model but cannot itself call a skill.

**Audit integration:** `audit` automatically ensures `code-evaluator` exists (creating it if absent) and runs `code-eval sync` to keep its references current, before the route terminal tasks; it also DEFER-recommends `code-eval enforce` when the evaluator is installed but the enforcement hooks are not wired. See [audit.md](references/procedures/audit.md) § Step 4a-bis.

**Grounding:** Read [references/procedures/code-eval.md](references/procedures/code-eval.md) for the full procedure (create / review / sweep / sync), [references/code-evaluator/skill-template.md](references/code-evaluator/skill-template.md) for the generated SKILL.md + advisor/reviewer agent templates, and [references/code-evaluator/cross-file-detection.md](references/code-evaluator/cross-file-detection.md) + [guards.md](references/code-evaluator/guards.md) for the detection method and false-positive guards.
<!-- /origin -->

---

Scaffold and maintain the `code-evaluator` skill — a language-agnostic code
quality evaluator that prevents common AI coding mistakes (dead code, duplication,
complexity hotspots, reinvented helpers, leftover scaffolding). This command is
skill-builder *machinery*; the `code-evaluator` skill it produces is what end
users actually run.

**Subcommands:** `create` · `review` · `sweep` · `sync` · `enforce`

```
/skill-builder code-eval create            # scaffold code-evaluator if absent (low-risk, executes)
/skill-builder code-eval review [path]     # post-write evaluation of a diff/path (high-risk, display default)
/skill-builder code-eval sweep             # full-codebase report (high-risk, display default)
/skill-builder code-eval sync              # refresh a user's code-evaluator references from shipped versions
/skill-builder code-eval enforce           # host-generate the always-on enforcement hooks (high-risk, display default)
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
- If `.claude/skills/code-evaluator/SKILL.md` already exists → do NOT overwrite the
  skill. First **repair any missing registration** (idempotent): for each of
  `code-design-advisor` and `deadcode-gardener`, if `.claude/agents/<name>.md` does
  not resolve to the installed AGENT.md, (re)create it per Step 3's registration
  rule. This self-heals installs created before registration was part of `create`
  (the agent files exist but were never registered, so the Phase 1 enforce hook's
  Task spawn cannot resolve). Then report: "code-evaluator already installed (ref
  version N)[; re-registered <names>]. Use `/skill-builder code-eval sync` to update
  its references." STOP.

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

**Register both agents so they are spawnable via the Task tool.** Writing the
AGENT.md under the skill directory is NOT enough — Claude Code only resolves a
`subagent_type` that has a registration under `.claude/agents/<name>.md`. After
writing each AGENT.md, create its registration (mirroring [agents.md](agents.md)
§ Step 4):
- `.claude/agents/code-design-advisor.md` → the advisor AGENT.md
- `.claude/agents/deadcode-gardener.md` → the reviewer AGENT.md
Prefer a symlink; fall back to a copy where symlinks are unavailable (Windows) and
report which was used. **Without this, the `code-eval enforce` Phase 1 hard block
instructs the model to "Spawn the code-design-advisor (Task)" — an agent type that
does not resolve — and the model is forced to improvise a bypass.** These are NOT
lane-excursion minions: do NOT stamp `generated-by: skill-builder lane-excursion`
or a `contract-stamp:` on them (that marker drives orphan-retirement deletion and
CONTRACT-DRIFT findings meant for cross-lane agents — DEC-2026-06-08).

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
- **Ensure both agent registrations resolve** (idempotent): for each of
  `code-design-advisor` and `deadcode-gardener`, if `.claude/agents/<name>.md` is
  missing, (re)create it per § create Step 3; on a copy-fallback host, refresh the
  copy so the registration never drifts from the AGENT.md sync just applied.

### Step 3 — Stamp + report
Update the user SKILL.md frontmatter `code_eval_ref_version` to `shipped`. Report:
"code-evaluator references updated vRECORDED → vSHIPPED" with the changed files
and the version.md changelog entries between the two versions.

### Display vs execute
Standalone `sync` executes (low-risk refresh of skill-builder-owned content).
When invoked from audit, it follows audit's mode: display mode reports the pending
update; execute mode applies it (see [audit.md](audit.md) § code-evaluator steps).

---

## Subcommand: `enforce`  (high-risk — display default, `--execute` to wire)

Host-generate the **always-on enforcement hooks** that make the `code-evaluator`
fire when code is written, regardless of whether any skill was loaded. This
un-defers the host-local hook backstop that DEC-2026-06-04 (item 7) anticipated.
The in-skill `CODE-EVAL-EMBED` gate (route.md § Step 7) is the *shipped*,
always-present layer; this subcommand adds the *host* layer that closes the
"code written with no skill loaded" gap.

**No-Distribute compliance (hard).** These hooks are generated ON THE HOST and
are NEVER shipped: they are not added to `skill-builder/hooks/`, not added to
`manifest.txt`, and not declared in any source `SKILL.md` frontmatter. The
EXCEPTION_HOOKS set (SKILL.md § Directives → No-Distribute-Hooks Gate) is exactly
`{protect-directives.sh, unique-persona.sh, protect-directives.ps1,
unique-persona.ps1}` — the enforce hooks are not in it and must never join it. This
subcommand is the sanctioned host-generation path, exactly like
`/skill-builder hooks --execute`.

**Posture (honest scope).** "No exceptions" is delivered as the strongest honest
mechanism, not a literal guarantee: a hook can nudge or block the model, but it
cannot itself call a skill, and code written via Bash (heredoc, `sed -i`, `tee`,
`cat >`) does not hit an `Edit|Write` matcher. The commit gate (Phase 3) is the
matcher-agnostic backstop that catches Bash-written code at the chokepoint. State
these residual gaps wherever the WIRED status is reported; never imply total
coverage. Phase 2's ladder signals are **heuristic pointers, not the evaluation**:
a grep can flag *that* a dependency manifest grew or *that* a name collides, but
only the advisor/reviewer decides whether it is actually over-built — the signal
narrows the agent's attention, it never renders a verdict.

### Enforce script versioning & drift

<!-- code-eval-enforce-version: 2 -->

The generated hook scripts are **versioned** so a wired host can detect when its
on-disk scripts predate the current procedure — the scripts are host-generated and
never shipped, so the installer/`code-eval sync` drift channel (which only refreshes
the markdown references) cannot carry an improved hook body. The shipped anchor is
the integer in the comment above (`code-eval-enforce-version`); **bump it whenever
any hook body in this section changes** in a way a wired host should receive. Each
generated script carries a matching `# code-eval-enforce-version: N` header line,
written at `--execute` time.

Drift is a one-way, host-only refresh:
- `shipped` = this section's anchor, read from the skill-builder install
  (`.claude/skills/skill-builder/references/procedures/code-eval.md`; in `dev` mode,
  the source path).
- `recorded` = the `# code-eval-enforce-version: N` header in the wired
  `.claude/skills/code-evaluator/hooks/code-eval-prewrite.sh` (absent → `0`, a
  pre-versioning install).
- `recorded >= shipped` → current. `recorded < shipped` → **stale**: the wired
  scripts predate the current signal/gate logic. `audit` Step 4a-bis and `verify`
  Step 3a DEFER-recommend a re-run of `/skill-builder code-eval enforce --execute`
  (never auto-run — re-wiring is a deliberate host act, exactly like initial wiring).
  Re-running regenerates every variant at the current version.

**Changelog:**
- **v1** (2026-06-23) — First versioned release. Phase 2 gains the deterministic
  ladder-signal pre-filter (rung 5 dependency / scaffolding / rung 2 reinvented
  helper). Pre-versioning wired installs report `recorded = 0` → stale → re-run.
- **v2** (2026-06-23) — Phase 1 before-write message gains a diagnostic line for the
  case where `code-design-advisor` does not resolve (unregistered/uninstalled
  evaluator): it points at `/skill-builder code-eval create` to restore the
  registration and forbids fabricating a substitute agent, instead of leaving the
  model to invent a bypass. Paired with the new registration step in `create`/`sync`
  (the agent is now actually spawnable). Wired pre-v2 hosts report `recorded(1) <
  shipped(2)` → stale → DEFER re-run.

### The three enforcement phases

| Phase | Event / matcher | Posture | Purpose |
|-------|-----------------|---------|---------|
| **1 — before write** | `PreToolUse` `Edit\|Write\|NotebookEdit` | **hard block** (`exit 2`) | On the first code write of a changeset, bounce until the `code-design-advisor` has supplied direction (what exists, what to reuse, what to watch). |
| **2 — at write** | `PostToolUse` `Edit\|Write\|NotebookEdit` | non-blocking inject | Track each changed source path as unreviewed; run the deterministic ladder-signal pre-filter (rung 5 / scaffolding / rung 2) over the added lines; debounced reminder to run `/code-evaluator review`. |
| **3 — commit gate** | `PreToolUse` `Bash` | **hard block** (`exit 2`) | Refuse `git commit` / `git push` while the working tree differs from the last clean review. Matcher-agnostic — catches Bash-written code too. |

### Marker contract (the shared state, all under `.claude/`, all git-ignored)

`enforce --execute` writes these names once; every hook and the evaluator's
coordination block reference them verbatim. Do not rename without updating all
consumers (the hooks, the evaluator's `CODE-EVAL-ENFORCE` block, verify, audit).

| Marker | Writer | Reader | Meaning |
|--------|--------|--------|---------|
| `.code-eval-active` | evaluator (review start/end) | all three hooks | evaluator is running its own review/auto-fix → hooks **skip** (loop guard). |
| `.code-eval-advised` | main model (after consulting the advisor) | Phase 1 | before-write direction taken for this changeset → Phase 1 allows writes. Cleared by a clean review. |
| `.code-eval-pending` | Phase 2 | Phase 2, verify | newline list of changed source paths not yet reviewed. Cleared by a clean review. |
| `.code-eval-reviewed` | evaluator (clean review) | Phase 3 | sha of the working-tree state at the last clean review. |
| `.code-eval-nudge-ts` | Phase 2 | Phase 2 | debounce timestamp so the at-write reminder fires ~once/120s, never per keystroke. |

### Preflight
1. Run the code-eval Preflight CHECKPOINT (dev parse, locate shipped refs, ground).
2. **Require `code-evaluator` installed.** If `.claude/skills/code-evaluator/SKILL.md`
   is absent → STOP: "code-evaluator not installed — run `/skill-builder code-eval create`
   first." The enforce hooks are inert without the skill they invoke.
2-bis. **Require both agents registered.** The Phase 1 hook hard-blocks until the
   `code-design-advisor` is spawned via Task — so it MUST resolve. For each of
   `code-design-advisor` and `deadcode-gardener`, confirm `.claude/agents/<name>.md`
   resolves to the installed AGENT.md; if missing, (re)create it per § create Step 3
   BEFORE wiring (it is additive/mechanical, not a hook write). Never wire a Phase 1
   hard block pointing at an unregistered agent.
3. **Require the evaluator coordination block.** The generated `code-evaluator`
   SKILL.md must carry the `CODE-EVAL-ENFORCE` managed block (shipped in
   skill-template.md § SKILL.md). If absent (an older evaluator) → append it via a
   `code-eval sync` first, then continue.

### Display mode (default)
Show, change nothing:
- The three hook scripts (bodies below) that WOULD be written to
  `.claude/skills/code-evaluator/hooks/`.
- The exact `.claude/settings.local.json` wiring entries (escaped-quoted
  `$CLAUDE_PROJECT_DIR`, shell-safety T3 form).
- The `.gitignore` lines that WOULD be added for the five markers.
- The current WIRED / UNWIRED status (are all three entries already present in
  `settings.local.json` and do their script files exist?), and for a wired host the
  scripts' `code-eval-enforce-version` vs the shipped anchor — WIRED / WIRED-STALE
  (§ Enforce script versioning & drift).

### Execute mode (`--execute`) — atomic generate-and-wire or neither
Generate a TaskCreate list; the whole set is **atomic**: if any step fails, roll
back so there is no on-disk-but-unwired half-armed state (the DEC-2026-06-08
lesson). Per OS, wire the matching variant (bash on linux/darwin, `.ps1` on
windows; read the session `Platform:` line — a concrete read, no agent).

1. Generate each script via `/skill-builder shell-safety write` (so the ERR trap,
   defensive stdin, and fail-open boilerplate come from the template, not
   hand-rolled), stamping the `# code-eval-enforce-version: <shipped>` header from
   the § Enforce script versioning anchor into each, save under
   `.claude/skills/code-evaluator/hooks/`, `chmod +x`.
2. `/skill-builder shell-safety lint` each script; a HARD finding aborts the whole
   atomic set (write nothing).
3. Wire all three entries into `.claude/settings.local.json` (T3 escaped-quoted
   form). Validate the merged JSON parses before keeping it.
4. Append the five marker names to `.claude/.gitignore` (create if absent) — these
   are runtime state, never committed.
5. Report `WIRED (scripts v<shipped>)` with the honest-scope note (Bash-written code
   is caught only at the commit gate; the before/at-write hooks are
   `Edit|Write|NotebookEdit`-scoped; a hook nudges/blocks the model but cannot itself
   call the skill). A re-run on an already-wired host is the sanctioned drift refresh
   — it regenerates every variant at the current version.

`/skill-builder code-eval enforce --remove [--execute]` strips all three wiring
entries and the script files, and reports the markers left behind (safe to delete).

### Hook bodies (bash — the host-generated scripts)

All three open with `trap 'exit 0' ERR` and read stdin defensively: **fail-open** —
any internal error exits 0 so a broken hook never bricks editing or commits
(shell-safety R3/R4/R5). `PROJ="${CLAUDE_PROJECT_DIR:-.}"` throughout.

**`code-eval-prewrite.sh`** — Phase 1, hard block before the first code write:
```bash
#!/bin/bash
# code-eval enforce — Phase 1 (before write): force design direction before code lands.
# code-eval-enforce-version: 2
trap 'exit 0' ERR
INPUT=$(cat 2>/dev/null) || exit 0
PROJ="${CLAUDE_PROJECT_DIR:-.}"
[ -f "$PROJ/.claude/.code-eval-active" ] && exit 0          # loop guard: evaluator's own edits
[ -f "$PROJ/.claude/.code-eval-advised" ] && exit 0         # direction already taken this changeset
FILE_PATH=$(printf '%s' "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
[ -z "$FILE_PATH" ] && exit 0
case "$FILE_PATH" in
  *.claude/*) exit 0 ;;                                      # skip skill machinery
  *.md|*.mdx|*.txt|*.rst|*.json|*.yaml|*.yml|*.toml|*.lock|*.cfg|*.ini|*.env) exit 0 ;;  # skip prose/config/data
esac
{
  echo "BLOCKED by code-eval enforce (before-write): get design direction before writing code."
  echo "1. Spawn the code-design-advisor (Task) for this approach — what already exists, what to reuse, what to watch for."
  echo "2. Then mark direction taken and re-attempt: touch \"$PROJ/.claude/.code-eval-advised\""
  echo "   If the code-design-advisor agent type does not resolve, the code-evaluator is not registered. Run /skill-builder code-eval create to restore it. Do NOT fabricate a substitute agent or skip the design check."
} >&2
exit 2
```

**`code-eval-postwrite.sh`** — Phase 2, track + deterministic ladder signals + debounced reminder:
```bash
#!/bin/bash
# code-eval enforce — Phase 2 (at write): track unreviewed source, emit deterministic ladder signals, remind to review.
# code-eval-enforce-version: 2
trap 'exit 0' ERR
INPUT=$(cat 2>/dev/null) || exit 0
PROJ="${CLAUDE_PROJECT_DIR:-.}"
[ -f "$PROJ/.claude/.code-eval-active" ] && exit 0          # loop guard
FILE_PATH=$(printf '%s' "$INPUT" | grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//')
[ -z "$FILE_PATH" ] && exit 0
case "$FILE_PATH" in *.claude/*) exit 0 ;; esac           # skill machinery

emit() {                                                   # $1 = plain text -> JSON additionalContext (fail-open)
  local esc
  esc=$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  printf '{"additionalContext":"%s"}\n' "$esc"
}

# rung 5 — dependency manifest grew. Checked BEFORE the code skip-list so package.json/etc. are seen.
case "$FILE_PATH" in
  */package.json|package.json|*/composer.json|composer.json|*/requirements*.txt|requirements*.txt|*/pyproject.toml|pyproject.toml|*/Cargo.toml|Cargo.toml|*/go.mod|go.mod|*/Gemfile|Gemfile|*/build.gradle*|*/pom.xml)
    if git -C "$PROJ" ls-files --error-unmatch -- "$FILE_PATH" >/dev/null 2>&1; then
      N=$(git -C "$PROJ" diff HEAD -- "$FILE_PATH" 2>/dev/null | grep -c '^+[^+]') || true   # tracked: added lines
    else
      N=$(grep -c . "$FILE_PATH" 2>/dev/null) || true                                        # untracked: whole file is new
    fi
    [ "${N:-0}" -gt 0 ] 2>/dev/null && emit "code-eval enforce — rung 5 (dependency): $FILE_PATH grew by ${N} line(s). Before a new dependency, check whether stdlib, a native feature, or an already-installed dep already covers what was added."
    exit 0 ;;
esac

# code files only beyond here
case "$FILE_PATH" in
  *.md|*.mdx|*.txt|*.rst|*.json|*.yaml|*.yml|*.toml|*.lock|*.cfg|*.ini|*.env) exit 0 ;;
esac
PENDING="$PROJ/.claude/.code-eval-pending"
grep -qxF "$FILE_PATH" "$PENDING" 2>/dev/null || printf '%s\n' "$FILE_PATH" >> "$PENDING" 2>/dev/null || exit 0

# Deterministic ladder signals over ADDED lines only (grep, no LLM). New/untracked file -> whole body is new.
# `|| true` on every grep-terminated substitution: a no-match grep returns non-zero, which the ERR trap
# would otherwise turn into a silent fail-open exit before the signal is ever emitted (shell-safety).
DIFF=$(git -C "$PROJ" diff HEAD -- "$FILE_PATH" 2>/dev/null | grep '^+' | grep -v '^+++') || true
[ -z "$DIFF" ] && DIFF=$(sed 's/^/+/' "$FILE_PATH" 2>/dev/null)
SIGNALS=""
SCAF=$(printf '%s' "$DIFF" | grep -noE 'console\.(log|debug)|\bdebugger\b|\bTODO\b|\bFIXME\b|\bdbg!|binding\.pry|pdb\.set_trace' | head -1) || true
[ -n "$SCAF" ] && SIGNALS="${SIGNALS}- scaffolding: debug/TODO marker in added lines ($SCAF) — strip before done.\n"
NAME=$(printf '%s' "$DIFF" | grep -oE '(def|function|fn|func)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' | head -1 | grep -oE '[A-Za-z_][A-Za-z0-9_]*$') || true
if [ -n "$NAME" ]; then
  REL="${FILE_PATH#"$PROJ"/}"                               # repo-relative, to match git grep's output and exclude self
  HIT=$(git -C "$PROJ" grep -wl -e "$NAME" 2>/dev/null | grep -vxF "$REL" | grep -ivE 'node_modules|vendor|dist|build|/\.' | head -1)
  [ -n "$HIT" ] && SIGNALS="${SIGNALS}- rung 2 (reuse): new \`$NAME\` may duplicate an existing symbol in $HIT — reuse before reimplementing.\n"
fi

# One debounced injection (~120s); actionable signals take priority over the generic reminder.
TS="$PROJ/.claude/.code-eval-nudge-ts"
NOW=$(date +%s 2>/dev/null) || exit 0
LAST=$(cat "$TS" 2>/dev/null || echo 0)
[ $((NOW - LAST)) -ge 120 ] || exit 0
printf '%s' "$NOW" > "$TS" 2>/dev/null
if [ -n "$SIGNALS" ]; then
  emit "code-eval enforce — ladder signals on added code:\n${SIGNALS}Then run /code-evaluator review; nothing commits until the review is clean."
else
  emit "code-eval enforce: source changed and not yet reviewed. Before declaring this code task done, invoke /code-evaluator review on the changed paths. Nothing commits until the review is clean."
fi
exit 0
```

### Deterministic ladder signals (Phase 2 — heuristic pre-filter)

Phase 2 runs three **grep-only** checks (no LLM, no skill call) over the *added*
lines of the just-written file, and folds any hit into the debounced injection so
the agent gets a *specific rung* instead of a generic "go review." They are a
pre-filter that points attention; the advisor/reviewer still renders every verdict.

| Signal | Maps to | Detection (added lines only) |
|--------|---------|------------------------------|
| **rung 5 — new dependency** | mistake-taxonomy.md "Needless new dependency" | the changed file is a known manifest (`package.json`, `requirements*.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, …) and `git diff HEAD` shows ≥1 added line |
| **scaffolding** | mistake-taxonomy.md "Leftover scaffolding" | added line matches `console.log/debug`, `debugger`, `TODO`/`FIXME`, `dbg!`, `binding.pry`, `pdb.set_trace` |
| **rung 2 — reinvented helper** | mistake-taxonomy.md "Reinvented helper" | an added top-level `def`/`function`/`fn`/`func` name that `git grep -w` also finds elsewhere in the repo (excluding the file itself and vendored/build dirs) |

Discipline (all fail-open, all bounded):
- **Added lines only** (`git diff HEAD`, or the whole body for an untracked new
  file) so pre-existing code is never re-flagged.
- **`git grep`, not a new tool** — reuses the git the commit gate already needs; no
  dependency on `rg` being installed.
- **Debounced** through the existing `.code-eval-nudge-ts` (≤1 injection / ~120s),
  so a colliding name on a file edited repeatedly cannot nag.
- **Heuristic, never a verdict** — `print(` is deliberately excluded (too noisy in
  Python); the reinvented-helper signal says "*may* duplicate," and the agent
  confirms via the advisor against `guards.md` before acting.
- New pitfall classes are added to this signal list the same way the taxonomy
  grows — one place, regenerated into the host script on the next `enforce`.

**`code-eval-commit-gate.sh`** — Phase 3, hard block on commit/push until reviewed:
```bash
#!/bin/bash
# code-eval enforce — Phase 3 (commit gate): no commit/push until the tree matches the last clean review.
# code-eval-enforce-version: 2
trap 'exit 0' ERR
INPUT=$(cat 2>/dev/null) || exit 0
PROJ="${CLAUDE_PROJECT_DIR:-.}"
[ -f "$PROJ/.claude/.code-eval-active" ] && exit 0
CMD=$(printf '%s' "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+(commit|push)\b' 2>/dev/null || exit 0
CUR=$( { git -C "$PROJ" diff HEAD 2>/dev/null; git -C "$PROJ" status --porcelain 2>/dev/null; } | sha256sum 2>/dev/null | cut -d' ' -f1)
[ -z "$CUR" ] && exit 0                                     # not a git repo / no sha tool → fail-open
SAVED=$(cat "$PROJ/.claude/.code-eval-reviewed" 2>/dev/null || echo "")
if [ "$CUR" != "$SAVED" ]; then
  {
    echo "BLOCKED by code-eval enforce (commit gate): the working tree changed since the last clean /code-evaluator review."
    echo "Run /code-evaluator review (it stamps the reviewed state on a clean pass), then commit."
  } >&2
  exit 2
fi
exit 0
```

### Hook bodies (PowerShell companions — `.ps1`)

Fail-open and **untested on a real Windows host** (same standing caveat as the
shipped `.ps1` exception hooks — DEC-2026-06-06-cross-platform-installer). Wired
only on `windows` platforms. Each mirrors its bash sibling: read `$input`, resolve
`$env:CLAUDE_PROJECT_DIR`, honor the same markers and skip-list, `exit 2` to block
(Phase 1 / 3) or emit the `additionalContext` JSON (Phase 2). The Phase 2 port
mirrors the same three ladder signals (rung 5 / scaffolding / rung 2) using
`git diff`/`git grep` and `Select-String`. Any error path falls through to
`exit 0`. Generate them with `/skill-builder shell-safety write` (the
PowerShell template) at `--execute` time; do not hand-roll. Each `.ps1` carries the
same `# code-eval-enforce-version: N` header so the drift check covers Windows too.
Until validated on a real Windows host, Windows status reports
`UNWIRED (PowerShell port unvalidated)` rather than implying coverage.

### Evaluator coordination (why the markers stay consistent)
The hooks only set/read markers; clearing them is the evaluator's job, wired by the
`CODE-EVAL-ENFORCE` block in the generated `code-evaluator` SKILL.md
(skill-template.md § SKILL.md). On every `review`: set `.code-eval-active` at
start, remove it at end (loop guard); on a **clean** pass, write the
`.code-eval-reviewed` sha and delete `.code-eval-pending` and `.code-eval-advised`.
The before-write protocol (consult advisor → `touch .code-eval-advised` →
re-attempt) is named in Phase 1's block message and documented in that block.

### Audit & legibility integration
- **Audit (DEFER only, never auto-wire).** Audit Step 4a-bis detects "installed
  but enforcement unwired" → DEFERs `/skill-builder code-eval enforce --execute`,
  AND "wired but stale" (`recorded < shipped` per § Enforce script versioning &
  drift) → DEFERs the same re-run with a "scripts predate the current procedure"
  reason. Both carry the honest-scope note. Audit must NEVER auto-wire OR auto-refresh
  these hooks — wiring/re-wiring is a deliberate host act (DEC-2026-06-08; SKILL.md
  § Directives → No-Distribute-Hooks Gate). They are not in the Audit Autonomy Gate's
  AUTO tier.
- **verify** reports a `Code-eval enforcement` WIRED / WIRED-STALE / UNWIRED row
  (staleness = wired scripts older than the shipped `code-eval-enforce-version`).
- The `CODE-EVAL-EMBED` block (route.md § Step 7d) surfaces enforcement status so a
  dormant hook is never mistaken for live coverage.

---

## Grounding

- [../code-evaluator/version.md](../code-evaluator/version.md) — drift anchor (shipped version + changelog)
- [../code-evaluator/skill-template.md](../code-evaluator/skill-template.md) — generated SKILL.md + advisor/reviewer AGENT.md templates
- [../code-evaluator/cross-file-detection.md](../code-evaluator/cross-file-detection.md), [guards.md](../code-evaluator/guards.md), [mistake-taxonomy.md](../code-evaluator/mistake-taxonomy.md), [native-tool-map.md](../code-evaluator/native-tool-map.md), [gotchas.md](../code-evaluator/gotchas.md) — the shipped intel set
- [new.md](new.md) — scaffolding contract `create` mirrors
- [route.md](route.md) — the embed gates that wire the advisor/reviewer into code-touching skills
- [audit.md](audit.md) — automatic ensure-exists + sync integration; Step 4a-bis DEFERs `enforce` when unwired
- [shell-safety.md](shell-safety.md) — `shell-safety write`/`lint` generate and validate the `enforce` hook scripts (fail-open, R1–R9)
