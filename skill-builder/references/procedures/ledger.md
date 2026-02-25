## Ledger Command Procedure

**Create an Awareness Ledger companion skill for institutional memory.**

When invoked with `/skill-builder ledger`:

### Step 1: Validate

- Check that `CLAUDE.md` exists in the project root
- Check that `.claude/skills/awareness-ledger/SKILL.md` does NOT already exist
- If ledger already exists, report error: "Awareness Ledger already exists at `.claude/skills/awareness-ledger/`. Use `/awareness-ledger review` to check its health."
- If no CLAUDE.md, report error: "No CLAUDE.md found. Run `claude /init` first."

### Step 2: Create Skill Structure

Create the full awareness-ledger skill directory. In display mode, show the proposed structure. In execute mode (`--execute`), create all files.

**Directory layout:**

```
.claude/skills/awareness-ledger/
├── SKILL.md
├── references/
│   ├── templates.md
│   ├── consultation-protocol.md
│   └── capture-triggers.md
├── ledger/
│   ├── index.md
│   ├── incidents/
│   ├── decisions/
│   ├── patterns/
│   └── flows/
├── agents/
│   ├── regression-hunter.md
│   ├── skeptic.md
│   └── premortem-analyst.md
└── hooks/
    └── capture-reminder.sh
```

**SKILL.md** (~150 lines, lean):

```yaml
---
name: awareness-ledger
description: "Institutional memory for your project. Commands: record, consult, review. Usage: /awareness-ledger [command] [args]"
allowed-tools: Read, Glob, Grep, Write, Edit, Task, TaskCreate, TaskUpdate, TaskList, TaskGet
---
```

Body includes:
- Quick commands table (`record [type]`, `consult [topic]`, `review`)
- Directives section (empty, ready for user directives)
- Record command workflow (walks through template, writes to appropriate `ledger/` subdirectory, updates `ledger/index.md`)
- Consult command workflow (triage → agent spawn → synthesis → capture suggestion)
- Review command workflow (stale entries, missing links, tag drift, statistics)
- Grounding links to `references/templates.md`, `references/consultation-protocol.md`, `references/capture-triggers.md`

Use templates from `references/ledger-templates.md` for all record type formats, agent definitions, hook script, and the consultation protocol.

**references/templates.md** — Record type templates (INC/DEC/PAT/FLW) with status lifecycle, tags, related-records linking.

**references/consultation-protocol.md** — How agents query the ledger: triage rules, proportional agent spawning (one type match → one agent, multiple → full panel, empty ledger → skip), synthesis rules (agreement = HIGH confidence, disagreement = the signal), capture suggestion format.

**references/capture-triggers.md** — Conversation signals that suggest a record should be created: rollback language, decision justification, pattern recognition phrases, debugging flow documentation.

**Agent definitions** (each with `context: none`, unique persona):

| Agent File | Persona | Reads | Focus |
|------------|---------|-------|-------|
| `regression-hunter.md` | Veteran QA engineer who has seen the same bug return three times | `ledger/incidents/`, `ledger/flows/` | Past incidents & flows overlapping with current change |
| `skeptic.md` | Epistemologist who treats every assumption as a hypothesis | `ledger/decisions/`, `ledger/patterns/` | Decisions & patterns, especially counter-evidence fields |
| `premortem-analyst.md` | Risk specialist trained in Klein's premortem methodology | Full index scope | Imagines the change already failed, works backward |

**hooks/capture-reminder.sh** — PreToolUse hook on Task/Bash. Exits 0 always (awareness, not blocking). Pattern-matches tool input against capture trigger patterns (incident, decision, pattern, flow language). Only outputs when a trigger matches — stays silent otherwise, eliminating reminder fatigue. See `references/ledger-templates.md` § "capture-reminder.sh" for the template.

**ledger/index.md** — Initialized with header and empty sections for tag-based groupings, relationship map, status summary, and statistics. Updated automatically when records are added.

### Step 3: Seed the Ledger

Analyze available project history to suggest initial records (gives the ledger a starting corpus instead of cold-starting empty):

1. **Git history scan** — Read recent git log for reverts, rollbacks, and large refactors. Each revert or rollback is a candidate incident record. Each refactor is a candidate decision record.
2. **CLAUDE.md scan** — Read existing CLAUDE.md for rules, conventions, and architectural decisions. Each substantial rule is a candidate decision or pattern record.
3. **TODO/FIXME scan** — Grep for `TODO`, `FIXME`, `HACK`, `WORKAROUND` comments. Each is a candidate pattern or incident record.

For each candidate:
- Show the source evidence (git commit, CLAUDE.md line, code comment)
- Propose a record type with pre-filled template
- User confirms before writing (directives are sacred — never auto-record)

If no candidates are found, report "No seed candidates found. The ledger starts empty — records accumulate as you work." This is fine; an empty ledger has zero consultation overhead.

### Step 4: Report

```
Created Awareness Ledger:
  .claude/skills/awareness-ledger/SKILL.md ([X] lines)
  .claude/skills/awareness-ledger/references/ (3 files)
  .claude/skills/awareness-ledger/agents/ (3 agents)
  .claude/skills/awareness-ledger/hooks/ (1 hook)
  .claude/skills/awareness-ledger/ledger/ (index + 4 subdirectories)
  Seed records: [N proposed, M confirmed by user]
```

### Step 5: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the newly created awareness-ledger skill — optimize, agents, and hooks in display mode, then offer execution choices.

**Grounding:** `references/ledger-templates.md` for all record formats, agent definitions, hook script, and consultation protocol.
