## Quick Audit Procedure (`audit --quick`)

**Lightweight audit for iterative workflows. Skips deep structural analysis.**

When invoked with `audit --quick`:

### Step 0: Disclaimer Acceptance (BLOCKING)

`--quick` is still an audit: run the Disclaimer Acceptance gate from [audit.md](audit.md) § Step 0 verbatim (interactive Accept/Cancel; headless requires the `audit-disclaimer: accepted` marker, else refuse). Only after acceptance continue to Step 1.

### Step 1: Scan All Skills

**Preflight — self-exclusion.** If invoked as `/skill-builder dev audit --quick`, include `skill-builder` in the skill set. Otherwise exclude `skill-builder` from the glob result. See SKILL.md § Self-Exclusion Rule.

Glob for `.claude/skills/*/SKILL.md` (exclude `skill-builder` unless `dev` prefix). For each skill, check ONLY:

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

### Step 4: Auto-Apply Mechanical Fixes (Audit Autonomy Gate — no y/n offer)

Per the 2026-06-06 streamlined-audit directive there is no per-item question. Under the Step 0 disclaimer consent:

- **AUTO:** wire orphaned-but-existing hooks into settings; reflow multi-line frontmatter descriptions to one line (**never truncate or shorten — preserve every word**); other deterministic frontmatter fixes.
- **DEFER (listed with commands, never asked):** over-line-target findings (the fix is `optimize`, which quick never scanned for — list `/skill-builder optimize <skill> --execute`); bad-frontmatter/quarantine repairs (hand-authored files — repair instructions per templates.md § frontmatter).

No sub-command display-mode pass. No structural invariant scanning. No narrative report. Just findings, auto-applied mechanical fixes, and a deferred list. `audit --quick --review` reports only.

**Excluded from quick audit:** the Model Lane Check (full audit Step 4f) does NOT run here — it is a structural/narrative scan plus an interactive prompt, both outside the quick path's contract. Model-aware routing is surfaced only by the full `audit`.
