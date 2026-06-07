## Strip Command Procedure

**Delete a skill completely and remove every connection to it from all other skills, settings, and dev-repo manifests.**

`strip` is the destructive counterpart to `new`. It deletes the target skill directory and sweeps every cross-reference (grounding links, route entries, hook bindings, permissions, prose mentions, agent grounding, installer manifests) so nothing dangles. High-risk — defaults to display mode and requires `--execute` to make changes.

### Preflight — self-exclusion (HARD REFUSAL)

If the target skill is the literal string `skill-builder` → REFUSE unconditionally, even when invoked as `/skill-builder dev strip skill-builder`. Print:

> "Refused: stripping skill-builder via skill-builder would delete the running tool mid-execution. To uninstall skill-builder, remove `.claude/skills/skill-builder/` manually after closing this session and rerun the installer if you want it back. The `dev` prefix permits self-modification, not self-deletion."

Stop. Do not dispatch.

For any other target, apply the standard self-exclusion CHECKPOINT from SKILL.md (the `dev` prefix is not required for non-self targets — strip operates on user skills by default).

### Display Mode (default) — `/skill-builder strip [skill]`

Display mode makes no file modifications. It produces an impact report so the user can review every connection before approving deletion.

#### Step 1: Validate target

```
Glob: .claude/skills/[skill]/SKILL.md
```

If the skill does not exist, report: "Skill /[skill] not found. Nothing to strip." and stop.

#### Step 2: Enumerate the skill's surface

Read the target's directory tree. Record:
- SKILL.md (line count)
- All `references/**/*.md`
- All agent files in BOTH forms: `agents/*.md` (flat-file agents) AND `agents/*/AGENT.md` (subdirectory-form agents)
- All `hooks/*` scripts
- Any `*.sha` checksum sidecars

This becomes the "to be deleted" inventory in the report.

#### Step 2b: In-target sacred content precheck (directive-touch hard floor extended to deletion)

Scan every file in the Step 2 inventory for `<!-- origin: user | ... immutable: true -->` blocks. **Deleting a file IS an edit span intersecting the immutable block** — the directives-are-sacred convention does not stop applying because the whole container is being removed.

