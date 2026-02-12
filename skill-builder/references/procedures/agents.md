## Agents Command Procedure

**Analyze and create agents for a skill.**

### Display Mode (default)

When running `/skill-builder agents [skill]`:

1. **Read the skill's SKILL.md** — understand its directives, workflows, and enforcement gaps
2. **Read `references/agents.md`** — load the 5 agent templates and opportunity detection table
3. **Evaluate each agent type** against the skill:

| Agent Type | Trigger Condition | Applies? |
|------------|-------------------|----------|
| **ID Lookup** | Skill references IDs, accounts, or external identifiers that must be validated | [yes/no + reasoning] |
| **Validator** | Skill has pre-flight checks or complex validation rules | [yes/no + reasoning] |
| **Evaluation** | Skill produces output that needs quality assessment | [yes/no + reasoning] |
| **Matcher** | Skill requires matching inputs to categories or patterns | [yes/no + reasoning] |
| **Voice Validator** | Skill produces written content AND has voice/style directives (tone rules, forbidden phrasing, writing constraints) | [yes/no + reasoning] |

4. **Report which agents would help and why:**

```markdown
## Agent Opportunities for /skill-name

| Agent Type | Recommended | Purpose | Priority |
|------------|-------------|---------|----------|
| ID Lookup | Yes | Validate account IDs against reference.md | High |
| Validator | No | No complex validation rules found | — |
| Evaluation | Yes | Assess output quality for reports | Medium |
| Matcher | No | No pattern matching needed | — |

### Recommended Agents
1. **ID Lookup Agent** — [specific purpose for this skill]
2. **Evaluation Agent** — [specific purpose for this skill]
```

### Execute Mode (`--execute`)

When running `/skill-builder agents [skill] --execute`:

1. Run display mode analysis first
2. **Generate task list from findings** using TaskCreate — one task per agent to create (e.g., "Create ID Lookup agent for /budget", "Create Validator agent for /deploy")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. Each task: create the agent file in `.claude/skills/[skill]/agents/`, following templates from `references/agents.md`

**Grounding:** `references/agents.md`
