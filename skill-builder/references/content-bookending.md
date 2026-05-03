# Content Bookending: Auto-Routing Writing Work to Opus 4.6 Subagents

**Read this before adding the Content Bookending Detection step in `agents.md` Step 4d, or when surfacing bookending findings during audit.**

## What "bookending" means

The parent agent (Opus 4.7) handles execution, code, and tool orchestration. When a skill's procedure produces **written content** — creative prose, dialogue, lessons, or technical documentation — the parent dispatches that step to a dedicated subagent declared with `model: claude-opus-4-6` in its AGENT.md frontmatter. The 4.6 subagent runs the writing, returns a structured payload, and the parent (still on 4.7) integrates the result. The pattern is "bookended" because the dispatch and the integration sit on either side of a 4.6 island inside an otherwise-4.7 conversation.

This is not the older `/model claude-opus-4-6` … `/model claude-opus-4-7` user-driven switch. The parent never changes models. The platform respects the subagent's frontmatter `model:` field when the parent invokes it via the Task tool.

**Reference implementation:** `nsayka-wawa` ships five content-author subagents (`room-scene-author`, `npc-dialogue-author`, `mission-prose-author`, `plot-narrative-author`, `classroom-lesson-author`) all carrying `model: claude-opus-4-6`. See its `.claude/plans/agent-refactor-2026-05-01.md` for the full design history.

## Why route writing work to 4.6

Opus 4.7 executes literally and is excellent at code and structured output. On creative and explanatory writing, it tends to under-fill — it does what the directive *says* without inferring tone, rhythm, or voice. 4.6 still infers. For voice-driven content, technical documentation, dialogue, lessons, and any prose that benefits from filling-in-the-blanks, 4.6 produces work readers find more natural. Routing only the writing steps to 4.6 keeps 4.7's execution discipline for everything around them.

## What counts as "content work" (in scope)

Both creative AND technical writing are in scope:

| Class | Examples |
|-------|----------|
| **Creative / voice-driven** | Articles, blog posts, newsletters, dialogue, narrative prose, lesson scripts, marketing copy |
| **Technical documentation** | README sections, API docs, tutorials, runbooks, architectural explanations, conceptual overviews |
| **Hybrid** | Release notes, changelogs that include narrative framing, error messages with explanatory tone |

**Out of scope** (do NOT bookend these):

- Pure structured-data emission (yaml, json, csv, table rows)
- Code generation (functions, scripts, configs)
- Diff / patch / refactor operations
- ID lookups, format checks, validation output
- Single-line strings (commit messages, status updates)

The line: if the artifact is **paragraphs a human will read for meaning or flow**, it's content work. If it's **structured data a machine will parse**, it isn't.

## Detection signals

Use **two of four** signals before recommending bookending. One signal alone false-positives.

| # | Signal | How to detect |
|---|--------|---------------|
| 1 | **Skill grounds against a content/voice skill** | SKILL.md or any procedure file links to `voice/`, `writing/`, `edit/`, or `text-eval/` |
| 2 | **Authoring verbs in execute steps** | Procedure files contain "author", "draft prose", "compose", "write the description", "write the body of", "produce the article" — present-tense imperatives that target prose |
| 3 | **Output contract is freeform paragraphs** | Procedure's "Output" or "Returns" section describes paragraphs/sentences/dialogue/markdown body — NOT yaml/json/table rows |
| 4 | **Skill name/description matches content vocabulary** | Skill name or description includes: writing, voice, prose, narrative, dialogue, copy, lesson, story, article, post, newsletter, README, docs, documentation, tutorial, runbook |

A skill matching only signal 4 (content-token in name) is NOT enough — many skills mention "documentation" without producing prose.

### Special case: technical documentation

A skill whose primary output is technical docs (README writers, API doc generators, tutorial authors) should bookend even if it doesn't ground against a voice skill. The "voice" for technical docs is project-house-style or platform-house-style; the same 4.6 strength (filling explanatory tone) applies. Treat signals 2 + 3 as sufficient when signal 4 includes any of: README, docs, documentation, tutorial, runbook, guide.