- IF any immutable block exists in the target → the strip is **BREAKING (sacred content)** regardless of dependents, and execute mode additionally requires **rehoming evidence**: the impact report must list each sacred block verbatim with its proposed new home (a surviving file the user names — e.g. the project's model-lanes.md directive region or a project directives file), and the user must have confirmed the rehomed copy as canonical BEFORE `--execute --confirm-breaking` is honored. The move is verbatim, markers intact — move-don't-rewrite applies absolutely. The completion report records every `old path → new path`.
- IF no immutable blocks → no change to the normal flow.

#### Step 3: Detect hard dependents

Some skills are referenced as load-bearing infrastructure by other skills. Stripping them leaves dangling reads that fail at runtime. Detect dependents by scanning every other skill for references to the target:

```bash
# Across .claude/skills/<other>/ for every other != target:
grep -rE \
  "(\.claude/skills/<target>/|\.\./<target>/|(?<![A-Za-z0-9_-])/<target>\b)" \
  .claude/skills/ \
  --include="*.md" --include="*.sh"
```

For each dependent skill found, record:
- Path of the file referencing the target
- The literal reference (link, prose mention, hook command)
- Severity: **HARD** if the reference is inside a workflow Read instruction, hook script body, or AGENT.md grounding; **SOFT** if it is prose, an auto-chain hint, or a comment

If any dependent has a HARD reference → mark the strip as **BREAKING** in the report and require an extra confirmation phrase to proceed in execute mode (see § Execute Mode step 0).

#### Step 4: Run the connection sweep

Apply each of the 17 detection patterns below across `.claude/skills/`, `.claude/agents/`, `.claude/settings.local.json`, and (if present at repo root) the `install` script and dev-only docs (`CLAUDE.md`, `COMMANDS.md`). Capture every hit with file path and line number.

| # | Pattern | Detection regex | Surface |
|---|---|---|---|
| 1 | Cross-skill `.claude/skills/<target>/...` paths | `\.claude/skills/<target>(/|\b)` | All `*.md`, `*.sh`, `*.json` |
| 2 | Relative `../<target>/...` links | `\]\(\.\./<target>/` | All `*.md` |
| 3 | Slash-skill prose mentions `/<target>` | `(?<![A-Za-z0-9_-])/<target>\b` | All `*.md` |
| 4 | Route catalog rows | `^\| /<target> \|` and `^### /<target>$` | `.claude/skills/route/references/index.md` |
| 5 | ROUTE-EMBED blocks naming the target | `<!-- ROUTE-EMBED START -->` … `<target>` … `<!-- ROUTE-EMBED END -->` | All SKILL.md |
| 6 | Hook commands referencing target's hooks dir | `\.claude/skills/<target>/hooks/` | `.claude/settings.local.json`, all SKILL.md frontmatter `hooks:` |
| 7 | `Skill(<target>)` permission entries | `Skill\(<target>\)` | `.claude/settings.local.json` |
| 8 | `Read(...skills/<target>/**)` permission entries | `skills/<target>/\*\*` | `.claude/settings.local.json` |
| 9 | Agent cross-skill grounding | `\.claude/skills/<target>/` inside agent files | All agent files in BOTH forms: `agents/*.md` (flat) AND `agents/*/AGENT.md` (subdir) |
| 10 | Auto-chain directives in prose | `(auto.?chain\|auto.?invoke\|chain (from\|to)\|invoke /<target>)` | All `*.md` |
| 11 | Hook script bodies that name the target | `<target>` inside `*/hooks/*.sh` | All hook scripts |
| 12 | Companion-skill hard-dependency phrases | `<target>/(ledger\|references)` if target is a known companion (awareness-ledger, voice, writing, text-eval, image-eval) | All `*.md` |
| 13 | Repo-root `install` per-skill loops | `for (ref\|proc\|ss\|agent) in` containing the target's files | `/install` (dev-only) |
| 14 | Repo-root `COMMANDS.md` mentions | target name as plain word | `/COMMANDS.md` (dev-only, if exists) |
| 15 | Repo-root `CLAUDE.md` mentions | target name as plain word | `/CLAUDE.md` (dev-only, if exists) |
| 16 | Lane-pinned excursion agents owned by the target | `excursion-skill: <target>` in agent frontmatter | All agent files (both skill forms) AND `.claude/agents/*.md` registration symlinks/copies (deref symlinks; remove the registration entry along with the agent) |
| 17 | LANE-AGENT-EMBED map entries naming the target's agents | `<!-- LANE-AGENT-EMBED START -->` … `<target>-` … `<!-- LANE-AGENT-EMBED END -->` | All SKILL.md |

Patterns 13–15 only fire if the corresponding files exist at the working-directory root (i.e., the user is running this in the source repo, not a downstream install). Surface them as "dev-repo cleanup" in the report; do not error if absent. Patterns 16–17 fire only when lane-pinned agents exist (see `references/lane-delegation.md`); they are swept before deletion like every other reference.

#### Step 5: Produce the strip report

```
## Strip Report: /[target]

**To be deleted:**
- .claude/skills/[target]/ ([N] files, [L] total lines)
  - SKILL.md ([n] lines)
  - references/* ([m] files)
  - agents/* ([k] AGENT.md files)
  - hooks/* ([h] scripts)

**Dependents:** [BREAKING / clean]
- HARD references: [N]
  - .claude/skills/[other]/[file]:[line] — [literal text, first 80 chars]
- SOFT references: [N]
  - .claude/skills/[other]/[file]:[line] — [literal text]

**Connection sweep:** [total hits across patterns 1–15]
- Pattern [#] (description): [count] hit(s)
  - [path]:[line] — [literal text]
  ...

**Settings cleanup:** ([yes / nothing to do])
- .claude/settings.local.json: [N] entries to remove
  - permissions.allow: Skill([target]), Read(...skills/[target]/**)
  - hooks.[event]: [list of hook commands referencing target]

**Dev-repo cleanup:** ([yes / nothing to do / not applicable — not in source repo])
- install: target appears in [N] loop(s)
- COMMANDS.md: [N] mention(s)
- CLAUDE.md: [N] mention(s)

**Status:** [SAFE / BREAKING]

To execute:
  /skill-builder strip [target] --execute
[If BREAKING:]
  Confirmation required. Re-run with: /skill-builder strip [target] --execute --confirm-breaking
```

Display mode ends here.

### Execute Mode — `/skill-builder strip [skill] --execute`

Execute mode applies the changes from the display report.

#### Step 0: Re-confirm and gate

1. Re-read display-mode results (rerun steps 1–4, including the Step 2b sacred-content precheck) to detect any drift since display.
2. If status is BREAKING and the invocation lacks `--confirm-breaking`, REFUSE and print the report's confirmation hint. Stop.
3. If the target contains sacred content (Step 2b) and there is no confirmed rehoming for every immutable block → REFUSE even with `--confirm-breaking`. Print: "Target contains immutable user directives with no ratified rehoming. Confirm each block's new home first — sacred text is never deleted, only moved verbatim." Stop.
4. If the user passed `--confirm-breaking` but status is SAFE (no HARD references, no sacred content), proceed normally — the flag is harmless when unneeded.

#### Step 1: Build the task list

Run TaskCreate with one task per discrete action, in the strict order below. The order matters: sweep references *before* deletion so other skills never sit on disk pointing at a missing target. Tasks:

1. Sweep grounding links and prose mentions in remaining `.claude/skills/*/SKILL.md`
2. Sweep `.claude/skills/*/references/**/*.md`
3. Sweep agent files in BOTH forms: `.claude/skills/*/agents/*.md` (flat) AND `.claude/skills/*/agents/*/AGENT.md` (subdir). Union the two — skipping one form leaves dangling references in those agent files.
4. Sweep hook script bodies in `.claude/skills/*/hooks/*`
5. Strip live `<!-- ROUTE-EMBED START -->` blocks naming the target (if any)
6. Update `.claude/settings.local.json` (remove `Skill(<target>)`, `Read(...skills/<target>/**)`, hook entries pointing at `<target>/hooks/`)
7. Update repo-root `install` (remove target from per-skill loops) — dev-only, skip if file absent
8. Update repo-root `COMMANDS.md` and `CLAUDE.md` (flag for human review with diff; do NOT auto-edit prose) — dev-only
9. Delete `.claude/skills/[target]/` recursively
10. Regenerate the route catalog: invoke `/skill-builder route index --execute` if `.claude/skills/route/` exists
11. Delete `.directives.sha` sidecar for the target (already covered by step 9, but verify)
12. Final verification sweep (re-run patterns 1–12) — must return zero hits naming the target

Mark each task complete via TaskUpdate as it finishes.

#### Step 2: Apply edits per pattern

**For pattern 1, 2, 3 (grounding links and prose mentions):**
- Inside link constructs `[text](path)` or `[text](../target/...)`: remove the entire bullet/line containing the link if the link was the line's payload; otherwise replace the link with the link's plain text. Never leave a dangling `[text]()` or `(broken-path)`.
- Inside prose body text (`/target` mentions outside markdown links): remove the mention by rewriting the sentence to drop the dependency, OR — for SOFT auto-chain mentions ("auto-chains to /target") — remove the entire sentence. Bias toward sentence-removal over rewording: this preserves the move-don't-rewrite principle for surrounding directive text.

**For pattern 5 (ROUTE-EMBED blocks):** if the target is the embed's referenced skill, delete the entire block from `<!-- ROUTE-EMBED START -->` through `<!-- ROUTE-EMBED END -->` inclusive. Do not partially edit embed blocks; they are auto-generated regions.

**For pattern 6, 7, 8 (settings.local.json):**
- Use a JSON-aware edit (parse → mutate → write back with stable formatting). Do not regex-edit JSON.
- Remove permissions entries by exact-string match.
- For `hooks.[event]` arrays, drop any object whose `command` references `.claude/skills/<target>/`.
- After mutation, verify the file still parses as valid JSON before writing.

**For pattern 9 (AGENT.md grounding):** same rules as pattern 1; AGENT.md grounding bullets are typically formatted as `- Read [.claude/skills/.../file.md] for X`. Remove the whole bullet.

**For pattern 10 (auto-chain prose):** delete the auto-chain instruction (sentence or bullet). If the auto-chain was inside a CHECKPOINT block, remove the entire CHECKPOINT block — it has no purpose without its target.

**For pattern 11 (hook scripts):** if the script's sole purpose is auto-chaining the target (e.g., `chain-image-eval.sh` when target is `image-eval`), delete the script entirely AND remove its hook entry from settings.local.json. Otherwise scrub the target name from the script body, preserving surrounding logic.

**For pattern 13 (install loops):** edit the appropriate `for ref in …` / `for proc in …` / `for ss in …` loop in `/install` to drop the target's filename(s). If the target is itself a top-level skill (not just files inside skill-builder), there will be no per-skill loop entry for it because each skill installs as its own directory; in that case patterns 1–12 cover the cleanup and `install` does not need editing.

**For patterns 14, 15 (repo-root CLAUDE.md / COMMANDS.md):** do NOT auto-edit prose in these files. Instead emit a "Manual review required" section in the final report with the file:line locations and the surrounding text, so the maintainer can rewrite by hand.

#### Step 3: Delete the skill directory

Only after every sweep task above has completed and verification of valid JSON / link integrity has passed:

```bash
rm -rf .claude/skills/[target]
```

This is irreversible at the filesystem layer. Git is the recovery mechanism — no separate backup is created.

#### Step 4: Regenerate route catalog

If `.claude/skills/route/` exists, invoke `/skill-builder route index --execute`. The route procedure is idempotent and will drop the target's catalog row and per-skill detail section.

If `.claude/skills/route/` does not exist, skip silently.

#### Step 5: Final verification

Rerun the connection sweep (patterns 1–12, target name as needle). Required result: zero hits. If any hits remain:
- Report them under "Verification failed" in the final report.
- Do NOT attempt automatic remediation — the strip is already destructive enough; surface the orphans for the user to inspect.

#### Step 6: Report completion

```
## Strip Complete: /[target]

**Deleted:** .claude/skills/[target]/ ([N] files removed)

**Connections removed:** [total]
- [pattern description]: [N] edits in [M] files
  ...

**Settings cleanup:** [N] entries removed from .claude/settings.local.json

**Dev-repo cleanup:**
- install: [N] entries removed / not applicable
- COMMANDS.md / CLAUDE.md: [N] manual-review locations flagged below

**Route catalog:** [regenerated / skipped — no /route skill installed]

**Verification sweep:** [PASS — zero remaining references / FAIL — N orphans listed below]

**Manual review required:**
[list of file:line locations from patterns 14, 15]

[If verification failed:]
**Orphaned references (clean up manually):**
[file:line — text]
```

### Notes

- **No `--all` mode.** Bulk-strip is too destructive to automate; each target is a separate invocation.
- **No backup.** Git is the source of truth; users are expected to commit before stripping.
- **Idempotency.** Running strip on a target that does not exist is a no-op (returns "Skill /[target] not found").
- **Self-exclusion absolute.** Stripping `skill-builder` is hard-refused regardless of `dev` prefix (the prefix permits self-modification, not self-deletion). The CHECKPOINT for normal self-exclusion does not gate this — the preflight refusal at the top of this procedure does.

**Grounding:** `references/principles.md` (move-don't-rewrite for sweep edits), `references/procedures/route.md` (route index regeneration), `references/procedures/post-action-chain.md` (NOT invoked — strip is a deletion, not a modification).
