# Discovered Patterns

*Document what works and what doesn't as you build skills:*

- **Hooks for hard rules, agents for judgment** — Hooks are fast and free (no tokens) but can only grep. Agents can reason but cost tokens and time. Use hooks for "never use ID X", use agents for "find the right ID for Y". (2026-01-22)

- **Context isolation for evaluation** — Evaluation skills should use `context: none` agents so the evaluator isn't biased by the conversation that created the content. This pattern works well for any quality check. (2026-01-22)

- **Grounding statements aren't enough** — Adding "state which ID you will use" to a skill helps but doesn't guarantee Claude reads reference.md. An ID Lookup Agent with `context: none` guarantees the ID comes from the file, not from memory. (2026-01-22)

- **reference.md reduces SKILL.md but total lines stay similar** — The goal isn't fewer total lines, it's fewer lines in SKILL.md (which loads every invocation). reference.md only loads when explicitly read. (2026-01-22)

- **Hook exit code 2 blocks, 0 allows** — Other exit codes are treated as errors but don't block. Always use exactly 2 to block. (2026-01-22)

- **Context mutability is the fundamental problem** — All text-based instructions (CLAUDE.md, rules, skills) can drift under long context. Only external enforcement (hooks, `context: none` agents) is truly immutable. See "Context Mutability & Enforcement Hierarchy" in references/enforcement.md. (2026-01-22)

- **Description must be single line** — Claude Code only shows the `description:` field when users type `/skill-name`, and multi-line descriptions get truncated. Use a single quoted line with modes/usage inline: `"Brief desc. Modes: a, b, c. Usage: /skill [args]"`. See "Frontmatter Requirements" in references/templates.md. (2026-01-24)

- **Voice directives need `context: none` enforcement** — Voice/style rules in SKILL.md get overridden by conversational context during long sessions. The creating conversation biases the model toward defending its own output. Only `context: none` agents reliably catch violations, because they evaluate text without knowing how it was created. The Text Evaluation Pair (The Reducer + The Clarifier) runs two adversarial agents in parallel — one checks for overbuilt/bloated text, the other checks for confusing/contradictory text. Hooks can't help here — voice judgment requires reasoning, not pattern matching. (2026-02-11, updated 2026-03-04)

- **Content-creation skills need different enforcement than API skills** — API skills need ID Lookup agents and grep-block hooks. Content skills need the Text Evaluation agent pair and evaluation pipelines. Detect the skill domain early (during optimize step 3) and recommend the right enforcement type. Don't apply the same playbook to both. (2026-02-11, updated 2026-03-04)

- **Audit weight should match user workflow** — Heavy audits (full structural invariant scanning, sub-command display passes, narrative reports) suit first-run or quarterly reviews. Iterative refinement sessions — which are the most common session type — need a lightweight quick check: frontmatter, line counts, wiring, priority fixes. Offer both via `audit` vs `audit --quick`. (2026-02-11)

- **Scope discipline prevents execute-mode drift** — When executing a task list, the model tends to discover "bonus" improvements and act on them unprompted. This is the same scope-creep pattern users experience in content sessions. The fix: treat the task list as a contract — execute only what's listed, note new opportunities in the completion report, never act on them. (2026-02-11)

- **Hooks report should cross-reference agents** — When a directive can't be enforced with a hook (requires judgment), the hooks command should explicitly recommend the right agent type instead of just saying "skip." Otherwise the recommendation is lost and the directive goes unenforced. The "Needs Agent, Not Hook" section in the hooks report closes this gap. (2026-02-11)

- **Silent skips create blind spots in orchestrators** — When sub-commands are told to "skip silently" if a feature doesn't exist (e.g., awareness ledger), the orchestrator (audit) inherits that silence and never surfaces the recommendation. Fix: sub-commands should skip silently (correct — they shouldn't recommend installation), but the orchestrator must have its own explicit check that reports the gap. The orchestrator is the only place with full visibility to make cross-cutting recommendations. (2026-02-23)

