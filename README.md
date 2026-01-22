# Claude Enforcer

A skill for building, auditing, and optimizing Claude Code skills, hooks, and agents.

## What It Does

- **Audits** your skill system (CLAUDE.md, skills, rules)
- **Optimizes** skills by splitting SKILL.md from reference.md
- **Creates** hooks for runtime enforcement
- **Creates** agents for validation and grounding
- **Converts** legacy rules to on-demand skills

## Install

From your Claude Code project root (where CLAUDE.md lives):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
```

If you haven't initialized Claude Code yet, run `claude /init` first.

### Manual Install

Copy the skill-builder to your project:

```bash
cp -r skill-builder /path/to/your/project/.claude/skills/
```

Or for user-level (all projects):

```bash
cp -r skill-builder ~/.claude/skills/
```

## Usage

```
/skill-builder audit     # Audit your entire skill system
/skill-builder agents    # Analyze agent opportunities
```

## Philosophy

- **CLAUDE.md** should be lean (~100-150 lines): universal guidance only
- **Skills** load on-demand for domain-specific rules and workflows
- **Hooks** enforce critical rules. Immutable, can't drift under long context.
- **Agents** validate before action. `context: none` prevents hallucination.
- **Rules** are legacy. Convert them to skills.

## License

MIT
