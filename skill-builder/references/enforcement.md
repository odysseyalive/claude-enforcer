# Enforcement Mechanisms & Context Mutability

## Opus 4.7 Behavioral Contract

Skill-builder and every skill it produces targets Opus 4.7+. The behavioral contract:

- **Literal execution.** 4.7 executes instructions as written. It does not infer intent from conversational phrasing, does not bridge implicit connections between steps, and does not substitute "the obvious thing" for a vague instruction.
- **No implicit inference.** Directives like "organize around the discovery arc", "keep it conversational", "appropriate persona" are under-executed on 4.7. On 4.6 the model supplied the missing logic; on 4.7 the model executes only what the text explicitly says.
- **Effort-sensitive tool invocation.** At lower effort levels, 4.7 reasons internally instead of making tool calls. Skills that depend on grounding reads, agent spawns, or hook triggers must declare `minimum-effort-level` in their frontmatter. See [templates.md](templates.md) § "Frontmatter Requirements".

  **When `xhigh` is justified vs. `high`.** `xhigh` costs roughly 2x to 3x the tokens of `high` per invocation. Use `xhigh` only for content-creation workflows where the output-quality delta is observable (voice profile loading, prose generation, evaluation against subjective rubrics). Use `high` for everything else: skills that spawn agents, invoke hooks, do analytical workflows, or depend on grounding reads but do not produce subjective prose. For per-procedure granularity (some workflows in a skill need `xhigh`, others are fine at `high`), use `strictness: thorough` at the skill level and let individual procedures document their own effort expectations rather than pinning the whole skill at `xhigh`. See [token-efficiency.md](token-efficiency.md) § "P2: xhigh effort without a content-creation profile" for the detection rule.

### Impact on the Enforcement Hierarchy

Every row of the hierarchy table is affected, but not equally:

| Level | 4.7 impact |
|-------|------------|
| Guidance (directives in SKILL.md) | Most affected. Soft directives need enforcement annotations to translate intent into explicit checkpoints. |
| Grounding ("state which ID you'll use") | "State" is conversational. Replace with explicit "Read X before Y" instructions. |
| Validation (agent with `context: none`) | The agent itself runs on 4.7. Its prompt language must be 4.7-explicit. |
| Hard block — deterministic (command hook) | Minimally affected — shell exit codes are deterministic. |
| Hard block — semantic (prompt hook) | The hook's LLM runs on 4.7. Prompt language must be 4.7-explicit. |
| Hard block — analytical (agent hook) | Same as validation — the agent is itself 4.7. |
| Drift re-injection (PostCompact) | The re-injected text reaches 4.7 literally. Write it explicitly. |

**Key consequence:** external enforcement (hooks, `context: none` agents) is NOT automatically 4.7-compatible. The mechanism is drift-resistant, but the prompt/agent language running inside the mechanism must itself be 4.7-explicit.

### The Fix Is Annotation, Not Rewriting

User directives in the `## Directives` section are sacred — verbatim, never reworded. They CAN be augmented with a machine-generated enforcement annotation that translates intent into explicit numbered steps. See [templates.md](templates.md) § "Enforcement Annotation Template" for the format.

Skill-builder machinery (workflow steps, grounding statements, enforcement language) is NOT sacred — it is rewritten in-place to 4.7-explicit language during `/skill-builder convert` and during `/skill-builder optimize`'s Directive Annotation Scan step.

---

## Context Mutability & Enforcement Hierarchy

CLAUDE.md and skills load at conversation start. Under long context windows, Claude's adherence to these instructions **drifts** — directives get forgotten or reinterpreted.

### What's Mutable (Can Drift)

- CLAUDE.md instructions
- Rules (`.claude/rules/*.md`)
- Directives in SKILL.md (once loaded)
- Grounding statements ("state which ID...")
- Any text-based instruction in context

### What's Immutable (External Enforcement)

- **Command hooks** — Shell scripts run outside Claude's context, block regardless of drift
- **Prompt hooks** — LLM evaluates a prompt with tool context; runs outside conversation context
- **Agent hooks** — Subagent with Read/Grep/Glob access verifies conditions; isolated from conversation
- **Agents with `context: none`** — Fresh subprocess, reads files without inherited drift
- **PostCompact hooks** — Fire after context compaction, re-inject critical awareness at the exact moment drift occurs