- **Date/time math needs programmatic backstop** — LLMs confidently produce wrong temporal claims. "A few weeks later" for a 92-day gap. "Recently" for something six months old. Hooks with datetime arithmetic catch what the model cannot. The LLM handles language; the hook handles math. Reference implementation exists in Odyssey Alive's `check-temporal-refs.sh`. See `references/temporal-validation.md` for the full specification. (2026-03-04)

- **Opus 4.7 literal execution breaks soft directives** — Conversational directives that 4.6 inferred correctly get under-executed on 4.7. Phrases like "organize around the discovery arc", "keep it conversational", "appropriate persona" all relied on the model supplying missing logic. 4.7 executes only what the text explicitly says. The fix is enforcement annotations (machine-generated CHECKPOINT blocks below the verbatim directive), not rewriting — the user's words stay sacred. See `references/enforcement.md` § "Opus 4.7 Behavioral Contract". (2026-04-22)

- **Enforcement annotations preserve directive sanctity** — When a soft directive needs 4.7-explicit execution, the fix is an annotation: a machine-generated CHECKPOINT block placed immediately below the sacred directive with numbered steps and STOP/CONTINUE gates. The directive itself never changes — it stays verbatim inside its `<!-- origin: user | immutable: true -->` block. The annotation sits outside that block, marked `auto-generated for Opus 4.7+`, with a `<!-- Source directive: "..." -->` comment quoting the original for provenance. Annotation is interpretation, not replacement. See `references/templates.md` § "Enforcement Annotation Template". (2026-04-22)

- **Analytical phases for vague input** — 4.7 executes too literally on insufficient input. Skills that accept conversational or exploratory arguments ("help me think about X", one-line feature requests, subjective terms) need an explicit Phase 0 — Assessment step that reads inputs, surfaces findings, and WAITS for user confirmation before proceeding to Phase 1. This replaces the implicit intent-inference that 4.6 used to supply. See `references/enforcement.md` § "Analytical Phase Prompting". (2026-04-22)

- **Effort level is load-bearing on 4.7** — At lower effort levels, 4.7 skips tool calls and reasons internally instead. Skills that depend on tool invocations — grounding reads, agent spawns, hook triggers — must declare a `minimum-effort-level` in frontmatter. Default `high`; content-creation skills default `xhigh`. This is distinct from the existing `effort:` field (which sets fork effort for the skill's own agents). The new field declares the minimum session effort required for the skill itself to function. See `references/templates.md` § "Frontmatter Requirements". (2026-04-22)

- **4.7-explicit skills are backward-compatible with 4.6** — Explicit instructions flow backward to generous models without breaking: a 4.6 session reading "IF count < 3 → STOP" understands it the same as a 4.7 session. Vague instructions do not flow forward: a 4.7 session reading "when it makes sense" will not infer what made sense to 4.6. Write for 4.7, test on 4.6. No backward-compat shims needed. (2026-04-22)

- **Validator chains should be opt-in for short edits** — Skills that auto-chain a validator agent (text-eval after /edit, diff-auditor after /optimize, etc.) pay an agent-spawn cost on every invocation even when the edit is trivial. The fix is a precheck gate (see `references/token-efficiency.md` § P4) plus an explicit opt-in flag for users who want the validator regardless. Default behavior: spawn only when the precheck signals ambiguity. Opt-in: `/skill --validate` forces a spawn. The agent stays available for deliberate review sessions; it just doesn't fire on every micro-edit. (2026-04-22)

- **Token efficiency is an optimization target** — Optimize doesn't just restructure for context clarity; it also scans for token-intensive patterns introduced by 4.6-era design decisions. Agent hooks doing mechanical checks, `xhigh` effort without a content-creation profile, oversized SKILL.md content, always-spawned validators, missing `strictness` field — each is detectable deterministically and each compounds across invocations. See `references/token-efficiency.md` for the full pattern catalog and detection rules. The scan is on-by-default in `/skill-builder audit` and `/skill-builder optimize [skill]`. (2026-04-22)

