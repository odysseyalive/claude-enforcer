# Individual Agents vs. Agent Teams
<!-- Enforcement: HIGH — routing decision determines architecture -->

Skill-builder must distinguish between two fundamentally different agent architectures. They serve different purposes and should never be conflated.

## Individual Agents (Isolated Evaluation)

Individual agents run independently with `context: none`. Each evaluates the same subject from their own perspective, without knowledge of what other agents think. Their findings are returned to the main AI, which synthesizes all opinions and makes a recommendation.

**This is the adversarial model.** Each agent is an independent expert offering an uncontaminated opinion. The main AI acts as the decision-maker who weighs all perspectives.

**When to use individual agents:**
- Evaluating output quality (writing, code, design decisions)
- Research where diverse perspectives prevent anchoring bias
- Decisions where the "right answer" requires judgment, not just validation
- Any situation where consensus-seeking would suppress dissent
- Diagnosing problems where competing hypotheses should be tested independently

**Architecture:**
```
Main AI (synthesizer/decision-maker)
  ├── Agent A (persona: security researcher) → independent findings
  ├── Agent B (persona: performance engineer) → independent findings
  └── Agent C (persona: UX specialist) → independent findings
      ↓
Main AI weighs all findings → recommendation
```

**How to invoke individual agents:**

Spawn each agent as a Task with `subagent_type: "general-purpose"`. Launch them in parallel (multiple Task calls in a single message) so they can't influence each other. Each agent reads its AGENT.md for instructions and persona.

```markdown
## Invocation Pattern (Individual Agents)

Launch all agents in parallel — a single message with multiple Task tool calls:

Task tool with subagent_type: "general-purpose"
Prompt: "You are [Persona A — e.g., 'a senior penetration tester'].
        Read .claude/skills/[skill]/agents/[agent-a]/AGENT.md for instructions.
        Then read [target file or content].
        Evaluate from your perspective. Return findings in the specified format."

Task tool with subagent_type: "general-purpose"
Prompt: "You are [Persona B — e.g., 'a database performance engineer'].
        Read .claude/skills/[skill]/agents/[agent-b]/AGENT.md for instructions.
        Then read [target file or content].
        Evaluate from your perspective. Return findings in the specified format."

After ALL agents return, synthesize their findings:
- Where agents agree → high confidence
- Where agents disagree → the disagreement IS the signal; investigate further
- Present the synthesis with attribution to each agent's perspective
```

## Agent Teams (Collaborative Execution)

Agent teams use Claude Code's experimental team mode (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`). Teammates share a task list, message each other, and coordinate work. A lead agent orchestrates.

**Prerequisite:** Agent teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings. The install script sets this automatically in `.claude/settings.local.json`.

**This is the collaborative model.** Teammates divide labor, share findings in real-time, and can challenge each other mid-task. Each teammate still gets a unique persona.

**When to use agent teams:**
- Parallel implementation across independent files/modules
- Large tasks that benefit from division of labor
- Cross-layer work (frontend + backend + tests) where coordination matters
- Investigations that benefit from real-time debate between agents

**Architecture:**
```
Lead (coordinator)
  ├── Teammate A (persona: frontend architect) ←→ messages ←→ Teammate B
  ├── Teammate B (persona: API designer) ←→ messages ←→ Teammate C
  └── Teammate C (persona: test engineer) ←→ messages ←→ Teammate A
      ↓
Shared task list + inter-agent messaging → coordinated output
```

**How to invoke agent teams:**

Agent teams are created through natural language — you tell Claude to form a team and describe the work. Claude uses the TeamCreate, TaskCreate, and SendMessage tools automatically. Each teammate is a full Claude Code instance that loads the project's CLAUDE.md, skills, and MCP servers.

```markdown
## Invocation Pattern (Agent Teams)

Tell the lead to create a team with specific personas and task assignments:

"Create an agent team to [describe the work]. Spawn teammates:
- [Persona A — e.g., 'a frontend architect'] to own [files/modules A]
- [Persona B — e.g., 'an API designer'] to own [files/modules B]
- [Persona C — e.g., 'a test engineer'] to own [files/modules C]
Have each teammate [describe their specific task].
Require plan approval before any teammate makes changes."

The lead will:
1. Call TeamCreate to set up the team
2. Call TaskCreate for each piece of work (with dependencies if needed)
3. Spawn teammates with the specified personas
4. Teammates claim tasks, do the work, message each other, mark complete
5. Lead synthesizes results and reports back
```

**Implementation in a SKILL.md:**

When a skill needs agent teams for a workflow step, document it like this:

```markdown
### Step N: [Team Task Description]

Form an agent team for [task]. Each teammate owns different files to avoid conflicts:

"Create an agent team to [task description]. Spawn teammates:
- [Persona A] to handle [scope A, specific files]
- [Persona B] to handle [scope B, specific files]
- [Persona C] to handle [scope C, specific files]
Have them coordinate via the shared task list. Require plan approval."

Wait for all teammates to complete before proceeding.
```

**Key differences from individual agents:**

| Aspect | Individual Agents | Agent Teams |
|--------|------------------|-------------|
| Invocation | Task tool calls (parallel) | Natural language → TeamCreate |
| Persona delivery | In the Task prompt | In the spawn prompt |
| Communication | None (isolated) | Shared mailbox + task list |
| Output collection | Each Task returns to main | Lead synthesizes |
| File editing | Read-only (evaluation) | Full read/write (implementation) |
| Permission mode | Inherits from caller | Inherits from lead |
| Session lifecycle | Single turn | Persistent until shutdown |

## Routing Decision Framework

| Signal | Use Individual Agents | Use Agent Teams |
|--------|----------------------|-----------------|
| Goal | Evaluate / judge / diagnose | Build / implement / coordinate |
| Interaction | Agents must NOT influence each other | Agents SHOULD influence each other |
| Output | Independent opinions → synthesis | Coordinated deliverable |
| File ownership | All agents read the same files | Each agent owns different files |
| Context isolation | Critical (prevents groupthink) | Not needed (collaboration is the point) |
| Persona role | Evaluative lens | Specialized contributor |

## When Agents Are Mandatory

**When a decision isn't overtly obvious and guessing is involved, agents are MANDATORY.** This is non-negotiable. If skill-builder is proposing changes, recommending structures, or making judgment calls that could reasonably go multiple ways, it must spawn agents to provide independent input before committing to a recommendation.

Examples of mandatory agent situations:
- Deciding whether to split a skill vs. keep it monolithic
- Evaluating whether a directive is best enforced by a hook, an agent, or guidance alone
- Assessing output quality where "good enough" is subjective
- Routing ambiguous user input to the correct workflow
- Any recommendation where the skill-builder would otherwise be guessing

---
*Split from agents.md by skill-builder optimize. Enforcement boundary: routing decision + invocation patterns.*
