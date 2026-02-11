# Discovered Patterns

*Document what works and what doesn't as you build skills:*

- **Hooks for hard rules, agents for judgment** — Hooks are fast and free (no tokens) but can only grep. Agents can reason but cost tokens and time. Use hooks for "never use ID X", use agents for "find the right ID for Y". (2026-01-22)

- **Context isolation for evaluation** — Evaluation skills should use `context: none` agents so the evaluator isn't biased by the conversation that created the content. This pattern works well for any quality check. (2026-01-22)

- **Grounding statements aren't enough** — Adding "state which ID you will use" to a skill helps but doesn't guarantee Claude reads reference.md. An ID Lookup Agent with `context: none` guarantees the ID comes from the file, not from memory. (2026-01-22)

- **reference.md reduces SKILL.md but total lines stay similar** — The goal isn't fewer total lines, it's fewer lines in SKILL.md (which loads every invocation). reference.md only loads when explicitly read. (2026-01-22)

- **Hook exit code 2 blocks, 0 allows** — Other exit codes are treated as errors but don't block. Always use exactly 2 to block. (2026-01-22)

- **Context mutability is the fundamental problem** — All text-based instructions (CLAUDE.md, rules, skills) can drift under long context. Only external enforcement (hooks, `context: none` agents) is truly immutable. See "Context Mutability & Enforcement Hierarchy" in references/enforcement.md. (2026-01-22)

- **Description must be single line** — Claude Code only shows the `description:` field when users type `/skill-name`, and multi-line descriptions get truncated. Use a single quoted line with modes/usage inline: `"Brief desc. Modes: a, b, c. Usage: /skill [args]"`. See "Frontmatter Requirements" in references/templates.md. (2026-01-24)

- **Voice directives need `context: none` enforcement** — Voice/style rules in SKILL.md get overridden by conversational context during long sessions. The creating conversation biases the model toward defending its own output. Only a `context: none` Voice Validator agent reliably catches violations, because it evaluates the text without knowing how it was created. Hooks can't help here — voice judgment requires reasoning, not pattern matching. (2026-02-11)

- **Content-creation skills need different enforcement than API skills** — API skills need ID Lookup agents and grep-block hooks. Content skills need Voice Validator agents and evaluation pipelines. Detect the skill domain early (during optimize step 3) and recommend the right enforcement type. Don't apply the same playbook to both. (2026-02-11)

- **Audit weight should match user workflow** — Heavy audits (full structural invariant scanning, sub-command display passes, narrative reports) suit first-run or quarterly reviews. Iterative refinement sessions — which are the most common session type — need a lightweight quick check: frontmatter, line counts, wiring, priority fixes. Offer both via `audit` vs `audit --quick`. (2026-02-11)

- **Scope discipline prevents execute-mode drift** — When executing a task list, the model tends to discover "bonus" improvements and act on them unprompted. This is the same scope-creep pattern users experience in content sessions. The fix: treat the task list as a contract — execute only what's listed, note new opportunities in the completion report, never act on them. (2026-02-11)

- **Hooks report should cross-reference agents** — When a directive can't be enforced with a hook (requires judgment), the hooks command should explicitly recommend the right agent type instead of just saying "skip." Otherwise the recommendation is lost and the directive goes unenforced. The "Needs Agent, Not Hook" section in the hooks report closes this gap. (2026-02-11)
