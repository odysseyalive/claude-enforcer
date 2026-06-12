---
name: skill-builder
description: "Create, audit, optimize Claude Code skills. Commands: skills, list, new, strip, optimize, agents, hooks, verify, inline, ledger, cascade, checksums, convert, shell-safety, route"
when_to_use: "When creating, auditing, or optimizing Claude Code skills, or when working with SKILL.md files, hooks, or agents"
argument-hint: "[command] [skill] [--execute]"
version: "1.5"
minimum-effort-level: high
strictness: standard
allowed-tools: Read, Glob, Grep, Write, Edit, TaskCreate, TaskUpdate, TaskList, TaskGet
hooks:
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: Directives are sacred. Never reword, paraphrase, or summarize text between <!-- origin: user | immutable: true --> markers. Optimization is restructuring, not rewriting. Move content — never rewrite it.\"}'"
          statusMessage: "Re-injecting directive awareness..."
---

# Skill Builder

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Quick Commands

| Command | Action |
|---------|--------|
| `/skill-builder` | Full audit: disclaimer → scan + report → auto-executes recommended fixes (Audit Autonomy Gate) |
| `/skill-builder audit` | Same as above |
| `/skill-builder audit --review` | Full scan + report + would-be Execution Plan, zero writes |
| `/skill-builder audit --quick` | Lightweight audit: frontmatter + line counts; auto-fixes mechanical findings |
| `/skill-builder cascade [skill]` | Validation cascade analysis: detect over-validation suppressing output |
| `/skill-builder dev [command]` | Run any command with skill-builder itself included |
<!-- /origin -->

---

<!-- origin: user | added: 2026-02-22 | immutable: true -->
## Directives

> **"When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY, in order to provide additional input in decision making."**

*— Added 2026-02-22, source: user directive*

> **"Each agent being created by this system always has to have an appropriate persona that is not being used anywhere else."**

*— Added 2026-02-22, source: user directive*

> **"When deploying a Team, one of the team member's persona is a research assistant who will research the issue using read-only reference tools. Other team members may also make requests from the research assistant to help augment the outcome."**

*— Added 2026-02-23, source: user directive (tool specifics in references/agents-teams.md)*

> **"When the dev flag gets called, you ALWAYS concentrate on the distribution files first, then sync changes to the .claude directory after."**

*— Added 2026-05-08, source: user directive (after dev edits repeatedly landed in the runtime copy instead of the source distribution)*

> **"No hooks! We don't distribute hooks. The project only makes hooks on the host system."**

*— Added 2026-05-08, source: user directive*

> **"Exception to the no-hooks-distribution rule: skill-builder's own load-bearing enforcement hooks — protect-directives.sh and unique-persona.sh — DO ship in the source distribution and the installer fetches them. They protect two sacred user directives (no rewording of immutable blocks; persona uniqueness across agents). Without them, every fresh install silently loses load-bearing enforcement. The general no-distribute rule still applies to every other hook on the host system. Wiring into settings.local.json remains host-local."**

*— Added 2026-05-11, source: user directive (after the regenerate-and-rewire loop revealed that no-distribute leaves load-bearing enforcement off on every fresh host).*

> **"Bifurcate jobs based on the currently selected model — split jobs between creative work (ie image generation, content generation, and design generation) and coding (everything else, including testing). When we run an audit, I want to make sure it's fluid in managing switching between models, with prompting, or not."**

*— Added 2026-06-01, source: user directive (the lane→model mapping is intentionally arbitrary/configurable because models change constantly; the model IDs live in references/model-lanes.md, never inside this immutable block).*

> **"It shouldn't make any decisions based on performance, but the full completion of integrity of skills expected to be performed by the user. Don't make decisions based on 'shortcut' mentality."**

*— Added 2026-06-04, source: user directive (governs the `reconcile` command: redundancy is never the target; only completion-breaking conflict is actionable; integrity over performance, never a shortcut).*

> **"When a project is audited and the model switching setup is deciding what is most likely creative, I want to make sure to flag any skill that has to do with communication, language translation, text evaluation, etc as creative."**

> **"Anything that has to do with research must be performed by the coding model before being handed off to creative."**

*— Added 2026-06-06, source: user directive (widens the creative lane of the 2026-06-01 bifurcation directive to communication / language-translation / text-evaluation skills, with research explicitly staying on the coding model and taking precedence over creative signals; the signal lists implementing this live in references/model-lanes.md § Advisory Lane Suggestion, never inside this immutable block).*

> **"Why option 3 is important, and this should be a directive moving forward, there are usually explicit directions on directing the text-evaluator workflow. These workflows may include routing points to other skills, so agents should be highly focused as to preserve the original intentent of the skill and preserve its workflow as the highest priority. There are no shortcuts. We aren't doing this for token efficiency. We're doing this to actually preserve the workflow and make the main model most effective at its task."**

*— Added 2026-06-06, source: user directive (captured verbatim from the lane-delegation workshop; "option 3" refers to the workshop's fleet-design choice of bespoke per-skill agents over a shared generic fleet. Governs lane-pinned excursion delegation: agents are designed per skill from that skill's reviewed material; workflow preservation — including routing points to other skills — is the highest priority; token efficiency is never a valid rationale. The delegation machinery lives in references/lane-delegation.md and references/procedures/agents.md, never inside this immutable block.)*

> **"All agents created or modified during the audit should have a model specified, per the user's choice of creativity model and everything else model."**