## Idempotency: when bookending is already configured

**Run this check FIRST. If any condition is true, skip the rest of the bookending evaluation and report "Content bookending already configured."**

Three conditions any of which means the skill already has bookending:

1. **Frontmatter signal.** Any `agents/*/AGENT.md` under the skill declares `model: claude-opus-4-6` in its frontmatter.
2. **Dispatch signal.** Any procedure file under the skill contains a Task / Agent invocation with an explicit `model: "claude-opus-4-6"` or `model: claude-opus-4-6` argument.
3. **CHECKPOINT signal.** The skill's SKILL.md contains a CHECKPOINT block whose name includes "Prose Subagent Dispatch" OR "Subagent Dispatch" OR "Content Subagent" OR similar wording mapping commands to 4.6 agents.

Detection commands (use Read/Grep/Glob, not Bash, when running this check inside skill-builder):

- Glob `.claude/skills/<skill>/agents/*/AGENT.md`; for each, check frontmatter for `model: claude-opus-4-6`.
- Glob `.claude/skills/<skill>/references/procedures/*.md` and `.claude/skills/<skill>/SKILL.md`; grep for `claude-opus-4-6`.
- Read `.claude/skills/<skill>/SKILL.md`; grep for `Prose Subagent Dispatch|Subagent Dispatch|Content Subagent`.

When idempotency triggers, the audit/agents report should say:

> **Content Bookending:** Already configured (detected via [frontmatter|dispatch|CHECKPOINT] in [filename]). No changes proposed.

Do not propose modifications. Do not "harmonize" a working configuration with the template. The user's existing wiring is the source of truth.

### Partial configuration

If only some content-author agents have `model: claude-opus-4-6` and the skill produces additional content artifacts not yet routed, treat as a **gap** rather than fully configured. Report:

> **Content Bookending:** Partially configured. Authors with 4.6 model: [list]. Content artifacts without a dedicated 4.6 author: [list]. Proposed: [missing author agents].

## What to propose (when not idempotent and signals match)

For each procedure that produces content, propose:

1. **A dedicated content-author subagent** at `.claude/skills/<skill>/agents/<role>-author/AGENT.md` with:
   - `name:` matching the folder
   - `description:` one line covering what content it authors
   - `persona:` unique across the project (the Persona Assignment Gate enforces this)
   - `model: claude-opus-4-6`
   - `allowed-tools:` minimum needed (typically `Read, Grep, Glob`; `Edit` only if the agent persists its own output)
   - `context: none`

2. **A dispatch CHECKPOINT in the parent SKILL.md** naming each command and the author agent it dispatches to. Use this format:

       <!-- ENFORCEMENT ANNOTATION — auto-generated for Opus 4.7+ literal execution -->
       <!-- Source: Content Bookending — route writing work to claude-opus-4-6 subagents -->
       CHECKPOINT — Prose Subagent Dispatch:
       1. Detect content-producing command. The following commands produce written content:
          - <command-1> → dispatches to <author-1>
          - <command-2> → dispatches to <author-2>
       2. IF invocation includes `--manual-prose` → bypass dispatch; main agent (4.7) authors the content directly. Continue to step 5.
       3. IF command matches a content-producing entry → spawn the named author subagent via Task tool with `subagent_type: "<author-name>"`. The platform reads `model: claude-opus-4-6` from the agent's frontmatter.
       4. Receive the structured payload from the subagent. Integrate it into the surrounding artifact (file, response, or downstream procedure step) without rewording the prose.
       5. Continue with the parent procedure.
       <!-- END ENFORCEMENT ANNOTATION -->

3. **Procedure file edits** replacing inline prose-generation steps with explicit `Agent({ subagent_type: "<author-name>", prompt: "..." })` invocations. The procedure passes the inputs the author needs (target file, scope, prior context) and receives the prose payload back.

