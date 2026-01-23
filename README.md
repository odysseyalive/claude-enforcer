# Claude Enforcer

Most people focus on what to *say* to AI. The real leverage is in what you *show* it before you speak.

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is Anthropic's command-line AI assistant for software development. When you run it in a project directory, it reads a `CLAUDE.md` file at the start of every conversation. Think of this file as a briefing room: your project's architecture, coding conventions, API keys to avoid, workflows to follow.

The problem is that briefing rooms fade. As conversations grow longer, the instructions you loaded at the start get diluted by everything that comes after. Researchers call this ["lost in the middle"](https://arxiv.org/abs/2307.03172), and it means your carefully written rules stop being consulted reliably.

This tool helps you build a context system that resists drift.

## The Problem

When you put everything in `CLAUDE.md`, two things happen:

1. **Context bloat.** Every conversation loads every rule, even irrelevant ones. A 500-line file full of deployment procedures wastes context when you're just trying to fix a CSS bug.

2. **Instruction drift.** Under long context, Claude "forgets" rules loaded at the start. Not literally, but it stops consulting them as reliably. The rules are still there. The model just drifts.

## The Solution

Claude Code has three mechanisms that help, but most developers underuse them:

**Skills** are reusable instruction files that load on-demand. Instead of a 500-line `CLAUDE.md` that fades, you have a lean briefing room (~100 lines) plus specialized skills you invoke when needed. Type `/deploy` when deploying, `/api` when working with your API, `/review` when reviewing code. The context stays relevant.

**Hooks** are shell scripts that run *before* Claude acts. A PreToolUse hook can block a forbidden action regardless of what Claude "remembers." It doesn't matter if the model forgot your rule about never using a certain account. The hook blocks it anyway.

**Agents** are subprocesses that start with fresh context. When you need to validate something without the drift of the current conversation, you spawn an agent with `context: none`. It reads your reference files directly, uninfluenced by the long conversation above.

## Install

From your Claude Code project root (where `CLAUDE.md` lives):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
```

If you haven't initialized Claude Code yet, run `claude /init` first.

## Usage

```
/skill-builder audit     # Audit your skill system
/skill-builder agents    # Analyze agent opportunities
```

The audit scans your `CLAUDE.md`, any `.claude/rules/` files, and existing skills. It identifies what can be extracted, what needs enforcement, and where context drift is likely to cause problems.

## Building Skills

You'll always be tweaking. A skill that works today might need adjustment next week as you discover edge cases, add new rules, or realize something drifts when it shouldn't.

Whether you're refining an existing skill or starting from scratch, just describe what you need:

```
/skill-builder I need a skill for deploying to production
/skill-builder add a rule to my deploy skill: always run tests first
/skill-builder my api skill is getting too long, help me split it up
/skill-builder I plan on doing this a lot: [describe task]. Create a skill for it.
/skill-builder I'm glad that problem got figured out. I never want to deal with that again. Can you make a skill for this?
```

You don't need to know the structure upfront. Describe the problem, and skill-builder helps you shape it.

## Analyzing Agent Opportunities

Sometimes a skill needs more than instructions. It needs a checkpoint.

Agents are subprocesses that validate something before Claude acts. They start fresh, without the drift of the current conversation, and can catch mistakes that instructions alone might miss.

```
/skill-builder agents
```

This analyzes your skills and identifies where agents could help: lookups that need to come from a file instead of memory, validations that should happen before an API call, evaluations that benefit from a second opinion.

Not every skill needs agents. But when you notice Claude "forgetting" a rule mid-conversation, an agent can enforce it reliably.

## When to Use Rules

Rules live in `.claude/rules/` and load automatically based on paths or triggers. A rule with `path: src/api/**` only loads when you're working in that directory. A rule with `trigger: deploy` loads when that word appears in your prompt.

This sounds convenient, but it has a cost.

Long lists of rules fade. They load at conversation start and drift just like `CLAUDE.md`. If your rules directory grows into dozens of files, you'll notice the symptoms: Claude runs hot, starts forgetting instructions mid-conversation, or completely ignores what you want to do.

Keep rules lean. Use them for lightweight, always-on guidance that doesn't fit in `CLAUDE.md`. For anything substantial, use skills instead. Skills load on-demand, refresh mid-conversation, and don't bloat every session.

## Philosophy

| Layer | What It Is | Purpose | Drift-Resistant? |
|-------|------------|---------|------------------|
| `CLAUDE.md` | File loaded at conversation start | Universal guidance | No |
| Rules | Files in `.claude/rules/` | Always-on context (keep lean) | No |
| Skills | On-demand instruction files | Domain-specific rules | No (but refreshable) |
| Hooks | Shell scripts before actions | Hard blocks on forbidden actions | Yes |
| Agents | Subprocesses with isolated context | Validation without drift | Yes |

The goal: soft guidance where drift is acceptable, hard enforcement where it isn't.

## Learn More

- [Context Is the Interface](https://odysseyalive.com/focus/context-is-the-interface) — The insight behind this approach
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code) — Official docs on skills, hooks, and agents
- [Lost in the Middle](https://arxiv.org/abs/2307.03172) — The research on long-context instruction following

## License

MIT