**4.7 note:** Immutability here refers to *drift resistance* — the mechanism fires regardless of how the conversation evolved. It does NOT mean the mechanism's internal language is immune to misinterpretation. The prompt evaluated by a prompt hook, the agent invoked by an agent hook, and the fresh subprocess reading a `context: none` agent's prompt all run on 4.7 themselves. If the hook or agent prompt uses inference-dependent phrasing, it still fires — but produces 4.7-literal output. See § "Opus 4.7 Behavioral Contract" above.

### Enforcement Hierarchy

| Level | Mechanism | Drift-Resistant? | Use For |
|-------|-----------|------------------|---------|
| Guidance | Directives in SKILL.md | No | Soft preferences |
| Grounding | "State which ID you'll use" | No | Important but not critical |
| Validation | Agent (`context: none`) | Yes | Important rules |
| Hard block — deterministic | Command hook (PreToolUse) | Yes | Rules expressible as pattern/regex |
| Hard block — semantic | Prompt hook (PreToolUse) | Yes | Rules requiring judgment (paraphrasing, intent) |
| Hard block — analytical | Agent hook (PreToolUse) | Yes | Rules requiring multi-file analysis |
| Drift re-injection | PostCompact hook | Yes | Re-state critical rules after context compaction |

### Analytical Phase Prompting

When a skill must handle vague or exploratory user input (e.g., "help me think about X", a one-line feature request with no spec, any argument containing subjective terms), it should include an explicit **Phase 0 — Assessment** step that runs before any execution.

**Format:**

    PHASE 0 — ASSESSMENT: Before executing the workflow, analyze [what]:
    1. Read [explicit inputs].
    2. State findings: [what to surface to the user].
    3. WAIT for user confirmation before proceeding to Phase 1.

**Rationale:** 4.7 executes literally. If the user's input is vague, a 4.6-era skill often compensated by inferring missing specification and proceeding. 4.7 instead executes the literal input and produces an off-target result. Phase 0 forces the skill to surface its interpretation of vague input and wait for user confirmation. This is the 4.7-compatible replacement for implicit "assumed intent".

**When to use Phase 0:**

- Skill is invoked with conversational or exploratory arguments (no structured input)
- Skill produces output in multiple possible directions and there's no default
- Skill's cost to run is high (long-running research, large content generation) and mis-specification is expensive
- User's request contains subjective terms ("good", "appropriate", "better") that require interpretation

**When NOT to use Phase 0:**

- Skill takes structured arguments that fully specify intent (specific ID, file path, explicit mode)
- Skill is a quick lookup or format check where execution is faster than a Phase 0 question
- Skill is invoked from a chain where Phase 0 was already run upstream

### Planning-Phase Activation

Some concerns must shape the plan itself, not just police its execution. Institutional memory is the primary example: if the ledger is only consulted when code is being edited, the plan has already been presented and approved — too late for historical context to change the recommendation.

**Consultation belongs in the planning phase.** The awareness ledger uses two layers that target thinking, not action:

| Layer | Role | When It Activates |
|-------|------|-------------------|
| CLAUDE.md line | Baseline awareness in every conversation | During research, before any plan is formed |
| Skill directive | Full agent-assisted analysis when warranted | When the awareness-ledger skill is loaded |

The CLAUDE.md line survives context compression (it reloads at the start of every conversation). The skill directive provides the escalation workflow — index scan, record review, agent spawning — that turns awareness into analysis.

**Why not a hook?** Hooks fire on tool use (Edit, Write, Bash). By the time a tool fires, the plan has already been presented. Consultation during planning is about shaping recommendations, not blocking actions. This is what directives are for — they influence reasoning, not execution.

**Hooks still serve capture.** The `capture-reminder.sh` hook fires on Task/Bash when trigger patterns match, suggesting records to capture. Capture is a reactive concern (detecting knowledge as it emerges) and suits the hook model. Consultation is a proactive concern (enriching thinking before it produces output) and suits the directive model.

**When to apply this pattern:** Cross-cutting concerns that must influence the planning phase. See `references/ledger-templates.md` § "CLAUDE.md Integration Line" and § "Auto-Activation Directives" for the two layers in practice.

### Skill-Builder Recommendations

When optimizing or creating skills:

