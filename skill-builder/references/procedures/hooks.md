## Hooks Command Procedure

**Inventory existing hooks and identify new enforcement opportunities.**

**Preflight — self-exclusion.** Detect invocation form:
- Invoked as `/skill-builder dev hooks …` → skill-builder may be targeted or iterated normally
- Invoked as `/skill-builder hooks skill-builder` → REFUSE. Say: "skill-builder is excluded from its own actions. Use `dev` prefix: `/skill-builder dev hooks skill-builder`". Do not proceed.
- Invoked as `/skill-builder hooks` (all skills, no target) → exclude `skill-builder` from any `.claude/skills/*/SKILL.md` and `.claude/skills/**/hooks/*.sh` glob

See SKILL.md § Self-Exclusion Rule.

When running `/skill-builder hooks` (all skills) or `/skill-builder hooks [skill]` (specific skill):

### Display Mode (default)

#### Step 1: Inventory Existing Hooks

Scan for hook scripts and their wiring:

```
1. Glob for .claude/skills/**/hooks/*.sh
2. Read .claude/settings.json AND .claude/settings.local.json → hooks section (merge; both contribute wiring)
3. Cross-reference: which scripts are wired, which are orphaned, which wired entries point at missing files
```

#### Step 2: Validate Existing Hooks

**Delegation:** the shell-level pitfall checks (path quoting, ERR trap, `set -e`, defensive I/O, stdin parsing) are owned by skill-builder's `shell-safety` subcommand (see [shell-safety.md](shell-safety.md)). Run `/skill-builder shell-safety audit .claude/settings*.json .claude/skills/*/hooks/` and merge its findings into this report rather than duplicating the rule logic here.

| Check | What to Verify | Owned By |
|-------|----------------|----------|
| **Wired** | Listed in settings.local.json `hooks` section | this procedure |
| **Matcher** | Correct tool matcher (Bash, Edit, etc.) | this procedure |
| **Exit codes** | Uses `exit 2` to block, `exit 0` to allow | this procedure |
| **Reads stdin** | Captures `INPUT=$(cat ...)` for tool input | shell-safety R5 |
| **Permission** | Script is executable (`chmod +x`) | this procedure |
| **Error output** | Writes block reason to stderr (`>&2`) | this procedure |
| **Hardened** | Has ERR trap (shell-safety R3) | shell-safety P3 |
| **No set -e** | Does NOT use `set -e` (shell-safety R4) | shell-safety P4 |
| **Defensive I/O** | Uses `2>/dev/null` and `|| exit 0` on fallible ops | shell-safety R5/R7 |
| **Path-safe quoting** | Command string wraps `$CLAUDE_PROJECT_DIR` in escaped double quotes (shell-safety R1+R2+R8). Unquoted commands fail silently when CWD ≠ project root or path contains whitespace. | shell-safety P1/P2 |

Unhardened hooks should be flagged as: "Hook lacks defensive hardening — see `skill-builder/references/shell-safety/rules.md` § R3 and templates T1/T2."

#### Step 2.5: Analyze Dead Wiring

Step 1 surfaces wired entries whose referenced files do not exist. This step enriches each one with intent, criticality, and recoverability so the Step 4 report can make a concrete recommendation instead of just listing the broken path.

Dead wiring is non-blocking by default (Claude Code logs `PreToolUse:Bash hook error` / `Failed with non-blocking status code` and proceeds), but each matching tool call prints the warning and the protection the hook was meant to provide is gone — silent loss of enforcement on load-bearing hooks is worse than the log noise.

**Flag:** `--no-git` skips the git recoverability check (one `git log` per missing file). On by default.

For each wired entry where the referenced file is missing:

1. **Parse the entry** — extract absolute path (resolve `$CLAUDE_PROJECT_DIR` against the current project root), event (PreToolUse / PostToolUse / PostCompact / SessionStart / etc.), matcher (Bash / Edit / Write / "Edit|Write" / etc.), and owning skill (from the `.claude/skills/[skill]/hooks/...` path segment — or `<project-level>` if the path is under `.claude/hooks/` rather than a skill directory).

