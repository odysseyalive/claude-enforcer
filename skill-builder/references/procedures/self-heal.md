## Self-Heal Command Procedure

**Install the Self-Heal companion skill.**

When invoked with `/skill-builder self-heal`:

### Step 1: Validate

- Check that `CLAUDE.md` exists in the project root
- Check that `.claude/skills/self-heal/SKILL.md` does NOT already exist
- If self-heal already exists: report "Self-Heal already installed at `.claude/skills/self-heal/`. Use `/self-heal review` to check its health."
- If no CLAUDE.md: report "No CLAUDE.md found. Run `claude /init` first."

### Step 2: Create Skill Structure

In display mode, show the proposed structure. In execute mode (`--execute`), create all files.

**Directory layout:**

```
.claude/skills/self-heal/
├── SKILL.md
├── references/
│   ├── directive-disagreement-signals.md
│   ├── diagnosis-protocol.md
│   ├── update-protocol.md
│   ├── error-compensation-signals.md
│   └── error-compensation-monitor.md
├── agents/
│   ├── root-cause-analyst.md
│   ├── error-analyst.md
│   └── patch-reviewer.md
└── (hook installed separately — see below)
```

**Hook files (installed to project root):**

```
.claude/hooks/
└── error-compensation-detect.sh
```

`self-heal-history.md` files are created per target skill (e.g., `.claude/skills/[target-skill]/self-heal-history.md`) when self-heal first runs diagnosis on that skill — not during install. See `references/self-heal-templates.md` § "self-heal-history.md Format" for the record format.

**SKILL.md** content — see `references/self-heal-templates.md` § "self-heal SKILL.md Template"

**references/directive-disagreement-signals.md** — How users express directive disagreements. The taxonomy of signals that trigger self-heal. Loaded by the trigger block during live sessions.

**references/diagnosis-protocol.md** — How to trace a directive disagreement back to the skill's non-directive wording. Loaded immediately when a disagreement is detected.

**references/update-protocol.md** — How to construct the before/after diff, frame the approval request, and apply the surgical update. Loaded when a fixable source is confirmed.

**references/error-compensation-signals.md** — What qualifies as compensated error worth diagnosing. Defines compensation patterns vs. noise. Loaded when the error compensation hook fires.

**references/error-compensation-monitor.md** — The full error compensation protocol. Loaded fresh when the AI finds a workaround after a hook-detected error. Steps: capture compensation, classify gap, spawn error-analyst, spawn patch-reviewer, present diff, apply with approval.

**agents/root-cause-analyst.md** — `context: none` agent. Reads the directive, the skill's SKILL.md, and what the user said. Determines whether the skill's non-directive wording caused the AI to misinterpret the directive. Unique persona: see `references/self-heal-templates.md` § "Agent Personas".

**agents/error-analyst.md** — `context: none` agent. Reads the error, the workaround, and the skill's workflow. Determines whether the error reveals a skill gap (SKILL_GAP) or is transient (TRANSIENT). Biased toward TRANSIENT — most errors are environmental noise. Unique persona: see `references/self-heal-templates.md` § "Error Analyst Agent Persona".

**agents/patch-reviewer.md** — `context: none` agent. Reads the proposed patch. Checks: is this the smallest possible change? Does it fix the root cause without introducing new ambiguity? Does it preserve all directives verbatim? For error compensation patches, also checks generality and bloat risk. Unique persona: see `references/self-heal-templates.md` § "Agent Personas".

### Step 2b: Install Error Compensation Hook

Create the hook script and add the hook configuration:

1. Create `.claude/hooks/` directory if it doesn't exist
2. Write `.claude/hooks/error-compensation-detect.sh` from `references/self-heal-templates.md` § "Error Compensation Hook Script Template"
3. Make the script executable (`chmod +x`)
4. Add the PostToolUse hook configuration to `.claude/settings.local.json` — merge into existing hooks if present, do not overwrite

See `references/self-heal-templates.md` § "Error Compensation Hook Script Template" for the hook config JSON and script content.

### Step 3: Report

```
Created Self-Heal:
  .claude/skills/self-heal/SKILL.md ([X] lines)
  .claude/skills/self-heal/references/ (5 files)
  .claude/skills/self-heal/agents/ (3 agents)
  .claude/hooks/error-compensation-detect.sh (hook installed)
  PostToolUse hook added to .claude/settings.local.json
  Self-heal history: created per skill on first diagnosis
```

### Step 4: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the newly created self-heal skill.

**Grounding:** `references/self-heal-templates.md` for all templates, agent definitions, and protocol content.
