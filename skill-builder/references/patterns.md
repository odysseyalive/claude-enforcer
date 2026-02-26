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

- **Silent skips create blind spots in orchestrators** — When sub-commands are told to "skip silently" if a feature doesn't exist (e.g., awareness ledger), the orchestrator (audit) inherits that silence and never surfaces the recommendation. Fix: sub-commands should skip silently (correct — they shouldn't recommend installation), but the orchestrator must have its own explicit check that reports the gap. The orchestrator is the only place with full visibility to make cross-cutting recommendations. (2026-02-23)

- **Self-heal is a companion skill, not a command** — Unlike audit or optimize which run on request, self-heal is ambient. It lives in skills as an observer and triggers automatically at session resolution. The distinction matters for design: it has no interactive UI, no report format, no progress indicators. It surfaces only when it has something actionable to say. (2026-02-25)

- **Surgical updates require two-agent validation** — Self-heal uses two `context: none` agents in sequence: root-cause-analyst to determine whether the skill caused the friction and identify the specific instruction, then patch-reviewer to validate the proposed fix is minimal, complete, and safe. One agent is not enough — the analyst is motivated to find a cause (it's their job), the reviewer is motivated to reject bad patches (it's their job). Separation of concerns produces better patches. (2026-02-25)

- **The observer is always last** — The Self-Heal Observer block must be the final section in any skill's SKILL.md. This ensures it doesn't interfere with the skill's primary workflow instructions, and that it loads into context last — where it functions as a background monitor, not a foreground concern. If optimization moves it, move it back. (2026-02-25)

- **Directives are never touched by self-heal** — Self-heal can update workflow instructions, context descriptions, scope language, and clarifying examples. It cannot touch directives under any circumstances. The patch-reviewer agent has an explicit directive-safety check and will reject any patch that modifies a directive. This is a hard boundary. (2026-02-25)

- **Ambiguous diagnoses do not trigger updates** — If the root-cause-analyst cannot confidently determine whether friction was skill-caused or reasoning-caused, the result is AMBIGUOUS and no update is proposed. The risk of a wrong patch — adding confusion where there wasn't — is worse than missing a fixable friction source. When in doubt, do nothing. (2026-02-25)

- **Eval and self-heal are complementary, not redundant** — Eval measures output quality against a rubric (scored). Self-heal detects instruction clarity issues from conversational friction (linguistically-grounded). They cross-reference during diagnosis: self-heal checks eval-history.md for pending compensations on the same instruction, eval pre-flight checks self-heal-history.md for recent patches that may affect rubric calibration. Neither replaces the other. (2026-02-25)
