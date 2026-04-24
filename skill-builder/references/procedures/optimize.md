## Optimize Command Procedure

**Restructure a specific skill for optimal context efficiency.**

**Special case:** If the target is `claude.md` (e.g., `/skill-builder optimize claude.md`), skip this procedure and run the **CLAUDE.md Optimization Procedure** instead (see [claude-md.md](claude-md.md)).

**Preflight — self-exclusion.** If the target skill is literally `skill-builder` AND the command was NOT invoked as `/skill-builder dev optimize skill-builder`, REFUSE. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev optimize skill-builder`". Do not proceed. See SKILL.md § Self-Exclusion Rule.

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

**Annotation Status (Opus 4.7):**
- Total directives: [N]
- HARD (already 4.7-compatible): [count] — list by first few words
- SOFT (need enforcement annotation): [count] — list by first few words, with one-line reason each ("relies on inference of X", "subjective term Y", etc.)
- Existing annotations found: [count] — list the directive each annotation covers

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
   - Recommend voice directive placeholder if Directives section has no voice/style rules
   - Text Evaluation agent pair is recommended by the `agents` procedure only when the skill **already has voice/style directives** — do not speculatively recommend it here

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

4b. **Agent panel: structural invariant review** *(opt-in. Skipped by default. Auto-fires only when auto-trigger conditions below are met, or whenever the user passes `--deliberate`.)*

   Auto-trigger conditions (any one activates the panel):
   1. The proposed-invariants list and the proposed-optimization-targets list overlap on ≥1 item (genuine ambiguity about whether a piece of content is load-bearing).
   2. Step 4 detected a structural invariant that also matches an optimization-target pattern (e.g., a numbered workflow step in `origin: skill-builder | modifiable: true` content that encodes ordering).
   3. The proposed move relocates content that is referenced from another skill (cross-skill dependency).
   4. The skill frontmatter sets `strictness: thorough`.

   If neither auto-triggered nor `--deliberate`, proceed to step 4c with the mechanically-derived invariants list as final.

   When the panel does fire, spawn 3 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`), each with a unique persona:

   - **Agent 1** (persona: Refactoring specialist, someone who has broken production by removing "dead code"). Review the proposed invariants list. Are any items falsely flagged as invariant when they're safely movable?
   - **Agent 2** (persona: Defensive architect, someone who designs systems that survive maintenance by strangers). Review the proposed optimization targets. Are any items falsely considered movable when they're actually load-bearing?
   - **Agent 3** (persona: Skill author's advocate, someone who asks "would the original author recognize this as equivalent?"). Review both lists. Does the overall restructuring preserve the skill's observable behavior?

   Each agent reads the skill's SKILL.md, the proposed invariants, and the proposed targets. They return independent findings. Synthesize:
   - Where all 3 agree, proceed with confidence.
   - Where agents disagree, the disputed item stays as an invariant (safe default).

4c. **Identify user directives** — User directives are identified by the `## Directives` section heading and blockquote format (`> **"..."**`). During optimization, preserve all directive text verbatim — never reword, compress, or remove user directives. Generated sections (workflow, grounding, etc.) can be freely restructured.

4d. **Directive Annotation Scan (Opus 4.7)** — For each directive identified in step 4c, classify HARD vs. SOFT and decide whether an enforcement annotation is needed.

   Classification criteria:
   - **HARD** (4.7-compatible, no annotation needed):
     - Names specific IDs, values, regex patterns, or concrete objects ("Never use Uncategorized accounts")
     - Concrete never/always rules with measurable conditions ("Always use `rg` instead of `grep`")
     - Explicit numbered steps with STOP/CONTINUE gates
     - Boolean checks with deterministic outcomes
   - **SOFT** (needs annotation):
     - Uses subjective terms: "appropriate", "clean", "organize around", "when needed", "naturally", "conversational"
     - Relies on inference: "keep it X", "structure so that Y", "only when it makes sense"
     - Conditional language without concrete criteria ("if applicable", "when warranted")
     - Voice/tone/style rules (almost always SOFT on 4.7 — these were 4.6's strength)

   For each SOFT directive:
   1. Check whether an existing enforcement annotation is present below the directive (look for `<!-- ENFORCEMENT ANNOTATION — auto-generated` marker and a matching `<!-- Source directive: -->` line). If present and the `Source directive` string matches the current directive verbatim, note "annotation exists, current" — no action needed.
   2. If an annotation exists but the `Source directive` string does NOT match (directive has since been edited), note "annotation stale — regenerate".
   3. If no annotation exists, note "annotation missing — generate".

   For each HARD directive: note "No annotation needed — directive is 4.7-compatible".

   Record the classification and annotation status in the audit checklist output under **Annotation Status (Opus 4.7)**. Do NOT generate annotations in display mode — only flag them. Annotations are generated in Execute Mode as tasks.

   Reference format: [templates.md](../templates.md) § "Enforcement Annotation Template".

4d'. **Agent panel: directive classification** *(opt-in. Skipped by default. Auto-fires only when auto-trigger conditions below are met, or whenever the user passes `--deliberate`.)*

   Auto-trigger conditions (any one activates the panel):
   1. At least one directive matches both a HARD marker (concrete ID, regex, boolean check, measurable never/always condition) AND a SOFT marker (subjective term from the list, inference-dependent phrasing, conditional without concrete criteria) from the 4d rubric — genuine classification ambiguity within a single directive.
   2. At least one directive's wording matches neither the HARD nor the SOFT pattern lists cleanly — outside the rubric and not mechanically classifiable.
   3. The skill frontmatter sets `strictness: thorough`.

   If neither auto-triggered nor `--deliberate`, proceed to step 4e with the mechanical HARD/SOFT classifications from step 4d as final.

   When the panel does fire, spawn 2 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`), each with a unique persona per the Persona Assignment Gate in SKILL.md. Before spawning, confirm the two personas do not duplicate each other and do not duplicate any existing persona under `.claude/skills/*/agents/*/AGENT.md` (glob and check).

   - **Agent 1** (persona: "Enforcement pragmatist who has watched 4.7 silently under-execute directives that looked specific enough"). Argue for SOFT classification on each ambiguous or outside-rubric directive. The cost of an unnecessary annotation is token overhead on every invocation; the cost of a missing annotation is silent directive under-execution. For ambiguous wording, which asymmetric cost should win?
   - **Agent 2** (persona: "Annotation minimalist who resists boilerplate CHECKPOINTs on rules that are already concrete"). Argue for HARD classification on each ambiguous or outside-rubric directive. Every annotation compounds per invocation — which of these directives is concrete enough that a CHECKPOINT block would be pure overhead?

   Each agent reads the skill's SKILL.md (for the directive list with surrounding context), the 4d rubric, and the list of ambiguous/outside-rubric directives flagged by the auto-trigger. Agents return per-directive classification verdicts with one-line reasoning. Synthesize per directive:
   - Where the two agents agree → adopt the agreed classification.
   - Where the two agents disagree → default to **SOFT** (safer — the asymmetric cost of silent under-execution on 4.7 outweighs the token overhead of an unnecessary CHECKPOINT, and an unnecessary annotation is easier to remove later than a missing one is to notice).

   Record panel outcomes in the audit checklist output. Append a line under **Annotation Status (Opus 4.7)** naming whether the panel fired, which directives it reclassified, and the synthesis reasoning for any disagreements.

4e. **Token Efficiency Scan (Opus 4.7)** — Scan for token-intensive patterns that compound across invocations. On-by-default in `/skill-builder audit` and `/skill-builder optimize [skill]`. Apply detection rules from [token-efficiency.md](../token-efficiency.md) § "Detection Patterns":

   - **P1 — Agent-type hook doing mechanical work.** Read SKILL.md frontmatter `hooks:` and settings.local.json `hooks:`. For each `type: agent` entry, read the prompt. Flag as mechanical if the prompt is dominated by pattern-match or byte-comparison verbs (extract/compare, grep, find matching, check marker count). Record the hook name and what it checks.
   - **P2 — xhigh effort without content-creation profile.** If the frontmatter sets `minimum-effort-level: xhigh` AND the skill failed the content-creation profile check in step 3, flag for downgrade to `high`.
   - **P3 — SKILL.md oversized with stable machinery.** Count total lines. Count lines inside `<!-- origin: skill-builder | ... modifiable: true -->` blocks that do not reference user directives. If total > 150 AND machinery > 30, flag for principles.md-style extraction.
   - **P4 — Always-spawned validator.** In Execute Mode procedure steps, find every unconditional Task-tool or context-none agent spawn. Check whether the preceding step is a deterministic precheck. If not, flag the spawn for precheck gating.
   - **P5 — Missing strictness field.** Check frontmatter for `strictness:`. If absent, flag for addition of `strictness: standard`.

   Record results in the audit checklist output under the **Token Efficiency** block (format specified in [token-efficiency.md](../token-efficiency.md) § "Scan Output Template"). Do NOT apply fixes in display mode; flag only. Execute Mode converts each flagged pattern into a task per [token-efficiency.md](../token-efficiency.md) § "Execute Mode Task Generation".

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

5b. **Agent panel: split decision** *(opt-in. Skipped by default. Auto-fires only when the reference file is genuinely near the threshold, or whenever the user passes `--deliberate`.)*

   Auto-trigger conditions:
   1. reference.md is in the borderline band (80 to 120 lines, OR 2 to 3 h2 sections where each section is between 15 and 30 lines). Outside the borderline band, the mechanical threshold check from step 5 is decisive and no panel is needed.
   2. The skill frontmatter sets `strictness: thorough`.

   If neither auto-triggered nor `--deliberate`, proceed to step 6 with the mechanical split recommendation from step 5 as final.

   When the panel does fire, spawn 2 individual agents:

   - **Agent 1** (persona: Context efficiency engineer, optimizes for minimal token load per invocation). Argue for splitting. What enforcement boundaries would splitting create?
   - **Agent 2** (persona: Simplicity advocate, resists premature abstraction). Argue for keeping. Is the overhead of multiple files worth it for this skill?

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
2. **Generate task list from findings** using TaskCreate — one task per discrete action (e.g., "Move accounts table to reference.md", "Fix frontmatter description to single line"). Include:
   - One task per directive flagged in step 4d with status "annotation missing — generate" or "annotation stale — regenerate". Each annotation task writes a CHECKPOINT block directly beneath the sacred `<!-- /origin -->` close marker of the directive it covers, following the format in [templates.md](../templates.md) § "Enforcement Annotation Template".
   - One task per token-efficiency pattern flagged in step 4e, following the task templates in [token-efficiency.md](../token-efficiency.md) § "Execute Mode Task Generation" (P1 hook downshift, P2 effort downgrade, P3 machinery extraction, P4 precheck gate, P5 strictness field).
3. Execute each task sequentially, marking complete via TaskUpdate as it goes
4. **If reference splitting was recommended:**
   a. Create `references/` directory
   b. Split each h2 section into its own file (content copied **verbatim**) using domain-based filenames: `ids.md`, `mappings.md`, `constraints.md`, `api.md`, `examples.md`, `theory.md`. Fallback: h2 heading lowercased and hyphenated.
   c. Update grounding links in SKILL.md to point to individual files in `references/`
   d. Verify no orphaned references (every grounding link resolves to a file)
   e. Delete original `reference.md` only after verification passes
   f. Generate enforcement recommendations per split file (hook, agent, or none based on priority from step 4)
5. Report before/after line counts
5b. **Post-optimize: Semantic equivalence verification (precheck first)**
    1. **Mechanical precheck.** Compare pre-optimize SKILL.md (`git show HEAD:.claude/skills/[skill]/SKILL.md`) against the current file. Verify all of:
       - Every `<!-- origin: user[^>]* immutable: true -->` ... `<!-- /origin -->` block is byte-identical pre vs. post.
       - The set of numbered workflow step headers appears in the same relative order.
       - Every section moved OUT of SKILL.md appears verbatim in a reference file under `references/`.
       - No content was both moved AND modified in the same operation.
    2. IF all precheck conditions pass, mark PASS and skip the agent spawn. Proceed to step 5c.
    3. IF any precheck condition fails, spawn the optimize-diff-auditor agent (`context: none`, see `.claude/skills/skill-builder/agents/optimize-diff-auditor/AGENT.md`). Provide the agent with the specific precheck condition that failed so it can focus its analysis.
    4. If the agent returns FAIL, present violations to user with revert option (`git checkout`). If PASS, proceed to step 5c.
5c. **Post-optimize: Regenerate directive checksums**
    Regenerate the `.directives.sha` sidecar following the spec in `references/procedures/checksums.md` § "Execute Mode" step 2.
    This confirms directives survived intact and updates the sidecar for continued protection.

**Grounding:** `references/optimization-examples.md`, `references/templates.md`
