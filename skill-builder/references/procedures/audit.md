## Audit Command Procedure

**When invoked without arguments or with `audit`, run the full audit as an orchestrator.**

### Sacred-Directive Enforcement Gates (relocated from SKILL.md, 2026-07-01)

<!-- The following ENFORCEMENT ANNOTATION blocks moved VERBATIM from SKILL.md, comment headers intact. They are literal-execution gates for sacred user directives (SKILL.md, Directives section). Execute them exactly as written whenever their triggers fire; never reword or reorder their contents. -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "Bifurcate jobs based on the currently selected model — split jobs between creative work (ie image generation, content generation, and design generation) and coding (everything else, including testing). When we run an audit, I want to make sure it's fluid in managing switching between models, with prompting, or not." -->
CHECKPOINT — Model-Lane Routing Gate (fires during `audit`; see audit.md § Step 4f):
1. Read `references/model-lanes.md`. Parse the Lane→Model table, the Skill→Lane table, and the `<!-- model-lane-setup: <state> -->` per-project marker (missing = `unset`).
2. IF the Skill→Lane table has no active (non-commented) rows AND no skill self-declares a `lane:` frontmatter key → the mapping is UNCONFIGURED. Branch on the setup-state marker (the onboarding fork; see audit.md § Step 4f-setup):
   - `model-lanes.md` absent entirely, OR marker is `declined`, OR the run is suppressed (headless/non-interactive or `audit --quick`) → STOP this gate silently (no report section, no setup question, no marker write). An undeclared/declined preference is correctly absent, not a gap.
   - marker is `unset` AND this is a full interactive `audit` → run the one-time Setup Onboarding Flow (offer Set it up now / Not now / Never ask). "Set it up now" → suggest+confirm per-skill lanes, confirm the Lane→Model mapping, write them plus `configured` into model-lanes.md (the only write this gate makes; it still never switches the model). "Not now" → leave `unset`. "Never ask" → write `declined`. Then continue or stop accordingly.
