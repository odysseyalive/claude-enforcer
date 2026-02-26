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
- team routing: [Individual/Team/Both/N/A]
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

4b. **Agent panel: structural invariant review** — Structural invariant identification is a judgment call. Content that looks movable may be load-bearing, and content that looks load-bearing may be safely movable. Per directive: agents are mandatory when guessing is involved.

   Spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`), each with a unique persona:

   - **Agent 1** (persona: Refactoring specialist — someone who has broken production by removing "dead code") — Review the proposed invariants list. Are any items falsely flagged as invariant when they're safely movable?
   - **Agent 2** (persona: Defensive architect — someone who designs systems that survive maintenance by strangers) — Review the proposed optimization targets. Are any items falsely considered movable when they're actually load-bearing?
   - **Agent 3** (persona: Skill author's advocate — someone who asks "would the original author recognize this as equivalent?") — Review both lists. Does the overall restructuring preserve the skill's observable behavior?

   Each agent reads the skill's SKILL.md, the proposed invariants, and the proposed targets. They return independent findings. Synthesize:
   - Where all 3 agree → proceed with confidence
   - Where agents disagree → the disputed item stays as an invariant (safe default)

4c. **Detect Awareness Ledger relevance** — Check if `.claude/skills/awareness-ledger/` exists and has records. If it does:

   - Read `ledger/index.md` and scan for tags that overlap with the skill's domain (file paths, function names, component names referenced in the skill's SKILL.md)
   - If relevant records exist, add to the audit output:
     ```
     **Awareness Ledger:**
     - Ledger installed: yes
     - Records matching this skill's domain: [count]
     - Record types: [INC: N, DEC: N, PAT: N, FLW: N]
     - Recommendation: [Add grounding link to relevant ledger records / No action needed]
     ```
   - If the skill's SKILL.md doesn't already reference the awareness-ledger, and matching records exist, recommend adding a grounding note: "Consult the Awareness Ledger for historical context before modifying [domain area]. See `.claude/skills/awareness-ledger/ledger/`."
   - If the project's CLAUDE.md does not already reference the awareness ledger (grep for "awareness ledger" or "ledger/index.md"), and the ledger has records, recommend adding the CLAUDE.md Integration Line from `references/ledger-templates.md` § "CLAUDE.md Integration Line". This provides baseline awareness across all conversations, not just when the skill is loaded.
   - If the skill being optimized IS the awareness-ledger itself, verify its SKILL.md contains the auto-activation directives (both READ auto-consultation and WRITE auto-capture). Check for keywords: "Auto-Consultation" and "Auto-Capture Suggestion". If missing, flag: "Awareness-ledger SKILL.md is missing auto-activation directives. Recommend adding READ (auto-consultation) and WRITE (auto-capture) workflows from `references/ledger-templates.md` § Auto-Activation Directives."
   - If `consult-before-edit.sh` exists in the awareness-ledger's `hooks/` directory, flag as obsolete: "consult-before-edit.sh fires at edit time — too late for consultation to shape the plan. Remove it. Ledger consultation is handled by the CLAUDE.md Integration Line and READ auto-activation directive during the planning phase."
   - If `capture-reminder.sh` fires on every Task completion without trigger pattern matching (grep for the generic "If findings, decisions, or patterns emerged" message), flag as: "capture-reminder.sh is outdated. Enhanced template available with trigger-pattern matching — run `/skill-builder hooks awareness-ledger` for upgrade recommendations."
   - If the skill has directives that encode historical knowledge (phrases like "because last time," "we learned that," "after the X incident"), flag these as candidates for ledger record capture if not already captured.
   - If the ledger does not exist or is empty, skip this step silently.

4d. **Detect Capture Integration gap** — Check if the skill produces institutional knowledge that should be captured in the awareness ledger. Only evaluate if `.claude/skills/awareness-ledger/` exists.

   **Positive indicators** (skill produces capturable knowledge — any 2+ of these):
   - Workflow includes investigation, diagnosis, or root cause analysis steps
   - Skill produces decisions with rationale (chose X because Y)
   - Output includes debugging flows, error resolution paths, or architectural evaluation
   - Directives reference past failures or learned patterns ("because last time," "we learned that")
   - Skill operates on areas with existing ledger records (overlapping tags/file paths)

   **Negative indicators** (capture not relevant — any 1 of these):
   - Skill is purely mechanical (formatting, linting, file manipulation)
   - Skill output is ephemeral (status reports, one-time lookups)
   - Skill already has a capture mechanism (check for: capture workflow step in SKILL.md, Capture Recommender agent in `agents/`, or `capture-reminder.sh` hook in `hooks/`)

   If positive indicators present and no negative indicators apply:
   - Add to the audit output:
     ```
     **Capture Integration:**
     - Produces institutional knowledge: yes
     - Existing capture mechanism: [workflow step / agent / hook / NONE]
     - Recommendation: [Add post-workflow capture prompt / No action needed]
     ```
   - Recommend adding a post-workflow capture step to SKILL.md that references the trigger patterns and Capture Opportunity format from `references/ledger-templates.md` § "Capture Trigger Patterns" and § "Capture Opportunity"
   - **Capture mechanism hierarchy:** workflow step (zero cost, recommended by `optimize`) > Capture Recommender agent (recommended by `agents`) > post-action reminder hook (recommended by `hooks`). Only recommend the workflow step here — the other mechanisms are recommended by their respective procedures, which check for existing mechanisms before recommending.

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

5b. **Agent panel: split decision** (if reference.md is near the threshold) — When the file is close to the splitting threshold (e.g., 80-120 lines, or 2-3 sections), the decision isn't clear-cut. Spawn 2 individual agents:

   - **Agent 1** (persona: Context efficiency engineer — optimizes for minimal token load per invocation) — Argue for splitting. What enforcement boundaries would splitting create?
   - **Agent 2** (persona: Simplicity advocate — resists premature abstraction) — Argue for keeping. Is the overhead of multiple files worth it for this skill?

   Synthesize their arguments and present both sides in the report. If the file clearly exceeds thresholds, skip this panel — the decision is obvious.

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
6. **Post-optimize: Self-Heal Observer check**
   - Check if self-heal is installed (`.claude/skills/self-heal/SKILL.md` exists)
   - Check if the optimized skill already has the Observer Instruction Block (grep for "Self-Heal Observer")
   - If self-heal installed AND observer missing → embed the Observer Instruction Block (from `references/self-heal-templates.md` § "Observer Instruction Block") as the last section
   - If self-heal installed AND observer present → verify it's still the last section; if optimization moved it, move it back
   - If self-heal not installed → skip silently
   - **Compound infrastructure check:** When embedding, verify combined infrastructure (observer + runtime eval protocol, if present) does not exceed 50 lines. If it does, flag to user. Also check the target skill's `self-heal-history.md` — if recent patches modified instructions that the eval rubric covers, flag: "Self-heal patched this skill recently. Eval rubric calibration may need review."

**Grounding:** `references/optimization-examples.md`, `references/templates.md`