- **Soft guidance** → Directives only
- **Soft guidance with unambiguous intent** → Directives + enforcement annotation (no agent). Use when the directive's *meaning* is clear but its *execution* relies on inference that 4.7 no longer supplies. The annotation encodes the execution steps explicitly. See [templates.md](templates.md) § "Enforcement Annotation Template".
- **Important rules** → Directives + agent validation (`context: none`)
- **Critical deterministic rules** → Directives + command hook (checksum, regex)
- **Critical semantic rules** → Directives + prompt hook (meaning-aware)
- **Critical multi-file rules** → Directives + agent hook (cross-reference analysis)
- **Drift-sensitive rules** → Above + PostCompact re-injection

### Why Not Rules?

Rules (`.claude/rules/*.md`) are:
- Always loaded (wastes context on irrelevant tasks)
- Mutable under long context (same drift problem as CLAUDE.md)
- Redundant when you have skills

Prefer: Lean CLAUDE.md (~100-150 lines) + on-demand skills + hooks for critical enforcement.

---

## Behavior Preservation in Optimization

Refactoring is defined as restructuring code (or in our case, skill files) **without changing observable behavior** (Fowler, *Refactoring* 2nd ed.). This is the foundational constraint. If an optimization changes what the skill *does* — even if it makes the file shorter, cleaner, or "better organized" — it is not optimization. It is breakage.

### The Behavior Preservation Test

Before applying any proposed change to a skill or agent file, ask:

> **"Does the skill produce identical results and enforce identical constraints after this change?"**

If the answer is no, or even uncertain, the change must not be made.

### Structural Invariants

Some content in skill files looks like it could be optimized (consolidated, moved, shortened) but actually serves a **structural purpose**. Changing it would alter the skill's behavior. These are **structural invariants** — the load-bearing walls of a skill's architecture.

#### How to Recognize Structural Invariants

| Pattern | Why It's Load-Bearing |
|---------|----------------------|
| Sequential workflow phases with blocking gates | Phase ordering enforces that step N completes before step N+1 can run. Reordering or merging phases removes the gate. |
| Pre-conditions on a workflow step | A step that says "X must be true before this runs" is enforced by the steps that come before it. Removing those steps removes the enforcement. |
| Directive in SKILL.md + enforcement in agent file | The directive states the rule; the agent workflow structurally prevents violation. Both are necessary — they serve different purposes. |
| Data flow dependencies between steps | Step A populates a structure that Step B reads from. Consolidating A and B may eliminate the structure, removing the constraint. |
| Repeated content across SKILL.md and agent files | Often not duplication — SKILL.md declares *what*, the agent file implements *how*. Removing the "duplicate" removes one half of the contract. |
| Intermediate state tracking (session variables, counters) | Tracks progress and feeds into later steps or the session summary. Removing it breaks downstream reporting or gating. |

#### The Rule

**If removing or reorganizing a piece of content would make it *possible* to skip a directive, bypass a constraint, or change the order of operations, that content is a structural invariant and must not be changed.**

### Pre-Change Verification Procedure

Before proposing any optimization that touches workflow structure, agent files, or content referenced by directives:

1. **List all directives** in the parent SKILL.md
2. **Trace enforcement paths** — for each directive, identify which workflow steps, pre-conditions, or data flows enforce it
3. **Evaluate the proposed change** against each enforcement path
4. **If the change would break any path** → do not propose it
5. **If uncertain** → do not propose it. Flag it for manual review instead.

### Proactive Invariant Scanning

The optimizer must not wait for breakage to discover structural invariants. It must **proactively scan** for them before proposing any changes. The danger is that structural invariants often look like the exact things an optimizer wants to clean up:

#### Content At Risk of Being Misidentified

| What the Optimizer Sees | What It Actually Is | Why It's Dangerous to Touch |
|-------------------------|--------------------|-----------------------------|
| Long, verbose workflow in an agent file | Sequential phases with ordering constraints | Shortening it may remove a blocking gate |
| Same concept described in SKILL.md and agent file | Declaration (what) + implementation (how) | Removing the "duplicate" leaves either the rule without enforcement or the enforcement without a rule |
| Task tool spawn template with inline prompt | Executable specification for an agent call | Moving or simplifying it may change what the agent does |
| Blocking annotations like `[BLOCKING]` | Phase gates that prevent step-skipping | Removing the label removes the instruction to wait |
| Pre-conditions like "X must be true before this step" | Structural enforcement of a directive | Removing it makes the directive advisory instead of enforced |
| Session state variables (counters, lookup caches, tracking lists) | Data flow connectors between phases | Removing them disconnects phases from each other and from the summary |
| Steps that seem to "just announce" something to the user | Checkpoints that create observable behavior the user relies on | Removing them changes what the user sees and when |
| Intermediate data structures populated by one step and consumed by another | The mechanism that makes ordering matter | Consolidating the steps may eliminate the structure |

