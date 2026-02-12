## Optimize Command Procedure

**Restructure a specific skill for optimal context efficiency.**

**Special case:** If the target is `claude.md` (e.g., `/skill-builder optimize claude.md`), skip this procedure and run the **CLAUDE.md Optimization Procedure** instead (see [claude-md.md](claude-md.md)).

### Display Mode (default)

When running `/skill-builder optimize [skill]`:

1. **Read the skill's SKILL.md** and any associated files
2. **Run per-skill audit checklist:**

```
## Audit: /skill-name

**Frontmatter:**
- Has YAML frontmatter: [yes/no]
- name matches folder: [yes/no]
- description is single line: [yes/no] ← CRITICAL (multi-line gets truncated)
- Has modes/subcommands: [yes/no]
- Modes listed in description: [yes/no/N/A]

**Modes/List Support:**
- Has multiple modes: [yes/no]
- Has Modes table: [yes/no/N/A]
- Table format correct (Mode | Command | Description): [yes/no/N/A]
- Supports `/skill-name list`: [yes/no/N/A]

**Directives found:** [count]
- Are they verbatim user rules? [yes/no]
- Are they at the top? [yes/no]

**Reference material inline:** [count] tables/lists
- Should move to reference.md? [yes/no]

**Reference file status:**
- reference.md exists: [yes/no]
- Line count: [X]
- H2 sections: [count] (each >20 lines: [yes/no])
- Split recommendation: [SPLIT into references/ | KEEP single file]

**Enforcement:**
- allowed-tools: [current]
- hooks: [present/missing]
- agents: [present/missing]
- Directives enforceable by hooks? [yes/no/partial]

**Structural Invariants:** [count found]
- [list each invariant: what it is, which directive it enforces, why it cannot be changed]

**Line count:** [X] (target: < 150 excluding reference.md)
```

3. **Detect skill domain** — classify the skill before deeper analysis:

   **Content-creation skill indicators** (any 2+ of these):
   - Directives mentioning: voice, tone, style, prose, writing, conversational, overbuilt, promotional, natural, plain language
   - Workflow produces: articles, posts, drafts, descriptions, captions, newsletters, emails
   - Tools include: text-eval, voice, writing skills referenced
   - Output files are predominantly `.md`, `.mdx`, or text content

   **If content-creation skill detected:**
   - Flag in audit output: `Domain: CONTENT CREATION`
   - Recommend Voice Validator agent (HIGH priority) if not already present
   - Recommend voice directive placeholder if Directives section has no voice/style rules
   - If a `text-eval` or `voice` skill exists in the project, recommend integration

   **API/DevOps skills** (default): proceed with standard optimization.

   - Read all agent files, reference files, and any files cross-referenced by SKILL.md
   - For each directive, trace its enforcement path: how does the skill's architecture prevent this directive from being violated?
   - Flag content that enforces directives through structure rather than text. This includes but is not limited to:
     - Sequential phases or steps where ordering matters
     - Blocking gates or pre-conditions ("step X must complete before step Y")
     - Data flow dependencies (step A populates a structure that step B requires)
     - Content that appears in both SKILL.md and an agent file (declaration + implementation, not duplication)
     - Intermediate state or session variables that connect phases
     - Task tool spawn templates in agent files (these are executable specifications)
   - Also flag content that is **at risk of being misidentified as an optimization target**:
     - Verbose workflow descriptions that encode ordering constraints
     - Repeated phrasing across files that serves cross-referencing rather than redundancy
     - Agent file content that mirrors SKILL.md directives (the agent file is the enforcement mechanism)
     - Steps that appear unnecessary but exist to create a checkpoint or pause point
   - Record all structural invariants in the audit output under "Structural Invariants"
   - These items are **excluded from all optimization targets** — they must not appear in proposed changes
5. **Evaluate reference splitting** (if reference.md exists):
   - Parse all h2 sections in reference.md; record heading, line count, content domain
   - Check thresholds: file >100 lines AND 3+ h2 sections AND each section >20 lines → recommend split
   - For each section, assign an enforcement priority:
     - IDs/accounts → **HIGH** (hook + agent)
     - Mappings/categories → **HIGH** (agent)
     - Constraints/limits → **MEDIUM** (hook)
     - API docs → **LOW** (hook for deprecated endpoints)
     - Examples/theory → **NONE**
   - If under threshold, note "Reference file: KEEP single file" and proceed
6. **Identify optimization targets** per `references/optimization-examples.md`, excluding all structural invariants found in step 4
7. **Destination impact check** — For each proposed move, calculate the destination file's line count *after* the move. If any destination file would exceed the split threshold (>100 lines, 3+ h2 sections, each >20 lines), include the split as part of the same proposed changes. Do not move content into a file and leave it bloated for a second pass to discover. The optimization must be a single atomic operation: move content AND split the destination if needed.
8. **List proposed changes** (what would move to reference.md, frontmatter fixes, etc.)
   - Each proposed change must note: "Structural invariant check: CLEAR" or explain why it does not affect any invariant
   - If step 7 flagged a destination file for splitting, include the split plan here (target directory, per-file breakdown, updated grounding pointers)

```markdown
### Proposed Changes
1. [e.g., Move accounts table (lines 45-80) to reference.md]
2. [e.g., Fix frontmatter description to single line]
3. [e.g., Add grounding requirement for reference.md]
4. [e.g., Split reference.md into references/ (destination exceeds threshold after moves)]

**Estimated result:** [X] → [Y] lines
```

### Execute Mode (`--execute`)

When running `/skill-builder optimize [skill] --execute`:

1. Run display mode analysis first
2. **Generate task list from findings** using TaskCreate — one task per discrete action (e.g., "Move accounts table to reference.md", "Fix frontmatter description to single line")
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. **If reference splitting was recommended:**
   a. Create `references/` directory
   b. Split each h2 section into its own file (content copied **verbatim**) using domain-based filenames: `ids.md`, `mappings.md`, `constraints.md`, `api.md`, `examples.md`, `theory.md`. Fallback: h2 heading lowercased and hyphenated.
   c. Update grounding links in SKILL.md to point to individual files in `references/`
   d. Verify no orphaned references (every grounding link resolves to a file)
   e. Delete original `reference.md` only after verification passes
   f. Generate enforcement recommendations per split file (hook, agent, or none based on priority from step 4)
5. Report before/after line counts

**Grounding:** `references/optimization-examples.md`, `references/templates.md`
