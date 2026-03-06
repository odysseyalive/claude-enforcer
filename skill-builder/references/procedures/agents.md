## Agents Command Procedure

**Analyze and create agents for a skill.**

### Display Mode (default)

When running `/skill-builder agents [skill]`:

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
4. Each task: create the agent file in `.claude/skills/[skill]/agents/`, following templates from `references/agents.md`
5. **Verify persona uniqueness** — after creating all agents, confirm no two share the same persona
6. **For agent teams**: verify `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is enabled in `.claude/settings.local.json`
7. **For agent teams**: always include the mandatory research assistant teammate in the generated team definition. The research assistant gathers reference information using the project's configured search tools. Other teammates reference the research assistant by name when they need research. See `references/agents-teams.md` § "Mandatory Research Assistant Teammate" for full specification.
8. **For agent teams**: verify research tool permissions are configured. Check `.claude/settings.local.json` for `permissions.allow` including the project's configured search tools. The install script sets these automatically. Additionally, recommend running `/skill-builder hooks --execute` to generate a PreToolUse hook that auto-approves these tools (belt-and-suspenders). See `references/agents-teams.md` § "Permissions" for details.

**Grounding:** `references/agents.md`