#### The Core Risk

**Structural invariants are invisible when you're looking for optimization targets.** They don't look like directives (they're not quoted user rules). They don't look like reference data (they're not tables of IDs). They look like verbose, repetitive, overly-detailed workflow prose — exactly what an optimizer is trained to consolidate.

That is why the scan must happen **before** optimization targets are identified, not after. If you identify targets first and filter invariants second, the invariants have already been mentally categorized as "things to change" and the filter becomes a formality. Scan first, exclude first, then look for what's left.

### What This Means for the Optimize Command

The optimize command protects directives (verbatim text), workflows (step order), and now **structural invariants** (content that enforces directives through architecture). The audit checklist includes a "Structural Invariants" section that must be populated before any optimization targets are proposed.

| Looks Like | Actually Is | Action |
|------------|-------------|--------|
| "Duplicated" content between SKILL.md and agent file | Declaration (SKILL.md) + implementation (agent) | Leave both |
| "Verbose" multi-phase workflow | Sequential gates that enforce ordering constraints | Never merge or reorder phases |
| "Redundant" pre-conditions or blocking annotations | Structural enforcement of a directive | Never remove |
| Agent file "repeating" a Task tool template from SKILL.md | The executable specification of how to spawn an agent | Belongs in the agent file; SKILL.md may summarize but agent file is authoritative |
| Intermediate variables or session state | Data flow that connects phases and feeds the session summary | Never remove |

---

## Content Provenance Model

Skill files contain two kinds of content with different modification rights. HTML comment markers identify which is which.

### Provenance Markers

```markdown
<!-- origin: user | added: 2026-02-22 | immutable: true -->
> **"When a decision needs to be made..."**
*— Added 2026-02-22, source: user directive*
<!-- /origin -->

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## Commands
[routing table]
<!-- /origin -->
```

### Permission Model

| Origin | Skill-builder can... | Cannot... |
|--------|---------------------|-----------|
| `user` | Move (preserving exact wording) | Reword, compress, remove |
| `skill-builder` | Modify, remove, replace, restructure | — |
| Unmarked (legacy) | Treat as user-origin (safe default) | — |

### Rules

1. **New directives** added via `inline` are tagged `origin: user`
2. **Generated sections** from `new`, `optimize`, or any skill-builder procedure are tagged `origin: skill-builder`
3. **During optimization**, markers are preserved — content moves between files but keeps its origin tag
4. **Legacy files** without markers are treated as user-origin (safe default) until explicitly tagged

---

## Enforcement Mechanisms

### Hook Handler Types

Claude Code supports four hook handler types. Choose based on what the check requires:

| Type | How It Works | Best For | Cost |
|------|-------------|----------|------|
| **command** | Run shell script, check exit code | Deterministic checks (regex, checksums, file existence) | Free |
| **prompt** | Send prompt + `$ARGUMENTS` to LLM for single-turn evaluation | Semantic checks (paraphrasing detection, intent classification) | 1 LLM call |
| **agent** | Spawn subagent with Read/Grep/Glob tools | Multi-file analysis (cross-reference checks, pattern compliance) | 1+ LLM calls |
| **http** | POST hook input JSON to a URL endpoint | External service integration (CI, logging, webhooks) | Network call |

**Decision guide:**
- Can you express it as a regex or exit code? → **command**
- Does it require understanding meaning? → **prompt**
- Does it need to read multiple files? → **agent**
- Does it need to reach an external service? → **http**

### Hook Lifecycle Events (Relevant to Skills)

| Event | When | Can Block? | Skill-Builder Use |
|-------|------|-----------|-------------------|
| `PreToolUse` | Before tool executes | Yes | Directive protection, persona uniqueness |
| `PostToolUse` | After tool succeeds | No | Post-edit verification, formatting |
| `PreCompact` | Before context compaction | No | Capture context state for diagnostics |
| `PostCompact` | After context compaction | No | Re-inject directive awareness (drift resistance) |
| `InstructionsLoaded` | When CLAUDE.md/rules load | No | Validate directive checksums at session start |
| `ConfigChange` | When config files change | No | **Drift detection** — validate CLAUDE.md/settings integrity |
| `FileChanged` | When watched files change | No | Trigger skill re-validation on external edits |
| `SubagentStart` | When subagent spawns | No | Log agent invocations |
| `SubagentStop` | When subagent finishes | No | Validate agent output |
| `TaskCreated` | When task added to list | No | Validate task structure for teams |
| `TaskCompleted` | When task marked complete | No | Post-action chain triggers |
| `TeammateIdle` | When teammate has no tasks | No | Rebalance work in teams |
| `Stop` | When Claude finishes responding | No | Final quality checks |

Full event list (25 events): SessionStart, UserPromptSubmit, PreToolUse, PermissionRequest, PostToolUse, PostToolUseFailure, Notification, SubagentStart, SubagentStop, TaskCreated, TaskCompleted, Stop, StopFailure, TeammateIdle, InstructionsLoaded, ConfigChange, CwdChanged, FileChanged, WorktreeCreate, WorktreeRemove, PreCompact, PostCompact, Elicitation, ElicitationResult, SessionEnd.

### ConfigChange Drift Detection

The `ConfigChange` event fires when configuration files are modified. Use it to detect unauthorized changes to CLAUDE.md or settings files.

```yaml
hooks:
  ConfigChange:
    - hooks:
        - type: command
          command: |
            INPUT=$(cat)
            FILE=$(echo "$INPUT" | grep -oP '"path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"path"\s*:\s*"//;s/"$//')

            # Check if CLAUDE.md was modified
            if echo "$FILE" | grep -q 'CLAUDE.md'; then
              # Verify directive checksums still match
              if [ -f ".claude/skills/*/hooks/checksum.sh" ]; then
                .claude/skills/*/hooks/checksum.sh --verify || echo '{"warning": "CLAUDE.md directives may have changed. Run /skill-builder checksums to verify."}'
              fi
            fi
            exit 0
          statusMessage: "Checking config integrity..."
```

**Use cases:**
- Detect when CLAUDE.md is edited outside a session
- Validate settings.local.json hasn't been tampered with
- Re-verify directive checksums after any instruction file changes

### InstructionsLoaded Validation

The `InstructionsLoaded` event fires when CLAUDE.md and rules are loaded at session start. Use it for session-start validation.

```yaml
hooks:
  InstructionsLoaded:
    - hooks:
        - type: command
          command: ".claude/skills/my-skill/hooks/verify-checksums.sh"
          statusMessage: "Validating directive integrity..."
```

**Use cases:**
- Validate directive checksums at session start
- Check that required rules files exist
- Verify skill dependencies are present

### Frontmatter Hooks (Portable Enforcement)

Skills can declare hooks directly in YAML frontmatter. These hooks are active while the skill is loaded — no `settings.local.json` wiring needed.

```yaml
---
name: my-skill
description: Example skill with embedded enforcement
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: prompt
          prompt: "Check if this edit alters sacred directives: $ARGUMENTS"
          if: "Edit(**/SKILL.md)|Write(**/SKILL.md)"
          statusMessage: "Checking directives..."
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"REMINDER: Directives are sacred.\"}'"
---
```

**Frontmatter-first strategy:** When skill-builder generates hooks, embed them in the skill's frontmatter by default. Use `settings.local.json` only for global hooks that must apply across all skills (like the directive checksum command hook).

**`if` field (preferred over bash scoping):** Narrows when a hook fires within its matcher. Uses permission rule syntax (e.g., `Edit(**/SKILL.md)` only fires for SKILL.md edits, not all Edit calls).

**Why prefer `if` over bash self-scoping:**
- More efficient — hook doesn't spawn if condition fails
- Declarative — intent is clear in the YAML
- No bash dependency — works on all platforms
- Easier to audit — scope is visible in frontmatter

```yaml
# GOOD: Use if field for scoping
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: prompt
          prompt: "Check directive integrity: $ARGUMENTS"
          if: "Edit(**/SKILL.md)|Write(**/SKILL.md)"

# AVOID: Bash self-scoping (slower, platform-dependent)
hooks:
  PreToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: |
            INPUT=$(cat)
            FILE=$(echo "$INPUT" | grep -oP '"file_path"...')
            if echo "$FILE" | grep -q 'SKILL.md'; then
              # actual check here
            fi
```

**`$ARGUMENTS` placeholder:** Replaced with the hook input JSON, giving prompts and agents access to tool name, file path, content, etc.

### PostCompact Drift Resistance

Context compaction is the exact moment instruction drift occurs. A `PostCompact` hook can re-inject critical rules into the active context immediately after compaction:

```yaml
hooks:
  PostCompact:
    - hooks:
        - type: command
          command: "echo '{\"additionalContext\": \"CRITICAL RULES: [your rules here]\"}'"
```

The `additionalContext` field in the JSON output injects text into Claude's context. This ensures core rules survive compaction regardless of what was compressed away.

### 1. PreToolUse Hooks (Strongest)

Block actions that violate directives BEFORE they execute:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": ".claude/skills/my-skill/hooks/validate.sh"
      }]
    }]
  }
}
```

Hook script exits 2 to block, 0 to allow. Receives JSON via stdin.

### 2. Permission Denials (Deny always wins)

```json
{
  "permissions": {
    "deny": ["Edit(.env)", "Bash(rm:*)"],
    "allow": ["Read", "Bash(curl:*)"]
  }
}
```

Deny rules are evaluated FIRST and cannot be overridden.

### 3. Allowed-Tools in Skills (Workflow restriction)

```yaml
---
allowed-tools: Read, Grep, Glob
---
```

Claude needs explicit permission for tools not listed.

### 4. Subagents with Tool Restrictions

Delegate to a specialized agent with limited tools:

```yaml
---
name: read-only-analyst
allowed-tools: Read, Grep, Glob
context: fork
---
```

---

## Self-Contained Hook Paths

Hooks should use relative paths from project root. The expanded `$CLAUDE_PROJECT_DIR` MUST be wrapped in escaped double quotes inside the JSON string:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR/.claude/skills/api-client/hooks/validate.sh\""
      }]
    }]
  }
}
```