2. **Infer intent** — best source wins:
   - (a) Read the owning skill's `SKILL.md`. If any directive, workflow step, table row, or comment references the hook filename (with or without `.sh`) or the concept it names (credentials, deploy, dark-mode, voice, citations, etc.), use the matched directive text as the intent. Include a short quote.
   - (b) Read the owning skill's frontmatter `hooks:` block for any declaration referencing the same filename. If present, its `statusMessage` or nearby comment is the intent.
   - (c) Fallback: derive from filename. Examples: `no-credentials.sh` → "Block credential leakage", `check-deploy-commands.sh` → "Validate deploy commands before they run", `no-dark-mode.sh` → "Enforce warm-light-only brand rule", `postcompact-voice-reinject.sh` → "Re-inject voice context after compaction", `postcompact-voice-protection.sh` → "Preserve voice-protection rules after compaction". Mark intent as "(inferred from filename — no directive found)" so the user knows it's a guess.

3. **Classify criticality:**
   - **Load-bearing** — the hook's absence causes silent correctness loss rather than just missing a guard. Criteria (any one):
     - `PostCompact` event on a content/voice/style/tone skill (drift across compaction boundaries is a known failure mode)
     - Directive-checksum protection (guards immutable user directives)
     - The owning skill's SKILL.md has an `<!-- origin: user | immutable: true -->` directive block whose rule maps directly to the hook's purpose (inferred-intent match must come from step 2a, not 2c — a filename guess is not enough to call something load-bearing)
   - **Protective** — PreToolUse/PostToolUse hook enforcing a project or brand rule documented in CLAUDE.md or the skill's non-sacred machinery, but not a sacred user directive. Absence means violations ship unblocked but no silent correctness loss.
   - **Advisory** — informational, reminder, logging, or capture-prompt hooks whose absence costs no enforcement, only a nudge.

4. **Check git recoverability** (skip if `--no-git`):
   - Run `git log --diff-filter=D --format='%h %ad %s' --date=short -- <path> | head -1` against the current repo.
   - If a deletion commit exists → record SHA + date + subject. Restoration command: `git show <sha>^:<path> > <path> && chmod +x <path>`.
   - If `git log` returns empty → the path is either untracked history or predates the repo; record as "not recoverable from git".
   - Per file, bound the git call to a few hundred ms; if a `git log` is unexpectedly slow, skip and record "git check timed out" rather than blocking the audit.

5. **Stage the enriched finding** for Step 4's "Dead Wiring" subsection.

**Recommendation policy** (applied when generating the report):
- **Load-bearing + recoverable** → recommend `git show <sha>^:<path> > <path> && chmod +x <path>`. Default action in execute mode.
- **Load-bearing + not recoverable** → recommend reconstructing the hook from the owning skill's directive; propose `/skill-builder shell-safety write` with template T1/T2 scaffolded from the directive text. User review required.
- **Protective** → present both options (recover from git or unwire from settings) and require user choice; do not auto-act in execute mode.
- **Advisory** → recommend unwire (remove the entry from settings.local.json / settings.json). Default action in execute mode.

**CHECKPOINT — criticality classification gate (per SKILL.md § Directives, non-obvious-decision rule):**
1. For each dead-wiring finding, list the alternatives: Load-bearing | Protective | Advisory.
2. IF exactly one class matches a concrete criterion from step 3 (PostCompact + content skill; checksum; sacred-directive match via intent source 2a) → classify without an agent.
3. IF two or more classes are plausible (e.g., intent came from filename-only inference, or the hook event doesn't fit the table cleanly) → STOP. Spawn one Task agent (persona: Enforcement auditor — judges whether a hook's absence causes silent correctness loss or merely weakens a guard; scope: read the owning SKILL.md and the hook path; output: single classification with one-sentence rationale). Apply the agent's classification.
4. IF two agents disagree on a marginal case → default to the safer class (Protective over Advisory; Load-bearing over Protective) so the report over-recommends recovery rather than over-recommends unwiring.

#### Step 3: Identify New Opportunities

**Handler type decision guide** (see `references/enforcement.md` § "Hook Handler Types"):

