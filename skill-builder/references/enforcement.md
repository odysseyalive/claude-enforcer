# Enforcement Mechanisms & Context Mutability

## Context Mutability & Enforcement Hierarchy

CLAUDE.md and skills load at conversation start. Under long context windows, Claude's adherence to these instructions **drifts** — directives get forgotten or reinterpreted.

### What's Mutable (Can Drift)

- CLAUDE.md instructions
- Rules (`.claude/rules/*.md`)
- Directives in SKILL.md (once loaded)
- Grounding statements ("state which ID...")
- Any text-based instruction in context

### What's Immutable (External Enforcement)

- **Hooks** — Bash scripts run outside Claude's context, block regardless of drift
- **Agents with `context: none`** — Fresh subprocess, reads files without inherited drift

### Enforcement Hierarchy

| Level | Mechanism | Drift-Resistant? | Use For |
|-------|-----------|------------------|---------|
| Guidance | Directives in SKILL.md | No | Soft preferences |
| Grounding | "State which ID you'll use" | No | Important but not critical |
| Validation | Agent (`context: none`) | Yes | Important rules |
| Hard block | Hook (PreToolUse) | Yes | Critical/never-violate |

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
- **Important rules** → Directives + agent validation
- **Critical rules** → Directives + hook enforcement

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

## Enforcement Mechanisms

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
allowed-tools: Read, Grep, Glob, WebSearch
context: fork
---
```

---

## Self-Contained Hook Paths

Hooks should use relative paths from project root:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/.claude/skills/api-client/hooks/validate.sh"
      }]
    }]
  }
}
```

`$CLAUDE_PROJECT_DIR` resolves to the project root, making hooks portable.

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