`$CLAUDE_PROJECT_DIR` resolves to the project root, making hooks portable.

### Path-with-spaces safety (REQUIRED quoting)

The hook runner invokes the command via `/bin/sh -c "<command>"`. If `$CLAUDE_PROJECT_DIR` expands to a path containing whitespace, an unquoted command silently splits at the first space. The shell treats the path prefix as the program name and everything after the space as arguments, producing errors like:

```
/bin/sh: line 1: /home/user/Sync/My Project: No such file or directory
```

This is common on:
- macOS iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs/...`)
- Linux Insync / rclone mounts of Google Drive (`~/Insync/.../Google Drive/...`)
- Windows OneDrive (`C:\Users\name\OneDrive - Org Name\...`)
- Any path with a literal space, hyphen-space, or non-ASCII whitespace

**Rule:** every hook command that references `$CLAUDE_PROJECT_DIR` (or any other shell variable that may expand to a path) MUST wrap the expansion in escaped double quotes (`"\"$CLAUDE_PROJECT_DIR/...\""`), so the entire path is a single shell argument after expansion. The unquoted form is never acceptable, even on systems where the path happens to contain no spaces today, because user environments move.

---

## Hook Scoping

Hooks fire globally on every matching tool invocation. The `matcher` field only supports tool names, not file paths. Hooks must **self-scope** by parsing JSON stdin to check whether the target file is within their domain.

### When to Scope

Style/content hooks (writing rules, voice rules, formatting rules) should skip `.claude/` infrastructure files. These hooks enforce output quality for project content, not skill machinery.

### Scope Check Pattern

Add this block after `INPUT=$(cat)` and before the content check:

```bash
# Scope check: skip .claude/ infrastructure files
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*"file_path"\s*:\s*"//;s/"$//')
if echo "$FILE_PATH" | grep -q '\.claude/'; then
  exit 0
fi
```

Uses grep/sed instead of jq to avoid a dependency. Extracts `file_path` from the JSON tool input and exits early if the file is under `.claude/`.
