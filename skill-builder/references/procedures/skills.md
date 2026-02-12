## Skills Command Procedure

**List all local skills available in this project.**

When invoked with `/skill-builder skills`:

1. Glob for all `.claude/skills/*/SKILL.md` files
2. Read each skill's frontmatter to extract name and description
3. Output a table of all available skills

### Output Format

```
| Skill | Description |
|-------|-------------|
| /deploy | Deploy application to staging or production |
| /api-client | API client integration and authentication |
| /db-migrate | Database migration management |
...
```

### Implementation

```bash
# Find all skills
.claude/skills/*/SKILL.md
```

For each skill file:
1. Read the frontmatter
2. Extract `name` and `description` fields
3. Format as table row: `| /[name] | [description] |`

Sort alphabetically by skill name.