| Check Requirement | Handler Type | Cost |
|-------------------|-------------|------|
| Pattern/regex match (deterministic) | `command` | Free |
| Meaning/intent evaluation (semantic) | `prompt` | 1 LLM call |
| Multi-file cross-reference (analytical) | `agent` | 1+ LLM calls |
| External service call | `http` | Network call |

Scan each skill's SKILL.md for directive patterns that can be enforced with hooks:

| Directive Pattern | Handler Type | Example |
|-------------------|-------------|---------|
| "Never use X" / "Never assign to X" | **command** (grep-block) | Block forbidden IDs/values |
| "Always use script Y" | **command** (require-pattern) | Block direct API calls, require helper |
| "Never call Z directly" | **command** (grep-block) | Block forbidden endpoints |
| "Must include X" | **command** (require-pattern) | Ensure required fields present |
| "Never exceed N" | **command** (threshold) | Block values above limit |
| "Never alter/reword directives" | **prompt** (semantic) | Block paraphrasing of sacred text |
| "Each X must be unique across Y" | **agent** (cross-reference) | Scan multiple files for duplicates |
| "No promotional language" | **prompt** (semantic) | LLM evaluates tone/style |
| "Verify dates are correct" | **command** (temporal) | Arithmetic check on date phrases |

**Prompt hooks unlock new enforcement:** Directives previously classified as "needs agent, not hook" may now be enforceable via prompt hooks. Re-evaluate style/tone/meaning directives — if a single-turn LLM evaluation suffices, a prompt hook is cheaper than a full agent and fires automatically.

**Still cannot be hooks — recommend agents instead:**
- "Choose the best X" → judgment call requiring context → **Matcher Agent**
- "If unclear, ask" → context-dependent → **Triage Agent**
- Complex multi-step evaluation → **Text Evaluation Pair** or **context: none agent**

These MUST appear in the hooks report under a **"Needs Agent, Not Hook"** section (see report template below) so the recommendation isn't lost.

**Scoping requirement:** Hooks that enforce writing/voice style rules must skip `.claude/` infrastructure files. Style hooks apply to project content output, not skill machinery. Use the scope check pattern from the grep-block template or the `if` field for frontmatter hooks.

**PostCompact opportunity:** For every skill with sacred directives, consider a PostCompact hook that re-injects critical rules after context compaction. This is low-cost (command hook echoing JSON) and addresses the root cause of drift.

#### Step 3a: Detect Awareness Ledger Hook Opportunities

Check if `.claude/skills/awareness-ledger/` exists. If it does:

