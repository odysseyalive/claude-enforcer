---
name: shell-safety
description: "Write and audit shell code (scripts, hook commands, JSON-embedded shell) for portability and resilience pitfalls. Modes: write, audit, lint. Usage: /shell-safety [mode] [path]"
allowed-tools: Read, Glob, Grep, Edit, Write, Bash
---

# Shell Safety

Write shell code that survives moving to a different machine, a path with a space in it, a missing optional tool, or a stdin that isn't shaped the way you expected. Audit existing shell for the same fragility classes and patch it where the fix is mechanical.

This skill is the source of truth for the rules. Other skills (skill-builder's `hooks` and `verify` procedures, any skill that generates or edits shell) call into it instead of duplicating the rules.

---

## Usage

```
/shell-safety [mode] [path]
```

### Modes

| Mode | Command | Description |
|------|---------|-------------|
| `write` | `/shell-safety write [target]` | Generate a new script or JSON shell entry from a template with safe defaults baked in |
| `audit` | `/shell-safety audit [path]` | Scan a file or directory for the documented pitfalls. Display findings; with `--execute`, patch the mechanical-safe ones |
| `lint` | `/shell-safety lint [file]` | Read-only single-file check. Useful as a pre-write or pre-commit step |

Default mode is `lint` if a single file is passed, `audit` if a directory is passed.

---

## Directives

> **"Auto-fix only the mechanical, deterministic patches. Flag the judgment-based ones for human review. A wrong silent rewrite is worse than a noisy report."**

*— Added at skill creation, source: design constraint*

> **"Never strip a security check, defensive guard, or error path during a rewrite. If the original code was overly cautious, that is information about its author's intent — preserve it."**

*— Added at skill creation, source: design constraint*

---

## What This Skill Covers

The pitfall classes — see [references/rules.md](references/rules.md) for the full list with rationale and bad/good examples:

| Class | What goes wrong |
|-------|-----------------|
| **Path resolution** | Bare relative paths in hook commands or scripts that assume CWD |
| **Path-with-spaces** | Unquoted variable expansions that split when expanded path contains whitespace |
| **Crash visibility** | Hook scripts without ERR traps; failures vanish into "non-blocking status code" noise |
| **`set -e` foot-guns** | Pipelines, conditionals, and ERR traps that don't behave as written |
| **Stdin parsing** | `$(cat)` without fallback; assumes stdin is JSON-shaped |
| **Tool dependence** | `jq`, `python3`, GNU-specific flags assumed available |
| **Grep pitfalls** | Unanchored patterns, missing `2>/dev/null`, `-q` exit code reliance without guard |
| **JSON-embedded shell** | settings.json command strings; quoting rules differ from script bodies |

---

## Workflow: Write

Generate a new script, hook command, or shell snippet with safe defaults pre-applied.

1. **Identify the target shape** — standalone script (`.sh`), hook command string (in JSON), inline tool invocation, or one-off Bash tool call
2. **Read the matching template** from [references/templates.md](references/templates.md)
3. **Customize the template** — replace placeholders with caller-specific logic. Keep the boilerplate (header comment, ERR trap, defensive stdin) intact.
4. **Validate before returning** — run a smoke test invocation if the script is standalone; for JSON entries, parse the surrounding JSON to confirm validity

---

## Workflow: Audit

Scan one or more files for documented pitfalls.

1. **Identify scan surface** — single file, a directory, or a glob pattern. If `path` is `.claude/settings*.json`, scan JSON command strings. If `.sh`, scan script bodies. If a directory, walk both classes.
2. **Run detection patterns** from [references/audit-patterns.md](references/audit-patterns.md) — each pattern returns line-level matches with severity (HARD = mechanical fix, SOFT = needs judgment) and the recommended remediation
3. **Classify findings:**
   - **Auto-fixable (mechanical)** — path quoting, `$CLAUDE_PROJECT_DIR` wrapping, missing `2>/dev/null` on fallible operations
   - **Flag for review (judgment)** — adding ERR traps to existing scripts, removing `set -e`, restructuring stdin parsing
4. **Display report** grouped by file. Show: line, pattern matched, severity, recommended fix.
5. **In `--execute` mode:** apply the auto-fixable patches. Back up each modified file as `[name].bak`. Validate after each rewrite (JSON parses, script still has correct shebang, etc.). Leave flag-only findings in the report for the user to address.

---

## Workflow: Lint

Read-only single-file check. Same detection logic as audit, no remediation.

1. **Read the file**
2. **Run detection patterns** from [references/audit-patterns.md](references/audit-patterns.md)
3. **Return findings** as a compact summary: `[file]: N findings (H hard, S soft)`. Exit 0 if none, exit 1 if findings present (so it composes with `&&` chains and pre-commit invocations).

---

## Grounding

Before writing, auditing, or remediating shell:

1. Read the relevant section of [references/rules.md](references/rules.md) for the pitfall class in question
2. State: "I will use [PATTERN/TEMPLATE] from references/[file] under [SECTION]"

Reference files:

- [references/rules.md](references/rules.md) — Canonical pitfall list with rationale and bad/good examples
- [references/templates.md](references/templates.md) — Script and JSON-embedded shell scaffolds with safe defaults
- [references/audit-patterns.md](references/audit-patterns.md) — Detection regexes, severity classification, mechanical vs judgment patches

---

## Integration with Other Skills

When another skill (e.g., skill-builder) generates or audits shell:

- **Generation:** call `shell-safety write` for the target shape; do not hand-roll boilerplate
- **Validation:** call `shell-safety lint` before writing to disk
- **Auditing:** call `shell-safety audit` and surface its findings inside the calling skill's existing report

This keeps the rule set in one place. When a new pitfall is discovered, add it here once; every consumer benefits without per-skill changes.

---

## Discovered Issues Log

*(none yet)*