3. Determine `ACTIVE_MODEL`: read the session system-context line "The exact model ID is ...", strip any `[1m]`/`[200k]` suffix, lowercase. This is a concrete read (no judgment) → no agent required.
4. For each audited skill, resolve its lane ONLY from a declared source: `lane:` frontmatter → Skill→Lane table → NO LANE. A skill with no declared lane is SKIPPED — never auto-classified into a flag. (Audit MAY print a non-blocking lane *suggestion* for undeclared skills per model-lanes.md § Advisory Lane Suggestion; a suggestion never triggers a prompt.)
5. Look up the resolved lane's Preferred Model. IF empty/absent → do NOT flag (lane flagging disabled by an empty cell). IF non-empty AND `preferred_model != ACTIVE_MODEL` → record a mismatch.
6. Reporting: list every mismatch in the Step 5 "Model Lane" report section (Skill | Lane | Preferred | Active | Source). This is report-only and never blocks.
7. Reporting is the CEILING (superseded mechanic, 2026-06-06 No-Switch-Prompt Gate): the report section in step 6 is the gate's entire output. NEVER emit a switch prompt, an AskUserQuestion, or any instruction to run `/model` — mismatches are stated as one-line advisories and the audit proceeds. (The pre-2026-06-06 batched switch prompt is abolished; `--model-prompt` is retired; `--no-model-prompt` is accepted as a harmless no-op.)
8. Suppression ("or not"): IF the session is headless/non-interactive (e.g. `verify`), the section still prints when mismatches exist; `audit --quick` omits the section entirely.
9. IF the gate fired but the model-lanes mapping could not be read while at least one skill declares a lane → STOP. Report: "Model-lane mapping unreadable; cannot evaluate model routing. Fix references/model-lanes.md."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When a project is audited and the model switching setup is deciding what is most likely creative, I want to make sure to flag any skill that has to do with communication, language translation, text evaluation, etc as creative." + "Anything that has to do with research must be performed by the coding model before being handed off to creative." -->
CHECKPOINT — Creative-Scope Classification Gate (fires wherever a lane is SUGGESTED: audit Step 4f advisory suggestions and the Step 4f-setup onboarding's per-skill lane suggestions):
1. Before emitting any lane suggestion for a skill, test its name and description against the signal lists in references/model-lanes.md § Advisory Lane Suggestion. Those lists implement this directive: communication, language-translation, and text-evaluation signals resolve to `creative`.
2. RESEARCH PRECEDENCE — evaluate BEFORE any creative signal: IF the skill's name or description indicates research (name token `research`; description terms `research`, `cited`) → suggest `coding` and STOP, regardless of creative hits. Research is performed by the coding model before any handoff to creative.
3. IF no research signal fired AND the skill's purpose is communication (email, messages, correspondence), language translation, or text evaluation → the suggestion MUST be `creative`. Never suggest `coding` for such a skill.
4. This gate widens SUGGESTIONS only — lane assignment stays declared-never-inferred (model-lanes.md principle 2); a suggestion never auto-assigns a lane and never produces anything beyond its advisory line.
5. IF a new class of skill requires a signal-list change to honor steps 2–3 → edit references/model-lanes.md; do NOT reword this directive or the 2026-06-01 directive.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "All agents created or modified during the audit should have a model specified, per the user's choice of creativity model and everything else model." -->
CHECKPOINT — Audit Agent Model-Assignment Gate (fires whenever audit, or any command running under audit — agents, code-eval create/sync, ledger — creates or modifies an AGENT.md):
1. Before writing the AGENT.md, read the Lane→Model table in references/model-lanes.md.
2. Classify the agent's own work (not its parent skill's): creative (content/image/design generation, communication, translation, text evaluation) vs everything-else (coding, testing, research, analysis, validation). Research ALWAYS classifies as everything-else per the 2026-06-06 research-precedence directive. IF the classification is not overtly obvious → apply the Non-Obvious Decision Gate (agent input) before stamping.
3. Stamp `model:` in the agent frontmatter with the classified lane's full model ID from the table. Never use an alias when a full ID is configured; never invent an ID.
4. IF the lanes are UNCONFIGURED (no Lane→Model preference declared, or the relevant cell is empty) → do NOT invent a model. Leave `model:` absent and flag the agent in the audit report: "agent has no model: — configure model lanes to enable assignment."
5. During audit's scan phase: any existing AGENT.md missing a `model:` field while lanes ARE configured → flag in the Model Lane report section with a fix task (stamp on `--execute`). Modifying any other part of an agent during audit also triggers this gate for that agent.
6. A remap of the Lane→Model table at the audit picker fans out to every `lane-pinned:` agent's `model:` field per references/lane-delegation.md § Fleet Rewrite — the rewrite touches the `model:` line only.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "likewise, I would like to prevent questions like this from happening, too. … The audit command should be as automated and streamlined as possible. There shouldn't be any hard questions like this for the user." + "I don't mind the two questions for choosing the creative model and analytical model. that needs asked every time audit is ran, regardless. Just limit any additional questions. Always do the work, instead of suggestion to skip work that will improve the system." -->
CHECKPOINT — Audit Autonomy Gate (governs every `audit` run, full and `--quick`, from Step 0 through completion):
1. FIVE QUESTIONS ONLY (the count was raised three → four by the 2026-06-24 Companion-Skill Selection Gate directive, then four → five by the 2026-06-24 Backup Offer directive, both newest-wins; this annotation's source-directive text and clause numbering are otherwise unchanged). An audit run may ask the user exactly: (a) the Step 0 disclaimer (Accept and proceed / Cancel audit), (b) the Step 0.2 Backup Offer (back up or not — fired SECOND, right after the disclaimer; suppressed in headless / non-interactive / `audit --quick`), (c) the Step 0.3 Companion-Skill Selection Gate (two grouped multi-selects — Evaluators / Helpers — in ONE AskUserQuestion call, so still ONE question slot; fired THIRD, right after the backup offer; same suppression), (d) the one-time 4f-setup lane onboarding, and (e) the Lane→Model picker — (a), (b), (c), and (e) asked EVERY full interactive audit run, regardless, per the user's verbatim instruction; (d) is one-time. NO other AskUserQuestion, y/n offer, execution menu, or end-of-turn decision question may be emitted anywhere in the audit path, including bootstrap mode, quick mode, chained sub-commands, and the post-action chain when its parent is audit. The backup offer and the companion gate are each a consent instrument alongside the disclaimer: backup authorizes ONE AUTO zip task at the head of Step 6 (never a delete); the companion gate authorizes the install half (AUTO) and feeds the removal half into the DEFER `strip` tier (clause 4) — neither auto-deletes.
2. DISCLAIMER = CONSENT. Step 0 acceptance authorizes the whole run: scan → report (including the Execution Plan block) → auto-execute the AUTO-tier task list via TaskCreate, sequentially, under Display/Execute rules 4 and 5 (the printed task list is the contract; never add unplanned work mid-run).
3. ALWAYS DO THE WORK. Work that improves the system is EXECUTED, never offered as skippable: mechanical fixes (descriptions reflowed without ever truncating or shortening — they are documentation), optimize/agents/hooks fixes, code-eval create/sync, Awareness Ledger creation, bootstrap CLAUDE.md extraction of HIGH-confidence candidates, reconcile's two mechanical auto-fixes, orphan minion retirement (marker-verified), and the terminal route index + route embed.
4. DEFER tier — the ONLY legitimate deferrals, each reported as a Deferred Items row (item | why | exact command), never silently dropped: strip deletions (consent lives in strip's own gates); convert/2-Brain migration (its inline sacred ratification gates cannot fire in a no-questions run); quarantine repairs of hand-authored files; protective or unrecoverable dead-wiring decisions; AMBIGUOUS bootstrap extraction candidates; and git-dependent fixes (optimize auto-revert, orphan deletion) when the project has no VCS safety net.
5. AMBIGUITY mid-run: agent panels fire exactly as procedures demand (the agent budget's display-mode suppression does not apply to the auto-execution phase). Panels agree → proceed; disagree → conservative alternative; a minion's `AMBIGUOUS:` return under audit resolves conservatively or DEFERS — never a mid-run user question, never a guess.
6. CONTAINMENT: Step 0.5 VCS preflight (clean → full AUTO; dirty → proceed with a one-line warning; no VCS → downgrade git-dependent items to DEFER). Per-task failure → mark ✗, continue independent tasks, skip dependents, surface in the Execution Summary. HEADLESS runs are scan+report-only — the acceptance marker unlocks the scan, NEVER writes; auto-execution requires a live Step 0 acceptance this run.
7. ESCAPE HATCH: `audit --review` (alias `--dry-run`) = full scan + report + would-be Execution Plan, zero writes, zero execution. `audit --execute` is accepted as a harmless no-op (execution is now the default).
8. The terminal report (Execution Summary + Deferred Items) is informational prose — it never ends with a question (Rule 8's over-fire guard applies: it is not a decision handoff).
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "I would like to add a gatekeeping item to the audit process. … If an item is unchecked, then audit should remove that skill set from the project." + "this question should be moved to second in line right after the acknowledgment question." + "If route is in this list, just make sure that in parentheses next to it it shows as recommended item. The same goes for ledger." + "Always defer to strip. But the removal process should be smart enough to go through all of the rest of the skills and remove it completely … the route index and rote embedding will affect the outcome too." -->
<!-- Amending directive (2026-06-25, Evaluators/Helpers split): "I like the idea of breaking up the list between Evaluators and Helpers." The gate renders as TWO grouped multi-selects in ONE call (count stays FIVE). -->
CHECKPOINT — Companion-Skill Selection Gate (fires THIRD in every full interactive `audit`, immediately after the Step 0.2 backup offer and BEFORE Step 0.5; see audit.md § Step 0.3):
1. SUPPRESSION FIRST. IF the run is headless / non-interactive OR `audit --quick` → STOP this gate silently: render no checkbox, write no marker, REMOVE nothing. Headless install behavior falls back to the persisted `<!-- companion-skills: … -->` marker, or — marker absent — to the pre-2026-06-24 install-on-absence / ensure-exists defaults. The install-on-absence default set is all four companions (`text-eval`, `code-evaluator`, `route`, `awareness-ledger`). Absence of an answer NEVER means remove.
2. THE OFFERABLE SET is the evaluator/helper companions audit force-installs: `text-eval` (Step 4c-bis), `code-evaluator` (Step 4a-bis), `route` (Step 4g), `awareness-ledger` (Step 4a). Each row carries an `install-on-absence` attribute: `yes` for all four. NO "(recommended)" label is rendered in this gate (the 2026-06-24 directive's "(recommended)" mechanic for `route`/`awareness-ledger` is SUPERSEDED newest-wins by the 2026-06-24 inversion follow-up — under the inverted widget of clause 3, a "(recommended)" tag next to a remove-checkbox reads as "recommended to remove"; the user ratified dropping it). `route` and `awareness-ledger` remain install-on-absence defaults, so the empty default keeps/installs them. The set is an enumerated table in audit.md § Step 0.3 so future companions extend it by adding a row, never by editing this block.
3. NO PRE-CHECK POSSIBLE → INVERTED WIDGET, RENDERED AS TWO GROUPS. `AskUserQuestion` has no `selected`/`default` field, so a multi-select CANNOT render pre-checked boxes (every box renders empty). The directive's "checkmarks by present items" intent is honored by making the empty default SAFE, not by a rendered checkmark: the gate INVERTS — an UNCHECKED box keeps/installs the companion, a CHECKED box opts it OUT (remove if present / skip install if absent). The gate renders as TWO multi-select question OBJECTS inside ONE `AskUserQuestion` call — **Evaluators** (`text-eval`, `code-evaluator`) and **Helpers** (`route`, `awareness-ledger`) — per the 2026-06-25 split directive. Two objects in one call is still ONE prompt screen and ONE sanctioned question slot (Lane→Model picker precedent), so the FIVE-question count is unchanged. Presence is computed per the table: function-/signal-based for `text-eval` (Step 4c-bis / § Build Scaffolds test, any FUNCTION-performing skill counts under any name), and name-based for the named companions (`code-evaluator`, `route`, `awareness-ledger` → `.claude/skills/<name>/SKILL.md` exists). Presence is surfaced in each row's label/description as PRESENT/ABSENT, NOT as a pre-check. The marker, when it exists, is reconciled against on-disk presence; on-disk wins, the marker records intent. (Inversion ratified 2026-06-24 — tool-capability reconciliation; present companions are retained BY DEFAULT.)
4. PROVENANCE GUARD (removal floor). Removal may target ONLY a skill skill-builder itself scaffolded (scaffold-provenance marker present). A function served by a user's hand-authored skill is detected-as-present (so no duplicate install is offered) but is NEVER eligible for removal: checking it for opt-out writes the `=off` intent and prints an informational note ("served by your own skill `<name>`; skill-builder will not remove a skill it did not create"), never a `strip` row.
5. UNCHECKED = KEEP (default) resolution: unchecked + present → keep; write `<name>=on`; no action. Unchecked + absent → AUTHORIZE the companion's existing AUTO install task (this gate is the authorization for Steps 4a / 4a-bis / 4c-bis / 4g appends; they no longer fire unconditionally); write `=on`. All four companions are install-on-absence: yes, so the empty default installs every absent companion uniformly.
6. CHECKED = OPT-OUT resolution: write `<name>=off`. IF absent → suppress the install (this is the opt-out; supersedes newest-wins the 2026-06-12 "absence alone" / "by default, not opt-in" auto-installs for this companion) — uniform across all four. IF present AND skill-builder-scaffolded → DEFER a `/skill-builder strip <name> --execute` row (add `--confirm-breaking` when HARD references exist) to the Deferred Items table. NEVER an AUTO delete — the user ratified "Always defer to strip", and the destructive-work-DEFERS floor (deletion delegated to strip, never reimplemented) is honored, not superseded. The DEFER note states that strip performs the COMPLETE cross-reference disconnection across every other skill plus the `route index`/embed refresh (why this gate fires THIRD — before the audit commits its terminal route tasks).
7. THE ONE WRITE, RESOLVED ACROSS BOTH GROUPS. This gate's only write is the per-project `<!-- companion-skills: text-eval=…,code-evaluator=…,route=…,awareness-ledger=… -->` marker in references/model-lanes.md (the checkbox answer IS the consent, like the Lane→Model picker). Resolve EVERY companion across BOTH question objects before the write and assert coverage — every offerable companion must map to exactly one `on`/`off`; abort the write if any key is unresolved (guards the split against a dropped second-group answer). Back-compat: a legacy `<!-- creative-scrub-build: off -->` marker reads as `text-eval=off`. It never switches the session model and never asks one to.
8. IF any change proposes auto-deleting on the opt-out selection (a checked box under the inverted widget), exposing a user-authored skill for removal, removing in a headless run, or removing without routing through `strip` → STOP and report the directive conflict.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "I would like Claude to ask if we would like to back up or not. The backup process would create a new zip file of the CLAUDE.md and the claude directory … rotation of the last three files and no more … check .getignore if it exists …" + "we also need a restore function … this backup is special and never removed by the rotation … if you choose Claude uninstall, it will restore this original Claude and skill set" + "updating the disclaimer … to let the person know that there is a backup process available … will allow for a clean uninstall of Claude enforcer." -->
CHECKPOINT — Audit Backup Gate (fires SECOND in every full interactive `audit`, immediately after the Step 0 disclaimer is accepted and BEFORE the Step 0.3 companion gate; see audit.md § Step 0.2):
1. SUPPRESSION FIRST. IF headless / non-interactive OR `audit --quick` → STOP this gate silently: ask nothing, back up nothing. No interactive question can render, and a missing answer NEVER triggers a backup (it is opt-in per run).
2. THE QUESTION. ONE AskUserQuestion, right after the disclaimer: "Back up `CLAUDE.md` + `.claude/` before proceeding?" — options at least **Back up first** / **Skip backup**. It is a configuration/consent question, never a switch prompt. On "Skip" → record no backup task and continue to the Step 0.3 companion gate. On "Back up first" → queue the backup as the FIRST task of the Step 6 auto-execution phase.
3. ORDER. The backup task runs FIRST in Step 6 — before any AUTO edit, before `code-eval`/`route`, before any deferred `strip` — so the zip captures the true pre-audit state. It never blocks: a zip failure is a one-line warning and the audit proceeds (the disclaimer was accepted).
4. MECHANICS LIVE IN backup.md. The zip target is `CLAUDE.md` + `.claude/`; the destination is `.claude-backups/` at the repo root (a sibling of `.claude/`, never nested — no self-inclusion); rotation keeps the last 3 rotating snapshots; the FIRST-EVER backup is a pinned baseline rotation never removes; `.gitignore` gains `.claude-backups/` only if a `.gitignore` already exists; the create is atomic (temp → verify → rename); a host-generated restore kit is written into `.claude-backups/` (never shipped). Follow references/procedures/backup.md exactly; never inline or reinvent the shell here.
5. RESTORE IS NOT THIS GATE. Restore is a standalone HIGH-RISK command (references/procedures/restore.md) — display-default + `--execute` + confirmation, auto-snapshot-before-overwrite, VCS check, blast-radius diff, integrity verify. Audit NEVER auto-fires restore (destructive-work-DEFERS floor). IF any change proposes auto-restoring during an audit, shipping the backup/restore shell as a manifest file, creating `.gitignore` where none exists, or letting rotation delete the baseline → STOP and report the directive conflict.
<!-- END ENFORCEMENT ANNOTATION -->

---

### Step 0: Disclaimer Acceptance (BLOCKING — fires before anything else)

Per the 2026-06-06 sacred directive (SKILL.md § Directives → Audit Disclaimer Gate), the audit disclaimer must be accepted by the user before the audit proceeds. This fires on EVERY audit entry — full `audit`, `audit --quick`, and the bare `/skill-builder` default — BEFORE any scan, sub-command, marker write, or report.

1. **Interactive session** → present as a clickable **AskUserQuestion** widget — the SAME mechanism as the Step 0.2 / 0.3 / 0.4 gates, NEVER as prose narration (see **Rendering discipline** below) — and STOP until answered. Set the `question` field to a short prompt and carry the four disclaimer bullets verbatim in the question body:
   - **`question` field (short prompt):** "Accept the skill-builder audit disclaimer below before the audit proceeds? (see the terms in this prompt)"
   - **Disclaimer bullets (verbatim, in the question body):**

   > **Disclaimer — acceptance required before the audit proceeds:**
   > - skill-builder is designed to be used with Opus 4.7 or higher model.
   > - However, skills created with skill-builder are backwards compatible with earlier models.
   > - Please backup your CLAUDE.md and .claude directory before proceeding. A backup process is available right after this — you'll be asked whether to snapshot it (kept under .claude-backups/, the last 3 plus a permanent first-run baseline). Taking it lets you cleanly uninstall claude-enforcer later and restore your original setup with `/skill-builder restore`.
   > - Accepting runs the audit and automatically applies its recommended fixes; deferred items are listed for manual follow-up.

   Options EXACTLY: **Accept and proceed** / **Cancel audit**. On **Cancel audit** → STOP entirely; report that nothing was scanned or written. (Sacred minimum content stays verbatim: bullets 1–2 and the LEAD sentence of bullet 3, "Please backup your CLAUDE.md and .claude directory before proceeding."; the rest of bullet 3 and bullet 4 are machinery disclosure — bullet 3's tail announces the Step 0.2 backup offer. The short `question`-field prompt is machinery text, not part of the sacred content. The two backup lines were merged 2026-06-24 at the user's request; only the modifiable machinery text was trimmed.)

   **Rendering discipline (fix, 2026-07-01 — the disclaimer was rendering as prose while the other four gates rendered as widgets).** This gate MUST fire as an actual `AskUserQuestion` tool call with the two exact options, identical in kind to every other Step 0.x question — it is a genuine two-way branch (Accept → run; Cancel → stop), never an FYI notice. Do NOT narrate the disclaimer as end-of-turn prose and wait for a typed "accept"; do NOT collapse the bullets into a paragraph and imply consent. The long, bullet-formatted, notice-shaped body is exactly what biases a literal executor toward prose — resist it: the body goes in the `question` field, the branch goes in the two options. Whenever the other Step 0.x gates render as clickable boxes, this one renders the same way in the same run.
2. **On Accept** → write/refresh the `<!-- audit-disclaimer: accepted -->` marker in `references/model-lanes.md` (the project's runtime copy, next to the `model-lane-setup` marker — update-preserved, per-project), then continue to Step 0.5. If `model-lanes.md` does not exist in the project, skip the marker write silently (the gate still asked and was accepted; the marker only exists to unblock headless scans). **Acceptance is the run's single consent (Audit Autonomy Gate, 2026-06-06): it authorizes the scan AND the auto-execution phase (§ Step 6).** No further execution question is ever asked this run. (Continue to Step 0.2, the backup offer.)
3. **Headless / non-interactive run** → IF the `audit-disclaimer: accepted` marker exists → print the disclaimer text into the report header and proceed with the **scan only** — a marker never authorizes writes; the fix plan lands in the report as would-be tasks, and auto-execution requires a live interactive acceptance this run. IF NO marker → print the disclaimer and REFUSE: "Audit disclaimer not yet accepted — run one interactive audit first." Acceptance is never assumed or auto-granted.
4. This gate asks about the disclaimer ONLY. It never asks the user to switch models — no audit step does (No-Switch-Prompt Gate). The full audit asks at most FIVE questions ever (count raised three → four → five by the two 2026-06-24 directives): this disclaimer, the Step 0.2 backup offer, the Step 0.3 Companion-Skill Selection Gate, the every-audit Lane→Model picker, and the one-time 4f-setup onboarding (Audit Autonomy Gate clause 1).

**Front-cluster question manifest (fix, 2026-06-24 — the every-audit picker was being skipped mid-scan).** Before scanning, commit to this firing order. Four of the five sanctioned questions now fire UP FRONT as one cluster, before any scan; only the one-time onboarding fires later (it needs the scan's per-skill lane suggestions):

| Order | Step | Question | Fires when |
|-------|------|----------|-----------|
| 1 | § 0   | Disclaimer (Accept / Cancel) | every interactive audit |
| 2 | § 0.2 | Backup offer (Back up first / Skip) | every interactive audit (not `--quick`/headless) |
| 3 | § 0.3 | Companion-Skill gate (two grouped multi-selects — Evaluators / Helpers — in one call; one slot) | every interactive audit (not `--quick`/headless) |
| 4 | § 0.4 | **Lane→Model picker (creative brain / coding brain)** | every interactive audit on a **`configured`** project (not `--quick`/headless) |
| 5 | § 4f-setup | One-time lane onboarding (incl. its own brain picks) | first interactive audit of an **`unset`** project only |

Why the picker moved to § 0.4 (was buried as "Step 4f step 2-bis"): it re-confirms two model IDs and needs ZERO scan data, yet it sat alone mid-scan inside a step headed "report-only scan," so under the auto-execution autonomy pressure it got flowed past into Step 6. Front-loading it with the other questions is the fix; Step 6 additionally hard-asserts it fired (§ Step 6 pre-execution check). On an `unset` project the picker is instead captured by the 4f-setup onboarding's batched brain picks (clause 1) — never both, never a double-ask.

### Step 0.2: Backup Offer (fires SECOND — right after Step 0, before Step 0.3)

Per the 2026-06-24 sacred directive (SKILL.md § Directives → Audit Backup Gate), the audit's SECOND question offers to snapshot the project's Claude configuration before any change, operationalizing the Step 0 disclaimer's "back up before proceeding" advice. It fires immediately after the disclaimer is accepted and before the Step 0.3 companion gate.

**Suppression (check FIRST).** IF the run is headless / non-interactive OR `audit --quick` → STOP this step silently: ask nothing, back up nothing. No interactive question can render, and a missing answer NEVER triggers a backup (it is opt-in per run).

**The question.** ONE AskUserQuestion, right after the disclaimer: *"Back up CLAUDE.md + .claude before proceeding? A snapshot lets you cleanly uninstall claude-enforcer later and restore your original setup."* Options at least **Back up first** / **Skip backup**. It is a configuration/consent question, never a switch prompt.

- **Back up first** → queue the backup as the FIRST task of the Step 6 auto-execution phase (before any AUTO edit, before `code-eval`/`route`, and before any deferred `strip`) so the zip captures the true pre-audit state. The backup never blocks: a zip failure is a one-line warning and the audit proceeds.
- **Skip backup** → record no backup task; continue to Step 0.3.

**Mechanics live in [backup.md](backup.md)** — `.claude-backups/` at the repo root (sibling of `.claude/`), rotation of the last 3, pinned first-run baseline, `.gitignore` update if a `.gitignore` exists, atomic create, host-generated restore kit. Never inline or reinvent the shell here. **Restore is NOT part of the audit** — it is a standalone, destructive command ([restore.md](restore.md)) that audit never auto-fires.

**Synergy with the companion gate (Step 0.3).** The companion gate DEFERS its removals to `/skill-builder strip`, which the user runs later from the Deferred Items table. A backup taken here — before any mutation — is the safety net that makes every later deferred `strip` (and every AUTO edit this audit applies) recoverable via `/skill-builder restore`. The two questions stay independent: declining the backup does not suppress the companion gate, and vice-versa.

### Step 0.3: Companion-Skill Selection Gate (fires THIRD — right after the Step 0.2 backup offer, before Step 0.5)

Per the 2026-06-24 sacred directive (SKILL.md § Directives → Companion-Skill Selection Gate), the audit's THIRD question is a multi-select checkbox that lets the user opt in/out of the evaluator/helper companion skills audit force-installs. It fires immediately after the Step 0.2 backup offer and BEFORE the Step 0.5 VCS preflight, so install/remove intent is known before the audit builds its execution plan and its terminal route tasks (Step 4g) — the user's stated reason for the placement ("the route index and route embedding will affect the outcome too").

**Suppression (check FIRST).** IF the run is headless / non-interactive OR `audit --quick` → STOP this step silently: render no checkbox, write no marker, REMOVE nothing. Headless install behavior falls back to the persisted marker (below), or — marker absent — to the pre-2026-06-24 install-on-absence / ensure-exists defaults (Steps 4a / 4a-bis / 4c-bis / 4g run as they did before). Absence of an answer NEVER means remove. (Bootstrap mode is a full interactive audit and DOES run this step — a fresh project is exactly where the install opt-in matters.)

**The offerable set (enumerated table — extend by adding a row, never by editing the directive):**

| Group | Companion | Presence test | Install on absence? | Install task |
|-------|-----------|---------------|---------------------|--------------|
| Evaluators | `text-eval` | evaluator-function skill per [creative-integrity.md](../creative-integrity.md) § Build Scaffolds pre-build guards (signal-based, never name-based) | yes | Step 4c-bis evaluator scaffold |
| Evaluators | `code-evaluator` | `.claude/skills/code-evaluator/SKILL.md` exists, OR a skill performing the code-quality-evaluator function | yes | Step 4a-bis `code-eval create` |
| Helpers | `route` | `.claude/skills/route/SKILL.md` exists | yes | Step 4g `route index` bootstrap |
| Helpers | `awareness-ledger` | `.claude/skills/awareness-ledger/SKILL.md` exists | yes | Step 4a `ledger --execute` |

(No per-row label column — the "(recommended)" mechanic is superseded for this gate, see below. All four companions are install-on-absence defaults, so under the inverted widget they are kept/installed unless explicitly checked for opt-out. The two `Group` values are the two question objects rendered in one AskUserQuestion call — see step 4.)

**No "(recommended)" label is rendered in this gate (superseded 2026-06-24, newest-wins).** The 2026-06-24 directive originally required `route` and `awareness-ledger` to show "(recommended)" in their checkbox row. That mechanic assumed the non-inverted "check to keep" widget. Under the inverted widget (step 4 — a **check means *opt out / remove***), a "(recommended)" tag next to a remove-checkbox reads as "recommended to remove," the opposite of the intent. The user ratified dropping the label from this gate entirely (2026-06-24 follow-up) to eliminate that confusion. The recommendation still lives in the marker doc and the install-on-absence defaults; the immutable directive text is unchanged — only this rendering mechanic is superseded.

**Procedure:**

1. **Read the marker.** Read the per-project `<!-- companion-skills: text-eval=…,code-evaluator=…,route=…,awareness-ledger=… -->` marker from `references/model-lanes.md` (§ Companion Skills). Back-compat: a legacy `<!-- creative-scrub-build: off -->` marker reads as `text-eval=off`. A missing marker means "never configured" — the first-run state is the SAFE default under the inverted widget: every box unchecked = keep all present companions and install the absent **install-on-absence** ones — all four (`route`, `awareness-ledger`, `text-eval`, `code-evaluator`). The marker is written from the user's submission (step 7).
2. **Compute presence (per the table's presence-test column).** For each companion, run its presence test. For `text-eval`, reuse the exact Step 4c-bis / § Build Scaffolds signal test (any § Scope-signal skill counts under any name) so the checkbox agrees with the scaffold step and never offers to install a second evaluator. For the NAMED companions (`code-evaluator`, `route`, `awareness-ledger`), the test is name-based (`.claude/skills/<name>/SKILL.md` exists). On-disk presence wins for the displayed PRESENT/ABSENT row state; the marker records intent.
3. **Compute provenance (removal floor).** For each PRESENT companion, determine whether skill-builder itself scaffolded it (scaffold-provenance marker / known companion-skill path). A function served by a user's hand-authored skill is present-but-not-skill-builder-scaffolded → it is detected-as-present (no duplicate install offered) but is NEVER eligible for removal (clause 6).
4. **Render the gate (INVERTED — a check means OPT OUT — as TWO grouped multi-selects in ONE call).** `AskUserQuestion` has no `selected`/`default` field, so a multi-select **cannot pre-check boxes** — every box renders empty regardless of what the procedure "intends." Pre-checking present companions is impossible at the tool layer. To keep the tool's natural empty default SAFE, the gate **inverts** the checkbox meaning: **a checked box opts the companion OUT (remove if present / skip install if absent); an unchecked box keeps or installs it.** Leaving every box unchecked = "keep everything as-is, install the absent install-on-absence companions" — the safe default, confirmed in one submission. Render **ONE `AskUserQuestion` call containing TWO multi-select question objects** — **"Evaluators"** (`text-eval`, `code-evaluator`) and **"Helpers"** (`route`, `awareness-ledger`) — per the 2026-06-25 split directive. Two objects in one call is still ONE prompt screen and ONE sanctioned question slot (the Lane→Model picker uses the same two-objects-one-call shape), so the FIVE-question count is unchanged. Each row states its **PRESENT/ABSENT** state in the label/description (e.g. `text-eval — PRESENT (check to remove)`, `code-evaluator — ABSENT (check to skip install)`). **No "(recommended)" wording appears** (superseded — see the note above). This is a CONFIGURATION question — its answer IS consent (like the Lane→Model picker), not a switch prompt. (Inversion ratified 2026-06-24; the two-group split ratified 2026-06-25.)
5. **Resolve UNCHECKED = KEEP (the default path).** Unchecked + present → keep; mark `=on`; no action. Unchecked + absent → AUTHORIZE the companion's install task (this gate is the authorization for the Step 4a / 4a-bis / 4c-bis / 4g appends — they no longer fire unconditionally; see those steps); mark `=on`. All four companions are install-on-absence: yes, so the empty default installs every absent companion uniformly.
6. **Resolve CHECKED = OPT OUT.** Mark `=off`.
   - Absent → suppress the install (the opt-out; supersedes newest-wins the 2026-06-12 "absence alone" / "by default, not opt-in" auto-install for this companion) — uniform across all four.
   - Present + skill-builder-scaffolded → add a **DEFER** row to the Deferred Items table: `/skill-builder strip <name> --execute` (append `--confirm-breaking` if strip's BREAKING detection would fire — i.e. HARD references exist). **NEVER an AUTO delete** (the user ratified "Always defer to strip"; the destructive-work-DEFERS floor stands). The row's note: "removes the skill and its COMPLETE cross-reference disconnection across every other skill, plus the `route index`/embed refresh (strip auto-runs `route index --execute`)."
   - Present + user-authored (no skill-builder provenance) → write `=off` and print an informational note only: "served by your own skill `<name>`; skill-builder will not remove a skill it did not create." No `strip` row.
7. **Write the marker (the one consented write), RESOLVED ACROSS BOTH GROUPS.** Read the answers from BOTH question objects and resolve EVERY companion in the offerable set to exactly one `on`/`off` — **assert coverage before the write; abort the marker write if any companion is unresolved** (guards the split against a silently dropped second-group answer). Edit `references/model-lanes.md`'s `<!-- companion-skills: … -->` marker with the resolved state for each companion (the checkbox answer is the consent). If the marker is absent, insert it beside the `model-lane-setup` / `audit-disclaimer` markers. If `model-lanes.md` does not exist in the project, skip the marker write silently (the gate still asked and was honored this run). This gate never switches the session model and never asks one to.
8. **Feed the plan.** Authorized installs flow into the Step 6 AUTO tier exactly where Steps 4a / 4a-bis / 4c-bis / 4g already place them (the gate only decides WHETHER they are appended). DEFER `strip` rows flow into the Deferred Items table. Because this ran THIRD (before Step 0.5 and the terminal route tasks), the `route index` / `route embed` tasks (Step 4g) reflect the install choices in the same run; removals run later via the deferred `strip` command, which itself refreshes the index/embed.

**Absence-vs-gap note.** The gate is a STANDING question (it fires every full interactive audit, like the disclaimer and picker — it is the user's standing install/removal control), so it is not omitted merely because the default is keep-everything (all boxes empty). It is suppressed ONLY by the headless/`--quick` rule above.

**Grounding:** [model-lanes.md](../model-lanes.md) § Companion Skills (marker scheme + back-compat), [creative-integrity.md](../creative-integrity.md) § Build Scaffolds (signal-based existence test), [strip.md](strip.md) (the removal path, BREAKING detection, cross-reference sweep, auto `route index`).

### Step 0.4: Every-Audit Lane→Model Picker (fires FOURTH — right after Step 0.3, before Step 0.5)

The every-audit Lane→Model picker (sacred 2026-06-06 workshop decision: the two model questions are asked on EVERY full interactive audit, regardless). **Relocated here from "Step 4f step 2-bis" (fix, 2026-06-24)** because it needs no scan data and was being silently skipped mid-scan — see § Step 0 clause 4's manifest. No immutable directive pins its flow position (the directives home this mechanic in the procedure files); only "asked every full interactive audit run, regardless" is sacred. It is a CONFIGURATION question — its answer IS consent — and it NEVER asks the user to switch the session model (No-Switch-Prompt Gate).

**Suppression (check FIRST).** IF the run is headless / non-interactive OR `audit --quick` → STOP this step silently (skip the picker; continue to Step 0.5). The Model Lane *scan* still runs later at Step 4f in those modes; only the interactive picker is suppressed.

**Branch on the setup-state marker** (`references/model-lanes.md`, § Setup State; missing = `unset`):
- **`configured`** → run the picker NOW (full spec in [lane-delegation.md](../lane-delegation.md) § Lane→Model Picker):
  1. Build the candidate options EXACTLY: `claude-opus-4-6`, `claude-opus-4-8`, `claude-sonnet-5`, `claude-fable-5`, and the latest released model by official ID — discovered fresh via the ladder in lane-delegation.md (`GET /v1/models` ~10s timeout → models-overview docs fetch → omit the option with a one-line notice; never fabricate an ID; never cache). Dedupe "latest" against the statics, then apply the four-option ceiling (drop the oldest static first — see lane-delegation.md § Lane→Model Picker).
  2. ONE batched AskUserQuestion — "Creative lane model" / "Coding (everything-else) lane model" — with the current mapping pre-selected as the default on each (confirming is one click; AskUserQuestion's auto-"Other" preserves manual entry; blank-to-disable remains available).
  3. **Unchanged** → no write. **Changed** → write the Lane→Model cells in `model-lanes.md` immediately (the picker answer IS the consent — the same single-consented-write discipline the Step 0.3 marker and the 4f-setup config use), then QUEUE the **Fleet Rewrite** as Step 6 auto-execution tasks (per [lane-delegation.md](../lane-delegation.md) § Fleet Rewrite on Remap: one TaskCreate task per `lane-pinned:` agent of each remapped lane, rewrite the `model:` line only, verify by re-grep, report per file — VCS-gated like every other Step 6 write; they run before the route terminal tasks so `route embed` reconciles against rewritten agents). The Fleet Rewrite needs no scan data, so queuing it from here is safe.
  4. The picker never writes the `model-lane-setup` marker and never switches the session model. **Record that the picker fired this run** (the Step 6 pre-execution check asserts against this).
- **`unset`** (or `model-lanes.md` absent) → SKIP this step silently. The picker is instead captured by the one-time 4f-setup onboarding's batched brain picks during the scan phase (§ Step 4f-setup clause 1) — the onboarding needs the scan's per-skill lane suggestions, so it cannot move forward. Never ask the picks both here and at 4f-setup.
- **`declined`** → SKIP silently (the user opted out of lane management for this project).

### Step 0.5: VCS Preflight (containment — never blocks)

Run `git rev-parse --is-inside-work-tree` and, if in a repo, `git status --porcelain -- CLAUDE.md .claude/`. Three states:

- **Clean repo** → full AUTO tier available (§ Step 6).
- **Dirty repo** → proceed with the full AUTO tier, but print one warning line in the report header: "Uncommitted changes in CLAUDE.md/.claude — the Step 0 backup advice is your rollback." Never block; the disclaimer was accepted.
- **No VCS** → downgrade the git-dependent AUTO items to DEFER (`optimize --execute` — its immutable-block precheck and auto-revert depend on `git show`/`git checkout`; orphan minion deletions; dead-wiring git recovery), each with reason "no version control — these need a recovery path." Everything else stays AUTO.

### Step 1: Gather Metrics

**Preflight — self-exclusion.** Detect invocation form:
- Invoked as `/skill-builder dev audit …` → include `skill-builder` in the skill set
- Otherwise → exclude `skill-builder` from any `.claude/skills/*/SKILL.md` glob

Apply this filter to every step below that iterates skills (Steps 2.5, 3, 4, 4b, 4b-bis, 4d, Step 5 Skills Summary, Step 5 Directives Inventory). See SKILL.md § Self-Exclusion Rule.

```
Files to scan:
- CLAUDE.md
- .claude/rules/*.md (if exists)
- .claude/skills/*/SKILL.md  (exclude skill-builder unless dev prefix)
```

### Step 2: CLAUDE.md & Rules Analysis

```markdown
## CLAUDE.md
- **Lines:** [X] (target: < 150)
- **Extraction candidates:** [list sections that could move to skills]

## Rules Files
- **Found:** [count] files in .claude/rules/
- **Should convert to skills:** [yes/no with reasoning]

## Settings
- **Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`):** [enabled/disabled]
  (Read `.claude/settings.local.json` → `env` section)
```

### Step 2.5: Bootstrap Check (No Skills Found)

If no `.claude/skills/*/SKILL.md` files exist (excluding skill-builder itself):

**Switch to bootstrap mode.** Do NOT report "no skills found" and stop. Instead:

1. Report that no skills exist yet — this is a fresh project
2. Run the **CLAUDE.md Optimization Procedure** (see [claude-md.md](claude-md.md)) as the primary action
3. Analyze CLAUDE.md for extraction candidates (domain-specific sections, inline tables, procedures >10 lines, rules that only apply to specific tasks)
4. Propose new skills to create from extraction candidates
5. Present the CLAUDE.md optimization report with proposed skill extractions, each tagged HIGH-confidence (mechanical, clearly self-contained section) or AMBIGUOUS (judgment about scope/splitting)
6. **Auto-execute the extraction (Audit Autonomy Gate — no menu, no question):** extract the HIGH-confidence candidates immediately under the Step 0 consent (the disclaimer names CLAUDE.md by name as the backup target). AMBIGUOUS candidates DEFER to the report's Deferred Items table with the command `/skill-builder optimize claude.md --execute` — never guessed, never extracted without confidence, never offered as a menu.

Skip Steps 3, 4 (sub-commands), 4c–4e (their per-skill sub-command runs and panels require existing skills). Do NOT skip Step 4f — see below.

**Still run Step 4a** (Awareness Ledger status check). This is a companion skill installation — it doesn't depend on existing skills and the audit is the orchestrator for surfacing it.

**Still run Step 4f — including the onboarding fork (bug fix, 2026-06-07).** A fresh project is exactly the Setup Onboarding Flow's audience: bootstrap is the first audit a project ever sees, and the earlier blanket "skip 4c–4f" left `model-lane-setup: unset` forever — the user was never asked to pick the creative and everything-else brains (field-reported, 2026-06-07; the onboarding is one of the audit's three sanctioned questions "in any audit" per the Audit Autonomy Gate, with no bootstrap exemption). Bootstrap mechanics: run Step 4f **after** Step 6's auto-execution and the post-bootstrap chain complete, so freshly extracted skills (plus any just-installed companions) exist for § Step 4f-setup clause 2's per-skill lane suggestions and the 5-bis agent-model scan covers the chain's new agents in the same run. If extraction produced zero skills, the onboarding question still fires — clause 2 simply has nothing to suggest; on "Set it up now" write the Lane→Model mapping and the `configured` marker with the Skill→Lane table left empty. All of 4f's existing suppressions are unchanged (headless/non-interactive and `--quick` stay silent no-ops; `declined` is honored). Append 4f's Model Lane section to the bootstrap report.

**Still run Step 4g — but only the `route index` half.** `/route` can (and should) bootstrap with an empty catalog so the dispatcher exists the moment the user's first skill is created. The `route embed` half is SKIPPED in bootstrap mode **only while the project still has zero skills** (there is nothing to embed into). See [route.md](route.md) § Mode: `index` → Step 1 "Zero-skill case is valid" and § Mode: `embed` → Step 1 "Zero-candidate case." Surface `route index --execute` as a recommended terminal action in the bootstrap report. **Exception (2026-06-07):** if Step 4f's onboarding just declared lanes on post-extraction skills, run `route embed` after the chain's final `route index` so the `MODEL-LANE-GATE` preflight is wired in the same audit (honoring § Step 4f-setup's "Invocation-time complement" promise — setup and enforcement complete in one audit run).

Bootstrap is a full interactive audit, so the Step 0.3 companion gate runs (right after the disclaimer) and GATES the companion installs below — a fresh project is exactly where the install opt-in matters. Under the inverted widget all four install-on-absence companions are authorized unless their box is checked for opt-out (unchecked = install; `route`, `awareness-ledger`, `text-eval`, and `code-evaluator` all install on absence by default — the empty default keeps them all).

Go to Step 6's auto-execution with a task list that includes:
- CLAUDE.md extraction of HIGH-confidence candidates (from above; AMBIGUOUS → Deferred Items)
- Awareness Ledger installation (from Step 4a, if not installed AND `awareness-ledger` checked at Step 0.3 — improvement work runs once authorized)
- `route index --execute` — bootstrap `/route` with an empty catalog (from Step 4g, auto-run in bootstrap mode when `/route` is not yet installed AND `route` checked at Step 0.3)

**Post-bootstrap chaining:** When CLAUDE.md extraction is executed and new skills are created, post-action chaining (per § Display/Execute Mode Convention rule 6) fires automatically — running optimize, agents, and hooks for each newly created skill **under the audit's Step 0 consent: the chain's execution menu is suppressed when its parent is audit** (post-action-chain.md § Step 3); its AUTO-tier recommendations execute and the rest defer. This ensures agents and hooks land in the same session, not deferred to a second audit. The chain also re-runs `route index` after new skills appear so the freshly-bootstrapped catalog picks them up.

### Step 2.7: Quarantine Unparseable Skills (fail-loud — never a silent skip)

A skill audit cannot silently drop what it cannot read — under the 2-Brain Harness an unindexed skill is unroutable and outside model management entirely, so a silent parse-skip amounts to uninstalling the skill without telling anyone.

1. Compute `quarantined = glob(.claude/skills/*/SKILL.md) − successfully_parsed` (frontmatter missing/invalid YAML, missing `---` delimiters, unreadable file). Empty set → continue silently.
2. For each quarantined skill: report a **QUARANTINED** row (name + path + one-line parse error) in the Skills Summary AND a **mandatory repair entry** in the Deferred Items table ("repair frontmatter of /[skill]: [error] — see templates.md § frontmatter and § Detecting Multi-line Descriptions"). Repair tasks are never auto-executed (the file may be hand-authored in ways parsing can't judge) — DEFER tier, with the repair instructions as the ready-to-run follow-up.
3. Propagate to the index: `route index` writes quarantined skills as explicit `QUARANTINED` catalog rows (present but unroutable, with the parse error) — never silently absent. `/route` answering an ask that matches a quarantined name reports "exists but unreadable — run its repair task" instead of "no match".
4. Quarantined skills are EXCLUDED from every downstream per-skill sub-command (they cannot be safely parsed) but INCLUDED in the final accounting line — `N audited · M quarantined` — so the totals never silently shrink.

### Step 3: Skills Summary Table

```markdown
## Skills Summary
| Skill | Lines | Description | Directives | Reference Inline | Hooks | Status |
|-------|-------|-------------|------------|------------------|-------|--------|
| /skill-1 | X | single/multi | Y | Z tables | yes/no | OK/NEEDS WORK |
| /broken-skill | — | — | — | — | — | QUARANTINED: [parse error] |

**Description column:** Flag `multi` if uses `|` or `>` syntax (needs optimization to single line)
**QUARANTINED rows:** per Step 2.7 — present, unroutable, carrying a mandatory repair task.
```

### Step 4: Run Sub-Commands in Display Mode

**Agent budget:** Sub-procedures running in display mode during the SCAN phase skip their own agent panels. Agent panels fire only in standalone mode or execute mode where decisions have real consequences — and the audit's **auto-execution phase (§ Step 6) IS execute mode**: every panel a sub-procedure demands for its execute path (optimize 4b/5b, agents § 5, excursion classification, reconcile adjudication where its findings went AUTO) fires there exactly as written. Panels replace user menus, never the other way around (Audit Autonomy Gate clause 5).

- Quick audit (`--quick`): **0 agent panels in the scan** — pure checklist, no spawning
- Standard audit scan: **1 agent panel total** (Step 4e priority ranking), plus lightweight cascade guard checks (no panel)
- Auto-execution phase: panels per the executing procedures' own contracts (uncapped — integrity over speed)

For each skill found:
1. Run **optimize** in display mode (skip agent panels in Steps 4b and 5b) → collect optimization findings
2. Run **agents** in display mode (skip agent panel in Step 5) → collect agent opportunities
3. Run **hooks** in display mode (skip agent panel in Step 3b) → collect hooks inventory and opportunities

### Step 4a: Ledger Status

Check if `.claude/skills/awareness-ledger/SKILL.md` exists.

**If the ledger exists:**
1. Count records: `find .claude/skills/awareness-ledger/ledger -name "*.md" -not -name "index.md"` (excludes index)
2. Check planning-phase integration: scan project CLAUDE.md for awareness ledger reference (grep for "awareness ledger" or "ledger/index.md")
3. If `consult-before-edit.sh` exists in hooks/ or is wired in settings.local.json, flag as obsolete
4. Report **status only**:
   ```
   **Awareness Ledger:** Installed
   - Records: [N] (INC: [n], DEC: [n], PAT: [n], FLW: [n])
   - CLAUDE.md integration: [yes/no]
   - Last updated: [date of most recent record file, or "unknown"]
   - Issues: [missing CLAUDE.md line / obsolete hook / empty ledger / none]
   ```

Per-skill ledger integration recommendations (capture gaps, grounding notes) are surfaced only when a specific skill is targeted via `optimize`, `agents`, or `hooks` — not as a global scan during audit.

**If the ledger does NOT exist:**
1. Report:
   ```
   **Awareness Ledger:** Not installed
   - Captures incidents, decisions, patterns, and flows so diagnostic findings
     and architectural decisions persist across sessions.
   - Will be created automatically in this run's execution phase.
   ```
2. This MUST appear in the report — do NOT skip silently. **Gated by the Step 0.3 companion gate (2026-06-24):** append `ledger --execute` to the auto-execution task list ONLY when `awareness-ledger` is checked (or, in a suppressed headless/`--quick` run, when the `companion-skills` marker has `awareness-ledger=on` or is absent — the install-on-absence default). When `awareness-ledger=off`, do NOT append; report "**Awareness Ledger:** not installed (opted out via the companion gate)". (Audit Autonomy Gate clause 3 still governs the install once authorized: it is additive scaffolding that touches nothing existing.)

### Step 4a-bis: Code Evaluator Status & Reference Sync

The `code-evaluator` skill prevents common AI coding mistakes (dead code, duplication, complexity). Audit ensures it exists and keeps its references current automatically. Like Step 4a, this is a **companion-skill singleton check** — run once, not per-skill. **SKIP in `audit --quick`** (it is a structural/file action, not a checklist item).

Check if `.claude/skills/code-evaluator/SKILL.md` exists.

**If it does NOT exist:**
1. Report:
   ```
   **Code Evaluator:** Not installed
   - Prevents dead code, duplication, complexity hotspots, reinvented helpers,
     and leftover scaffolding in code the AI writes.
   - Will be created automatically when you run audit with execution.
   ```
2. **Gated by the Step 0.3 companion gate (2026-06-24 — the "by default, not opt-in" auto-append is superseded newest-wins by the checkbox):** append `code-eval create` to the execution task list (Step 6) ONLY when `code-evaluator` is checked (or, in a suppressed headless/`--quick` run, when the marker has `code-evaluator=on` or is absent — the prior ensure-exists default). When `code-evaluator=off`, do NOT append; report "**Code Evaluator:** not installed (opted out via the companion gate)". Once authorized it is low-risk/additive (scaffolds a new skill; touches nothing existing); running it makes `code-evaluator` available and lets the route terminal tasks (4g) wire its gates into code-touching skills.

**If it DOES exist:**
1. Read its frontmatter `code_eval_ref_version` (= `recorded`).
2. Read skill-builder's shipped version: the integer in `.claude/skills/skill-builder/references/code-evaluator/version.md` (= `shipped`). (In `dev` maintainer mode read from the source path `skill-builder/references/code-evaluator/version.md`.)
3. Compare:
   - `recorded >= shipped` → report **status only**:
     ```
     **Code Evaluator:** Installed (references v[recorded], current)
     ```
   - `recorded < shipped` → references are **stale**. Report:
     ```
     **Code Evaluator:** Installed (references v[recorded] → v[shipped] available)
     - skill-builder ships newer evaluation intel; your copy is behind.
     ```
     and append `code-eval sync` to the execution task list (Step 6) — by default. Sync is a block-aware refresh of skill-builder-owned (`modifiable: true`) reference blocks that preserves any `origin: user` seams (see [code-eval.md](code-eval.md) § sync).
4. **Enforcement-hook status (DEFER only — never auto-wire).** Check whether the always-on enforcement hooks are wired: do `.claude/settings.local.json` hooks entries reference the `code-eval-*` scripts AND do those script files exist under `.claude/skills/code-evaluator/hooks/`?
   - **Wired** → check for script drift: read `recorded` = the `# code-eval-enforce-version: N` header in `.claude/skills/code-evaluator/hooks/code-eval-prewrite.sh` (absent → `0`), and `shipped` = the `<!-- code-eval-enforce-version: N -->` anchor in `.claude/skills/skill-builder/references/procedures/code-eval.md` (dev mode: the source path).
     - `recorded >= shipped` → report **status only**: `**Code-eval enforcement:** wired (scripts v[recorded], current)`.
     - `recorded < shipped` → wired scripts are **stale** (they predate the current procedure — e.g. they lack a newer Phase-2 signal or gate fix). Report `**Code-eval enforcement:** wired but stale (scripts v[recorded] → v[shipped])` and add a **DEFER** row to the Deferred Items table: `/skill-builder code-eval enforce --execute` — reason "wired enforce hooks predate the current procedure (v[recorded] → v[shipped]); re-running regenerates every variant with the current signal/gate logic. Re-wiring is a deliberate host act — never auto-run (DEC-2026-06-08; No-Distribute-Hooks Gate)." Include the honest-scope note.
   - **Unwired** → report `**Code-eval enforcement:** not wired` and add a **DEFER** row to the Deferred Items table: `/skill-builder code-eval enforce --execute` — reason "always-on enforcement is a deliberate host act; wiring a blocking PreToolUse hook under blanket Step-0 consent is reserved for an explicit `code-eval enforce` run (SKILL.md § Directives → No-Distribute-Hooks Gate; DEC-2026-06-08)." Include the honest-scope note (the before/at-write hooks are `Edit|Write|NotebookEdit`-scoped; Bash-written code is caught only at the commit gate; a hook nudges/blocks the model but cannot itself call a skill). **Audit never auto-wires OR auto-refreshes these** — they are not in the Audit Autonomy Gate AUTO tier.
5. **Agent registration health (AUTO-repair — additive, not a hook write).** The two evaluator agents must be spawnable via the Task tool, which requires a `.claude/agents/<name>.md` registration (deref symlinks; copy-fallback counts) for each of `code-design-advisor` and `deadcode-gardener`. This is scoped by PATH (the two known agents under `.claude/skills/code-evaluator/agents/`), **NOT** by the `generated-by: skill-builder lane-excursion` marker — these are the evaluator's own L1/L2 agents, not lane-excursion minions, so the Step 4f.5-bis fleet checks (contract-stamp, orphan retirement) do NOT apply to them. Any missing registration → report `**Code Evaluator agents:** <name> unregistered (Phase 1 enforce hook's Task spawn cannot resolve)` and append a re-registration task to the execution list (Step 6). Re-creating a registration is additive/mechanical (the AGENT.md already exists; symlink, copy-fallback on Windows) → **AUTO tier**, like `code-eval create` itself; it is NOT a hook write and is unaffected by the enforce DEFER rule in item 4. This is the path by which an install made before registration was part of `create` self-heals on the next audit.

**Both `code-eval create` and `code-eval sync` auto-append to audit's execution task list by default** — mirroring how `route index`/`route embed` are appended (Step 4g). They run in the auto-execution phase under the Step 0 consent (Audit Autonomy Gate); audit never silently writes during the scan — the Execution Plan block lists them before they run. In `--review` mode, surface the pending create/sync as recommended actions in the report's Priority Fixes section.

**Grounding:** Read [code-eval.md](code-eval.md) for the create/sync procedure and [../code-evaluator/version.md](../code-evaluator/version.md) for the drift-anchor format.

### Step 4b: Temporal Reference Risk

For each skill, assess temporal reference risk:

1. Check the skill's temporal risk level per `references/temporal-validation.md` § "Temporal Risk Classification"
2. Check whether a temporal validation hook exists for the skill
3. If HIGH or MEDIUM risk with no hook, include in the aggregate report

Skip silently for LOW-risk skills or skills with temporal hooks already in place.

**Grounding:** Read [references/temporal-validation.md](../temporal-validation.md) for risk classification criteria.

### Step 4b-bis: Directive Protection Check (report-only scan)

Surface skills whose `origin: user | immutable: true` directive blocks lack checksum protection — closing the gap where only `verify` (Step 2b) reported this and `audit` ignored it entirely. **Report-only: this step never generates a `.directives.sha` sidecar and never wires a hook.** SKIP in `audit --quick` (structural/file scan, like Steps 4a-bis and 4d-bis). Honors the Step 1 self-exclusion filter (skill-builder excluded unless `dev`).

For each audited skill, resolve its directive-protection state (same logic as [verify.md](verify.md) § Step 2b):

1. Extract the skill's `<!-- origin: user … immutable: true -->` blocks. **No immutable blocks → N/A** (nothing to protect — not a finding).
2. **No `.directives.sha` sidecar → MISSING.**
3. **Sidecar present → recompute** each block's SHA-256 with the canonical normalization (strip markers, trim trailing whitespace per line, collapse 3+ blank lines to 2 — byte-identical to `protect-directives.sh`) and compare. All match → PROTECTED; any differ → MISMATCH.

**Tiering — both findings DEFER; nothing here auto-executes (Audit Autonomy Gate, DEFER tier):**

- **MISSING → DEFER** with `/skill-builder checksums <skill> --execute`. That command generates the sidecar **and** wires the validating `protect-directives` / `unique-persona` hooks in one deliberate host action — complete, armed protection that audit must NOT perform silently: wiring a blocking PreToolUse hook under blanket Step-0 consent is a host-local act reserved for an explicit `checksums` / `hooks` run (SKILL.md § Directives → No-Distribute-Hooks Gate; a sidecar is inert without its validating hook, so generating sidecars alone would be a half-armed non-improvement).
- **MISMATCH → DEFER, FLAG-ONLY** — never a runnable command in the Execution Plan. A mismatch means a protected directive block changed since its fingerprint: an intentional edit or tampering. **Never auto-regenerate** — that silently blesses the change and destroys the tamper signal (checksums.md § Override Path). The Deferred row reads: "investigate; if intentional, delete the sidecar and regenerate via `/skill-builder checksums <skill> --execute`."

Feed findings to the Step 5 **Directive Protection** subsection and the Deferred Items table. Headless runs report identically — this step writes nothing in any mode.

### Step 4c: Per-Skill Integration Checks

These checks run only for skills **explicitly targeted** by the user (e.g., `/skill-builder optimize [skill]`, `/skill-builder agents [skill]`). During a full audit, skip per-skill integration checks — companion skill status is reported in Step 4a.

When running for a targeted skill:

**Awareness Ledger relevance** — If `.claude/skills/awareness-ledger/` exists with records:
- Scan `ledger/index.md` for tags overlapping the skill's domain (file paths, function names, component names)
- Only recommend integration if matching records actually exist for this skill's domain
- If the skill IS the awareness-ledger, verify auto-activation directives (Auto-Consultation + Auto-Capture)

**Capture Integration gap** — If the awareness-ledger exists, check whether the targeted skill produces institutional knowledge but lacks a capture mechanism. If gap found, include in report with recommended mechanism per hierarchy: workflow step > agent > hook.

### Step 4c-bis: Creative-Workflow Integrity Check (scan + additive build)

Per the 2026-06-11 scrub-loop directive and its same-day build clause (SKILL.md § Directives → Creative-Integrity Gate), check every skill that manages a detect/evaluate/revise creative workflow against the Nine Scrub Principles — and BUILD the missing machinery where eligible, instead of only deferring it. Unlike Step 4c, this step runs during the FULL audit (not only for targeted skills).

**SKIP this step entirely in `audit --quick`** — it is structural/narrative scanning (same exclusion as 4a-bis, 4d-bis, and 4f).

1. **Identify qualifying skills** per [creative-integrity.md](../creative-integrity.md) § Scope: declared creative lane plus evaluator agents, AI-tells pattern libraries, scrub/finishing-chain machinery, eval-chained generators, or voice-profile enforcement. Not overtly obvious → Non-Obvious Decision Gate (but per the Step 4 agent budget, defer ambiguous classification to the report as "needs classification" rather than spawning panels mid-audit).
2. **Check by equivalence** against the Compliance Checklist (creative-integrity.md § Compliance Checklist). A principle present in the skill's own wording — including inside its own immutable directive blocks — is SATISFIED. A criterion outside the skill's role (e.g., a regeneration loop in an evaluator-only skill) is N/A, never a gap.
3. **Scrub-loop non-negotiables:** where a qualifying skill carries a scrub loop, verify the ◆ items of the Canonical Scrub-Loop Spec (entry provenance guard; MUST FIX + hard-directive auto-fix tier only; atomic fix + whole-document echo re-scan; cycle cap 2; best-so-far + divergence abort; humanity floor for text; fixability classifier + palette lock for images; evaluator never triggers regeneration; never detector-score-driven). A missing ◆ item is a finding naming the exact missing safeguard — built in step 4 when eligible, deferred otherwise.

3-bis. **Pattern-library gap check** (portable-rules transfer, 2026-06-12; full policy in creative-integrity.md § Pattern-Library Gap Check): for each qualifying skill that carries a text AI-tells pattern library (and is not opted out via `creative-scrub: off`), read the shipped drift anchor [creative-integrity/version.md](../creative-integrity/version.md), then diff the skill's library against the shipped catalog [creative-integrity/text-tells.md](../creative-integrity/text-tells.md) **by mechanism-equivalence, both directions** — different naming/wording/grouping is COVERED; only a demonstrably absent mechanism is a gap; equivalence-uncertain is silently skipped (never a row, never an append). Tiering (2026-06-12 install-on-absence directive, second clause — updates are APPLIED, never offered): AUTO append — scaffold-generated libraries into their machine-owned `modifiable: true` region; hand-authored libraries into ONE machine-owned `origin: skill-builder | modifiable: true` appendix region at the END of the library file, existing bytes never modified, under three guards (structural fit; live grounding — the evaluator must ground against the full library file; `.scrub-gaps.acked` as sole dedup authority), each degrading to a paste-ready Deferred Items row per skill — full policy in creative-integrity.md § Pattern-Library Gap Check tier 4. Both paths re-dedupe against the full library immediately before the write. **Report-once:** acked slugs recorded in the skill's `.scrub-gaps.acked` sidecar are suppressed until the shipped entry materially changes in a newer version. **Forced upgrade on catalog growth (2026-06-12 third clause):** a shipped version anchor newer than a library's last-checked version → the comparison RUNS and its AUTO appends APPLY in this same audit (never skipped, never offered, never a question); scaffold-generated libraries' machine-owned regions version-sync to the current catalog (code-eval `sync` discipline); new signs are never acked and always land — full policy in creative-integrity.md § Pattern-Library Gap Check tier 8. The check is additive-only — it never proposes removals, re-tiering, or relaxing a project's hard-directive elevations.
4. **Tiering (Audit Autonomy Gate + 2026-06-11 build clause; full policy in creative-integrity.md § Audit Policy):**
   - FLAG-NEVER-TOUCH: any finding whose remediation would intersect an `origin: user | immutable: true` block — quote it verbatim for the human. A build NEVER rewords, reorders, or deletes hand-authored text anywhere.
   - **BUILD-into-existing (AUTO):** a loop leg that is DEMONSTRABLY ABSENT (true absence confirmed by a design panel that read the FULL skill — never a mere equivalence-negative) → write a panel-adapted scrub-chain reference file (creative-integrity.md § Build Scaffolds) plus ONE machine-owned `CREATIVE-SCRUB-EMBED` pointer region (grounding link only, behaviorally inert; never gating logic in the workflow body). **Equivalence-uncertain → DEFER, never BUILD** — a missed equivalence must cost one ignorable row, never a competing chain. `creative-scrub: off` frontmatter opts a skill out.
   - **BUILD new evaluator skill (AUTO on absence — 2026-06-12 install-on-absence directive, superseding newest-wins the declared-evidence precondition; default name `text-eval`; further gated by the Step 0.3 companion gate, 2026-06-24):** NO skill performs the evaluator function AND no `text-eval` skill directory exists AND `model-lanes.md` carries no `<!-- creative-scrub-build: off -->` marker AND the Step 0.3 companion gate did not resolve `text-eval=off` (an unchecked `text-eval`, or a marker `text-eval=off` in a suppressed run, suppresses this scaffold exactly as `creative-scrub-build: off` does) → scaffold it per § Build Scaffolds, seeded from the shipped catalog creative-integrity/text-tells.md (persona + model gates apply; lanes unconfigured → `model:` absent + flagged, never invented; the terminal route tasks register it). Lane declarations do not gate the build — the precondition is absence alone (the code-evaluator ensure-exists precedent, § Step 4a-bis); the scaffold authors its own `lane: creative` frontmatter and never touches the Skill→Lane table. The existence test is **signal-based, never name-based** (any § Scope-signal skill counts as the evaluator), and the pre-build **name-collision guard** refuses to build when a `text-eval` skill directory already exists (→ DEFER, never a second skill).
   - **Atomic-or-absent:** a build that cannot complete its panel/anchor checks writes nothing and becomes a DEFER row. Built voice-dependent gates (humanity floor) are advisory-only when no voice profile exists.
   - DEFER: equivalence-uncertain legs; anything needing the user's wording; behavioral changes to hand-authored workflows; gap appends whose structural-fit or live-grounding guard fails — Deferred Items row with an exact follow-up command.
   - AUTO (machine-owned bytes): grounding-link insertion, enforcement-annotation generation beneath existing directives, reference sync of creative-integrity.md, reconciliation of this step's own `modifiable: true` regions (never a user-edited seam, never a whole scaffolded skill file).
5. Build tasks land in the Execution Plan like any other AUTO work (Step 6 tail order: before the route terminal tasks, so `route index`/`route embed` register new scaffolds and pointer regions). Findings feed the aggregate report's **Creative Integrity** section (Step 5). Apply absence-vs-gap: omit the section entirely when no skill qualifies.

**Grounding:** Read [creative-integrity.md](../creative-integrity.md) — the Nine Scrub Principles (verbatim), § Scope, § Compliance Checklist, § Canonical Scrub-Loop Spec, § Audit Policy, § Pattern-Library Gap Check. For step 3-bis, additionally [creative-integrity/version.md](../creative-integrity/version.md) (cheap anchor read) and [creative-integrity/text-tells.md](../creative-integrity/text-tells.md) (the shipped catalog — load only when a comparison actually runs).

### Step 4d: Validation Cascade Analysis

For each skill with 2+ validators or evaluation agents:
1. Run the cascade analysis per [cascade.md](cascade.md)
2. Include findings in the aggregate report under "Validation Cascade"
3. If cascade risk is MODERATE or HIGH, add to Priority Fixes

Skip silently for skills with 0-1 validators.

### Step 4d-bis: Cross-Skill Reconciliation

Where cascade (4d) analyzes validators *within* one skill, this step reads the next layer out — collisions *between* skills that make one silently fail to run: duplicate command/skill names, duplicate or conflicting hook matchers, selection-shadowing description overlap, circular/overridden dispatch chains, redundant skills, and contradicting directives. Run per [reconcile.md](reconcile.md).

Governed by the sacred integrity-over-performance directive (SKILL.md § Directives, 2026-06-04): **only completion-breaking conflicts are reported — harmless or intentional overlap (chains, shared kernels, defense-in-depth) is dropped silently.** Redundancy alone is never a finding.

- **SKIP this step entirely in `audit --quick`** — it is structural scanning, not a checklist item (same exclusion as 4a-bis and 4f).
- Runs in **display mode** during audit. Per the Step 4 agent budget, reconcile's own judgment-class adjudication panels are **suppressed here** — the audit's only panel is the Step 4e priority ranking. Mechanical findings (duplicate names, duplicate/conflicting hook matchers, duplicate embed blocks) and the complementary-overlap allow-list are evaluated without panels; genuinely ambiguous judgment-class candidates are reported as "needs adjudication (run `reconcile [skill]` standalone)" rather than resolved inside the audit.
- Findings feed the aggregate report's **Cross-Skill Reconciliation** section (Step 5). Apply absence-vs-gap: omit the section entirely when there are zero conflicts.
- **Priority Fixes elevation:** completion-breaking findings (duplicate name, conflicting hook matchers, circular/overridden dispatch, redundant skill, contradicting directives) elevate into Priority Fixes — a skill that silently never runs is a larger regression than most optimizations.
- **Execution (Audit Autonomy Gate):** the two mechanical auto-fixes (collapse duplicate machine-generated embed blocks / drop byte-identical hook dupes) are **AUTO tier** — they touch only machine-owned bytes and run in the auto-execution phase. Any confirmed redundant-skill `strip` hand-off is **DEFER tier** — deletion consent lives in strip's own gates; it lands in Deferred Items as `/skill-builder strip <skill>`. Directive/description/persona/conflicting-hook findings remain flag-only — never auto-applied.

**Grounding:** Read [reconcile.md](reconcile.md) for the collision-class table, the conflicts-only filter, the complementary-overlap allow-list, and the remediation ladder.

### Step 4e: Agent panel — priority ranking

After collecting findings from all sub-commands, the audit must rank fixes by priority. This is a judgment call — which fix has the highest impact? Which is most urgent? Per directive: agents are mandatory when guessing is involved.

Spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

- **Agent 1** (persona: Risk analyst — prioritizes by blast radius and failure probability) — Review all findings. Rank by: what breaks first if left unfixed? What affects the most users or invocations?
- **Agent 2** (persona: Developer experience advocate — prioritizes by friction and daily pain) — Review all findings. Rank by: what slows people down the most? What causes the most confusion or repeated mistakes?
- **Agent 3** (persona: Architectural debt specialist — prioritizes by compounding cost) — Review all findings. Rank by: what gets harder to fix over time? What blocks other improvements?

Each agent reads the aggregated findings from optimize, agents, and hooks across all skills. They return independently ranked priority lists. Synthesize:
- Items ranked top-3 by 2+ agents → highest priority
- Items ranked top-3 by only 1 agent → medium priority
- Present the synthesized ranking with attribution to each agent's rationale

### Step 4f: Model Lane Check (report-only scan + one-time setup onboarding; NO switch prompts)

Make the audit model-aware per the user directives (SKILL.md § Directives → Model-Lane Routing Gate and No-Switch-Prompt Gate). This step runs **after** the priority panel (4e) and **before** the route terminal tasks (4g) — except in bootstrap mode, where 4c–4e are skipped and this step runs after Step 6's auto-execution instead (§ Step 2.5, 2026-06-07 fix). It is report-only for mismatches — it never asks the user to switch models; the only questions it may ask are configuration ones (onboarding, picker).

**SKIP this step entirely in `audit --quick`** — the quick path does no structural/narrative scanning (see [quick-audit.md](quick-audit.md) § Step 4).

1. **Read the mapping.** Read `references/model-lanes.md` (path relative to the skill-builder install). Parse the Lane→Model table, the Skill→Lane table, and the `<!-- model-lane-setup: <state> -->` marker (§ Setup State; treat a missing marker as `unset`).
2. **Unconfigured → branch on setup state (the onboarding fork).** The feature is **unconfigured** when `model-lanes.md` has no active Skill→Lane rows AND no audited skill self-declares a `lane:` key. When unconfigured:
   - **Reconcile first.** IF the table actually has active rows or a skill self-declares a lane → the project is `configured` (upgrade the marker if it still says `unset`); skip this fork and continue to step 3.
   - IF `model-lanes.md` is **absent** entirely → silent no-op (nothing to offer against); stop this step.
   - IF the marker is `declined` → **silent no-op** (the user opted out for this project). Omit the Model Lane section. Stop this step.
   - IF the run is **suppressed for setup questions** (headless/non-interactive, or `audit --quick`) → silent no-op; do NOT write the marker. Omit the section. Stop this step.
   - IF the marker is `unset` AND this is a full interactive `audit` → **run the Setup Onboarding Flow** (§ Step 4f-setup below). Then either continue to step 3 with the freshly-written lanes (if the user set them up) or stop this step (if "Not now"/"Never ask").
   - Otherwise (configured) → the **every-audit Lane→Model picker already ran at § Step 0.4** (front question cluster, before the scan). Do NOT re-run it here; continue to step 3. **(Absence-vs-gap still holds:** a `declined` or suppressed run reports nothing; only an `unset` interactive run surfaces the one-time onboarding.)

2-bis. **Picker relocated to § Step 0.4 (fix, 2026-06-24).** The every-audit Lane→Model picker — which used to fire here — now fires UP FRONT at § Step 0.4 (it needs no scan data and was being silently skipped mid-scan; see § Step 0 clause 4's manifest). Its full spec lives at § Step 0.4 and [lane-delegation.md](../lane-delegation.md) § Lane→Model Picker. On a `configured` project it has therefore already run before this scan reached Step 4f; on an `unset` project the picks are captured by the 4f-setup onboarding (clause 1). The Fleet-Rewrite-on-remap likewise queues from § Step 0.4. The "asked EVERY full interactive audit run, regardless" guarantee is preserved — it just fires earlier, with a hard Step 6 backstop assertion. (This sub-step is retained as an anchor so existing "Step 4f step 2-bis" cross-references resolve to the relocation note.)
3. **Detect the active model.** Read the session system-context line "The exact model ID is …", strip any `[1m]`/`[200k]` suffix, lowercase → `ACTIVE_MODEL`. See [model-lanes.md](../model-lanes.md) § Active-Model Detection. This is a concrete read — no agent.
4. **Resolve each skill's lane from a DECLARED source only.** For each audited skill (respecting self-exclusion from Step 1): `lane:` frontmatter → Skill→Lane table → **NO LANE**. A skill with no declared lane is **skipped for flagging** — never auto-classified. Optionally compute a non-blocking lane *suggestion* for undeclared skills per [model-lanes.md](../model-lanes.md) § Advisory Lane Suggestion (suggest-only; a suggestion never triggers a prompt).
5. **Compare.** Look up the lane's Preferred Model. IF empty/absent → skip (flagging disabled by empty cell). IF non-empty AND `preferred_model != ACTIVE_MODEL` → record a **mismatch**. Apply the stale-ID self-check from [model-lanes.md](../model-lanes.md) § Comparison Rule: if a non-empty preferred model is not of `claude-<family>-<major>-<minor>` shape or names a clearly superseded family, downgrade to a "mapping may be stale" advisory instead of a mismatch finding.
5-bis. **Excursion coverage, legacy-switching, and agent-model scans (report-only).** Read [lane-delegation.md](../lane-delegation.md) once, then:
   - **Excursion coverage:** for each lane-declared skill, walk its workflow per § Excursion Signal Vocabulary + § NON-DELEGABLE Hard-Stop List (heuristic pass only — the classification agent panel is suppressed here per the agent-budget rule; it fires in `agents [skill]` standalone/`--execute`). Cross-lane steps with no covering `LANE-AGENT-EMBED` map entry → finding "excursion uncovered — run `agents [skill] --execute`".
   - **Legacy switching:** flag any non-managed mid-workflow model-switch instruction (`/model`, "switch model" outside any START/END markers) as "REVAMP: legacy mid-workflow switching — replace with lane-pinned delegation". Candidates inside `origin: user | immutable: true` blocks are FLAG-ONLY (directive-touch hard floor).
   - **Agents missing `model:` (sacred directive, 2026-06-06):** glob all agent forms (both skill forms + `.claude/agents/*.md`, deref symlinks, dedupe); any AGENT.md missing a `model:` field while lanes are configured → finding with a fix task (stamp per the Audit Agent Model-Assignment Gate on `--execute`). Lanes unconfigured → skip this scan silently.
   - **Fleet registration health (2-Brain Harness, 2026-06-06 — panel-measured failure: a live fleet had 104 agent files with 2 registrations, silently degrading every spawn):** every agent carrying `generated-by: skill-builder lane-excursion` MUST resolve through a `.claude/agents/<name>.md` registration (dereference symlinks; copy-fallback counts). Unregistered → finding "minion unregistered — spawns fall to the degraded path; re-register" with a fix task (recreate the symlink/copy on `--execute`). Also report CONTRACT-DRIFT and UNSTAMPED counts per route.md § Step 9c's vocabulary.
   - **Orphan retirement (execute path — report-only-forever guarantees accumulation):** a `generated-by: skill-builder lane-excursion`-marked agent whose `excursion-skill` no longer exists, or whose map entry was REMOVEd, → **AUTO-tier deletion task** (one task per file; consent = Step 0 acceptance, eligibility = mechanical marker check, re-verified at delete time — marker absent or ambiguous → skip + Deferred; no VCS → DEFER per Step 0.5). Agents WITHOUT the `generated-by` marker are user property — never listed, never touched.
6. **Report (always).** Emit the Model Lane section in the Step 5 aggregate report (table below). Report-only; never blocks.
7. **Report is the ceiling (No-Switch-Prompt Gate, sacred 2026-06-06).** The step-6 report section is this step's ENTIRE output for mismatches. NEVER emit a switch prompt, an AskUserQuestion about models, or any instruction to run `/model` — each mismatch is a one-line advisory ("Lane advisory: `<skill>` declares `<lane>` (preferred `<preferred>`); session is on `<active>`.") and the audit proceeds. The pre-2026-06-06 batched switch prompt is abolished. `--model-prompt` is retired; `--no-model-prompt` is accepted as a harmless no-op.
8. **Quick-mode scope.** `audit --quick` omits the Model Lane section entirely. Headless/non-interactive runs still print the section when mismatches exist (it is report-only and cannot block).
9. **Unreadable mapping with declared lanes → stop.** IF at least one skill declares a lane but `model-lanes.md` cannot be parsed → report "Model-lane mapping unreadable; cannot evaluate model routing. Fix references/model-lanes.md." and continue the rest of the audit.

#### Step 4f-setup: Setup Onboarding Flow (one-time, interactive, opt-in)

Fires only from step 2 when the feature is unconfigured, the marker is `unset`, and the run is a full interactive `audit` (never headless, never `--quick`, never when `declined`). This onboarding offers to set up model lanes instead of staying silently no-op so the user discovers the capability per project. It is a configuration question, not a switch request — no part of it asks the user to change the session model (No-Switch-Prompt Gate, 2026-06-06).

1. **The single onboarding question (2-Brain Harness directive, 2026-06-06: "at the audit's single onboarding question, the user picks the creative model and the model for everything else").** Emit ONE batched **AskUserQuestion** call containing THREE questions — never three separate prompts:
   - *(a) header "Model lanes":* *"Set up the 2-brain harness for this project? Creative work (image / content / design generation, plus communication, language translation, and text evaluation) runs on one model; everything else (including testing and research) runs on the other. Audit and your skills will then report when the active model doesn't match a skill's lane, and cross-lane steps delegate to model-pinned agents."* Options — **Set it up now** / **Not now** / **Never ask in this project**.
   - *(b) header "Creative brain":* the Lane→Model Picker option list (the two static IDs + the discovered latest release, per [lane-delegation.md](../lane-delegation.md) § Lane→Model Picker).
   - *(c) header "Everything-else brain":* the same option list.
   Resolution: **Not now** → leave the marker `unset`, discard (b)/(c), omit the Model Lane section, stop this step. **Never ask in this project** → write `<!-- model-lane-setup: declined -->`, discard (b)/(c), stop this step (reversible by hand: set it back to `unset`). **Set it up now** → the (b)/(c) answers ARE the Lane→Model mapping — the picker ran inside the single question; do NOT re-prompt it in clause 3. Continue to clause 2.
2. **Suggest lanes (suggest + confirm; never auto-assign).** For each audited skill, compute its Advisory Lane Suggestion per [model-lanes.md](../model-lanes.md) § Advisory Lane Suggestion (`creative` / `coding` / `AMBIGUOUS`, with confidence). Present the suggestions and let the user **confirm or edit** the per-skill assignments via AskUserQuestion (batch the choices; default each to its suggested lane, offer "leave unassigned"). `AMBIGUOUS` and MEDIUM-confidence skills default to unassigned — never guessed, never pre-selected. The user's confirmed choices — not the raw suggestions — are what gets written (honors model-lanes.md's "lane assignment is declared, never inferred" principle).
3. **Lane→Model mapping — already answered.** The clause-1 batched call captured both brain picks (this onboarding-only path stands in for the § Step 0.4 picker, which is skipped on an `unset` project — clause 1 IS the picker for the just-configuring case). Never emit a second mapping prompt during onboarding. (Leaving a lane's cell empty disables flagging for it, per § Comparison Rule.)
4. **Write the config (the one consented write).** Edit `model-lanes.md`: insert the confirmed Skill→Lane rows into the table, apply any Lane→Model edits, and set the marker to `<!-- model-lane-setup: configured -->`. Do not touch any `origin: user | immutable: true` content; the Skill→Lane and Lane→Model blocks are `immutable: false` user-editable mapping. Re-read the file once to confirm it parses.
5. **Continue.** Return to step 3 of the main flow and run the normal mismatch check against the just-written lanes (so a mismatch with the active model is surfaced immediately, including the route-embed wiring of the invocation-time gate at Step 4g/§ Step 8).

**One write, no model-switch, no menu item.** The ONLY thing this step ever writes is `model-lanes.md` — the setup-state marker plus, on explicit "Set it up now" consent, the confirmed Skill→Lane and Lane→Model rows. It still has **no `--execute` action and no Step 6 / TaskCreate entry**, and it never switches the session model and never asks the user to (No-Switch-Prompt Gate). It must not wedge into the route terminal tasks (4g) or the auto-execution task list. *(One scoped exception, 2026-06-06: when the § Step 0.4 picker — or, for a just-configuring project, this onboarding's clause-1 brain picks — REMAPS a lane, the consented Fleet Rewrite of `lane-pinned:` agents' `model:` lines runs as Step 6 auto-execution tasks — see lane-delegation.md § Fleet Rewrite on Remap. That write is picker-consented, surfaced per file, and touches `model:` lines only.)*

**Invocation-time complement.** This step is the *audit-time* half of the model-lane directive (it fires only when the user runs `audit`). The *invocation-time* half — a preflight gate embedded into each lane-declared skill's own workflow that surfaces a one-line lane advisory before generative work (never a prompt) — is the `MODEL-LANE-GATE` managed-block family, wired/refreshed/removed by `route embed` (the **last** terminal task, Step 4g; see [route.md](route.md) § Step 8). So once the onboarding flow declares lanes, the same audit's `route embed` task wires the invocation-time gate into those skills — setup and enforcement complete in one audit run.

**Grounding:** [model-lanes.md](../model-lanes.md), [lane-delegation.md](../lane-delegation.md) (picker spec, fleet rewrite, excursion + model-assignment scans), SKILL.md § Directives (Model-Lane Routing Gate, Bespoke Excursion-Agent Gate, Audit Agent Model-Assignment Gate), [update.md](update.md) § The `update` Command (prompt-style precedent; moved from SKILL.md 2026-07-01).

### Step 4g: Route Index & Embed (final task list items)

After all sub-commands and the priority ranking panel finish, the audit's execution task list MUST end with these two items, in this exact order:

- **Second-to-last task:** `route index` — refresh the `/route` skill's catalog. Skills that were renamed, added, or had their description/modes changed by earlier optimize/agents/hooks tasks need to be reflected in the index immediately. Also fires in **bootstrap mode** (Step 2.5) — `/route` bootstraps with an empty catalog so the dispatcher is ready as soon as the user creates their first skill.
- **Last task:** `route embed` — refresh consultation gates across skills. Earlier tasks may have added or removed workflow steps that change which skills should carry the route gate; this step reconciles. It reconciles **all four managed-block families** in one pass — `ROUTE-EMBED`, `CODE-EVAL-EMBED`, the `MODEL-LANE-GATE` invocation-time model-lane preflight ([route.md](route.md) § Step 8), and the `LANE-AGENT-EMBED` Excursion Delegation Map ([route.md](route.md) § Step 9, reconcile-only) — so a skill that gained or lost a declared lane gets its preflight gate and delegation map wired or stripped as a terminal audit action. **Skipped in bootstrap mode** — no skills exist to embed into; the embed mode itself stops cleanly in that state ([route.md](route.md) § Mode: `embed` → Step 1 "Zero-candidate case").

Both are **auto-appended terminal tasks** (Audit Autonomy Gate — there is no menu to deselect them from; they appear in the Execution Plan block before running). They are appended to whatever combined task list TaskCreate produces — they do NOT replace any earlier task. Order matters: `route index` must run before `route embed` so that `embed`'s index-refresh chain (Step 6 of `route.md` § `embed` — Post-Embed Index Refresh) does not double-rebuild a stale catalog.

**Companion-gate interaction (Step 0.3, 2026-06-24).** `route` is an install-on-absence default in the Step 0.3 gate (no "(recommended)" label is shown — that mechanic is superseded; under the inverted widget `route` is kept/installed unless explicitly checked for opt-out). The terminal `route index`/`route embed` tasks run normally whenever `route` is NOT checked for opt-out — the overwhelmingly common case, including absent-and-unchecked → bootstrap. Two edge resolutions: `route` checked (opt-out) + ABSENT → suppress the bootstrap (do not append `route index`/`route embed`; the project has opted out of the dispatcher); `route` checked (opt-out) + PRESENT → still run `route index`/`route embed` THIS audit (so the catalog reflects the run's other changes consistently), and surface the removal as a DEFER `/skill-builder strip route --execute --confirm-breaking` row (strip is almost always BREAKING for `route` since the four managed-block families reference it) — never an AUTO delete. Removing the dispatcher is high-blast-radius, which is why it is deferred, never automatic.

**In `audit --review` mode** (zero writes), surface these two as recommended terminal actions in the report's Priority Fixes section so the user knows they would run last. When the model-lane mapping is configured (at least one skill resolves to a lane with a non-empty preferred model), note in the same entry that `route embed` will also wire/refresh/remove the `MODEL-LANE-GATE` preflight on lane-declared skills (Step 8), so the invocation-time advisory gate is surfaced as a pending action, not silently applied. In bootstrap mode, only `route index` runs (embed is N/A).

**Grounding:** [route.md](route.md)

### Step 5: Aggregate Report

Combine all sub-command outputs into a single report:

**Reporting principle — absence vs. gap:** Capability sections (Teams, Temporal Hooks, Validation Cascade) that have nothing to report should be omitted entirely rather than displayed with "none" values. A capability that doesn't apply is correctly absent, not missing. The Awareness Ledger section is always included regardless of state — it has an explicit installation recommendation and is surfaced by design as the audit is the orchestrator for companion skill adoption.

```markdown
# Skill System Audit Report

## CLAUDE.md
[from Step 2]

## Rules Files
[from Step 2]

## Skills Summary
[from Step 3]

## Optimization Findings
[aggregated from optimize display mode per skill]

## Token Efficiency
[aggregated from optimize step 4e Token Efficiency Scan per skill — see token-efficiency.md for pattern list]
| Skill | Agent hooks flagged | Effort downgrade | SKILL.md slim-down | Precheck gates | Strictness |
|-------|---------------------|------------------|--------------------|----------------|------------|
| /skill-1 | [count + hook names] | [yes/no] | [lines trimmable] | [count] | [missing/present] |

## Agent Opportunities
| Skill | Agent Type | Purpose | Priority |
|-------|------------|---------|----------|
| /skill-1 | id-lookup | Enforce grounding for IDs | High |
[from agents display mode per skill]

## Hooks Status
[aggregated from hooks display mode]

### Hook Wiring Drift
*(Include only if the hooks sub-command's Step 2.5 surfaced dead wiring — wired entries pointing at files that do not exist on disk. Omit entirely when every wired entry resolves to a real file. Non-blocking at runtime but silently drops whatever enforcement the missing hook provided; load-bearing cases warrant recovery, advisory cases warrant unwiring.)*

Surface the full Dead Wiring table from the hooks sub-report (Skill | Hook | Event/Matcher | Intent | Intent source | Criticality | Recoverable). Do not summarize the table away — the intent/criticality/recoverability columns are what turn this from "broken reference" into an actionable recommendation.

**Priority Fixes elevation rule:** Every **Load-bearing** dead-wiring finding MUST appear in the Priority Fixes list at or above any optimization or agent-opportunity finding. Rationale: load-bearing hooks enforce sacred directives or content-quality rules whose silent absence is a larger regression than most structural improvements. Protective findings enter Priority Fixes at medium priority; advisory findings do not unless there are enough of them (3+) that the log noise itself is the problem.

## Directive Protection
*(from Step 4b-bis; omit entirely when no audited skill has `immutable: true` directive blocks — absence is not a gap. Always omitted in `audit --quick`.)*

| Skill | Immutable blocks | Sidecar | Status |
|-------|------------------|---------|--------|
| /skill-1 | 2 | present | PROTECTED |
| /skill-2 | 1 | MISSING | unprotected → Deferred |
| /skill-3 | 3 | present | MISMATCH → Deferred (investigate) |

Report-only. MISSING and MISMATCH both land in the Deferred Items table; this audit never generates a sidecar or wires a hook (deliberate host act — see Step 4b-bis).

## Creative Integrity
*(from Step 4c-bis; include only when at least one skill qualifies as a creative-workflow skill per creative-integrity.md § Scope. Omit entirely otherwise — absence is not a gap. Always omitted in `audit --quick`.)*

| Skill | Role | Principles | Scrub loop | Action |
|-------|------|------------|------------|--------|
| /text-eval-class | evaluator | 9/9 SATISFIED (equivalence) | ◆ complete | none |
| /image-class | generator | 7/7 applicable | ◆ leg demonstrably absent | BUILD: scrub-chain reference + CREATIVE-SCRUB-EMBED pointer |
| /content-class | producer | equivalence uncertain on principle 4 | — | DEFER → `[exact command]` (uncertain never builds) |
| *(no evaluator in project, declared creative lane present)* | — | — | — | BUILD: evaluator scaffold per § Build Scaffolds |

Equivalence is the bar (a principle in the skill's own wording is SATISFIED); builds are strictly additive (a build never rewords hand-authored text); immutable-block findings are FLAG-NEVER-TOUCH and quoted verbatim; equivalence-uncertain and guard-failed cases land in Deferred Items with exact commands (Step 4c-bis tiering).

## Teams Status
*(Include this section only if agent teams are actively configured — i.e., `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set AND at least one skill uses team routing. If no skills use teams, omit this section entirely. Team routing is evaluated per-skill during Step 4 via the agents sub-command, which applies the routing decision framework from `references/agents-teams.md`. Absence of teams is not a gap — it means individual agent routing is correct for the current workloads.)*

- **Skills using teams:** [list]
- **Research assistant present:** [per-team status]
- **Issues:** [any team-related issues or "none"]

## Awareness Ledger
[from Step 4a — status, record counts, capture gaps, or installation recommendation]

## Temporal Reference Risk
[from Step 4b — per-skill risk levels, missing hooks]
| Skill | Risk Level | Exposure | Temporal Hook |
|-------|-----------|----------|---------------|
| /skill-1 | HIGH/MEDIUM | [temporal patterns found] | present/MISSING |

## Model Lane
*(Include only if Step 4f found at least one declared lane with a non-empty preferred model. Omit entirely when the mapping is unconfigured — absence is not a gap. Always omitted in `audit --quick`.)*

Active session model: `[ACTIVE_MODEL]`
Lane→Model picker: [confirmed unchanged / remapped (`<lane>` → `<new id>`) → N lane-pinned agents rewritten / suppressed]

| Skill | Lane | Lane Source | Preferred | Active | Match |
|-------|------|-------------|-----------|--------|-------|
| /skill-1 | creative | frontmatter/table | claude-opus-4-6 | claude-opus-4-8 | ✗ MISMATCH |

*Undeclared skills (advisory suggestions only — not flagged):* [skill → suggested lane (confidence), or "none"]

**Excursion delegation** *(from Step 4f.5-bis; omit when no lane-declared skill has cross-lane signals)*:
| Skill | Step (anchor) | Direction | Status |
|-------|---------------|-----------|--------|
| /skill-1 | "[quoted phrase]" | creative→coding (research) | UNCOVERED — run `agents /skill-1 --execute` |
| /skill-2 | "[/model prompt at ...]" | — | REVAMP: legacy mid-workflow switching |

*Agents missing `model:` (2026-06-06 directive; only when lanes configured):* [agent path list with fix tasks, or "none"]

Mismatch advisories above are this section's entire output — no switch prompt ever follows the report (No-Switch-Prompt Gate, 2026-06-06; see Step 4f step 7).

## Validation Cascade
[from Step 4d — per-skill cascade risk]
| Skill | Validators | Cascade Risk | Top Finding |
|-------|-----------|-------------|-------------|
| /skill-1 | [count] | [NONE/LOW/MODERATE/HIGH] | [summary] |

## Cross-Skill Reconciliation
*(from Step 4d-bis. Include only if at least one completion-breaking conflict was found. Omit entirely when there are zero conflicts — redundancy-only overlaps are never reported, per the integrity-over-performance directive. Always omitted in `audit --quick`.)*

| ID | Class | Skills involved | Evidence (file:line) | Tier | Recommended action |
|----|-------|-----------------|----------------------|------|--------------------|
| R1 | Duplicate name | /a, /b | ... | FLAG | You choose which keeps the verb |
| R3 | Duplicate hook entry | settings.local.json | ... | AUTO-FIX | Drop byte-identical dupe (`--execute`) |
| R8 | Contradicting directives | /c, /d | ... | FLAG-NEVER-TOUCH | Both quoted verbatim; you resolve |

*Judgment-class candidates needing adjudication (panels suppressed during audit):* [list, or "none"] — run `/skill-builder reconcile [skill]` standalone to adjudicate.

## Directives Inventory
[List all directives found across all skills - ensures nothing is lost]

## Priority Fixes
1. [Most impactful optimization]
2. [Second priority]
3. [Third priority]

## Execution Plan
*(The exact TaskCreate list about to run, in Step 6 tail order. Printed BEFORE any write so a mid-run
crash leaves the full findings + plan in hand. In `--review` mode and headless runs this is the
would-be plan and nothing below it executes.)*
1. [task — e.g. "optimize --execute /skill-1 (P5 strictness, description reflow — no truncation)"]
2. [task]
…
N-1. route index
N.   route embed

## Deferred — needs your call
*(DEFER tier only — never silently dropped. Omit the section when nothing deferred.)*
| Item | Why deferred | Run it with |
|------|--------------|-------------|
| [e.g. Redundant skill /foo (R7)] | deletion — consent lives in strip | `/skill-builder strip foo` |
| [e.g. /bar protective dead hook] | recover-vs-unwire is your policy call | `/skill-builder hooks bar --execute` |
| [e.g. 2-Brain migration (/qux)] | ratification gates inside convert | `/skill-builder convert qux --execute` |

## Execution Summary
*(After the auto-execution phase: per-task ✓/✗, files touched, reverts performed, panels consulted.
Informational prose — never ends with a question.)*
```

### Step 6: Auto-Execution (Audit Autonomy Gate — the execution menu is abolished)

Per the 2026-06-06 sacred directive ("The audit command should be as automated and streamlined as possible. … Always do the work, instead of suggestion to skip work that will improve the system"), there is **no execution question**. After the Step 5 report (including its Execution Plan block) is printed, build the combined task list via TaskCreate and execute it sequentially under the Step 0 disclaimer consent, marking progress via TaskUpdate. **Scope discipline (Display/Execute rule 5) is the contract:** execute ONLY the printed plan; new opportunities discovered mid-run are noted in the Execution Summary, never acted on.

**Suppression:** in `audit --review` (alias `--dry-run`) and in headless runs, STOP after the report — the Execution Plan is the would-be plan; nothing executes. `--execute` is accepted as a harmless no-op (execution is the default).

**Pre-execution picker assertion (HARD GATE — fix, 2026-06-24; the structural backstop the design panel required).** Before building or running the Step 6 task list, on a **full interactive run of a `configured` project**, confirm the every-audit Lane→Model picker (§ Step 0.4) actually fired THIS run. This is a hard gate, not a warning: IF the picker did not fire this run (it was missed) → ASK it now (§ Step 0.4's batched AskUserQuestion — it has no scan dependency, so it is safe to ask here) and apply its result (write changed cells; queue the Fleet Rewrite) BEFORE executing any task. Do NOT enter the auto-execution phase until the picker has demonstrably been asked this run. (On `unset`/`declined` projects, in headless/`--quick`, or when the picker already fired at § Step 0.4, this assertion is a no-op.) Rationale: every soft/narrative guard in this procedure dissolves under the "do the work; auto-execute" autonomy pressure that caused the original skip (INC-2026-06-07-bootstrap-onboarding-skip is the same recurrence shape) — so the picker is both front-loaded AND asserted here.

**AUTO tier — runs automatically (improvement work is done, never offered as skippable):**

| Work | Notes |
|------|-------|
| Pre-audit backup zip | gated by Step 0.2 = "Back up first"; runs FIRST (before every other task) so the snapshot captures pre-audit state — per [backup.md](backup.md). Never blocks (zip failure → ✗ + Execution Summary note + a one-line "proceeding without snapshot" warning). Skipped when Step 0.2 was suppressed (headless / `--quick`) or answered "Skip backup" |
| Mechanical fixes | frontmatter single-line reflow (**never truncate or shorten a description — reflow preserving every word**), `strictness:` fields, annotation generation, P-ranked structural fixes |
| `optimize --execute` per flagged skill | VCS-gated (Step 0.5). Its immutable-block precheck + optimize-diff-auditor verification fire as written; a FAIL verdict auto-reverts via `git checkout` and lands in Deferred — never a mid-run question |
| `agents --execute` incl. lane-excursion design (4f.5-bis UNCOVERED/REVAMP) and `model:` stamps | additive files + managed blocks; persona/panel gates fire as written; panel disagreement → NO-DELEGATE |
| Fleet Rewrite (only if § Step 0.4 picker REMAPPED a lane) | one task per `lane-pinned:` agent of each remapped lane; rewrite the `model:` line only, verify by re-grep, report per file (Audit Agent Model-Assignment Gate clause 6). Picker-consented at § Step 0.4; VCS-gated; runs before the route terminal tasks |
| `hooks --execute` new hooks, temporal hooks, dead-wiring auto classes | load-bearing+recoverable auto-recover; advisory auto-unwire |
| `ledger --execute` (if absent) | additive companion scaffold — **gated by Step 0.3** (`awareness-ledger` checked) |
| `code-eval create` / `code-eval sync` | per § Step 4a-bis, before the route tasks — `create` **gated by Step 0.3** (`code-evaluator` checked); `sync` is unconditional drift-refresh of an already-present evaluator |
| `reconcile` mechanical auto-fixes | duplicate machine-generated embed collapse; byte-identical hook dedupe — machine-owned bytes only |
| Creative-integrity machine-owned fixes | per § Step 4c-bis: grounding-link insertion, enforcement-annotation generation beneath existing directives, creative-integrity.md reference sync, and pattern-library gap appends (§ step 3-bis) — into the machine-owned region of scaffold-generated libraries, and into ONE machine-owned appendix region at the end of hand-authored libraries (2026-06-12 install-on-absence directive, second clause; existing bytes never modified; structural-fit + live-grounding + ack-sidecar guards, each degrading to DEFER) — hand-authored loop mechanics and immutable blocks are never auto-edited |
| Creative-integrity BUILDS (2026-06-11 build clause + 2026-06-12 install-on-absence directive) | per § Step 4c-bis step 4: scrub-chain references + `CREATIVE-SCRUB-EMBED` pointer regions into skills whose loop leg is demonstrably absent (panel-confirmed); evaluator-skill scaffold on absence alone (no evaluator-function skill + no `text-eval` directory + no `creative-scrub-build: off` marker + Step 0.3 did not resolve `text-eval=off` — lane declarations do not gate it); atomic-or-absent; before the route terminal tasks |
| Orphan minion retirement | marker-gated per 4f.5-bis; VCS-gated |
| Bootstrap CLAUDE.md extraction | HIGH-confidence candidates only (Step 2.5) |
| `route index` → `route embed` | always the final two tasks (§ Step 4g) |

**DEFER tier — lands in the Deferred Items table with an exact command, never silently dropped, never asked about:**

| Work | Why |
|------|-----|
| `strip` hand-offs (redundant skills) | deletion — consent lives in strip's own `--execute`/`--confirm-breaking` gates |
| Companion-gate removals (Step 0.3 — a PRESENT, skill-builder-scaffolded companion was CHECKED for opt-out under the inverted widget) | `/skill-builder strip <companion> --execute [--confirm-breaking]` — the user ratified "Always defer to strip"; the checkbox suppresses re-install and defers removal, never an AUTO delete. Strip performs the COMPLETE cross-reference disconnection across every other skill plus the `route index`/embed refresh. User-authored (non-scaffolded) companions are never offered for removal (provenance guard) |
| 2-Brain migration via `convert` | its inline sacred ratification gates (classification, harvested-lane confirmation, directive rehoming) cannot fire in a no-questions run |
| Quarantine repairs (Step 2.7) | hand-authored files parsing can't judge |
| Protective / not-recoverable dead wiring | recover-vs-unwire is a policy call |
| AMBIGUOUS bootstrap extraction candidates | judgment about scope — never guessed |
| Git-dependent items in no-VCS projects | no recovery path (Step 0.5) |
| Directive protection — MISSING or MISMATCH `.directives.sha` (Step 4b-bis) | sidecar+hook wiring is a deliberate host act (checksums.md § Override Path); MISMATCH never auto-regenerated — would bless tampering |
| Code-eval enforcement unwired (Step 4a-bis) | `/skill-builder code-eval enforce --execute` — wiring blocking PreToolUse hooks under blanket Step-0 consent is a deliberate host act (DEC-2026-06-08); never in the AUTO tier |
| Code-eval enforcement wired but stale (Step 4a-bis) | `/skill-builder code-eval enforce --execute` — wired scripts predate the current procedure (`code-eval-enforce-version` recorded < shipped); re-wiring/refresh is a deliberate host act, never auto-refreshed |
| Creative-integrity non-buildable findings (Step 4c-bis) | equivalence-UNCERTAIN legs (uncertain never builds — competing-chain risk); anything needing the user's wording or a behavioral change to a hand-authored workflow; incomplete builds (atomic-or-absent); pattern-library gap appends whose structural-fit or live-grounding guard fails (one paste-ready row per skill quoting the exact proposed additions; report-once via the `.scrub-gaps.acked` sidecar); immutable-block findings are FLAG-NEVER-TOUCH |

**Tail order:** (0) the pre-audit backup zip (if Step 0.2 = "Back up first") runs BEFORE everything else, so the snapshot is genuinely pre-mutation (before code-eval/route and before any AUTO edit or deferred strip); (1) `code-eval create`/`sync` next, so the evaluator exists before routing; (2) reconcile mechanical fixes — before the route tasks so the catalog reflects them; (2-bis) lane-excursion `agents --execute` tasks and the § Step 0.4 Fleet Rewrite (if a lane was remapped) — before the route tasks so `route embed`'s Step 9 reconciles fresh `LANE-AGENT-EMBED` blocks and rewritten agent `model:` lines; (2-ter) creative-integrity builds (Step 4c-bis: scrub-chain references, `CREATIVE-SCRUB-EMBED` pointer regions, evaluator scaffolds) — before the route tasks so new scaffolds and scrub functions are indexed and gated the moment they exist; (3) `route index` (second-to-last) and `route embed` (last).

**Failure containment:** a failed task → mark ✗, continue independent tasks, skip dependents (`route embed` depends on `route index`), surface in the Execution Summary. Never silently retry a write. Ambiguity mid-run resolves per the Audit Autonomy Gate clause 5 (panel → conservative → DEFER), never via a user question.

**Close with the Execution Summary + Deferred Items** (Step 5 template) — informational prose; never end the audit with a question.

**Follow § Output Discipline** (in SKILL.md) for cascade execution and cross-skill separation.
