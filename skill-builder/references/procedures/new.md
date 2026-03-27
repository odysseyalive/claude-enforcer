## New Command Procedure

**Create a new skill from template, then auto-chain a scoped review.**

When invoked with `/skill-builder new [name]`:

### Step 1: Validate Name

- Check that `[name]` uses lowercase alphanumeric + hyphens only (e.g., `my-skill`)
- Check that `.claude/skills/[name]/SKILL.md` does NOT already exist
- If skill already exists, report error: "Skill /[name] already exists. Use `/skill-builder optimize [name]` to restructure it."
- If name format is invalid, report error: "Skill names must be lowercase alphanumeric with hyphens (e.g., `my-skill`)."

### Step 2: Detect Domain

Classify the skill before selecting a template:

**Content-creation skill indicators** (any 2+ of these in the name or user context):
- Name suggests writing/content: `writing`, `blog`, `newsletter`, `email`, `content`, `copy`, `voice`, `editorial`
- User describes output as: articles, posts, drafts, descriptions, captions, newsletters, emails
- User mentions: tone, voice, style, prose

**If content-creation detected:** use the standard template with a voice directive placeholder added to the Directives section. Do not embed Text Evaluation agent pair or temporal hooks — the agents procedure will recommend Text Eval when the skill already has voice/style directives, and the hooks procedure will recommend temporal validation when the workflow actually produces date-sensitive citations.

**Otherwise:** use standard template.

### Step 3: Create Skill Files

Using templates from `references/templates.md`:

1. Create directory: `.claude/skills/[name]/`
2. Create `SKILL.md` from template with:
   - Frontmatter: `name`, `description` (single-line), `allowed-tools`
   - `## Directives` section (empty, ready for population)
   - Grounding link to reference.md
3. Create `reference.md` (minimal placeholder)
4. If content-creation domain: add voice directive placeholder to the Directives section

### Step 3b: Note Companion Skill Availability

Check if `.claude/skills/awareness-ledger/` exists. If it does:

1. Note in the creation report: "Awareness Ledger available — audit will recommend integration if relevant to this skill's domain."
2. Do **not** auto-embed ledger grounding into the new skill. Integration recommendations belong in the audit, scoped to skills whose domain overlaps with ledger records.

If the ledger does not exist, skip this step silently.

### Step 3d: Generate Directive Checksums

If the new SKILL.md includes directives (user-provided during creation), generate the `.directives.sha` sidecar file following the spec in [checksums.md](checksums.md) § "Execute Mode" step 2. If no directives yet, skip (no sidecar needed).

### Step 4: Report Creation

```
Created skill /[name]:
  .claude/skills/[name]/SKILL.md ([X] lines)
  .claude/skills/[name]/reference.md ([Y] lines)
  Domain: [standard / content-creation]
  Awareness Ledger: [available — audit will recommend if relevant / not installed]
```

### Step 5: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the newly created skill.

**Grounding:** `references/templates.md`
