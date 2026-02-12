## Inline Directive Procedure

**Quick-add a directive to a skill, then run a scoped review for optimization and enforcement opportunities.**

When invoked with `/skill-builder inline [skill] [directive text]`:

### Step 1: Validate Target Skill

```bash
Glob: .claude/skills/[skill]/SKILL.md
```

If skill doesn't exist, report error: "Skill /[skill] not found. Create it first with `/skill-builder new [skill]`."

### Step 2: Read Current SKILL.md

Read the skill's SKILL.md. Find the `## Directives` section.

- If section exists: note its location for insertion
- If section doesn't exist: it will be created after the frontmatter/title, before the first workflow section

### Step 3: Add Directive

Insert the directive verbatim:

```markdown
> **[exact text from user, verbatim]**

*— Added [today's date], source: user instruction (inline)*
```

**Rules:**
- Quote the user's exact words — never reword
- Place in the `## Directives` section
- If the section is new, create it with the `## Directives` heading

### Step 4: Report

```
Added directive to /[skill]:
> "[first 60 chars of directive]..."

Location: .claude/skills/[skill]/SKILL.md § Directives
```

### Step 5: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the target skill. The chain's hooks display mode will automatically detect enforceable patterns in the new directive and recommend hooks or agents as appropriate.
