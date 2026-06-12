## Local-Mode Command Procedure

**Audit project for local LLM compatibility.**

When invoked with `/skill-builder local-mode`:

### Phase 1: Audit (display mode — default)

#### Step 1: Gather Metrics

1. Glob all skills in `.claude/skills/` (exclude `skill-builder` unless `dev` prefix)
2. For each skill, count lines in `SKILL.md`
3. Count lines in project root `CLAUDE.md`
4. Grep each skill's `SKILL.md` and any `agents/` directory for agent spawning indicators:
   - `context: none` in agent files
   - `Agent` in allowed-tools
   - References to `TaskCreate` combined with subprocess patterns
5. Check for `awareness-ledger` skill specifically

#### Step 2: Classify Skills

Classify each skill into one of three categories:

| Category | Criteria |
|----------|----------|
| **Ready** | SKILL.md under 100 lines, no agent spawning, no subprocess dependencies |
| **Needs Trimming** | SKILL.md over 100 lines but no agent spawning — optimize to reduce |
| **Incompatible** | Spawns agents or depends on subprocesses — disabled in local mode |

#### Step 3: Produce Local Compatibility Report

```
## Local Compatibility Report

### Ready (X skills)
- skill-name (Y lines)

### Needs Trimming (X skills)
- skill-name (Y lines) — over 100-line limit by Z lines

### Incompatible (X skills — disabled in local mode)
- skill-name — spawns N agents
- awareness-ledger — disabled (context cost)

### CLAUDE.md
- Current: Y lines [OK | OVER LIMIT — must be under 100 lines]

### Local Infrastructure
- .claude/skills/local/SKILL.md: [installed | missing]
- .claude/hooks/detect-local-mode.sh: [installed | missing]
```

#### Step 4: Offer Execution

Present the report and offer execution choices:
- Optimize skills that need trimming
- Install local skill if missing
- Install SessionStart hook if missing

---

### Phase 2: Execute (`--execute` flag)

#### Step 1: Create Task List

Use `TaskCreate` before any file modification. One task per discrete action:

1. For each skill over 100 lines: "Optimize [skill-name] for local compatibility"
2. If CLAUDE.md over 100 lines: "Flag CLAUDE.md for trimming (manual review required)"
3. If local skill missing: "Install local skill (.claude/skills/local/)"
4. If SessionStart hook missing: "Install detect-local-mode.sh hook"

#### Step 2: Execute Tasks

For each task, sequentially:

- **Skills over 100 lines:** Run the optimize procedure in display mode for that skill. Present the optimization plan and offer execution via AskUserQuestion. Do NOT auto-execute.
- **CLAUDE.md over 100 lines:** Surface a trim recommendation with current line count and the 100-line target. List sections that could be extracted to skills. Do NOT auto-modify CLAUDE.md.
- **Install local skill:** Create `.claude/skills/local/SKILL.md` and `.claude/skills/local/references/local-constraints.md` from the repo templates.
- **Install SessionStart hook:** Create `.claude/hooks/detect-local-mode.sh` (chmod +x). Add hook registration to `.claude/settings.local.json` under `hooks.SessionStart`.

#### Step 3: Report

```
Local Mode Setup Complete:
  Skills optimized: X
  CLAUDE.md: [trimmed | flagged for manual review | OK]
  Local skill: [installed | already present]
  SessionStart hook: [installed | already present]
  Total changes: X
```

---

**Grounding:** `.claude/skills/local/references/local-constraints.md` for model specs, skill compatibility lists, and environment variable reference.