*— Added 2026-06-06, source: user directive (every AGENT.md that audit — or any command running under audit — creates or modifies must carry an explicit `model:` field, resolved from the user's Lane→Model choices in references/model-lanes.md: creative-lane work gets the creativity model, everything else gets the everything-else/coding model. The assignment mechanics live in references/lane-delegation.md § Audit Model-Assignment Rule, never inside this immutable block.)*

> **"The system is a 2-brain harness that balances between creativity and analytics: at the audit's single onboarding question, the user picks the creative model and the model for everything else. /route is the preferred smart door that matches the orchestrator to the work's lane with at most one prompt per endeavor. If the user wants to hand run skills, that's absolutely fine — hand-run skills stay lane-aware through their own slim gates, which go silent when route already covered the endeavor."**

*— Added 2026-06-06, source: user directive (ratified from the 2-Brain Harness workshop; see ledger DEC-2026-06-06-two-brain-harness and INC-2026-06-06-silent-lane-correctness. Drafted from the user's verbatim session wording and ratified as a unit. The gate/dispatch mechanics live in references/procedures/route.md and references/model-lanes.md, never inside this immutable block.)*

> **"When the user asks to create skills, route looks for a similar skill and modifies that or builds a new one — and the skill creation decision is part of the skill-builder skill. The system gives Claude Code as much creative leeway as possible to propose; the user ratifies. Skill management is risk-tiered to the analytical brain: high-risk commands prompt for it, low-risk additions run wherever the session is."**

*— Added 2026-06-06, source: user directive (ratified from the 2-Brain Harness workshop. Route's no-match path hands off to skill-builder's intent-router, which owns the modify-vs-create decision; route never synthesizes the `dev` prefix; direct `/skill-builder` invocation remains the always-legal maintenance hatch. The handoff and risk-tier mechanics live in references/procedures/route.md and references/procedures/intent-router.md, never inside this immutable block.)*

> **"The orchestrator has an army of minions, bounded to a platoon: delegation is justified only by model-fit (cross-lane work) or context isolation (unbiased evaluation), never by token efficiency or speed. Every minion is pinned to one of the two brains. A minion that discovers ambiguity returns the question to the orchestrator — it never guesses."**

*— Added 2026-06-06, source: user directive (ratified from the 2-Brain Harness workshop, panel-bounded from "army" to "platoon" per the fleet-mechanics review. The delegation rationale vocabulary, AMBIGUOUS sentinel, and fleet-hardening mechanics live in references/lane-delegation.md, never inside this immutable block.)*

> **"No user should ever be asked this question. No model switching should be requested during the audit process or any function of skill-builder. However, I would like to mention that there be a disclaimer that must be accepted by the user before proceeding with audit. The disclaimer should mention that skill-builder is designed to be used with Opus 4.7 or higher model. However, skill created with skill-builder are backwards compatible with earlier models. Please backup your CLAUDE.md and .claude directory before proceeding."**

*— Added 2026-06-06, source: user directive (issued in reaction to the audit Step 4f batched switch prompt — "this question" refers to that AskUserQuestion instructing the user to run `/model`. Eliminates every model-switch request across skill-builder: the audit 4f switch prompt, route's dispatch-time lane preflight prompt, the embedded MODEL-LANE-GATE preflight prompt, and route's high-risk analytical-brain prompt all become report-only advisories. Supersedes prompting mechanics only, newest-wins, user-ratified 2026-06-06: the 2026-06-01 "with prompting, or not" resolves permanently to "or not"; the 2026-06-06 "at most one prompt per endeavor" resolves to zero switch prompts; the 2026-06-06 "high-risk commands prompt for it" becomes a one-line advisory. The lane system, the audit's single onboarding question, and the every-audit Lane→Model picker are unchanged per the same ratification — they configure the mapping and never request a switch. The disclaimer-acceptance checkpoint lives at the top of references/procedures/audit.md; advisory mechanics live in audit.md § Step 4f and references/procedures/route.md, never inside this immutable block.)*

> **"likewise, I would like to prevent questions like this from happening, too. ... The audit command should be as automated and streamlined as possible. There shouldn't be any hard questions like this for the user."**

> **"I don't mind the two questions for choosing the creative model and analytical model. that needs asked every time audit is ran, regardless. Just limit any additional questions. Always do the work, instead of suggestion to skip work that will improve the system."**

*— Added 2026-06-06, source: user directive (first clause issued in reaction to audit Step 6's batched execution menu — "questions like this" refers to that Fixes/System multi-select AskUserQuestion; "likewise" extends the same-day no-switch-prompt directive from model-switch prompts to execution menus. Second clause is the user's clarification in the same session: the Lane→Model picker's two model questions are asked on EVERY audit run, regardless; everything else is limited; improvement work is DONE, never offered as skippable. Together they abolish audit's Step 6 execution menu and every mid-audit decision question: disclaimer acceptance (audit Step 0, whose backup warning is the consent instrument) authorizes the run — audit scans, reports, then auto-executes its recommended fixes and terminal route tasks as a sequential TaskCreate list, including bootstrap-mode CLAUDE.md extraction at high confidence and Awareness Ledger creation, with agent panels — never user menus — resolving judgment; ambiguity resolves to the conservative alternative or DEFERS to the report's Deferred Items table with a ready-to-run command, never a guess, never a question, never a silent skip. Only genuinely destructive or ratification-gated work defers: strip deletions, convert/migration (inline sacred gates), quarantine repairs of hand-authored files, protective/unrecoverable dead wiring, and git-dependent fixes in no-VCS projects. The only questions any audit may ask are exactly three: the Step 0 disclaimer, the one-time 4f-setup onboarding, and the every-audit Lane→Model picker. Supersedes execution-menu mechanics only, newest-wins: Rule 3's "offers the user a choice", the Step 6 menu, the bootstrap extraction menu, quick-audit's per-item y/n offer, and the under-audit post-action-chain menu all become automatic; standalone commands invoked outside audit keep their own menus. The AUTO/DEFER tiering and execution mechanics live in references/procedures/audit.md § Step 6, never inside this immutable block.)*

> **"The 2026-05-11 hooks-in-source exception extends to the PowerShell companions of the same two hooks — protect-directives.ps1 and unique-persona.ps1 — so Windows hosts keep the mechanical backstop. The exception set is exactly these four files: the two bash originals and their two PowerShell ports. Nothing else about the no-hooks-distribution rule changes; wiring into settings.local.json remains host-local, and the hooks procedure wires the OS-appropriate variant."**

*— Added 2026-06-06, source: user directive (ratified via AskUserQuestion — "Ship .ps1 companions" — during the cross-platform installer session; see ledger DEC-2026-06-06-cross-platform-installer. Drafted from the ratified option's stated scope and ratified as a unit. Amends the 2026-05-11 exception's file set only; that directive's text above stays verbatim. The .ps1 ports are fail-open and remain dormant on any host until wired via /skill-builder hooks; the port implementations live in skill-builder/hooks/, never inside this immutable block.)*

> **"When you give route a task, it reads the whole course of action it's been handed and picks the dominant hemisphere for the job — the brain the main loop will mostly run in — and relies on the agents for the rest. Route can't switch the model itself, but it's the one door allowed to ask: when the dominant hemisphere doesn't match the current session model, route asks the user to run `/model` and waits before dispatching. This doesn't override bringing up a skill manually — hand-run skills stay advisory-only. This restores route's dispatch-time ask, superseding (newest-wins) only the route clause of the 2026-06-06 No-Switch-Prompt directive; audit and the per-skill gates stay report-only."**

*— Added 2026-06-07, source: user directive (ratified "ratify" after a 3-agent fidelity/conflict/premortem panel tightened the verbatim wording. Restores route's dispatch-time ask ONLY: when the dominant hemisphere — the matched entry skill's PRIMARY lane, or the task's lane on the no-match path — does not match the active model, /route alone may ask the user to run `/model` and wait. Route can never switch the model itself; a tie/UNCONFIRMED lane resolves to the analytical brain and never asks; off-hemisphere steps delegate to lane-pinned agents. Supersedes newest-wins ONLY the route-dispatch-prompt clause of the 2026-06-06 No-Switch-Prompt directive — audit Step 4f, the per-skill MODEL-LANE-GATE, and hand-run invocation stay report-only/advisory-only. The ask mechanics, dominant-hemisphere resolution, tie default, and assessment-based endeavor coverage live in references/procedures/route.md § Canonical Dispatch CHECKPOINT clause 2, never inside this immutable block.)*

> **"Hand-run skills stay non-blocking on a lane mismatch, but the advisory must name the exact remedy: state the preferred model and the literal command — run `/model <preferred>` and re-invoke — then proceed as-is. Never a question, never blocking, and the skill still can never switch the model itself."**

*— Added 2026-06-11, source: user directive (ratified via AskUserQuestion — "Strengthen the advisory (Recommended)" — after a 3-agent research/skeptic/premortem panel reviewed the hand-run vs route-door asymmetry; drafted from the ratified option's stated scope and ratified as a unit. Amends ADVISORY WORDING ONLY, superseding (newest-wins) the 2026-06-06 No-Switch-Prompt directive's never-name-`/model` mechanic for the per-skill MODEL-LANE-GATE advisory line alone: naming the command informationally is now REQUIRED there; asking a question, blocking, or switching remains forbidden. The 2026-06-07 route-ask directive's door ask, audit Step 4f's report-only advisories, and the hand-run advisory-only rule are all unchanged. The advisory template lives in references/procedures/route.md § Step 8c clause 4, never inside this immutable block.)*

> **"build that scrub loop for text and images.. and make sure we do research around these topics an explicitely update, through audit, these mechanisms for any skill that manages this type of workflow"**

> **"But, i'd like item #2 to build new skills or funciton within existing skills of the project to facilitate all these points?"**

*— Added 2026-06-11, source: user directive (the scrub-loop build order, issued with nine accompanying scrub principles — detection philosophy: clustering, not signals; three tiers of tells; the subtle tells that survive review; fixes introduce new tells; protect the voice, don't just hunt AI; context-isolated validation; severity architecture; SEO/snippet text conflicts with voice; keep the pattern library living. The nine principles are preserved VERBATIM in references/creative-integrity.md § The Nine Scrub Principles — user-origin, immutable there — never paraphrased into this block. The second clause ("item #2" refers to the Creative Integrity audit check) was issued the same day after the first implementation shipped report-only: it upgrades audit Step 4c-bis from report-and-defer to BUILDING the missing scrub machinery — new functions within existing skills, and new evaluator skills where none exist. Build mechanics were premortem-hardened and ratified as a unit: builds are strictly ADDITIVE (a build never rewords hand-authored text and never touches an immutable block); build-into-existing fires only when the loop leg is demonstrably absent (equivalence-uncertain degrades to DEFER, never to a competing chain); whole-new-skill scaffolding fires only on DECLARED creative-lane evidence, never inferred classification; voice-dependent gates in built scaffolds are advisory-only when the project has no voice profile; builds are atomic-or-absent with code-eval-grade modifiable-true seams. Scrub loops themselves stay per the design panel's conservative scope (auto-fix MUST FIX + hard-directive flags only; best-so-far + divergence abort; humanity floor; fixability classifier; provenance guard). Research around these topics runs on the coding model per the 2026-06-06 research-precedence directive. The compliance checklist, canonical loop spec, build policy, scaffolds, and research digest live in references/creative-integrity.md, never inside this immutable block.)*

> **"Okay, we have a problem with the text-eval not being installed if nothing yet exists... check out this correspondence..."**

> **"... and I also want to make sure that existing skills that do the function of text-eval get updated with audit, no questions asked."**

> **"yeah, keep in mind, we may be adding more "signs" to flag in the future, so everything will need to be forceably upgraded."**

*— Added 2026-06-12, source: user directive (issued with an attached audit transcript in which an all-coding-lane project received no evaluator — zero declared creative lanes meant the 2026-06-11 new-skill tier never fired, and the audit defended the non-build as correct; the user rejects that defense. First clause: audit installs the `text-eval` evaluator scaffold whenever nothing serving that function yet exists — the precondition is ABSENCE ALONE: the signal-based, never name-based existence test finds no skill performing the evaluator function AND no `text-eval` skill directory exists (mirroring the code-evaluator ensure-exists precedent, audit.md § Step 4a-bis). Lane declarations no longer gate the build; the scaffold's own `lane: creative` frontmatter is authored by the build, never inferred from any existing skill, and the project's Skill→Lane table is never touched. Supersedes newest-wins ONLY the "declared creative-lane evidence" precondition of the 2026-06-11 build clause's new-skill tier (and its inferred-only→DEFER row); every other hardening of that clause stands unchanged — strictly additive builds, demonstrably-absent panel confirmation for build-into-existing, equivalence-uncertain→DEFER, atomic-or-absent, name-collision guard, advisory-only voice gates absent a voice profile. Panel-adopted guards ratified with this directive: a project-level `<!-- creative-scrub-build: off -->` marker in references/model-lanes.md silently suppresses the new-skill build (declarative opt-out, never a question); lanes unconfigured → the scaffold's agent ships with `model:` absent and flagged, never an invented ID (Audit Agent Model-Assignment Gate clause 4). Second clause: skills qualify for updates by FUNCTION — the lane-free § Scope signals (evaluator, scrub, voice machinery) already implement this — and "no questions asked" means audit APPLIES the updates instead of deferring them: pattern-library gap appends into hand-authored libraries move from DEFER to AUTO, written only as ONE machine-owned `origin: skill-builder | modifiable: true` appendix region at the end of the library file — existing bytes never modified, structural fit verified before the write (no parseable fit → paste-ready DEFER row, the atomic-or-absent discipline), the `.scrub-gaps.acked` sidecar is the sole dedup authority (acked slugs never re-append even if equivalence misses a user-moved row), and the append fires only when the skill's evaluator demonstrably grounds against the full library file (else DEFER — the inert-sidecar lesson, DEC-2026-06-08). Immutable blocks stay FLAG-NEVER-TOUCH; equivalence-uncertain stays silently skipped. Third clause (same session): the shipped signs catalog will keep growing, and growth propagates FORCIBLY — whenever the shipped catalog version anchor (references/creative-integrity/version.md) is newer than what an installed evaluator or library was last checked against, audit MUST run the gap comparison and apply the AUTO appends in that same run (never skipped, never offered, never a question); scaffold-generated libraries' machine-owned regions are version-synced to the current catalog the same way code-eval sync refreshes its shipped references; the ack sidecar suppresses only slugs whose shipped entry is unchanged — new signs are never acked and always land. Design panels are agents, never user questions, per the 2026-02-22 agents directive. The build and tiering mechanics live in references/creative-integrity.md § Audit Policy / § Pattern-Library Gap Check and references/procedures/audit.md § Step 4c-bis and § Step 6, never inside this immutable block.)*
<!-- /origin -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY, in order to provide additional input in decision making." -->
CHECKPOINT — Non-Obvious Decision Gate:
1. Before committing to any classification, structural change, or content-removal decision that depends on interpretation, list the decision's alternatives in one sentence each.
2. IF exactly one alternative matches a concrete, measurable criterion (ID match, regex match, frontmatter field present/absent, file exists/absent) → CONTINUE without an agent.
3. IF two or more alternatives are plausible AND the selection requires judgment on wording, scope, priority, or fit → STOP. Spawn at least one agent via the Task tool (or an agent panel per the relevant procedure — e.g., optimize.md § 4b, § 5b) to supply independent input.
4. Read the agent findings. Where agents agree → proceed with the agreed alternative. Where agents disagree → default to the safer/conservative alternative.
5. IF an agent was required but skipped → STOP. Report to user: "Agent consultation skipped for a non-obvious decision. Respawn with agent input before proceeding."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "Each agent being created by this system always has to have an appropriate persona that is not being used anywhere else." -->
CHECKPOINT — Persona Assignment Gate:
1. Before writing or editing any AGENT.md file, extract the proposed persona string from the agent frontmatter.
2. Read references/agents-personas.md § "Persona assignment rules" to confirm the persona fits the agent's stated role (task, scope, perspective).
3. Glob ALL agent-file forms and read each file's persona field: `.claude/skills/*/agents/*.md` (flat-file agents like `agents/failure-triage.md`), `.claude/skills/*/agents/*/AGENT.md` (subdirectory-form agents like `agents/optimize-diff-auditor/AGENT.md`), AND `.claude/agents/*.md` (project-registered agents — dereference symlinks and dedupe by resolved target, since registration symlinks point back into the skill forms). Union the globs — agents may live in any form, and dropping one form silently drops uniqueness coverage for that slice of the population.
4. IF the proposed persona string matches any existing persona verbatim OR paraphrases one already in use (same core identity, different words) → STOP. Report: "Persona conflicts with [path]: '[existing persona]'. Choose a different persona."
5. IF no duplicate AND the persona fits the role (step 2 passed) → CONTINUE to write the AGENT.md.
6. There is no shipped backstop hook for this gate (skill-builder does not distribute pre-built hook scripts; cross-platform compatibility takes precedence). The CHECKPOINT above IS the enforcement — follow it literally during authorship. Users who want a deterministic backstop on their own systems can generate one via `/skill-builder hooks dev skill-builder --execute`, which builds an OS-appropriate hook locally without shipping it.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When deploying a Team, one of the team member's persona is a research assistant who will research the issue using read-only reference tools. Other team members may also make requests from the research assistant to help augment the outcome." -->
CHECKPOINT — Team Research Assistant Gate:
1. Detect team deployment: the procedure invokes TeamCreate, uses language like "Spawn teammates", or explicitly assembles multiple parallel agents under one task.
2. IF detected → read references/agents-teams.md § "Individual vs. team routing" for the allowed research-assistant tool list (read-only reference tools).
3. Enumerate the planned team members and their personas. IF none are labeled as the research assistant → STOP. Add a research-assistant team member with the read-only reference toolset from step 2 before spawning.
4. IF a research assistant is present → confirm its allowed-tools contains ONLY read-only reference tools. Strip any write or side-effect tools from the research assistant before spawn.
5. After spawn, surface to other team members: "Research assistant '[persona]' is available for read-only reference queries. Route lookups through the assistant rather than duplicating research."
6. IF a team is deployed without a research assistant (step 3 skipped) → STOP. Report: "Team deployment blocked — no research assistant in team composition."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When the dev flag gets called, you ALWAYS concentrate on the distribution files first, then sync changes to the .claude directory after." -->
CHECKPOINT — Source-First Ordering Gate (fires when `dev_mode == true`):
1. Maintainer mode detection: does `${CLAUDE_PROJECT_DIR}/skill-builder/SKILL.md` exist?
   - YES → maintainer mode active. Continue.
   - NO  → end-user mode. This CHECKPOINT is a no-op.
2. Track per-session state: which `skill-builder/<path>` files have been edited so far in this session? Maintain a mental ledger of source paths touched.
3. Before issuing ANY Edit/Write tool call on a file under `.claude/skills/skill-builder/<path>` or `skill-builder/<path>`:
   - IF the planned target is `skill-builder/<path>` → CONTINUE. This is the canonical first-pass edit.
   - IF the planned target is `.claude/skills/skill-builder/<path>`:
     - IF `skill-builder/<path>` has already been edited in this session → CONTINUE. This is the mirror phase.
     - IF `skill-builder/<path>` has NOT been edited in this session → STOP. REWRITE the target to `skill-builder/<path>` BEFORE issuing the call. Edit source first.
4. Reverse-order forbidden: never edit runtime first then "sync back to source." The runtime contains intentional runtime-only content (local hooks frontmatter, sidecars) that must NOT propagate to source.
5. End-of-session check: `git status --short -- skill-builder/`. Empty when changes were expected = FAIL. Report: "Source-first ordering violated. Edits landed in the runtime only. Reverse order and retry."
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "No hooks! We don't distribute hooks. The project only makes hooks on the host system." -->
<!-- Exception directive (2026-05-11, extended 2026-06-06): protect-directives.{sh,ps1} and unique-persona.{sh,ps1} DO ship in source. -->
CHECKPOINT — No-Distribute-Hooks Gate:
1. Define the EXCEPTION_HOOKS set: `{ protect-directives.sh, unique-persona.sh, protect-directives.ps1, unique-persona.ps1 }` (the two bash originals per the 2026-05-11 directive, plus their PowerShell companions per the 2026-06-06 extension). Every step below applies to all hooks EXCEPT those in this set; the exception steps (1b, 3b) cover the named hooks explicitly.
2. Before adding any hook script under `skill-builder/hooks/` whose basename is NOT in EXCEPTION_HOOKS → STOP. The source distribution MUST NOT contain hook scripts other than the named exceptions. Hooks live only in the runtime copy on the host system.
   - 2b. Exception path: adding any of the four EXCEPTION_HOOKS files under `skill-builder/hooks/` is PERMITTED and REQUIRED per the 2026-05-11 sacred directive and its 2026-06-06 PowerShell-companion extension. These ship in source.
3. Before adding a `hooks:` frontmatter block to source `skill-builder/SKILL.md` → STOP. Source SKILL.md MUST NOT declare hooks. The runtime SKILL.md may declare hooks the host has generated locally; source must not.
4. Before adding any hook-script entry to `manifest.txt` (the shared file list consumed by both `install` and `install.ps1`) or any fetch line to either installer script → check against EXCEPTION_HOOKS.
   - 4a. If the basename is in EXCEPTION_HOOKS → PERMITTED. The manifest is expected to list these four files (the `.sh` pair with the `hook` flag for the unix executable bit; the `.ps1` pair as plain entries). Confirm the destination resolves to `.claude/skills/skill-builder/hooks/` on the host.
   - 4b. If the basename is NOT in EXCEPTION_HOOKS → STOP. Adding the manifest entry or fetch line violates the directive.
5. Hooks ARE permitted in the runtime copy (`.claude/skills/skill-builder/hooks/`) and in runtime `SKILL.md` frontmatter, but only when generated on the host system via `/skill-builder hooks <skill> --execute` or maintained by hand by the host operator. The two EXCEPTION_HOOKS additionally arrive via the installers' manifest-driven fetch. Runtime hooks NOT in EXCEPTION_HOOKS never propagate back to the source distribution.
6. IF a workflow proposes shipping a hook NOT in EXCEPTION_HOOKS via the installers, adding non-exception hook scripts to `skill-builder/`, or declaring hooks in source frontmatter → REFUSE and report: "No-distribute-hooks directive violated. Hooks are made on the host system only — only protect-directives.{sh,ps1} and unique-persona.{sh,ps1} are permitted in source per the 2026-05-11 exception and its 2026-06-06 extension."
<!-- END ENFORCEMENT ANNOTATION -->

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
<!-- Source directive: "It shouldn't make any decisions based on performance, but the full completion of integrity of skills expected to be performed by the user. Don't make decisions based on 'shortcut' mentality." -->
CHECKPOINT — Integrity-Over-Performance Gate (governs the `reconcile` command; see reconcile.md):
1. This gate fires for every `reconcile` finding and for any cross-skill remediation decision.
2. **Redundancy alone is NEVER a reason to act.** Before reporting or fixing anything, confirm the overlap demonstrably threatens a skill's *full completion* (selection-shadowing, dispatch-bypass, suppression cascade, mutation race, or a hard name/embed collision). IF it does not → DROP it silently. It is not a finding.
3. **No performance/tidiness justification.** IF the only rationale for a removal or modification is speed, token savings, deduplication, or "cleaner" — STOP. That is the shortcut mentality this directive forbids. Do not act.
4. **No shortcut on judgment.** A non-obvious conflict call requires the agent panel (per the Non-Obvious Decision Gate). Skipping the panel to reach a faster verdict is forbidden. Agents disagree → keep both, flag for the human.
5. **Directive blocks are untouchable.** Any remediation whose edit span intersects an `<!-- origin: user | immutable: true -->` block downgrades to FLAG-ONLY, overriding its class default. Never reword, reorder, or delete to "resolve" a directive conflict.
6. **Deletion is delegated, never reimplemented.** A confirmed redundant skill routes through `/skill-builder strip` (with its BREAKING detection and `--confirm-breaking` gate) — `reconcile` never deletes.
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
<!-- Source directive: "Why option 3 is important, and this should be a directive moving forward, … We're doing this to actually preserve the workflow and make the main model most effective at its task." -->
CHECKPOINT — Bespoke Excursion-Agent Gate (fires whenever a lane-pinned excursion agent is designed or its delegation entry is woven into a skill — agents.md § Step 4d, and audit's legacy-revamp path):
1. Read the FULL target skill before designing: SKILL.md, the complete workflow, existing managed-block embeds, and every routing point to other skills. The agent is designed per skill from this reviewed material — never instantiated generically from the template alone.
2. Delegation replaces ONLY the EXECUTOR of the excursion step. Workflow order, step inputs/outputs, CHECKPOINT gates, and routing points to other skills stay exactly as written — the workflow body itself is never edited; delegation entries live in the skill's single LANE-AGENT-EMBED map block (references/lane-delegation.md § Delegation Map). IF a proposed delegation would reorder, merge, reword, or drop any step or routing point → STOP. Redesign.
3. Token efficiency is NOT a valid rationale anywhere in this flow. IF the only justification for a delegation, merge, or simplification is token/cost/speed savings → STOP. Do not act.
4. Each agent is highly focused: one excursion direction per skill (split only when the design panel finds contracts genuinely differ), a minimal excursion-appropriate `tools:` list (never Task/Skill/Edit), the OTHER lane's full model ID in `model:` frontmatter, and a unique persona (the Persona Assignment Gate applies in full).
5. IF excursion-point identification is ambiguous (which steps are other-lane work, per the NON-DELEGABLE list in references/lane-delegation.md) → spawn the agent panel per the Non-Obvious Decision Gate. Panel disagreement → NO-DELEGATE; the step runs in the main session as written. Never guess a delegation.
6. Delegation never substitutes for the primary-lane gate: a skill whose PRIMARY lane mismatches the active model still surfaces the mismatch as a one-line report advisory (route.md § Step 8 — never a prompt, per the 2026-06-06 No-Switch-Prompt Gate). In particular, coding/analysis primary work runs on the coding main model — never a creative main session orchestrating coding-pinned agents.
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
<!-- Source directive: "The system is a 2-brain harness that balances between creativity and analytics: … hand-run skills stay lane-aware through their own slim gates, which go silent when route already covered the endeavor." -->
CHECKPOINT — Two-Brain Harness Gate (governs audit onboarding, /route dispatch, and every per-skill model gate):
1. Audit onboarding asks ONE batched question (audit.md § 4f-setup): the user picks the creative brain and the analytical (everything-else) brain. These two picks are the ONLY model IDs the system ever stamps into gates or minions; everything downstream re-stamps from them.
2. /route is the PREFERRED door, never the only one. At dispatch: resolve ask → skill:function → lane from DECLARED provenance only (frontmatter → Skill→Lane table; the index is a derived cache — never lane-advise on UNCONFIRMED provenance, never write lane authority into auto-generated files) → compare the active model ID (session system-context line, stateless) → at the route door, at most ONE lane interaction per endeavor: an ASK when the dominant hemisphere ≠ the active model (route-ask directive, 2026-06-07; route still cannot switch the model itself, only the human `/model` command can), otherwise a silent match; a tie/UNCONFIRMED lane resolves to the analytical brain and never asks → dispatch with endeavor coverage recorded (route having assessed the lane this turn is the coverage signal, whether it asked or matched).
3. Hand-running a skill directly is ALWAYS permitted — never treat direct invocation as a bypass to close. The skill's own slim gate keeps the run lane-aware.
4. Per-skill gates are SLIMMED, never stripped. Every lane-declared skill carries the slim gate (resolve lane → compare → advise once → silent no-op when /route already covered this endeavor; headless suppressed; `model-lane-gate: off` honored). The gate's output is a one-line advisory that names the remedy informationally per the 2026-06-11 named-command advisory directive ("to align, run `/model <preferred>` and re-invoke; proceeding as-is") — never an AskUserQuestion, never a blocking wait, never a switch performed by the skill (the per-skill gate stays advisory-only; the 2026-06-07 route-ask carve-out applies to the /route door ONLY). IF any change proposes removing a skill's gate without the route-coverage no-op already in place → STOP. Invariant: ≥1 checkpoint on every entry path; ≤1 lane interaction per endeavor (one ASK at the /route door, or one advisory on a hand-run path); 0 switch prompts on every NON-route surface (audit Step 4f, per-skill gates). /route is the one sanctioned door that may ask, and it still cannot switch the model itself.
5. IF a proposed design routes around this gate's invariant (e.g., "mandatory routing" wording that closes the hand-run path, or lane data homed in an overwritten file) → STOP and report the directive conflict.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When the user asks to create skills, route looks for a similar skill and modifies that or builds a new one — and the skill creation decision is part of the skill-builder skill. … high-risk commands prompt for it, low-risk additions run wherever the session is." -->
CHECKPOINT — Skill-Creation Ownership Gate (fires on /route's no-match path and any route→skill-builder dispatch):
1. Route NEVER decides modify-vs-create. On no catalog match it offers exactly: modify the closest-match skill / build a new skill / cancel (AskUserQuestion), then hands the verbatim freeform ask to skill-builder's intent-router (references/procedures/intent-router.md), which owns the classification. Route never invents a skill name and never invents a function.
2. Claude proposes with maximum creative leeway; the USER ratifies via AskUserQuestion before any skill is created or modified. No ratification → no write.
3. Route NEVER synthesizes the `dev` prefix. A route-dispatched ask targeting skill-builder itself surfaces the Self-Exclusion refusal verbatim. Direct `/skill-builder` invocation is the always-legal maintenance hatch — recovery never runs through the door.
4. Risk tiering before dispatching skill-builder work: high-risk commands (optimize, audit --execute, route embed, strip, convert, reconcile --execute) → emit a one-line analytical-brain advisory when the active model is not the analytical brain (never a prompt, never a `/model` request — the "high-risk commands prompt for it" mechanic is superseded newest-wins by the 2026-06-06 No-Switch-Prompt directive, user-ratified; the risk-tier CLASSIFICATION itself stands). Low-risk additive commands (inline, new, skills, list, verify, checksums) → run on the current model with a one-line advisory.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "The orchestrator has an army of minions, bounded to a platoon: delegation is justified only by model-fit (cross-lane work) or context isolation (unbiased evaluation), never by token efficiency or speed. … A minion that discovers ambiguity returns the question to the orchestrator — it never guesses." -->
CHECKPOINT — Platoon Gate (fires before any minion spawn and during fleet design in agents.md § Step 4d):
1. Name the delegation rationale before spawning. The vocabulary is exhaustive: (a) MODEL-FIT — the step's lane differs from the executing session's lane; (b) CONTEXT ISOLATION — unbiased evaluation requires a fresh context (the text-eval/image-eval pattern). There is NO third rationale. Token efficiency and speed remain forbidden justifications everywhere.
2. IF a proposed delegation is same-lane AND has no isolation rationale → STOP. The step runs in the main session as written (the NON-DELEGABLE list in references/lane-delegation.md is the floor; this clause is the ceiling).
3. Every minion's `model:` frontmatter carries one of the two ratified brain IDs from the Lane→Model table. Never invent an ID; lanes unconfigured or cell blank → leave `model:` absent and flag (Audit Agent Model-Assignment Gate applies in full).
4. A minion with all REQUIRES present but multiple valid interpretations returns `AMBIGUOUS: <question>` — the orchestrator owns the resolution. Under `audit` (Audit Autonomy Gate): agent panel → conservative alternative or DEFER to the report — never a mid-run user question. Outside audit, AskUserQuestion remains available per Rule 8. A minion NEVER guesses, and `INCOMPLETE:` still covers missing inputs.
5. Minion spawns within a workflow are sequential in step order; concurrent same-file minions are forbidden until a concurrency model exists.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "No user should ever be asked this question. No model switching should be requested during the audit process or any function of skill-builder. However, I would like to mention that there be a disclaimer that must be accepted by the user before proceeding with audit. …" -->
CHECKPOINT — No-Switch-Prompt Gate (fires on EVERY skill-builder command, embed template, and generated block):
1. Before emitting any AskUserQuestion or end-of-turn question, test: does it ask, instruct, or invite the user to run `/model` or otherwise change the session model? IF YES → FORBIDDEN. Do not emit it. Replace with a one-line report advisory, e.g. "Lane advisory: `<skill>` declares the `<lane>` lane (preferred `<preferred>`); session is on `<active>`." Then proceed without blocking. (Per the 2026-06-11 named-command advisory directive, the per-skill MODEL-LANE-GATE's advisory line additionally NAMES the remedy — "to align, run `/model <preferred>` and re-invoke; proceeding as-is" — naming the command informationally in that one advisory line is not a switch request and stays non-blocking.) EXCEPTION (2026-06-07 route-ask directive, newest-wins): `/route`'s dispatch-time lane preflight (route.md § Canonical Dispatch CHECKPOINT clause 2) MAY ask the user to switch the session model — at most one ask per endeavor, at the /route door ONLY, and route still cannot switch the model itself. Every OTHER surface (audit Step 4f, the per-skill MODEL-LANE-GATE, the high-risk skill-builder advisory, all embed templates) stays report-only per this clause.
2. This supersedes (newest-wins, user-ratified 2026-06-06) the prompting mechanics of three earlier directives: "with prompting, or not" → permanently "or not"; "at most one prompt per endeavor" → zero switch prompts (at most one advisory line per endeavor); "high-risk commands prompt for it" → a one-line analytical-brain advisory, no prompt. The earlier directives' texts above remain verbatim and untouched. (The route-dispatch sub-clause of THIS supersession is itself re-superseded newest-wins by the 2026-06-07 route-ask directive: at the /route door, "at most one prompt per endeavor" is restored as at most one ASK per endeavor — route only. Audit Step 4f and the per-skill gates remain at zero switch prompts.)
3. Configuration questions are NOT switch requests and stay: the audit onboarding question (audit.md § 4f-setup) and the every-audit Lane→Model picker (lane-delegation.md § Lane→Model Picker) ask which model maps to which lane — they never ask the user to switch. The lane system, mismatch REPORTING, lane-pinned agent `model:` stamping, and excursion delegation are all unchanged.
4. IF any procedure text, embed template, or generated block is found to still request a model switch (grep: `/model`, "switch", AskUserQuestion options like "switched") → that text is stale; fix the template and reconcile via `route embed` rather than honoring it at runtime. EXCEPT `/route`'s § Canonical Dispatch CHECKPOINT clause 2, whose `/model` ask is INTENTIONAL per the 2026-06-07 route-ask directive — it is not stale and must NOT be removed. ALSO EXCEPT the per-skill MODEL-LANE-GATE advisory template (route.md § Step 8c clause 4) and its embedded copies, whose informational "run `/model <preferred>` and re-invoke" naming is INTENTIONAL per the 2026-06-11 named-command advisory directive — informational naming in a non-blocking advisory is not a switch request.
5. A flag whose only purpose is to force a switch prompt (`--model-prompt`) is retired; `--no-model-prompt` is accepted as a harmless no-op for backward compatibility.

CHECKPOINT — Audit Disclaimer Gate (fires at the START of every `audit` run, including `audit --quick` and bare `/skill-builder`, BEFORE any scan, sub-command, or write):
1. INTERACTIVE session → present the disclaimer via AskUserQuestion and STOP until answered:
   > **Disclaimer — acceptance required before the audit proceeds:**
   > - skill-builder is designed to be used with Opus 4.7 or higher model.
   > - However, skills created with skill-builder are backwards compatible with earlier models.
   > - Please backup your CLAUDE.md and .claude directory before proceeding.
   > - Accepting runs the audit and automatically applies its recommended fixes; deferred items are listed for manual follow-up.
   Options EXACTLY: **Accept and proceed** / **Cancel audit**. On Cancel → STOP the audit entirely; report nothing was scanned or written.
2. On Accept → write/refresh the `<!-- audit-disclaimer: accepted -->` marker in `references/model-lanes.md` (next to the `model-lane-setup` marker; same update-preserved, per-project mechanism), then proceed with the audit. Acceptance is the run's consent: it authorizes the scan AND the auto-execution phase (Audit Autonomy Gate clause 2).
3. HEADLESS / non-interactive run → IF the `audit-disclaimer: accepted` marker exists → print the disclaimer text into the report and proceed with the SCAN ONLY — a marker never authorizes writes; the full fix plan lands in the report as would-be tasks (auto-execution requires a live interactive acceptance this run). IF NO marker → print the disclaimer and REFUSE: "Audit disclaimer not yet accepted — run one interactive audit first." Acceptance cannot be assumed or auto-granted.
4. This gate asks about the disclaimer ONLY — it never mentions models beyond the verbatim disclaimer text and never asks the user to switch anything. The first three bullets are the sacred minimum content, verbatim; the fourth is machinery disclosure for informed consent.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "likewise, I would like to prevent questions like this from happening, too. … The audit command should be as automated and streamlined as possible. There shouldn't be any hard questions like this for the user." + "I don't mind the two questions for choosing the creative model and analytical model. that needs asked every time audit is ran, regardless. Just limit any additional questions. Always do the work, instead of suggestion to skip work that will improve the system." -->
CHECKPOINT — Audit Autonomy Gate (governs every `audit` run, full and `--quick`, from Step 0 through completion):
1. THREE QUESTIONS ONLY. An audit run may ask the user exactly: (a) the Step 0 disclaimer (Accept and proceed / Cancel audit), (b) the one-time 4f-setup lane onboarding, and (c) the Lane→Model picker — asked EVERY audit run, regardless, per the user's verbatim instruction. NO other AskUserQuestion, y/n offer, execution menu, or end-of-turn decision question may be emitted anywhere in the audit path, including bootstrap mode, quick mode, chained sub-commands, and the post-action chain when its parent is audit.
2. DISCLAIMER = CONSENT. Step 0 acceptance authorizes the whole run: scan → report (including the Execution Plan block) → auto-execute the AUTO-tier task list via TaskCreate, sequentially, under Display/Execute rules 4 and 5 (the printed task list is the contract; never add unplanned work mid-run).
3. ALWAYS DO THE WORK. Work that improves the system is EXECUTED, never offered as skippable: mechanical fixes (descriptions reflowed without ever truncating or shortening — they are documentation), optimize/agents/hooks fixes, code-eval create/sync, Awareness Ledger creation, bootstrap CLAUDE.md extraction of HIGH-confidence candidates, reconcile's two mechanical auto-fixes, orphan minion retirement (marker-verified), and the terminal route index + route embed.
4. DEFER tier — the ONLY legitimate deferrals, each reported as a Deferred Items row (item | why | exact command), never silently dropped: strip deletions (consent lives in strip's own gates); convert/2-Brain migration (its inline sacred ratification gates cannot fire in a no-questions run); quarantine repairs of hand-authored files; protective or unrecoverable dead-wiring decisions; AMBIGUOUS bootstrap extraction candidates; and git-dependent fixes (optimize auto-revert, orphan deletion) when the project has no VCS safety net.
5. AMBIGUITY mid-run: agent panels fire exactly as procedures demand (the agent budget's display-mode suppression does not apply to the auto-execution phase). Panels agree → proceed; disagree → conservative alternative; a minion's `AMBIGUOUS:` return under audit resolves conservatively or DEFERS — never a mid-run user question, never a guess.
6. CONTAINMENT: Step 0.5 VCS preflight (clean → full AUTO; dirty → proceed with a one-line warning; no VCS → downgrade git-dependent items to DEFER). Per-task failure → mark ✗, continue independent tasks, skip dependents, surface in the Execution Summary. HEADLESS runs are scan+report-only — the acceptance marker unlocks the scan, NEVER writes; auto-execution requires a live Step 0 acceptance this run.
7. ESCAPE HATCH: `audit --review` (alias `--dry-run`) = full scan + report + would-be Execution Plan, zero writes, zero execution. `audit --execute` is accepted as a harmless no-op (execution is now the default).
8. The terminal report (Execution Summary + Deferred Items) is informational prose — it never ends with a question (Rule 8's over-fire guard applies: it is not a decision handoff).
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "When you give route a task, it reads the whole course of action it's been handed and picks the dominant hemisphere for the job … This restores route's dispatch-time ask, superseding (newest-wins) only the route clause of the 2026-06-06 No-Switch-Prompt directive; audit and the per-skill gates stay report-only." -->
CHECKPOINT — Route Dominant-Hemisphere Ask Gate (fires ONLY at /route dispatch; route-door only):
1. SCOPE. This gate governs `/route` dispatch ONLY. It does NOT change hand-run skill invocation (the per-skill MODEL-LANE-GATE stays advisory-only), audit Step 4f (report-only), or any embed template. It supersedes newest-wins ONLY the route-dispatch-prompt clause of the 2026-06-06 No-Switch-Prompt directive.
2. DOMINANT HEMISPHERE = the lane the main-loop job mostly lives in: the matched target skill's PRIMARY lane (DECLARED provenance only — frontmatter → Skill→Lane table; a per-function row for the resolved mode wins). Route dispatches one skill at a time and CANNOT enumerate a multi-skill chain at the door — it never guesses a plan-wide majority; it reads the entry skill's primary lane, or, on the no-match freeform path, lane-classifies the task per model-lanes.md § Advisory Lane Suggestion.
3. TIE / UNCONFIRMED / ABSENT lane → resolve to the analytical (everything-else) brain and DO NOT ask. Research signals always resolve analytical (research precedence). An ask fires ONLY on a clear dominant-hemisphere mismatch.
4. THE ASK. When the dominant hemisphere's preferred model ≠ the active model, route prints ONE blocking lane-check naming `/model <preferred>` and waits for the user (route.md § Canonical Dispatch CHECKPOINT clause 2). Route can NEVER switch the model itself — only the human `/model` command can. At most ONE ask per endeavor, at the route door. The user may switch then continue, or continue as-is.
5. COVERAGE = assessment performed, not advisory printed. Route having assessed the lane this turn (whether it asked, matched silently, or — on non-route surfaces — advised) IS the endeavor-coverage signal: the dispatched skill's per-skill gate and every skill it chains stay silent (route.md § Step 8c clause 1). This holds whether the user switched, declined, or proceeded as-is.
6. THE REST ON THE AGENTS. Off-hemisphere steps inside the dispatched workflow are delegated to lane-pinned excursion agents (Platoon Gate rationale (a) MODEL-FIT), never re-asked mid-workflow. Route picks the dominant-lane model for the main session; minority-lane steps run on pinned subagents.
7. HEADLESS / non-interactive → skip the ask and dispatch (the door cannot block where there is no user).
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "Hand-run skills stay non-blocking on a lane mismatch, but the advisory must name the exact remedy: state the preferred model and the literal command — run `/model <preferred>` and re-invoke — then proceed as-is. Never a question, never blocking, and the skill still can never switch the model itself." -->
CHECKPOINT — Named-Command Advisory Gate (fires wherever the per-skill MODEL-LANE-GATE advisory line is emitted, and wherever its template text is written or refreshed):
1. The hand-run lane advisory remains exactly ONE line and NEVER blocks, NEVER emits an AskUserQuestion, and NEVER switches the model. This directive amends wording only — the 2026-06-07 hand-run advisory-only rule stands.
2. The advisory line MUST name the exact remedy: "Lane advisory: this skill declares the `<lane>` lane (preferred `<preferred>`); the active model is `<active>` — to align, run `/model <preferred>` and re-invoke; proceeding as-is." `<preferred>` resolves from the Lane→Model table in references/model-lanes.md. An emitted or embedded advisory that omits the command is STALE (pre-2026-06-11 template) → refresh via `route embed`.
3. Naming `/model` in this advisory is INFORMATIONAL, not a switch request: the No-Switch-Prompt Gate's stale-text grep (its clause 4) must NOT flag the Step 8c clause-4 template or its embedded copies. A question, a blocking wait, or an option menu built on this line remains FORBIDDEN.
4. Scope: the per-skill MODEL-LANE-GATE advisory line ONLY. Audit Step 4f report advisories, the high-risk analytical-brain advisory, and route's door ask keep their own ratified formats unchanged.
5. IF any surface converts this named-command advisory into a question, a blocking wait, or an automatic switch → STOP. Report the directive conflict instead of emitting it.
<!-- END ENFORCEMENT ANNOTATION -->

<!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
<!-- Source directive: "build that scrub loop for text and images.. and make sure we do research around these topics an explicitely update, through audit, these mechanisms for any skill that manages this type of workflow" + "But, i'd like item #2 to build new skills or funciton within existing skills of the project to facilitate all these points?" (+ the nine scrub principles, verbatim in references/creative-integrity.md) -->
<!-- Amending directive (2026-06-12, install-on-absence): "Okay, we have a problem with the text-eval not being installed if nothing yet exists..." + "... and I also want to make sure that existing skills that do the function of text-eval get updated with audit, no questions asked." -->
CHECKPOINT — Creative-Integrity Gate (fires during audit Step 4c-bis, and whenever any skill-builder command creates or modifies a skill that manages a detect/evaluate/revise creative workflow):
1. Identify qualifying skills per references/creative-integrity.md § Scope (creative lane + evaluator/scrub/voice machinery). IF the classification is not overtly obvious → apply the Non-Obvious Decision Gate (agent input) before classifying.
2. Check each qualifying skill against the Nine Scrub Principles via the Compliance Checklist (creative-integrity.md § Compliance Checklist) — **by equivalence**: a principle satisfied in the skill's own wording, including inside its own immutable blocks, is SATISFIED; a criterion outside the skill's role is N/A, never a gap.
3. BUILD tier (2026-06-11 second clause — audit builds the missing machinery, additively):
   - **Build-into-existing (AUTO):** when a qualifying skill's loop leg is DEMONSTRABLY ABSENT — a true absence confirmed by a panel that read the FULL skill, never a mere equivalence-negative — build it: a new scrub-chain reference file adapted per skill from the § Build Scaffolds templates, plus ONE dedicated machine-owned `CREATIVE-SCRUB-EMBED` pointer region (grounding link only — never gating logic spliced into the workflow body). Equivalence-UNCERTAIN → DEFER, never a competing chain.
   - **New-skill scaffold (AUTO on absence — 2026-06-12 install-on-absence directive, superseding newest-wins the declared-evidence precondition):** when NO skill in the project performs the evaluator function (existence test signal-based, never name-based, per § Build Scaffolds pre-build guards) AND no `text-eval` skill directory exists AND `model-lanes.md` carries no `<!-- creative-scrub-build: off -->` marker → scaffold the evaluator from § Build Scaffolds (persona + model gates apply in full; lanes unconfigured → `model:` absent + flagged, never an invented ID). Lane declarations do not gate the build — the precondition is absence alone; the scaffold authors its own `lane: creative` frontmatter and never touches the project's Skill→Lane table.
   - **Pattern-library gap appends (AUTO — 2026-06-12 second clause):** demonstrably absent mechanisms from the shipped catalog are APPLIED, never deferred: appended into the machine-owned region of scaffold-generated libraries, or — for hand-authored libraries — into ONE machine-owned `origin: skill-builder | modifiable: true` appendix region at the end of the library file. Existing bytes never modified; structural fit verified before the write (no parseable fit → paste-ready DEFER row); `.scrub-gaps.acked` is the sole dedup authority; the append fires only when the skill's evaluator grounds against the full library file (else DEFER — inert-sidecar lesson). Equivalence-uncertain stays silently skipped. **Forced upgrade on catalog growth (2026-06-12 third clause):** a shipped version anchor newer than what a library was last checked against → the gap comparison RUNS and its AUTO appends APPLY in that same audit (never skipped, never offered); scaffold-generated libraries' machine-owned regions version-sync to the current catalog; the ack sidecar suppresses only slugs whose shipped entry is unchanged — new signs always land.
   - **Atomic-or-absent:** a build that cannot complete its panel/anchor checks writes NOTHING and becomes a DEFER row. Reconciliation on later audits touches only `modifiable: true` machine bytes (code-eval-grade user seam); `creative-scrub: off` frontmatter opts a skill out entirely, and the project-level `<!-- creative-scrub-build: off -->` marker in `model-lanes.md` suppresses the new-skill scaffold.
4. HARD FLOORS unchanged by the build tier: a build never rewords, reorders, or deletes hand-authored text; any finding whose remediation would intersect an `<!-- origin: user | immutable: true -->` block is FLAG-NEVER-TOUCH (quoted verbatim). Voice-dependent gates in BUILT scaffolds (humanity floor) are advisory-only when the project has no documented voice profile — never blocking on non-English or technical content.
5. Scrub-loop non-negotiables (creative-integrity.md § Canonical Scrub-Loop Spec, ◆ items): entry provenance guard; auto-fix limited to MUST FIX + hard-directive flags; atomic fix pass + whole-document echo re-scan; cycle cap 2; best-so-far + divergence abort; humanity floor (text); fixability classifier + palette lock (image); evaluator never triggers regeneration; never optimize toward a detector score. A qualifying skill's loop missing a ◆ item → BUILD it when eligible per step 3, else FLAG with the exact missing safeguard named.
6. Research precedence: research that grows pattern libraries or loop parameters runs on the coding model (2026-06-06 research-precedence directive) before handoff to creative drafting.
<!-- END ENFORCEMENT ANNOTATION -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Phase 0: Dev Path Discipline (BLOCKING — maintainer mode)

**When `dev_mode == true` AND `${CLAUDE_PROJECT_DIR}/skill-builder/SKILL.md` exists (this repo IS the skill-builder source distribution), every Edit/Write on a skill-builder file MUST target the source path under `skill-builder/...` BEFORE any mirror to the runtime copy at `.claude/skills/skill-builder/...`.**

The runtime is gitignored. It gets overwritten on every `bash install`. Runtime-only edits never reach end users.

**Mandatory order — non-negotiable:**

1. **Edit `skill-builder/<path>` first** (the source distribution under repo root).
2. **Then mirror the same change to `.claude/skills/skill-builder/<path>`** so the running session matches source. The mirror is a content sync, not a wholesale overwrite. Preserve runtime-only content the source intentionally lacks: local hooks frontmatter, `.directives.sha` sidecars, generated artifacts.
3. **Never reverse the order.** Runtime contains intentional runtime-only content that must NOT propagate to source.

**Hooks-in-source exception:** Four skill-builder hooks ship in the source distribution — `protect-directives.sh` and `unique-persona.sh` per the 2026-05-11 sacred directive, plus their PowerShell companions `protect-directives.ps1` and `unique-persona.ps1` per the 2026-06-06 extension. When `dev` mode targets any of these files, the canonical source path is `skill-builder/hooks/<name>` — edit there first, then mirror to `.claude/skills/skill-builder/hooks/<name>`. Every other hook file remains runtime-only and follows the original no-distribute rule.

**CHECKPOINT — fires before any skill-builder Read/Edit/Write when `dev` is in the invocation:**

1. Maintainer mode: does `${CLAUDE_PROJECT_DIR}/skill-builder/SKILL.md` exist?
   - YES → maintainer mode active. Continue.
   - NO  → end-user mode. This CHECKPOINT is a no-op. Proceed to dispatch.
2. For every planned Edit/Write whose path starts with `.claude/skills/skill-builder/`:
   - REWRITE the path BEFORE issuing the tool call: replace `.claude/skills/skill-builder/` with `skill-builder/`. The source path is the canonical first-pass edit target.
   - IF the source file does not exist while the runtime file does → STOP. Report: "Runtime is ahead of source for [path]. Determine canonical state before editing." Do not auto-mirror.
   - Hook path exception: paths matching `.claude/skills/skill-builder/hooks/<name>` where `<name>` is one of `protect-directives.sh`, `unique-persona.sh`, `protect-directives.ps1`, `unique-persona.ps1` rewrite to `skill-builder/hooks/<name>` (these four ship in source per the 2026-05-11 directive and its 2026-06-06 extension). Any OTHER `.claude/skills/skill-builder/hooks/*` path stays runtime-only — do NOT rewrite to source for those.
3. For Reads on skill-builder content: prefer `skill-builder/<path>` so planning grounds on canonical source. Reads from runtime are allowed but second choice — the runtime may be stale.
4. After all source edits land, perform the runtime mirror as a separate, explicit phase. For each `skill-builder/<path>` modified in this session, replicate the same change to `.claude/skills/skill-builder/<path>`. Touch only the changed sections; do not overwrite runtime-only frontmatter, hook scripts, or sidecars.
5. End-of-session check: `git status --short -- skill-builder/`. Empty output when changes were expected = FAIL. The edits landed in the runtime only. Reverse order and retry from step 2.

**No hook backstop for this gate.** Per the user directive "No hooks! We don't distribute hooks. The project only makes hooks on the host system" (see § Directives), there is no shipped hook for Phase 0 enforcement. The CHECKPOINT above IS the enforcement and must run during authorship. A maintainer who wants a local mechanical backstop on their own host can generate one via `/skill-builder hooks dev skill-builder --execute`, but that is a host-system action and is never part of the source distribution.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Commands

All commands operate in display mode by default. Add `--execute` to apply changes.
Before executing any command, read its procedure file from `references/procedures/`.

| Command | Procedure | Summary |
|---------|-----------|---------|
| `audit` | [audit.md](references/procedures/audit.md) | Full system audit |
| `audit --quick` | [audit.md](references/procedures/audit.md) | Lightweight: frontmatter + line counts |
| `cascade [skill]` | [cascade.md](references/procedures/cascade.md) | Validation cascade analysis (diagnostic only) |
| `reconcile [skill]` | [reconcile.md](references/procedures/reconcile.md) | Cross-skill conflict detection + integrity-preserving remediation |
| `convert [skill]` | [convert.md](references/procedures/convert.md) | Convert 4.6-era skill to 4.7-compatible (annotations + explicit steps) |
| `optimize [skill]` | [optimize.md](references/procedures/optimize.md) | Restructure for context efficiency |
| `optimize claude.md` | [claude-md.md](references/procedures/claude-md.md) | Extract domain content to skills |
| `agents [skill]` | [agents.md](references/procedures/agents.md) | Analyze/create agents |
| `hooks [skill]` | [hooks.md](references/procedures/hooks.md) | Inventory/create hooks |
| `new [name]` | [new.md](references/procedures/new.md) | Create skill from template |
| `strip [skill]` | [strip.md](references/procedures/strip.md) | Delete a skill and remove all cross-references |
| `inline [skill] [directive]` | [inline.md](references/procedures/inline.md) | Quick-add directive |
| `skills` | [skills.md](references/procedures/skills.md) | List local skills |
| `list [skill]` | [list.md](references/procedures/list.md) | Show modes/options |
| `verify` | [verify.md](references/procedures/verify.md) | Health check (headless-compatible) |
| `ledger` | [ledger.md](references/procedures/ledger.md) | Create Awareness Ledger |
| `checksums [skill]` | [checksums.md](references/procedures/checksums.md) | Generate/verify directive checksums |
| `shell-safety [mode] [path]` | [shell-safety.md](references/procedures/shell-safety.md) | Write / audit / lint shell code and JSON-embedded shell for pitfalls |
| `route [mode]` | [route.md](references/procedures/route.md) | Maintain `/route` skill index and embed route-consultation hooks into other skills |
| `code-eval [mode]` | [code-eval.md](references/procedures/code-eval.md) | Scaffold/maintain the `code-evaluator` skill (create / review / sweep / sync) |
| `model-map` | [model-map.md](references/procedures/model-map.md) | Choose the creative + coding/everything-else model (Lane→Model picker + fleet rewrite), no audit |
| `local-mode [--execute]` | [local-mode.md](references/procedures/local-mode.md) | Audit project for local LLM compatibility (classify skills, trim, install local infrastructure) |
| `update` | *(inline below)* | Update to latest version |
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `update` Command

Re-run the installer to update skill-builder to the latest version.

The installer issues many file writes and bash calls in sequence. Without auto-accept, the user will be prompted to approve each one. Claude Code does NOT expose a way for a skill to flip the session into "accept edits on" mode programmatically, nor to detect the current permission mode at runtime — mode changes require the user to press Shift+Tab. The procedure below therefore prompts the user to enable auto-accept before the installer runs.

**CHECKPOINT — fires when `/skill-builder update` is invoked:**

1. **BEFORE running the installer**, output this notice to the user verbatim and STOP for their acknowledgement:

   > **Before I run the installer, please enable "accept edits on" mode so you don't get prompted for every file write and bash call.**
   >
   > Press **Shift+Tab** until the prompt indicator shows **"accept edits on"** (it cycles: default → accept edits on → plan mode).
   >
   > I cannot detect or set this mode from inside the session — it has to be you. Reply with anything (e.g., "go") once it's enabled and I'll run the installer.

2. After the user acknowledges, select the installer by platform. Read the `Platform:` line from the session environment context (a concrete read, no judgment, no agent):
   - IF platform is `linux` or `darwin` (macOS) → run via the shell tool: `bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"`
   - IF platform is `windows`/`win32` → run via the shell tool: `powershell -NoProfile -Command "irm https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install.ps1 | iex"` (this works whether the session's shell tool is Git Bash or PowerShell, so no shell detection is needed)
   - IF the platform line is absent or unrecognized → ask the user which OS they are on before running anything.
   Both installers consume the same shared `manifest.txt`, so they ship identical content.
3. Tell the user: **"Restart Claude Code to load the updated skill."** The current session still has the old skill loaded in memory, so start a new conversation. Once you're back, run `/skill-builder audit` — updates often add new recommendations that apply to your existing skills.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `convert` Command

Convert existing Opus 4.6-era skills to Opus 4.7-compatible execution. User directives stay verbatim and receive enforcement annotations (machine-generated CHECKPOINT blocks beneath the sacred block); skill-builder machinery (workflow steps, grounding statements) is rewritten in-place for literal execution.

- Display mode (default): `/skill-builder convert [skill]` — report what would change
- Execute mode: `/skill-builder convert [skill] --execute` — apply changes
- Batch display: `/skill-builder convert --all` — summary across all skills
- Batch execute: `/skill-builder convert --all --execute` — convert every skill in sequence (one task per skill; the task list survives context compaction)

High-risk command — defaults to display mode, requires `--execute` to modify files.

**Grounding:** Read [references/procedures/convert.md](references/procedures/convert.md) for the full procedure, [references/templates.md](references/templates.md) § "Enforcement Annotation Template" for the annotation format, and [references/enforcement.md](references/enforcement.md) § "Opus 4.7 Behavioral Contract" for the literal-execution model.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `route` Command

Maintain the `/route` skill — a glorified, auto-generated index of every installed skill — and embed route-consultation hooks into other skills so the AI dispatches through registered skills instead of freelancing. `/route` is a peer to `intent-router`, not a replacement: `intent-router` handles freeform `/skill-builder <text>` invocations within skill-builder; `/route` handles user-level task routing across every installed skill.

- `/skill-builder route index` — scan all skills, regenerate `/route`'s catalog (including each skill's DECLARED lane with provenance — the index is a derived cache, never lane authority). Bootstraps `/route` if missing. Diffs against the prior index and reports NEW / REMOVED / UPDATED / UNCHANGED. Default mode is execute (low-risk; only writes auto-generated content inside `/route`).
- `/skill-builder route index --dry-run` — display-only summary of what would change.
- `/skill-builder route lane-status [skill]` — read-only legibility report: resolved lane → provenance → preferred vs active model → gate state → verdict ("silence is correct" / "would prompt"). Answers "why wasn't I prompted?" in one read (remediation of ledger INC-2026-06-06-silent-lane-correctness). Executes immediately (read-only).
- `/skill-builder route embed` — display mode (high-risk default). For each skill, classify NEW / REFRESH / REMOVE / NOOP based on workflow heuristics + a reconciliation against any embed blocks already on disk.
- `/skill-builder route embed --execute` — apply the planned embeds, refreshes, and removals; auto-runs `route index --execute` afterward to keep the catalog current.
- `/skill-builder route embed --remove [skill]` — manually opt a skill out of the route gate.

Both `index` and `embed` are intelligent on re-run: `index` diffs against the prior catalog and rewrites idempotently; `embed` reconciles against existing `<!-- ROUTE-EMBED START -->` markers and either refreshes them, removes them when the skill no longer qualifies, or adds them where workflows now require routing.

`route embed` manages **four independent managed-block families** in one pass: the `ROUTE-EMBED` consultation gate (freeform-follow-up skills), the `CODE-EVAL-EMBED` gate (code-touching skills), the `MODEL-LANE-GATE` invocation-time preflight (skills that resolve to a model lane with a non-empty preferred model — see [route.md](references/procedures/route.md) § Step 8), and the `LANE-AGENT-EMBED` Excursion Delegation Map ([route.md](references/procedures/route.md) § Step 9 — **reconcile-only**: created by `agents [skill]` under the Bespoke Excursion-Agent Gate, never by `route embed`). The model-lane gate is the invocation-time complement to audit's report-only Step 4f: embedded near the top of a lane-declared skill's workflow, it surfaces a one-line lane advisory before any generative step when the active model does not match the skill's PRIMARY lane (never a prompt, never blocking — the advisory names `/model <preferred>` informationally per the 2026-06-11 named-command advisory directive). Cross-lane mid-workflow steps never re-advise — they delegate to lane-pinned excursion agents per the skill's delegation map (see [references/lane-delegation.md](references/lane-delegation.md)). Neither gate ever switches the model itself, and both are silent no-ops when no lane is declared or the lane's preferred-model cell is empty. `--remove [skill]` strips all four families.

**Audit integration:** `route index` is appended as the second-to-last item in audit's task list, and `route embed` is the last item — and `route embed` is the single write path for the model-lane gate (no separate menu item). See [audit.md](references/procedures/audit.md) § Step 4g.

**Grounding:** Read [references/procedures/route.md](references/procedures/route.md) for the full procedure, including the embed block format, reconciliation rules, and the `/route` skill template used during bootstrap.
<!-- /origin -->

---

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

**Audit integration:** `audit` automatically ensures `code-evaluator` exists (creating it if absent) and runs `code-eval sync` to keep its references current, before the route terminal tasks. See [audit.md](references/procedures/audit.md) § Step 4a-bis.

**Grounding:** Read [references/procedures/code-eval.md](references/procedures/code-eval.md) for the full procedure (create / review / sweep / sync), [references/code-evaluator/skill-template.md](references/code-evaluator/skill-template.md) for the generated SKILL.md + advisor/reviewer agent templates, and [references/code-evaluator/cross-file-detection.md](references/code-evaluator/cross-file-detection.md) + [guards.md](references/code-evaluator/guards.md) for the detection method and false-positive guards.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `model-map` Command

Choose which model runs the **creative** lane and which runs the **coding / everything-else** lane (the 2-brain harness Lane→Model mapping), apply the change, and stop — without running a full `audit`. This is the standalone door to the same Lane→Model Picker + Fleet Rewrite machinery audit reaches at Step 4f step 2-bis; it is purely a mapping refresh, never a scan.

- `/skill-builder model-map` — run the Lane→Model picker (one batched AskUserQuestion: creative model / coding model), write only the changed cells in `references/model-lanes.md`, then fan the new IDs out to every generated `lane-pinned:` excursion agent (Fleet Rewrite). Executes immediately — the picker answer IS the consent (Display/Execute Rule 1).

**Scope (deliberately narrow).** This command ONLY chooses lane→model and rewrites generated agents' `model:` lines. It NEVER assigns skills to lanes — Skill→Lane assignment stays declared-never-inferred (use `audit` onboarding or edit `model-lanes.md` by hand) — and NEVER runs an audit scan. On a project with no lanes configured it writes the Lane→Model mapping and marks lanes `configured` (Skill→Lane left empty); on a `declined` project it asks for an explicit opt-in before flipping the marker.

**Configuration, not a switch.** The two model questions configure the mapping — they never ask the user to run `/model` and the command never switches the session model (No-Switch-Prompt directive; the Lane→Model picker is the sanctioned configuration carve-out). Suppressed in headless / non-interactive sessions: an interactive picker cannot run with no user, so it refuses cleanly and writes nothing.

**Relationship to audit.** `audit` still runs this exact picker on every full interactive run (Step 4f step 2-bis); `model-map` is the lightweight path when you only want to change models and skip the scan. Blanking a lane's preferred-model cell disables that lane, and `model-map` then chains `route embed` to strip the now-orphaned gates and excursion maps.

**Grounding:** Read [references/procedures/model-map.md](references/procedures/model-map.md) for the full procedure, which grounds against [references/lane-delegation.md](references/lane-delegation.md) § Lane→Model Picker + § Fleet Rewrite on Remap and [references/model-lanes.md](references/model-lanes.md) § Setup State.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `reconcile` Command

Detect redundancies and collisions **across** skills and remediate only the ones that are mechanically safe. Where `cascade` looks inside one skill for over-suppression, `reconcile` looks across the whole installed set for the colliding-task failure mode: as a project grows and skills accumulate, two skills can fight over the same trigger, hook matcher, command name, dispatch step, or file region — so a skill "seems to fail to run" when it was really shadowed, bypassed, suppressed, or overwritten.

Governed by the sacred integrity-over-performance directive (§ Directives, 2026-06-04): **redundancy is never the target — only a conflict that breaks a skill's full completion is actionable. No shortcut mentality.** Harmless or intentional overlap (chains, shared kernels, defense-in-depth) is left alone.

- Display mode (default): `/skill-builder reconcile` — scan all skills, report cross-skill conflicts with `file:line` evidence; change nothing
- Targeted: `/skill-builder reconcile [skill]` — report conflicts involving one skill
- Execute mode: `/skill-builder reconcile --execute` — apply ONLY the two mechanical auto-fixes (collapse a duplicate machine-generated embed block; drop a byte-identical duplicate hook entry). Everything touching a directive, description, persona, conflicting hook, or chain stays flag-only; a confirmed redundant skill is routed to `strip`, never deleted here

High-risk command — defaults to display mode, requires `--execute`. `--execute` never edits `origin: user | immutable: true` content, never rewords descriptions or personas, and never deletes a skill directly.

**Audit integration:** `reconcile` runs as audit **Step 4d-bis** (between cascade and the priority panel), display-only with its agent panels suppressed; completion-breaking findings elevate into Priority Fixes. Skipped in `audit --quick`. See [audit.md](references/procedures/audit.md) § Step 4d-bis.

**Grounding:** Read [references/procedures/reconcile.md](references/procedures/reconcile.md) for the full procedure — the collision-class table with reliability tiers, the conflicts-only filter and complementary-overlap allow-list, the remediation ladder with the directive-touch hard floor, the mandatory agent adjudication for judgment-class findings, and the `strip` hand-off.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `strip` Command

Delete a skill completely and remove every connection to it from other skills, settings, hook bindings, and dev-repo manifests. The destructive counterpart to `new`.

- Display mode (default): `/skill-builder strip [skill]` — produce an impact report listing every file to be deleted, every cross-reference to be removed, dependent skills, and BREAKING status if any HARD references exist
- Execute mode: `/skill-builder strip [skill] --execute` — apply the deletion plan
- Breaking confirmation: `/skill-builder strip [skill] --execute --confirm-breaking` — required when the target has HARD references in other skills (workflow Read instructions, hook scripts, or AGENT.md grounding)

Destructive command — defaults to display mode, requires `--execute`. Stripping `skill-builder` itself is HARD-REFUSED even with the `dev` prefix; the prefix permits self-modification, not self-deletion.

After deletion, the procedure auto-runs `route index --execute` to drop the target from the `/route` catalog (when `/route` is installed).

**Grounding:** Read [references/procedures/strip.md](references/procedures/strip.md) for the full procedure, including the 15 cross-reference detection patterns, dependent classification, settings.local.json mutation rules, and the strict task ordering (sweep references before deletion).
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `shell-safety` Command

Write, audit, and lint shell code (scripts, hook commands, JSON-embedded shell strings) against the canonical pitfall rule set. Used internally by `hooks` and `verify`, and available for direct user invocation.

- Write: `/skill-builder shell-safety write [target]` — generate a new script or JSON shell entry from a safe-default template
- Audit: `/skill-builder shell-safety audit [path]` — scan for pitfalls; with `--execute`, patch the mechanical-safe ones
- Lint: `/skill-builder shell-safety lint [file]` — read-only single-file check (exit 1 on findings, composes with `&&`)

**Grounding:** Read [references/procedures/shell-safety.md](references/procedures/shell-safety.md) for the full procedure, [references/shell-safety/rules.md](references/shell-safety/rules.md) for the pitfall catalog, [references/shell-safety/templates.md](references/shell-safety/templates.md) for safe scaffolds, and [references/shell-safety/audit-patterns.md](references/shell-safety/audit-patterns.md) for detection regexes.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Self-Exclusion Rule

**The skill-builder skill MUST be excluded from all actions (audit, optimize, agents, hooks, skills list) unless the command is prefixed with `dev`.**

- `/skill-builder audit` → audits all skills EXCEPT skill-builder
- `/skill-builder optimize some-skill` → works normally
- `/skill-builder optimize skill-builder` → REFUSED. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev optimize skill-builder`"
- `/skill-builder dev audit` → includes skill-builder in the audit
- `/skill-builder dev optimize skill-builder` → allowed

**Detection:** If the first argument after the command is `dev`, strip it and proceed with self-inclusion enabled. Otherwise, skip any skill whose name is `skill-builder` when iterating skills, and refuse if `skill-builder` is explicitly named as a target.

**CHECKPOINT — apply before dispatching to any procedure (Opus 4.7 literal-execution gate):**

1. Parse the invocation. Is the first positional argument the literal string `dev`?
   - YES → `dev_mode = true`; strip `dev` from the argument list; continue.
   - NO  → `dev_mode = false`.
2. Extract the first remaining positional argument as `first_arg`.
3. Define the known-command set: `{ audit, optimize, agents, hooks, new, inline, skills, list, verify, ledger, cascade, reconcile, checksums, convert, shell-safety, route, code-eval, model-map, local-mode, update }`.
4. IF `first_arg` is empty (no arguments remaining) → dispatch to the default full-audit flow per § Quick Commands. Do NOT invoke the intent router. STOP this CHECKPOINT.
5. IF `first_arg` is in the known-command set → treat it as the command name. Determine whether a skill target was specified in the remaining arguments. CONTINUE to step 7.
6. IF `first_arg` is NOT in the known-command set AND the remaining argument string is non-empty →
   - STOP normal dispatch.
   - Ground on [references/procedures/intent-router.md](references/procedures/intent-router.md) (read-before-use).
   - Invoke the Intent Router procedure, passing the full remaining argument string (including `first_arg`) as the freeform intent, and `dev_mode` as context.
   - The router is responsible for either re-dispatching to a known command (in which case resume this CHECKPOINT at step 7 with the router's resolved command and target) or halting with an AskUserQuestion / explanatory message.
   - The router NEVER modifies files; all file-touching work happens in the re-dispatched command.
7. IF `dev_mode == false`:
   - IF the skill target is the literal string `skill-builder` → REFUSE and STOP. Print: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev [command] skill-builder`". Do not dispatch.
   - IF no target was specified (all-skills/iteration mode) → the skill set passed into the procedure MUST have `skill-builder` filtered out before any per-skill iteration begins.
8. IF `dev_mode == true` → skill-builder is included normally.
9. Dispatch to the procedure file.

This CHECKPOINT fires every invocation. Procedure files repeat it in their own preflight blocks for defense in depth — 4.7 executes each file literally, so both gates matter.

**Dev Path Discipline (defense-in-depth pointer):** Phase 0 at the top of this SKILL.md is the primary gate for source-vs-runtime path resolution in maintainer mode. It fires BEFORE this CHECKPOINT in document order. If Phase 0 ran cleanly, the path was already rewritten to the source location before reaching dispatch. If you reached this point and a planned Edit/Write still targets `.claude/skills/skill-builder/...`, STOP and re-read § Phase 0.

**Post-dev check:** After any `dev` command that modifies skill-builder files, run BOTH of the following:

1. **Manifest check.** Glob `skill-builder/**/*.md`. Compare against the paths listed in the repo-root `manifest.txt` — the single authoritative shipped-file list consumed by BOTH installers (`install` for bash, `install.ps1` for PowerShell). Flag any new/renamed/removed files the manifest doesn't list. This prevents drift between the repo and what users receive on install, on every platform at once. (The only shipped hook scripts are the two 2026-05-11 exceptions, listed in the manifest with the `hook` flag; users generate all other per-system hooks via `/skill-builder hooks`.)
2. **Source-edit verification.** Run `git status --short -- skill-builder/`. If the dev session was expected to produce changes and the output is empty, the edits landed in the runtime copy. Report the failure with the runtime/source diff so the user can mirror canonical changes back to source.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Display/Execute Mode Convention

**Commands are classified by risk level, which determines their default mode:**

| Risk | Commands | Default Mode |
|------|----------|-------------|
| **Low-risk** (additive, non-destructive) | `new`, `inline`, `skills`, `list`, `verify`, `ledger`, `checksums`, `route index`, `route lane-status`, `code-eval create`, `code-eval sync`, `model-map` | **Execute directly** |
| **Single-consent auto** (2026-06-06 Audit Autonomy Gate) | `audit`, `audit --quick` | **Scan + report, then auto-execute** under the Step 0 disclaimer consent; `--review`/`--dry-run` = report-only; `--execute` = harmless no-op |
| **High-risk** (restructuring, modifying) | `optimize`, `agents`, `hooks`, `cascade`, `reconcile`, `convert`, `route embed`, `code-eval review`, `code-eval sweep`, `local-mode` | **Display mode** (requires `--execute`) *when invoked standalone; under audit they run in the auto-execution phase* |
| **Destructive** (deletes files irreversibly) | `strip` | **Display mode** (requires `--execute`; `--confirm-breaking` if dependents exist) — NEVER auto-fired by audit (DEFER tier) |

| Mode | Behavior | Flag |
|------|----------|------|
| **Display** | Read-only plan of what would change | *(default for high-risk)* |
| **Execute** | Apply changes to files | `--execute` or *(default for low-risk)* |

### Rules

1. **Low-risk commands execute immediately.** `new`, `inline`, `skills`, `list`, `verify`, `ledger`, `checksums`, and `route index` do their work directly without requiring `--execute`. They are additive or read-only — there is nothing to preview. (`route index` is auto-generated content inside the `/route` skill only — idempotent regeneration.) `model-map` is the one low-risk command that mutates files (Lane→Model cells + generated agents' `model:` lines): it is low-risk because its core action is an interactive picker whose answer IS the consent — there is no meaningful display mode for an AskUserQuestion — exactly the single-consent pattern audit's 4f-setup already uses.
2. **High-risk commands default to display mode.** Running `/skill-builder optimize my-skill` shows what *would* change without modifying anything. Add `--execute` to apply.
3. **Audit calls sub-commands in display mode for the scan, then auto-executes** (2026-06-06 Audit Autonomy Gate — the Step 6 execution menu is abolished): after the report and its Execution Plan block, audit runs the AUTO-tier task list under the Step 0 disclaimer consent; DEFER-tier items appear in the Deferred Items table with their exact commands, never as a menu. `audit --review` is the zero-write opt-out.
4. **Execution requires a task plan.** When a high-risk command runs with `--execute`, the command MUST:
   - First produce a numbered task list using TaskCreate, one task per discrete action
   - Execute each task sequentially, marking progress via TaskUpdate
   - This ensures context can be refreshed mid-execution without losing track, no tasks get forgotten during long context windows, and the user can see progress and resume if interrupted
5. **Scope discipline during execution.** Execute ONLY the tasks in the task list. Do not add bonus tasks, expand scope, or create deliverables not in the original plan. If execution reveals a new opportunity, note it in the completion report — do not act on it. The task list is the contract.
6. **Post-action chaining.** Any action that modifies a skill (`new`, `inline`, adding directives) automatically chains into a scoped mini-audit for the affected skill — running optimize, agents, and hooks in display mode, then offering execution choices. Additionally (2-Brain Harness, 2026-06-06), EVERY skill-mutating execute path (`new`, `inline`, `convert --execute`, `agents --execute`, `optimize --execute`, `code-eval create`) chains a **scoped route reconciliation** for the affected skill(s) — `route index` row refresh + four-family embed reconciliation per [post-action-chain.md](references/procedures/post-action-chain.md) § Step 1a — so new skills and newly generated functions are indexed and gated the moment they exist. Use `--no-chain` to suppress.
7. **Model-lane reporting + audit disclaimer.** Model-switch prompts are ABOLISHED everywhere in skill-builder (2026-06-06 No-Switch-Prompt directive, superseding the earlier "flag + prompt" mechanic newest-wins): when `audit` finds a skill whose declared lane's preferred model differs from the active session model (see § Directives → Model-Lane Routing Gate and audit.md § Step 4f), it **reports** the mismatch as a one-line advisory and proceeds — never an AskUserQuestion, never an instruction to run `/model`. `--model-prompt` is retired; `--no-model-prompt` is a harmless no-op. **Disclaimer (every audit):** before any audit work begins, the user must accept the audit disclaimer (designed for Opus 4.7+; skills created are backwards compatible with earlier models; back up CLAUDE.md and .claude first) — see § Directives → Audit Disclaimer Gate and audit.md § Step 0. Headless runs require a prior interactive acceptance marker. **Onboarding:** when a project has no lanes configured yet, a full interactive `audit` offers a one-time setup question (Set it up now / Not now / Never ask in this project), tracked per project via the `model-lane-setup` marker in `model-lanes.md` — this configures the mapping; it never requests a switch. Bootstrap audits on fresh projects included (2026-06-07 fix — bootstrap mode runs Step 4f after its auto-execution phase; see audit.md § Step 2.5). See audit.md § Step 4f-setup and model-lanes.md § Setup State. **Picker (every full audit):** once configured, every full interactive audit re-confirms the Lane→Model mapping via a batched picker — options exactly `claude-opus-4-6`, `claude-opus-4-8`, and the latest released model by official ID (discovered live, never fabricated), current values pre-selected. A confirmed remap fans out to every generated `lane-pinned:` agent's `model:` frontmatter (Fleet Rewrite). See audit.md § Step 4f step 2-bis and references/lane-delegation.md. **Excursions never advise:** cross-lane mid-workflow steps delegate to lane-pinned agents instead (§ Directives → Bespoke Excursion-Agent Gate).
8. **Decision handoffs use AskUserQuestion — never a free-text "should I?".** Every point where a command ends its turn to let the user decide *whether to proceed, what to change, or which direction to take* MUST be presented via **AskUserQuestion** (a clickable menu), not as end-of-turn prose like "Would you like me to proceed?". This holds for **every** command, display and execute alike, and generalizes Rules 3, 6, and 7 into one invariant. **Audit carve-out (2026-06-06 Audit Autonomy Gate):** under `audit` the only permitted questions are the Step 0 disclaimer, the one-time 4f-setup onboarding, and the every-audit Lane→Model picker — audit makes no other decision handoffs; it does the work and defers the rest into the Deferred Items table (informational prose, not a handoff). **Over-fire guard:** if you cannot name at least two concrete options, it is not a decision handoff — ask in prose (open-ended freeform like "paste the error text" stays prose; in-turn status, progress narration, bare acknowledgements, and audit's terminal Execution Summary/Deferred Items never prompt). **Option floor:** every decision menu offers at least the recommended path, one genuine alternative, and an explicit **"Skip / not now"** so the user is never trapped into authorizing an action (AskUserQuestion's auto-appended "Other" preserves freeform on top of these). Style on the `update` CHECKPOINT.
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Core Principles

**Read [references/principles.md](references/principles.md) before running any high-risk command** (`optimize`, `agents`, `hooks`, `audit`, `cascade`, `convert`). That file contains the full Core Principles, Sacred Directive Pattern, Output Discipline rules, and Grounding Protocol. It was split out of SKILL.md during the 4.7 upgrade to reduce always-loaded context weight.

**IMPORTANT: Never break anything.** Optimization is RESTRUCTURING, not REWRITING. MOVE content, don't rewrite it. PRESERVE all directives exactly. KEEP all workflows intact. If the original author reviewed the result, they should say "this does exactly what mine did, just organized differently."
<!-- /origin -->

---

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Grounding

Grounding protocol (read-before-use, state which pattern will be used) is documented in [references/principles.md](references/principles.md) § "Grounding Protocol".

Reference files:
- [references/principles.md](references/principles.md) — Core Principles, Sacred Directive Pattern, Output Discipline, Grounding Protocol (READ FIRST for high-risk commands)
- [references/enforcement.md](references/enforcement.md) — Hook JSON, permissions, context mutability, provenance permission model
- [references/model-lanes.md](references/model-lanes.md) — Lane→Model routing map (user-editable), active-model detection, advisory lane classification (read by audit Step 4f)
- [references/creative-integrity.md](references/creative-integrity.md) — The Nine Scrub Principles (verbatim), creative-workflow scope heuristic, equivalence-aware compliance checklist, canonical scrub-loop spec, pattern-library gap check, research digest (read by audit Step 4c-bis)
- [references/creative-integrity/](references/creative-integrity/) — Shipped portable text-evaluation intel: version.md (drift anchor), text-tells.md (the project-agnostic AI-text-signature catalog seeding audit-built `text-eval` scaffolds and baselining the Step 4c-bis gap check)
- [references/lane-delegation.md](references/lane-delegation.md) — Lane-pinned excursion delegation: per-step classification, NON-DELEGABLE list, Context Contract, agent template, Delegation Map block, Lane→Model picker + fleet rewrite (read by agents § Step 4d, route § Step 9, audit § Step 4f)
- [references/agents.md](references/agents.md) — Agent templates, opportunity detection, creation workflow
- [references/agents-personas.md](references/agents-personas.md) — Persona assignment rules, selection heuristic, research backing
- [references/agents-teams.md](references/agents-teams.md) — Individual vs. team routing, invocation patterns, mandatory agent situations
- [references/templates.md](references/templates.md) — Skill directory layout, SKILL.md template, frontmatter
- [references/optimization-examples.md](references/optimization-examples.md) — Before/after examples, optimization targets
- [references/portability.md](references/portability.md) — Install instructions, rule-to-skill conversion
- [references/patterns.md](references/patterns.md) — Lessons learned
- [references/platform.md](references/platform.md) — Claude Code skill platform architecture, frontmatter fields, listing budget, invocation flow
- [references/token-efficiency.md](references/token-efficiency.md) — Token-intensive pattern catalog and Token Efficiency Scan rules (optimize step 4e)
- [references/temporal-validation.md](references/temporal-validation.md) — Temporal risk classification, phrase mappings, hook generation spec
- [references/ledger-templates.md](references/ledger-templates.md) — Awareness Ledger record templates, agent definitions, consultation protocol
- [references/procedures/](references/procedures/) — Per-command procedure files (audit, verify, optimize, agents, hooks, new, inline, ledger, cascade, checksums, shell-safety, etc.)
- [references/procedures/checksums.md](references/procedures/checksums.md) — Directive checksum generation spec (scripts generated at runtime, not shipped)
- [references/procedures/shell-safety.md](references/procedures/shell-safety.md) — Shell-safety subcommand procedure (write / audit / lint)
- [references/procedures/route.md](references/procedures/route.md) — Route subcommand procedure (index + embed) with `/route` skill bootstrap template
- [references/procedures/code-eval.md](references/procedures/code-eval.md) — Code-eval subcommand procedure (create / review / sweep / sync) for the `code-evaluator` skill
- [references/procedures/model-map.md](references/procedures/model-map.md) — Standalone Lane→Model picker + fleet rewrite (choose creative + coding models without an audit)
- [references/procedures/reconcile.md](references/procedures/reconcile.md) — Reconcile subcommand procedure (cross-skill collision detection, conflicts-only scope, integrity-preserving remediation ladder, strip hand-off)
- [references/code-evaluator/](references/code-evaluator/) — Shipped intel for the generated `code-evaluator` skill: version.md (drift anchor), cross-file-detection.md, guards.md, mistake-taxonomy.md, native-tool-map.md, gotchas.md, skill-template.md
- [references/shell-safety/](references/shell-safety/) — Shell-safety rule set (rules.md, templates.md, audit-patterns.md) — the canonical pitfall catalog used by hooks, verify, and shell-safety
- [agents/optimize-diff-auditor/](agents/optimize-diff-auditor/) — Post-optimize semantic equivalence verification agent
<!-- /origin -->
