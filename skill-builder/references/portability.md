# Portability / Transmutability

This skill is designed to be copied to any Claude Code installation.

## Installing in Another Account

```bash
# Copy entire skill-builder directory
cp -r .claude/skills/skill-builder ~/.claude/skills/

# Or for project-level
cp -r .claude/skills/skill-builder /path/to/project/.claude/skills/
```

## Converting Existing Rules to Skills

When imported to a new account, run: `/skill-builder audit`

**Workflow:**

1. **Scan for existing instructions**
   - Read `CLAUDE.md` for inline rules
   - Read `.claude/rules/*.md` for rule files
   - Read any existing `.claude/skills/`

2. **Identify directive candidates**
   Look for patterns like:
   - "Never...", "Always...", "Do not..."
   - "IMPORTANT:", "CRITICAL:", "WARNING:"
   - Conditional rules: "If X, then Y"
   - Workflow descriptions

3. **Extract and quote verbatim**
   ```markdown
   ## Directives

   > **[Exact text from CLAUDE.md or rules file]**

   *— Migrated from [source file], line [X]*
   ```

4. **Separate reference material**
   Move ID tables, API docs, configuration to `reference.md`

5. **Create enforcement hooks**
   For any directive that can be validated programmatically

## Conversion Example

**Before (in CLAUDE.md):**
```markdown
## API Integration Rules
- Always use the helper script for tokens: `./scripts/api-token.sh`
- Never call OAuth endpoint directly for each request
- Organization ID is always 123456789

### Account IDs
| Account | ID |
|---------|-----|
| Primary | 12345 |
```

**After (as skill):**

`SKILL.md`:
```markdown
## Directives

> **Always use the helper script for tokens: `./scripts/api-token.sh`**
> **Never call OAuth endpoint directly for each request.**

*— Migrated from CLAUDE.md, API Integration Rules section*

## Grounding

Before any API call, state: "I will use org ID [X], found in reference.md"

See [reference.md](reference.md) for IDs.
```

`reference.md`:
```markdown
# API Reference

Organization ID: 123456789

## Account IDs
| Account | ID |
|---------|-----|
| Primary | 12345 |
```