1. **Check for skill-specific consultation gaps** — If the skill has directives that reference past failures, learned patterns, or architectural decisions (phrases like "we decided to," "after the incident," "this was chosen because"), and those aren't captured in the ledger, flag as: "Directive references historical knowledge not yet in the ledger. Recommend `/awareness-ledger record` to capture."
2. **Check for outdated capture hook** — If `capture-reminder.sh` fires on every Task completion without trigger pattern matching (grep for the generic "If findings, decisions, or patterns emerged" message, or check if it's a PostToolUse hook instead of PreToolUse), flag as: "capture-reminder.sh uses blanket reminders. Enhanced template available with trigger-pattern matching that eliminates reminder fatigue — see `references/ledger-templates.md` § capture-reminder.sh." Add to the report under "Recommended Actions" as an upgrade opportunity.
3. **Check for obsolete consult-before-edit.sh** — If `consult-before-edit.sh` exists in the skill's `hooks/` directory or is wired in `settings.local.json`, flag as: "consult-before-edit.sh is obsolete. Ledger consultation belongs in the planning phase (CLAUDE.md line + skill directive), not at edit time. Remove the hook and ensure the CLAUDE.md Integration Line and READ auto-activation directive are in place — see `references/ledger-templates.md` § Auto-Activation Directives and § CLAUDE.md Integration Line."

If the ledger does not exist, skip this step silently.

#### Step 3a-ii: Evaluate Post-Action Capture Hook

If `.claude/skills/awareness-ledger/` exists, evaluate whether a lightweight post-action reminder hook would help capture institutional knowledge from skill output.

**Proportionality checks — skip if any apply:**
- Skill already has a capture workflow step in SKILL.md (keywords: "capture," "record," "ledger," "/awareness-ledger record") → workflow step is superior, no hook needed
- Capture Recommender agent was recommended by the `agents` procedure → agent provides intelligent filtering, hook would be redundant
- Skill runs frequently with routine output (formatting, linting, status checks) → reminder fatigue outweighs capture value

**When to recommend:**
- Skill produces occasional findings worth capturing, but not enough to justify an agent
- No other capture mechanism exists for this skill
- Skill completes as a discrete action (agent/Task tool) so PostToolUse hook can fire

If recommending, reference the `capture-reminder.sh` template from `references/ledger-templates.md` § "capture-reminder.sh". Add to the report under "New Opportunities" with hook type "Post-action capture reminder" and note the capture mechanism hierarchy:

**Capture mechanism hierarchy:** workflow step (zero cost, recommended by `optimize`) > Capture Recommender agent (judgment-based, recommended by `agents`) > post-action reminder hook (lightweight fallback, recommended here). Only one mechanism per skill.

If the ledger does not exist, skip this step silently.

#### Step 3b: Agent panel — enforcement boundary decisions *(skip when running as sub-command of audit — fires only in standalone or `--execute` mode)*

Some directives sit at the boundary between hook-enforceable and agent-required. "Never use informal language" — is that a grep pattern or a judgment call? "Always validate inputs" — is that a pre-flight check or a simple pattern match? Per directive: agents are mandatory when guessing is involved.

For directives that aren't clearly in the "hook" or "agent" column, spawn 2 individual agents in parallel (Task tool, `subagent_type: "general-purpose"`):

- **Agent 1** (persona: Shell scripting pragmatist — writes hooks that catch 80% of violations with zero false positives) — Review the ambiguous directives. Which can be reliably enforced with grep/pattern matching? What specific patterns would the hook check? What's the false positive risk?
- **Agent 2** (persona: AI evaluation specialist — designs agent-based validation for nuanced rules) — Review the same directives. Which require reasoning, context, or judgment that a shell script can't provide? What would the agent need to read and evaluate?

Synthesize:
- Directives both agree are hook-enforceable → hooks section
- Directives both agree need agents → "Needs Agent, Not Hook" section
- Disagreements → present in the report with both arguments; let the user decide

Skip this panel when all directives are clearly one category or the other (e.g., "Never use account ID X" is obviously a grep-block hook).

#### Step 3c: Detect Temporal Validation Opportunities

Scan each skill for temporal exposure — patterns that indicate the skill produces or manipulates date/time-sensitive content where the model's arithmetic could silently fail.

**Temporal exposure indicators** (any 2+ → temporal risk):
- Content generation with citations or references containing dates
- Scheduling, calendar, or timeline workflows
- Data reporting with date ranges or period comparisons
- Directives requiring temporal accuracy ("dates must be accurate," "verify timelines")
- Output that embeds relative time phrases ("a few weeks ago," "recently," "since [date]")

**Classify risk per `references/temporal-validation.md` § "Temporal Risk Classification":**

- **HIGH risk:** Add to "New Opportunities" table with hook type "Temporal-validation" and **High** priority. Classify based on actual temporal patterns found (citation workflows, date arithmetic, timeline generation), not domain assumption.
- **MEDIUM risk:** Add to "New Opportunities" table with hook type "Temporal-validation" and **Medium** priority.
- **LOW risk:** Skip silently — no hook needed.

**In execute mode:** Generate the hook script following the architecture specification in `references/temporal-validation.md` § "Hook Generation Specification," adapted to the target system's available tools (detect Python/GNU date/BSD date at runtime). The hook:
- Scopes to content files only (skips `.claude/` infrastructure)
- Handles Edit vs. Write tool input differently (new content only for edits)
- Strips non-prose content before scanning
- Uses the temporal phrase → day-range mapping for mismatch detection
- Exits 2 with specifics on mismatch, exits 0 when unverifiable

**Grounding:** Read [references/temporal-validation.md](../temporal-validation.md) before generating temporal hooks.

#### Step 4: Generate Report

```markdown
# Hooks Audit Report

## Existing Hooks

| Script | Skill | Matcher | Wired | Status |
|--------|-------|---------|-------|--------|
| no-uncategorized.sh | /budget | Bash | Yes | OK |
| validate-org-id.sh | /api-client | Bash | Yes | OK |
| orphaned-script.sh | /skill | — | No | ORPHANED |

## Wiring Issues
- [List any scripts not in settings.json (orphans — on-disk but not wired)]
- [List any command strings that reference `$CLAUDE_PROJECT_DIR` (or any other path-bearing variable) without escaped-quote wrapping. Remediation: rewrite each `"$VAR/..."` as `"\"$VAR/...\""`. Mechanical, no semantic change.]
- Dead wiring (wired but file missing) is detailed in its own section below.

## Dead Wiring

*(Omit this section entirely if no dead wiring was found. Otherwise include the table and the per-class recommendation list.)*

| Skill | Hook | Event / Matcher | Intent | Intent source | Criticality | Recoverable |
|-------|------|-----------------|--------|---------------|-------------|-------------|
| /email | no-credentials.sh | PreToolUse Bash | Block credential leakage in Bash output | filename (inferred) | Protective | Yes — `abc1234` (2026-03-12) |
| /voice | postcompact-voice-reinject.sh | PostCompact | Re-inject voice context after compaction | SKILL.md directive: "voice must survive compaction" | Load-bearing | Yes — `def5678` (2026-02-28) |
| /deploy | check-deploy-commands.sh | PreToolUse Bash | Validate deploy commands before they run | filename (inferred) | Protective | No (not in git history) |

### Recommended Actions by Class

**Load-bearing + recoverable (auto-recover in `--execute`):**
- `git show abc1234^:.claude/skills/voice/hooks/postcompact-voice-reinject.sh > .claude/skills/voice/hooks/postcompact-voice-reinject.sh && chmod +x .claude/skills/voice/hooks/postcompact-voice-reinject.sh`

**Load-bearing + not recoverable (user review, scaffold suggested):**
- /skill-name — reconstruct from directive "[quoted directive]" via `/skill-builder shell-safety write .claude/skills/[skill]/hooks/[name].sh`

**Protective (user choice — not auto-executed):**
- /email no-credentials.sh — recover from `abc1234` OR unwire the entry from `.claude/settings.local.json`

**Advisory (auto-unwire in `--execute`):**
- /skill-name — remove entry from `.claude/settings.local.json` hooks section

## New Opportunities

| Skill | Directive | Hook Type | Priority |
|-------|-----------|-----------|----------|
| /skill-name | "Never use Uncategorized" | Grep-block | High |

## Needs Agent, Not Hook

| Skill | Directive | Recommended Agent | Why Not a Hook |
|-------|-----------|-------------------|----------------|
| /skill-name | "Never produce overbuilt prose" | Text Evaluation Pair | Requires judgment, not pattern matching |
| /skill-name | "Match vendor to category" | Matcher | Requires reasoning about best fit |

*Needs agent, not hook — flagged for the agents sub-command.*

## Recommended Actions
1. [Wire orphaned script X]
2. [Create hook for directive Y in /skill-name]
3. [Fix exit code in script Z]
4. [Create Text Evaluation agent pair for /skill-name (see above)]
```

### Execute Mode (`--execute`)

When running `/skill-builder hooks [skill] --execute`:

1. Run display mode analysis first (Steps 1-4 above)
2. **Generate task list from findings** using TaskCreate — one task per discrete action
3. Execute each task sequentially, marking complete via TaskUpdate as it goes

**Frontmatter-first strategy:** Embed hooks in the skill's SKILL.md frontmatter by default. Use `settings.local.json` only for:
- Global hooks that must apply across ALL skills (e.g., directive checksum protection)
- Command hooks that need shell scripts on disk

**For frontmatter hooks (prompt/agent/PostCompact):**
- Add `hooks:` section to the skill's YAML frontmatter
- Use `if` field to scope (e.g., `if: "Edit(**/SKILL.md)"`)
- Use `$ARGUMENTS` placeholder for hook input data

**For command hooks (grep-block, require-pattern, threshold):**
- Generate the script body via `/skill-builder shell-safety write` using template T1 (advisory) or T2 (blocking) from `skill-builder/references/shell-safety/templates.md`. Do not hand-roll the boilerplate (ERR trap, defensive stdin, scope check); the template has it.
- Save to `.claude/skills/[skill]/hooks/[name].sh`
- Make executable: `chmod +x [script]`
- Wire the settings.local.json entry using template T3 from `skill-builder/references/shell-safety/templates.md` (the escaped-quoted `$CLAUDE_PROJECT_DIR` form). This satisfies shell-safety R1, R2, and R8 in one step.
- Before writing the entry to disk, run `/skill-builder shell-safety lint` on the generated artifacts.

**Existing-hook remediation (when Step 2 surfaces shell-safety findings):**
- For HARD findings reported by `/skill-builder shell-safety audit`, add one task per file to the execute task list and run `/skill-builder shell-safety audit [file] --execute`. The shell-safety subcommand performs the mechanical rewrite (path quoting, `$CLAUDE_PROJECT_DIR` wrapping) and creates `.bak` files.
- For SOFT findings (missing ERR traps, `set -e` removal, stdin parsing changes), surface them in the report for the user to address. Do not auto-patch.
- Validate the rewritten JSON or script parses before marking the task complete.

**Dead-wiring remediation (when Step 2.5 surfaces missing hook files):**

Execute mode acts only on the unambiguous classes. Protective and load-bearing-not-recoverable findings are listed in the task plan as "user decision required" and not mutated.

- **Load-bearing + recoverable** → one task per file:
  1. `git show <sha>^:<path> > <path>`
  2. `chmod +x <path>`
  3. Verify the restored file parses (`bash -n <path>` for shell scripts).
  4. Run `/skill-builder shell-safety lint <path>` — if it fails, leave the restored file in place but surface the lint finding for user review.
- **Advisory** → one task per entry: remove the entry from `.claude/settings.local.json` (or `.claude/settings.json`) hooks section. Preserve JSON validity: if removing the entry empties a matcher block, remove the matcher block too; if removing the matcher block empties the event array, remove the event key.
- **Protective** and **Load-bearing + not recoverable** → add a task labeled "USER DECISION REQUIRED — [skill] [hook]" that prints the recommendation and stops without modifying files. The user re-runs with the decision encoded (e.g., `/skill-builder hooks [skill] --execute --recover=<file>` or `--unwire=<file>`; or hand-edits settings).
- After all tasks complete, re-run Step 1 cross-reference as a post-check; report any remaining dead wiring.

To skip the git recoverability check at scale (large monorepos, shallow clones where `git log` is slow), pass `--no-git` through to Step 2.5. In that mode, every finding is treated as "recoverability unknown" and the execute-mode auto-recover branch is disabled — the user must explicitly confirm recovery for each file.

**Template for command hooks (grep-block):**
```bash
#!/bin/bash
# Hook: [purpose] per /[skill] directive
# Scope: Project content files only (skips .claude/ infrastructure)
INPUT=$(cat 2>/dev/null) || exit 0

# Scope check: skip .claude/ infrastructure files
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')
if echo "$FILE_PATH" | grep -q '\.claude/' 2>/dev/null; then
  exit 0
fi

if echo "$INPUT" | grep -q "FORBIDDEN_VALUE" 2>/dev/null; then
  echo "BLOCKED: [reason] per /[skill] directive" >&2
  exit 2
fi
exit 0
```

**Template for prompt hooks (semantic enforcement):**
```yaml
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: prompt
          prompt: "[Describe what to check]: $ARGUMENTS. If [violation condition], DENY with explanation. Otherwise APPROVE."
          if: "[scope filter]"
          statusMessage: "[description]..."
```

**Template for agent hooks (multi-file verification):**
```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: agent
          prompt: "[Describe analysis task]: $ARGUMENTS. Scan [files/patterns]. If [violation], DENY. If [ok], APPROVE."
          if: "[scope filter]"
          statusMessage: "[description]..."
```

**Template for PostCompact hooks (drift re-injection):**
```yaml
hooks:
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: [critical rules to re-inject after compaction]\"}'"
          statusMessage: "Re-injecting [skill] awareness..."
```

**Grounding:** `references/enforcement.md`
