# Discovered Patterns

*Document what works and what doesn't as you build skills:*

- **Hooks for hard rules, agents for judgment** — Hooks are fast and free (no tokens) but can only grep. Agents can reason but cost tokens and time. Use hooks for "never use ID X", use agents for "find the right ID for Y". (2026-01-22)

- **Context isolation for evaluation** — Evaluation skills should use `context: none` agents so the evaluator isn't biased by the conversation that created the content. This pattern works well for any quality check. (2026-01-22)

- **Grounding statements aren't enough** — Adding "state which ID you will use" to a skill helps but doesn't guarantee Claude reads reference.md. An ID Lookup Agent with `context: none` guarantees the ID comes from the file, not from memory. (2026-01-22)

- **reference.md reduces SKILL.md but total lines stay similar** — The goal isn't fewer total lines, it's fewer lines in SKILL.md (which loads every invocation). reference.md only loads when explicitly read. (2026-01-22)

- **Hook exit code 2 blocks, 0 allows** — Other exit codes are treated as errors but don't block. Always use exactly 2 to block. (2026-01-22)

- **Context mutability is the fundamental problem** — All text-based instructions (CLAUDE.md, rules, skills) can drift under long context. Only external enforcement (hooks, `context: none` agents) is truly immutable. See "Context Mutability & Enforcement Hierarchy" in references/enforcement.md. (2026-01-22)

- **Description must be single line** — Claude Code only shows the `description:` field when users type `/skill-name`, and multi-line descriptions get truncated. Use a single quoted line with modes/usage inline: `"Brief desc. Modes: a, b, c. Usage: /skill [args]"`. See "Frontmatter Requirements" in references/templates.md. (2026-01-24)
