## List Mode Procedure

**Every skill with multiple modes MUST support a `list` mode.**

When a user runs `/skill-name list`, output a clean table showing all available modes:

```
| Mode | Command | Purpose |
|------|---------|---------|
| **mode1** | `/skill-name mode1 [args]` | Brief description of what this mode does |
| **mode2** | `/skill-name mode2 [args]` | Brief description of what this mode does |
```

### Why This Matters

The `description:` field in frontmatter is limited to one line and gets truncated. Users need a way to discover all available options without reading the full SKILL.md.

### Implementation

Skills with modes should include a `## Usage` section near the top:

```markdown
## Usage

```
/skill-name [mode] [args]
```

### Modes

| Mode | Command | Description |
|------|---------|-------------|
| `mode1` | `/skill-name mode1 [args]` | What mode1 does |
| `mode2` | `/skill-name mode2 [args]` | What mode2 does |

Default mode is `[default]` if not specified.
```

### Handling `/skill-name list`

When invoked with `list` as the first argument:
1. Read the skill's SKILL.md
2. Find the Modes table
3. Output the table directly to the user

**This is a reserved mode name.** Skills should not use `list` for other purposes.

### Audit Check

When auditing skills, verify:
- Does the skill have multiple modes? → Must have a Modes table
- Is the Modes table in a consistent format? → Command + Description columns
- Does the description mention `list` if applicable? → Add to frontmatter
