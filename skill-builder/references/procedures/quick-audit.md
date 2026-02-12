## Quick Audit Procedure (`audit --quick`)

**Lightweight audit for iterative workflows. Skips deep structural analysis.**

When invoked with `audit --quick`:

### Step 1: Scan All Skills

Glob for `.claude/skills/*/SKILL.md`. For each skill, check ONLY:

```
| Skill | Lines | Frontmatter OK | Hooks Wired | Issues |
|-------|-------|----------------|-------------|--------|
| /skill-1 | 45 | Yes | Yes | — |
| /skill-2 | 210 | No (multi-line desc) | No | OVER LINE TARGET, BAD FRONTMATTER |
```

**Checks (per skill):**
- Frontmatter exists with single-line description
- `name` matches folder
- Line count vs 150-line target
- Hooks in `hooks/` are wired in settings.local.json
- Agent files exist and are referenced in SKILL.md

### Step 2: Check CLAUDE.md

```
CLAUDE.md: [X] lines (target: < 150) — [OK / OVER TARGET]
```

### Step 3: Output Priority Fixes

List only HIGH-priority issues in a numbered list:

```
## Priority Fixes
1. /skill-2: Frontmatter description is multi-line (gets truncated)
2. /skill-2: 210 lines — exceeds 150-line target, needs optimization
3. /skill-3: Hook validate.sh exists but is not wired in settings.local.json
```

### Step 4: Offer Immediate Execution

For each fix, offer direct execution:

> Fix these now? (y/n per item, or "all")

No sub-command display-mode pass. No structural invariant scanning. No narrative report. Just findings and fixes.
