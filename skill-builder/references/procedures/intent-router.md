## Intent Router Procedure

**Map freeform `/skill-builder <text>` invocations to an existing command+skill, a new-skill proposal, a directive addition, or an honest "not a skill op" halt. The router NEVER modifies files — it classifies and re-dispatches.**

Invoked by SKILL.md § Self-Exclusion Rule CHECKPOINT step 6, when the first positional argument is non-empty but is not in the known-command set.

### Step 1: Preflight

1. Receive `intent_text` (the full remaining argument string, including the unmatched first token) and `dev_mode` (bool) from the caller.
2. Tokenize `intent_text` on whitespace. IF fewer than 3 tokens → set `short_intent = true` and SKIP Step 3 (agent classification). Go directly to Step 6 with minimal options.
3. Trim leading filler ("please", "can you", "I want to", "I'd like to") from a working copy used only for classification. The original `intent_text` stays verbatim for any downstream dispatch.

### Step 2: Gather Skills Inventory

1. Follow [skills.md](skills.md) Steps 1–3 to build rows of `{skill_name, description}`. Do NOT re-implement the glob or frontmatter parse inline.
2. IF `dev_mode == false` → remove `skill-builder` from the resulting inventory (it is excluded from its own targeting).
3. Hold the inventory in memory for Step 3.

### Step 3: Spawn Classifier Agent

Per SKILL.md § "CHECKPOINT — Non-Obvious Decision Gate", freeform intent classification is inherently a guess that requires independent input. STOP and spawn a single `intent-router` agent via the Task tool.

Input payload for the agent:

- `intent_text` — verbatim user string
- `skills_inventory` — from Step 2
- `known_commands` — the set listed in SKILL.md § Self-Exclusion Rule CHECKPOINT step 3
- `dev_mode` — from Step 1

The agent is defined at `agents/intent-router/AGENT.md`. Its persona is unique (reference desk clerk) and does not duplicate any existing persona. Its tools are read-only (Read, Grep, Glob).

Parse the agent's JSON output. Fields: `classification`, `target_skill`, `suggested_command`, `confidence` (0.0–1.0), `reasoning`, `alternatives[]`.

### Step 4: Apply Classification

Before acting, print a one-line announcement so the user can see what got interpreted:

```
→ Routing: [classification] — [suggested_command] [target_skill] (confidence [0.xx])
  Reason: [reasoning]
```

Then act on the classification:

| `classification` | Action |
|---|---|
| `existing-skill-sub-command` | Re-dispatch: construct the invocation `<suggested_command> <target_skill>` and resume SKILL.md § Self-Exclusion CHECKPOINT at step 7 with that resolved command + target. The target procedure handles its own preflight (including self-exclusion) and display/execute defaults. |
| `add-directive-to-existing` | Re-dispatch as `inline <target_skill> <intent_text>`. The `inline` procedure handles provenance wrapping and the post-action chain. |
| `new-skill` | Derive a skill name from `intent_text`: lowercase, kebab-case, ≤4 words, drop stopwords (a, an, the, for, of, to, with, and). Present via AskUserQuestion: "Create new skill `/[derived-name]` for: [one-line summary of intent]?" Options: `Create it`, `Edit name`, `Cancel`. On `Create it` → re-dispatch as `new <derived-name>`. On `Edit name` → prompt for a replacement name and re-dispatch with the corrected name. On `Cancel` → STOP. |
| `not-a-skill-op` | STOP. Print: "This doesn't appear to be a skill-builder operation. The skill-builder skill operates on skills, directives, agents, and hooks. If you meant something else, invoke the appropriate skill directly or ask in a fresh message." |

### Step 5: Confidence Gating

Apply before Step 4's `existing-skill-sub-command` and `add-directive-to-existing` branches. (The `new-skill` branch always confirms via AskUserQuestion because `new` writes files. The `not-a-skill-op` branch halts.)

1. IF `confidence < 0.70` → go to Step 6 (AskUserQuestion ambiguity resolution).
2. IF the top two alternatives are within 0.15 of each other → go to Step 6.
3. Otherwise → proceed with Step 4's dispatch.

### Step 6: Ambiguity Resolution via AskUserQuestion

Present at most 5 options, ordered by the agent's ranking. Mirror the pattern in [post-action-chain.md](post-action-chain.md) Step 3 (numbered list of options).

Options to include (in order):

1. Up to 3 top candidate `(command, skill)` pairs from the agent, each rendered as: "Run `[command] [skill]` — [one-line reasoning from the agent]"
2. "Create a new skill for this" — only include when the intent genuinely reads like new capability
3. "This wasn't meant for skill-builder — cancel"

Dispatch by user selection:

- **Candidate pair** → resume SKILL.md § Self-Exclusion CHECKPOINT at step 7 with the resolved command + target.
- **Create a new skill** → go to Step 4's `new-skill` branch (derive name, confirm, dispatch to `new`).
- **Cancel** → STOP with the "not a skill op" message from Step 4.

When `short_intent == true` (Step 1.2), present only the final two options: "Create a new skill for this" and "Cancel" — the classifier's candidate pairs aren't trustworthy on such thin input.

### Step 7: Edge Cases and Invariants

- **Empty args.** Unreachable. SKILL.md CHECKPOINT step 4 already short-circuits to the full-audit default before invoking the router.
- **`dev` as first token.** Unreachable. CHECKPOINT step 1 strips `dev` before the router sees anything.
- **Unknown target skill from the agent.** IF `target_skill` is not present in the Step 2 inventory, treat it as a classifier error and fall through to Step 6 (ambiguity gate).
- **Infinite re-dispatch.** The router re-dispatches to concrete command names from the known-command set only. It never returns `intent_text` as a command. Re-entry into the router from a re-dispatch is therefore impossible by construction.
- **No file writes.** The router does NOT call Write/Edit, does NOT regenerate checksums, does NOT invoke the post-action chain directly. All file-touching work happens inside the re-dispatched command.
- **Skill-builder self-targeting.** Re-dispatch always lands at SKILL.md CHECKPOINT step 7, where the self-exclusion rule enforces the `dev`-prefix requirement. The router does not duplicate that enforcement.

### Grounding

- [skills.md](skills.md) — canonical inventory procedure (reused in Step 2)
- [post-action-chain.md](post-action-chain.md) — AskUserQuestion pattern (mirrored in Step 6)
- [agents-personas.md](../agents-personas.md) — persona uniqueness rules (the `intent-router` agent's persona was chosen against the existing set)
