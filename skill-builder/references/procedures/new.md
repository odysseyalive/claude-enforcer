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

**If content-creation detected:** use content-creation template variant (includes Voice Validator agent placeholder and voice directive placeholder).

**Otherwise:** use standard template.

### Step 3: Create Skill Files

Using templates from `references/templates.md`:

1. Create directory: `.claude/skills/[name]/`
2. Create `SKILL.md` from template with:
   - Frontmatter: `name`, `description` (single-line), `allowed-tools`
   - `## Directives` section (empty, ready for population)
   - Grounding link to reference.md
3. Create `reference.md` (minimal placeholder)
4. If content-creation domain: add voice directive placeholder and note about Voice Validator agent

### Step 3b: Embed Ledger Awareness

Check if `.claude/skills/awareness-ledger/` exists. If it does:

1. Add a **Grounding** section to the new skill's SKILL.md (or append to existing Grounding section):
   ```markdown
   ## Project Memory

   Before recommending changes to files in this skill's domain, check
   `.claude/skills/awareness-ledger/ledger/index.md` for relevant records.
   If matching records exist, read them and incorporate their warnings,
   decisions, and patterns into your plan. Use `/awareness-ledger consult`
   for full agent-assisted analysis when high-risk overlap is detected.

   After resolving issues that produce institutional knowledge (root causes,
   architectural decisions, recurring patterns, user flows), ask the user
   if they want to record it with `/awareness-ledger record [type]`.
   ```
2. This ensures every new skill starts with ledger integration built in, rather than relying on the post-action chain to recommend adding it after the fact.

If the ledger does not exist, skip this step silently.

### Step 3d: Embed Self-Heal Observer

Check if `.claude/skills/self-heal/SKILL.md` exists. If it does:

1. Append the Observer Instruction Block (from `references/self-heal-templates.md` § "Observer Instruction Block") to the new skill's SKILL.md
2. Verify total line count stays under 150. If over, flag: "Skill is [N] lines with observer embedded. Consider optimizing before adding more content."
3. **Compound infrastructure check:** If the skill also has a runtime eval protocol section, verify combined infrastructure (observer + eval protocol) does not exceed 50 lines. If it does, flag to the user and recommend optimizing the skill first.
4. Add to creation report: `Self-heal observer: embedded`

If self-heal is not installed:
1. Skip silently — do not recommend installation here
2. The audit orchestrator is responsible for surfacing the gap

### Step 4: Report Creation

```
Created skill /[name]:
  .claude/skills/[name]/SKILL.md ([X] lines)
  .claude/skills/[name]/reference.md ([Y] lines)
  Domain: [standard / content-creation]
  Ledger integration: [embedded / not installed]
  Self-heal observer: [embedded / not installed]
```

### Step 5: Run Post-Action Chain

Run the **Post-Action Chain Procedure** (see [post-action-chain.md](post-action-chain.md)) for the newly created skill.

**Grounding:** `references/templates.md`