4. **A `--manual-prose` flag** documented in the parent SKILL.md commands table. Setting this flag bypasses the dispatch and lets the parent (4.7) author directly. This is the escape hatch for cases where 4.6's output regresses, where the prose is short enough that subagent overhead isn't worth it, or where the user wants 4.7's literal output.

## Grounding bundle: when to recommend, when not to

`nsayka-wawa` distilled 18 grounding files (voice + craft + pedagogy + forest-beings) into one ~3K-token `references/prose-grounding-bundle.md` because each subagent dispatch needed all 18 files and reading them per-dispatch was wasteful (~6× cheaper after distillation).

**Recommend a bundle ONLY when:**

- The skill dispatches to content authors more than ~3 times per typical session, AND
- Each dispatch reads ≥3 grounding files (voice, style guide, glossary, etc.), AND
- The grounding files are stable (don't change between dispatches in the same session)

**Otherwise, the author subagent reads the existing grounding files directly** (one Read per file). For most skills with 1–2 dispatches per session, the bundle is overhead, not savings.

If a bundle is recommended, also propose a maintenance command (`/<skill> regen-grounding-bundle`) that re-distills when source groundings change. Without that, the bundle silently goes stale.

## Persona uniqueness

Every new content-author agent needs a unique persona per the Persona Assignment Gate (see SKILL.md). Personas should fit the role:

- Creative prose → editorial / craft personas (essay coach, novelist, dialogue writer)
- Technical docs → instructional personas (technical writer, runbook author, exhibit copywriter)
- Dialogue → voice-aware personas (radio-drama writer, screenwriter)
- Lessons → pedagogical personas (textbook author, exhibit copywriter, museum educator)

Reference [`agents-personas.md`](agents-personas.md) for the full selection heuristic. The PreToolUse hook on AGENT.md writes catches duplicate personas at tool-call time as a backstop.

## Risks and guardrails

| Risk | Mitigation |
|------|------------|
| **False-positive bookending** (technical script ends up routed to 4.6) | Require 2 of 4 signals. Out-of-scope list above is authoritative. |
| **Subagent spawn cost > savings** (skill rarely runs, dispatches once) | Recommend bookending only when the skill is invoked frequently enough that 4.6's quality lift offsets spawn overhead. For one-off skills, skip. |
| **Grounding-bundle staleness** (source files change, bundle doesn't) | Only recommend bundle when ≥3 dispatches per session. Always pair with a regen command. |
| **Persona collision** | Persona Assignment Gate + AGENT.md PreToolUse hook block duplicates at write time. |
| **User wants 4.7 anyway** (e.g., for highly structured "writing" like log lines) | `--manual-prose` flag bypasses dispatch. Document it in the parent SKILL.md. |
| **Existing config rewritten by drift** | Idempotency check runs first. Working configurations are NEVER modified. |

## Display-mode discipline

`agents` is a high-risk command; bookending recommendations are display-only by default. The detection step proposes additions but does NOT write files unless `--execute` is set. In `--execute` mode, file creation follows the same task-list discipline as other agent creation: one TaskCreate task per agent file plus one task per CHECKPOINT addition plus one task per procedure-file edit.

## Audit integration

During a full audit, this detection runs inside the per-skill `agents` display-mode pass (Step 4 of `audit.md`). Findings surface in the Agent Opportunities section of the aggregate report under a dedicated "Content Bookending" column or sub-table. Idempotency-pass skills are reported as "configured" and surface no recommendations. Gap skills surface their proposed authors and the dispatch CHECKPOINT for review.

The audit's priority-ranking agent panel (Step 4e) treats bookending recommendations as **medium priority** by default — they improve content quality but do not break anything when absent. Promote to high priority only if the skill is heavily content-focused and currently producing prose on 4.7 that the user has flagged as thin.

## Self-exclusion

Skill-builder is excluded from its own actions unless invoked with `dev` (see SKILL.md § Self-Exclusion Rule). The Content Bookending detection inherits this — it never proposes 4.6 subagents *for* skill-builder under a non-`dev` invocation, even if skill-builder happened to grow content-authoring procedures.
