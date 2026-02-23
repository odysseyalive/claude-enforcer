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
| **Voice Validator** | Skill produces written content AND has voice/style directives (tone rules, forbidden phrasing, writing constraints) | [yes/no + reasoning] |

4. **Identify mandatory agent situations** — scan the skill for non-obvious decisions where guessing is involved. Per directive: "When a decision needs to be made that isn't overtly obvious, and guesses are involved, AGENTS ARE MANDATORY." Flag these as requiring agent panels.

5. **Agent panel: type applicability and routing** — Deciding which agent types apply to a skill and whether they should be individual or team is itself a judgment call. Spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

   - **Agent 1** (persona: Systems architect who designs for failure modes) — Review the skill's directives and workflows. Which agent types would prevent the highest-risk failures? What happens if each agent type is absent?
   - **Agent 2** (persona: Token economist who optimizes cost-per-value) — Review the same skill. Which agents are worth the token cost? Which would fire frequently enough to justify their existence vs. being rare edge cases?
   - **Agent 3** (persona: Workflow designer who builds for human-AI collaboration) — Review the same skill. Should agents be isolated evaluators or collaborative teammates for this skill's use cases? What does the skill's output pattern suggest?

   Each agent reads the skill's SKILL.md, `references/agents-teams.md` § "Routing Decision Framework", and the evaluation table from step 3. They return independent recommendations. Synthesize:
   - Agent types recommended by 2+ agents → include in the report
   - Routing (individual vs. team) agreed by 2+ agents → adopt
   - Disagreements → present both sides in the report for user decision

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

**Grounding:** `references/agents.md`
