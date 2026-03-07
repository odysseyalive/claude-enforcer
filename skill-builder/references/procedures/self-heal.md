## Self-Heal Command Procedure

**Install the Self-Heal companion skill.**

When invoked with `/skill-builder self-heal`:

### Step 1: Validate

- Check that `CLAUDE.md` exists in the project root
- Check that `.claude/skills/self-heal/SKILL.md` does NOT already exist (see Step 1b for upgrade path)
- If no CLAUDE.md: report "No CLAUDE.md found. Run `claude /init` first."

### Step 1b: Upgrade Path (self-heal already exists)

If `.claude/skills/self-heal/SKILL.md` already exists, check for stale error compensation artifacts from a previous version:

**Detect stale artifacts:**
1. Check for `.claude/hooks/error-compensation-detect.sh`
2. Check for `.claude/hooks/hook-health-check.sh`
3. Check for `.claude/hooks/.crash-log` and `.claude/hooks/.crash-log.reported`
4. Check for `.claude/skills/self-heal/references/error-compensation-signals.md`
5. Check for `.claude/skills/self-heal/references/error-compensation-monitor.md`
6. Check for `.claude/skills/self-heal/agents/error-analyst.md`
7. Check `.claude/settings.local.json` for PostToolUse entries referencing `error-compensation-detect.sh` or `hook-health-check.sh`
8. Grep all `.claude/skills/*/SKILL.md` for `## Error Compensation` trigger blocks

**If any stale artifacts found:**
Report what was found and offer cleanup:
```
Self-heal is already installed, but has stale error compensation artifacts
from a previous version. Error compensation hooks have been removed — self-heal
now triggers from conversation only.

Stale artifacts found:
  [list each artifact found]

Should I clean these up?
```

**If user approves cleanup:**
1. Delete hook scripts: `.claude/hooks/error-compensation-detect.sh`, `.claude/hooks/hook-health-check.sh`
2. Delete crash logs: `.claude/hooks/.crash-log`, `.claude/hooks/.crash-log.reported`
3. Delete stale reference/agent files: `error-compensation-signals.md`, `error-compensation-monitor.md`, `error-analyst.md`
4. Remove PostToolUse entries from `.claude/settings.local.json` that reference `error-compensation-detect.sh` or `hook-health-check.sh`. If PostToolUse becomes empty, remove the key entirely. Preserve all other hook entries.
5. Strip `## Error Compensation` sections from all skills' SKILL.md files (remove from the `## Error Compensation` heading through the end of the block — typically ~10 lines ending before the next `##` or end of file)
6. Update `.claude/skills/self-heal/SKILL.md` to single-path version (from `references/self-heal-templates.md` § "self-heal SKILL.md Template")
7. Report cleanup summary

**If no stale artifacts found:**
Report: "Self-Heal already installed at `.claude/skills/self-heal/`. Use `/self-heal review` to check its health."

### Step 2: Create Skill Structure

In display mode, show the proposed structure. In execute mode (`--execute`), create all files.

**Directory layout:**

```
.claude/skills/self-heal/
├── SKILL.md
├── references/
│   ├── directive-disagreement-signals.md
│   ├── diagnosis-protocol.md
│   └── update-protocol.md
└── agents/
    ├── root-cause-analyst.md
    └── patch-reviewer.md
```

`self-heal-history.md` files are created per target skill (e.g., `.claude/skills/[target-skill]/self-heal-history.md`) when self-heal first runs diagnosis on that skill — not during install. See `references/self-heal-templates.md` § "self-heal-history.md Format" for the record format.

**SKILL.md** content — see `references/self-heal-templates.md` § "self-heal SKILL.md Template"

**references/directive-disagreement-signals.md** — How users express directive disagreements. The taxonomy of signals that trigger self-heal. Loaded by the trigger block during live sessions.

**references/diagnosis-protocol.md** — How to trace a directive disagreement back to the skill's non-directive wording. Loaded immediately when a disagreement is detected.

**references/update-protocol.md** — How to construct the before/after diff, frame the approval request, and apply the surgical update. Loaded when a fixable source is confirmed.

**agents/root-cause-analyst.md** — `context: none` agent. Reads the directive, the skill's SKILL.md, and what the user said. Determines whether the skill's non-directive wording caused the AI to misinterpret the directive. Unique persona: see `references/self-heal-templates.md` § "Agent Personas".

**agents/patch-reviewer.md** — `context: none` agent. Reads the proposed patch. Checks: is this the smallest possible change? Does it fix the root cause without introducing new ambiguity? Does it preserve all directives verbatim? Unique persona: see `references/self-heal-templates.md` § "Agent Personas".

### Step 3: Report

```
Created Self-Heal:
  .claude/skills/self-heal/SKILL.md ([X] lines)
  .claude/skills/self-heal/references/ (3 files)
  .claude/skills/self-heal/agents/ (2 agents)
  Self-heal history: created per skill on first diagnosis
```

### Step 4: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the newly created self-heal skill.

**Grounding:** `references/self-heal-templates.md` for all templates, agent definitions, and protocol content.
