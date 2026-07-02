## Agents Command Procedure

**Analyze and create agents for a skill.**

### Sacred-Directive Enforcement Gates (relocated from SKILL.md, 2026-07-01)

<!-- The following ENFORCEMENT ANNOTATION blocks moved VERBATIM from SKILL.md, comment headers intact. They are literal-execution gates for sacred user directives (SKILL.md, Directives section). Execute them exactly as written whenever their triggers fire; never reword or reorder their contents. -->

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

---

### Display Mode (default)

When running `/skill-builder agents [skill]`:

**Preflight — self-exclusion.** If the target skill is literally `skill-builder` AND the command was NOT invoked as `/skill-builder dev agents skill-builder`, REFUSE. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev agents skill-builder`". Do not proceed. See SKILL.md § Self-Exclusion Rule.

1. **Read the skill's SKILL.md** — understand its directives, workflows, and enforcement gaps
2. **Read `references/agents.md`** — load agent templates, opportunity detection table, persona requirements, and individual-vs-team routing framework
3. **Evaluate each agent type** against the skill:

| Agent Type | Trigger Condition | Applies? |
|------------|-------------------|----------|
| **ID Lookup** | Skill references IDs, accounts, or external identifiers that must be validated | [yes/no + reasoning] |
| **Validator** | Skill has pre-flight checks or complex validation rules | [yes/no + reasoning] |
| **Evaluation** | Skill produces output that needs quality assessment | [yes/no + reasoning] |
| **Matcher** | Skill requires matching inputs to categories or patterns | [yes/no + reasoning] |
| **Text Evaluation Pair** | Skill produces written content AND **already has voice/style directives in its `## Directives` section** — spawns two agents: The Reducer (overbuilt, bloated, verbose) and The Clarifier (confusing, contradictory, ambiguous). Do not recommend speculatively for content-creation skills without existing voice directives. | [yes/no + reasoning] |
| **Capture Recommender** | Skill produces findings/decisions/patterns AND awareness-ledger exists AND no simpler capture mechanism present (workflow step or hook) | [yes/no + reasoning] |

3b. **Cascade guard** — Before recommending new validators, check the skill's current validation load:
   - Count existing validators (hooks, evaluation agents, text evaluation pair, inline validation steps)
   - If the skill already has 3+ validators, run the cascade analysis per [cascade.md](cascade.md)
   - If cascade risk is MODERATE or HIGH, note in the report: "This skill has [N] existing validators with [risk level] cascade risk. Adding more validators may suppress creative output. Consider consolidating existing validators before adding new ones."
   - If cascade risk is LOW or NONE, proceed normally

