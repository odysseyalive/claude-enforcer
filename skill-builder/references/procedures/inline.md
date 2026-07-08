## Inline Directive Procedure

**Quick-add a directive to a skill, then run a scoped review for optimization and enforcement opportunities.**

When invoked with `/skill-builder inline [skill] [directive text]`:

**Preflight — self-exclusion.** If the target skill is literally `skill-builder` AND the command was NOT invoked as `/skill-builder dev inline skill-builder …`, REFUSE. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev inline skill-builder …`". Do not proceed. See SKILL.md § Self-Exclusion Rule.

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

Insert the directive verbatim, wrapped in provenance markers:

```markdown
<!-- origin: user | added: [today's date] | immutable: true -->
> **[exact text from user, verbatim]**

*— Added [today's date], source: user instruction (inline)*
<!-- /origin -->
```

**Rules:**
- Quote the user's exact words — never reword
- Place in the `## Directives` section
- If the section is new, create it with the `## Directives` heading
- Always wrap with `origin: user` provenance markers

### Step 3b: Update Directive Checksums

After adding the directive, regenerate the `.directives.sha` sidecar file for the target skill. Follow the sidecar generation spec in [checksums.md](checksums.md) § "Execute Mode" step 2 — read SKILL.md, strip frontmatter, extract immutable blocks, normalize, hash, write sidecar. This ensures the new directive is immediately protected by the checksum hook.

### Step 4: Report

```
Added directive to /[skill]:
> "[first 60 chars of directive]..."

Location: .claude/skills/[skill]/SKILL.md § Directives
```

**Post-capture advisory (report-only):** IF the captured directive is habit-fighting (opposes an automatic model tendency; detection markers in [optimize.md](optimize.md) § Step 4d) or hinges on an abstract multi-word concept with no concrete condition, append one line to the report: prose alone may not hold; recommend `/skill-builder optimize [skill]` (generates the enforcement annotation) or `/skill-builder hooks [skill]` (hard block). `inline` itself NEVER generates annotations (templates.md Rule 7) — it only recommends the command that does. Rationale: [enforcement.md](../enforcement.md) § "Research Grounding".

### Step 5: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the target skill. The chain's hooks display mode will automatically detect enforceable patterns in the new directive and recommend hooks or agents as appropriate.
