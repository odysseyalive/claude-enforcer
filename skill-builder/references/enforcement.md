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