3c. **Output-contract & spawn-pattern check.** Enumerate the skill's existing agents (`agents/*.md` and `agents/*/AGENT.md`):
   - For each agent whose output a consumer parses (mechanical trigger: the agent is referenced by a procedure or workflow step that branches on named fields, tokens, or a verdict line of its return), verify the AGENT.md defines an explicit output contract per `references/agents.md` § Output Contracts. Missing, or defined only in the caller's prompt → flag: "consumer-parsed agent without an output contract (drift risk)".
   - Flag any spawn instruction that uses `subagent_type: "general-purpose"` for an agent registered under `.claude/agents/` (this bypasses the agent's `model:` pin, `tools:` grant, and persona; the fix is the canonical pattern in `references/agents.md` § Spawning Agents (Canonical Pattern)). Ad-hoc prompt-persona panels are exempt.
   - Flag any agent spawned by name anywhere but not registered under `.claude/agents/` (unresolvable subagent_type; precedent ledger DEC-2026-06-23-code-eval-agent-registration).

4. **Identify mandatory agent situations** — scan the skill for non-obvious decisions where guessing is involved. Per directive: "When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY." Flag these as requiring agent panels.

4b. **Detect Awareness Ledger** *(runs only when this skill is explicitly targeted, not during audit's display-mode pass)* — Check if `.claude/skills/awareness-ledger/SKILL.md` exists. If it does:

   - Check if `ledger/index.md` has any records (non-empty ledger)
   - Scan the skill's SKILL.md for file paths, domain tags, and function names that overlap with ledger record tags
   - Only recommend ledger integration if the skill's domain **explicitly overlaps** with existing ledger records (matching file paths, component names, or domain tags)
   - If overlap found:
     - Add **Ledger Consultation** to the agent type evaluation table as an applicable type
     - Recommend the **proportional auto-activation model**: index scan (free) → read matching records (cheap) → spawn agents (expensive, only when high-risk overlap detected). Reference `references/ledger-templates.md` § "Auto-Activation Directives" for template text.
   - If the ledger is empty, note: "Awareness Ledger exists but has no records yet. Consultation integration will become relevant once records accumulate."
   - If the ledger does not exist, skip this step silently

4c. **Evaluate Capture Recommender Agent** *(runs only when this skill is explicitly targeted, not during audit's display-mode pass)* — If the awareness-ledger exists, evaluate whether the skill would benefit from a Capture Recommender agent (see `references/agents.md` § "Capture Recommender Agent"):

   - **When to recommend:** Skill produces diagnostic findings, architectural decisions, debugging flows, or pattern observations that match capture trigger patterns. The agent applies judgment to determine *whether* output is ledger-worthy.
   - **Check for existing capture integration first:** Before recommending, verify no capture mechanism already exists (workflow step, hook, or agent). One capture mechanism per skill.
   - If recommending, add **Capture Recommender** to the evaluation table with reasoning referencing specific trigger patterns.

4d. **Excursion detection & lane-pinned placement pass** — *Precondition (deterministic, no agent needed to enter): model lanes are configured AND the target skill resolves to a declared lane with a non-empty preferred model (lane resolution per model-lanes.md § Comparison Rule step 1). Otherwise skip this step silently.* Read [../lane-delegation.md](../lane-delegation.md) in full before proceeding (Bespoke Excursion-Agent Gate, SKILL.md § Directives 2026-06-06).

   1. Resolve the skill's primary lane and preferred model.
   2. Walk the skill's workflow **step by step**, classifying each step against lane-delegation.md § Excursion Signal Vocabulary (research precedence fires first — a research step in a `coding` skill is native, never an excursion) and the § NON-DELEGABLE Hard-Stop List.
   3. For each cross-lane candidate, check coverage: is it already governed by an entry in the skill's `LANE-AGENT-EMBED` Delegation Map block? Covered → NOOP. Uncovered → propose delegation (NEW).
   4. **Legacy revamp scan:** flag any non-managed mid-workflow model-switch instruction (`/model`, "switch model" outside START/END markers) as REVAMP. Candidates inside `origin: user | immutable: true` blocks are FLAG-ONLY — the machine never rewords sacred text, even to revamp it.
   5. **Ambiguity → agent panel mandatory** (3 unique personas, e.g. workflow-integrity inspector / context-dependence auditor / lane-classification specialist). Panel split → NO-DELEGATE. *(Panel suppressed when running as audit's display-mode sub-command, per audit's agent-budget rule — heuristic-only flagging there; the panel fires standalone or in `--execute`.)*
   6. Report section (append to the step 7 report):

```markdown
### Lane Excursion Opportunities
Primary lane: [lane] (preferred model [id]; active model [id])

| Step (anchor) | Other-lane signal | Proposed agent | model: | tools: | Status |
|---|---|---|---|---|---|
| "[quoted phrase]" | research | [skill]-researcher | [other-lane full ID] | Read, Grep, Glob, Bash, WebFetch, WebSearch | NEW |
| "[quoted phrase]" | — | — | — | — | NON-DELEGABLE ([reason]) |
| "[/model prompt at ...]" | legacy switching | — | — | — | REVAMP |
```

5. **Agent panel: type applicability and routing** *(skip when running as sub-command of audit — fires only in standalone or `--execute` mode)* — Deciding which agent types apply to a skill and whether they should be individual or team is itself a judgment call. Spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

   - **Agent 1** (persona: Systems architect who designs for failure modes) — Review the skill's directives and workflows. Which agent types would prevent the highest-risk failures? What happens if each agent type is absent?
   - **Agent 2** (persona: Token economist who optimizes cost-per-value) — Review the same skill. Which agents are worth the token cost? Which would fire frequently enough to justify their existence vs. being rare edge cases?
   - **Agent 3** (persona: Workflow designer who builds for human-AI collaboration) — Review the same skill. Should agents be isolated evaluators or collaborative teammates for this skill's use cases? What does the skill's output pattern suggest?

   Each agent reads the skill's SKILL.md, `references/agents-teams.md` § "Routing Decision Framework", and the evaluation table from step 3. They return independent recommendations. Synthesize:
   - Agent types recommended by 2+ agents → include in the report
   - Routing (individual vs. team) agreed by 2+ agents → adopt
   - Disagreements → present both sides in the report for user decision
   - **When routing recommends a team:** The mandatory research assistant teammate is automatically included and does not count against the panel's recommended agents. It is structural infrastructure, not a panel recommendation.
   - **When Text Evaluation Pair is recommended:** This counts as two agents in the panel (The Reducer and The Clarifier). Their personas are fixed — do not reassign. Both are always individual agents (`context: none`), never part of a team. They run in parallel and their findings are synthesized by the main AI.

6. **Assign personas** — for each recommended agent, propose a specific persona using the heuristic: "If I could only gather 3 to 5 people at the top of their field to evaluate this subject, who would they be?" Ensure no two agents share a persona. Match creative tasks to notable practitioners, analytical tasks to disciplinary experts.

7. **Report which agents would help and why:**

```markdown
## Agent Opportunities for /skill-name

### Routing
Architecture: [Individual agents / Agent team / Both]
Rationale: [Why this routing — evaluation vs. implementation, isolation needs, etc.]

### Agent Panel

| Agent | Type | Persona | Purpose | Priority |
|-------|------|---------|---------|----------|
| security-reviewer | Evaluation | Senior penetration tester | Audit auth module for vulnerabilities | High |
| perf-analyst | Evaluation | Database performance engineer | Identify query bottlenecks | High |
| ux-reviewer | Evaluation | Product designer (mobile-first) | Assess API ergonomics | Medium |

### Output Contracts & Spawn Patterns
[Findings from step 3c, or: "All consumer-parsed agents carry output contracts; spawn patterns canonical."]

### Mandatory Agent Situations
[List any non-obvious decisions in this skill that require agent input]

### Recommended Agents
1. **security-reviewer** (persona: Senior penetration tester) — [specific purpose]
2. **perf-analyst** (persona: Database performance engineer) — [specific purpose]
```

### Execute Mode (`--execute`)

When running `/skill-builder agents [skill] --execute`:

1. Run display mode analysis first
2. **Generate task list from findings** using TaskCreate — one task per agent to create (e.g., "Create security-reviewer agent with penetration tester persona for /auth")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. Each task: create the agent file in `.claude/skills/[skill]/agents/`, following templates from `references/agents.md`; when a consumer will parse the agent's result, author its output contract in the AGENT.md at creation time (`references/agents.md` § Output Contracts), including the in-band failure channel and the caller-side parse-failure behavior
4b. **Model assignment (sacred directive, 2026-06-06):** every AGENT.md created or modified by these tasks gets an explicit `model:` field per SKILL.md § Directives → Audit Agent Model-Assignment Gate — classify the agent's own work (creative vs everything-else; research → everything-else) and stamp the matching lane's full model ID from model-lanes.md. Lanes unconfigured or cell empty → leave `model:` absent and flag; never invent an ID.
4c. **Lane-pinned excursion tasks** (from step 4d findings, one task each, in this order per excursion):
   1. Design the bespoke agent from the skill's reviewed material (Bespoke Excursion-Agent Gate clauses 1–4; template + Context Contract per `references/lane-delegation.md`).
   2. Persona uniqueness check across the extended glob union (both skill-agent forms + `.claude/agents/*.md`, deref symlinks, dedupe; composed scheme per agents-personas.md Rule 5).
   3. Curate the minimal `tools:` list from lane-delegation.md's curation table (never Task/Skill/Edit).
   4. Write `.claude/skills/[skill]/agents/[name]/AGENT.md` — including `contract-stamp:` (sha256 of the normalized skill workflow text the design reviewed, per lane-delegation.md's agent template; route embed § Step 9 and verify § Step 4b compare it to detect CONTRACT-DRIFT); create the registration symlink `.claude/agents/[name].md` (copy fallback where symlinks are unavailable — report which was used).
   5. Insert or refresh the skill's single `LANE-AGENT-EMBED` Delegation Map block immediately after its MODEL-LANE-GATE block (insertion + anchor rules in lane-delegation.md § The Delegation Map; never inside/before/reordering an immutable block; the workflow body stays byte-identical).
   6. REVAMP removals: strip a legacy mid-workflow switch instruction ONLY if it is machine-generated / `modifiable: true` content; user-authored prose stays flagged, never edited.
   7. Verify: frontmatter parses (including `lane-pinned:`, `generated-by:`, `excursion-skill:`, `model:`), the map block appears exactly once, every anchor matches exactly once, no immutable block was touched. Note that `route embed` (audit's terminal task) keeps the block reconciled from here on.
4d. **Registration (standard step):** every created agent that a procedure or skill spawns by name (equivalently: any agent with a defined output contract or a `model:` pin) gets a registration symlink `.claude/agents/[name].md` (copy fallback where symlinks are unavailable; report which was used), after a mechanical name-collision check across `.claude/agents/`. Ephemeral panel personas are never registered. Existing consumer-parsed agents that step 3c found unregistered are registered here too. Parent-skill spawn instructions created or updated by these tasks use the canonical pattern from `references/agents.md` § Spawning Agents (Canonical Pattern), never bare `general-purpose` for a registered agent.
5. **Verify persona uniqueness** — after creating all agents, confirm no two share the same persona
6. **For agent teams**: verify `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled in `.claude/settings.local.json`
7. **For agent teams**: always include the mandatory research assistant teammate in the generated team definition. The research assistant gathers reference information using the project's configured search tools. Other teammates reference the research assistant by name when they need research. See `references/agents-teams.md` § "Mandatory Research Assistant Teammate" for full specification.
8. **For agent teams**: verify research tool permissions are configured. Check `.claude/settings.local.json` for `permissions.allow` including the project's configured search tools. The install script sets these automatically. Additionally, recommend running `/skill-builder hooks --execute` to generate a PreToolUse hook that auto-approves these tools (belt-and-suspenders). See `references/agents-teams.md` § "Permissions" for details.
9. **Lane-guardrail permission backstop (optional, opt-in):** when the project participates in the lane system, an `Agent(model:…)` deny guardrail can block ad-hoc off-lane subagent spawns. This is NOT authored here — it is owned by `/skill-builder hooks` § Step 3d (detection + opt-in write), because it does not bind the frontmatter-pinned fleet and it is a hard block departing from the advisory-only norm. Point the user there rather than emitting deny rules from `agents`. See `references/lane-delegation.md` § "Lane-Guardrail Permission Rules".

**Grounding:** `references/agents.md` (including § Output Contracts and § Spawning Agents (Canonical Pattern) for step 3c / execute 4 and 4d), `references/lane-delegation.md` (step 4d / execute 4b–4c)
