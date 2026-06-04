# Claude Enforcer

> **Claude Enforcer is now compatible with Opus 4.7.** [Learn what changed →](#claude-47-upgrade)

> **Content generation skills can fall back to 4.6 if needed.** [See the workaround →](#content-generation-workaround)

Most people focus on what to *say* to AI. The real leverage is in what you *show* it before you speak.

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is Anthropic's command-line AI assistant for software development. When you run it in a project directory, it reads a `CLAUDE.md` file at the start of every conversation. This file is where you write the rules. Your project's architecture, coding conventions, API keys to avoid, workflows to follow. Everything Claude needs to know before it touches your code.

The problem is that rules fade. As conversations grow longer, the instructions you loaded at the start get diluted by everything that comes after. Researchers call this ["lost in the middle"](https://arxiv.org/abs/2307.03172), and it means your carefully written rules stop being consulted reliably.

This tool helps you build a context system that resists drift.

![Instructions left at the start of a conversation, consumed by everything that follows](assets/images/breadcrumbs.png)

## Install

Claude Code **v2.1.32 or later** is required. Skills became user-invocable in v2.1.3 (January 2026). Earlier versions refuse to run `/skill-builder` directly. Check with `claude --version` and update with `claude update` if needed.

### Option A. npx (recommended)

```bash
npx skills add odysseyalive/claude-enforcer
```

Works across Claude Code, Cursor, Codex, and [37 other agents](https://skills.sh/docs).

### Option B. curl

Includes extra setup (agent teams, auto-approved research tools).

```bash
claude /init
```

If you haven't already initialized the project. Then run the installer.

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
```

Then run your first audit.

```
/skill-builder audit
```

### Updating

To pull the latest version, run the installer again or use `/skill-builder update` from inside a session. See [COMMANDS.md § Maintenance](COMMANDS.md#maintenance) for both update paths.

## Building & Modifying Skills

You'll always be tweaking. A skill that works today might need adjustment next week as you discover edge cases, add new rules, or realize something drifts when it shouldn't. The whole point of the tool is to make that easy.

Describe what you need in plain language. No structure required.

```
/skill-builder I need a skill for deploying to production
```

```
/skill-builder add a rule to my deploy skill: always run tests first
```

```
/skill-builder my api skill is getting too long, help me split it up
```

```
/skill-builder I'm glad that problem got figured out. I never want to deal with that again. Can you make a skill for this and hook it into other skills affected by this?
```

Skill-builder shapes the problem from the description. The command list, formal frontmatter, hook wiring. None of that is something you need to know upfront.

### Capturing Directives Mid-Session

Sometimes you notice a pattern violation while you're working. Claude uses a forbidden phrase, drifts from your voice, or makes a mistake you want to prevent from ever happening again. You don't want to stop and run a full audit. You just want the rule captured.

```
/skill-builder inline writing Never use the phrase "in conclusion" in any article.
```

```
/skill-builder inline deploy Always run the test suite before pushing to production.
```

This adds the directive verbatim to the target skill with a date and source attribution. If the directive is programmable (contains "never" or "always" with a specific value), skill-builder suggests a hook but won't create one unless you ask.

### Retiring a Skill

Sometimes a skill outlives its purpose. The directive moved into another skill, the workflow stopped getting invoked, the project shifted off the platform that needed it. `strip` handles the cleanup. It deletes the skill directory. Then it sweeps every cross-reference, hook binding, and route catalog entry across the rest of the project. Other skills don't sit pointing at a missing target.

```
/skill-builder strip old-deploy
```

Display mode by default. Add `--execute` to apply. If other skills hard-depend on the target, an additional `--confirm-breaking` flag is required.

See [COMMANDS.md § Creating & Adding](COMMANDS.md#creating--adding) for `new`, `inline`, and `ledger`. See [COMMANDS.md § Removing](COMMANDS.md#removing) for `strip`. See [COMMANDS.md § Restructuring & Enforcement](COMMANDS.md#restructuring--enforcement) for `optimize`, `agents`, `hooks`, and `checksums`.

## Keep Your Skills Current

Skills age. A directive that worked perfectly on one model gets under-executed on the next. A hook that felt essential two releases ago might now be redundant with a new platform feature. An agent panel that made sense when every judgment call needed an outside vote might now be firing too often against too little signal. None of this is a failure of the skill. It's the model underneath shifting shape.

The `/skill-builder audit` command is the health check for that. It scans your CLAUDE.md, your rules, and every installed skill, and it flags what's gotten stale. Directives that need enforcement annotations for the current model. Hooks that could downshift from agent to command. Oversized SKILL.md files carrying machinery that should live in a reference. Effort levels that cost more than they return. After every Claude update, run it. After anything fundamental changes in how you work with the tool, run it. Every so often just because.

```
/skill-builder audit
```

Full scan. For a lightweight pass (frontmatter + line counts + priority fixes only):

```
/skill-builder audit --quick
```

See [COMMANDS.md § Inspection & Diagnostics](COMMANDS.md#inspection--diagnostics) for what each mode covers and when `verify` or `cascade` is the better tool for the job.

## Routing Instead of Freelancing

A skill exists for a reason. Someone codified the rules, wrote the directives, wired the hooks. When the AI picks up a task and runs its own ad-hoc tool calls instead of consulting that skill, the rules get bypassed. Not by intent. By default. The model reaches for the most direct path through whatever tools it remembers, and the carefully built skill sits unused.

The `route` system fixes that. It has two halves.

```
/skill-builder route index
```

This builds an index of every installed skill. Names, descriptions, modes, trigger phrases. The output lives inside a new `/route` skill that the AI can consult for any task. Pass it a task description and it picks the right skill and function.

```
/route find recent papers on transformer architecture
/route summarize this URL
/route audit the skills in this project
```

The second half is `embed`.

```
/skill-builder route embed
```

This walks every installed skill and looks for places where the workflow tends to hand off to research, web search, or follow-up analysis. For each skill that has those open-ended steps, embed inserts a Route Consultation Gate. A short checkpoint that tells the AI to consult `/route` before improvising on a follow-up. The skill stays in charge of its own deterministic steps. Route catches the freelancing.

Both commands are smart on re-run. Index diffs against the prior catalog and reports what changed. Embed reconciles its consultation gates against what's already on disk. New skills get gates added. Skills that no longer need a gate get them removed. Stale gates get refreshed. The audit appends both as the last two task items, so every audit ends with a current index and current gates.

As your skill library grows, so does the chance the AI silently picks a generic path through tasks that have purpose-built skills. Route is the pattern that keeps that drift from compounding. Build a skill once. The system finds it.

See [COMMANDS.md § Routing](COMMANDS.md#routing) for the full command reference.

## Catching Code Mistakes Before They Land

AI writes code fast and leaves a mess behind it. Dead exports nothing imports. A helper reinvented three files over from one that already exists. A function that grew an extra layer of abstraction for its single caller. None of it breaks the build, and all of it accrues.

The `code-eval` command builds a `code-evaluator` skill that watches for exactly that. It is language-agnostic. It uses ripgrep and whatever native tools a project already has instead of depending on one compiler, so it reads a Rust crate, a Python package, and a TypeScript app the same way.

```
/skill-builder code-eval create
```

The skill works in three layers. Before code gets written, an advisor agent checks the planned approach against the existing codebase and asks whether the thing already exists and whether it will rot. After code gets written, a reviewer agent reads the diff for dead code, duplication, and complexity. On demand, a full sweep surveys the whole tree.

```
/code-evaluator review
/code-evaluator sweep
```

The safety model is deliberately strict. A grep that finds no references is a candidate, never a verdict. Only high-confidence findings that clear every false-positive guard get fixed automatically, and only when the build and the tests still pass afterward. Duplication and complexity are always left for a person to decide.

Audit ties it together. Run `/skill-builder audit` and it creates the evaluator when it's missing, keeps the detection references current as they improve, and wires the pre-write and post-write gates into every skill that writes, edits, or debugs code.

See [COMMANDS.md § Code Evaluation](COMMANDS.md#code-evaluation) for the full command reference.

## Philosophy

| Layer | What It Is | Purpose | Drift-Resistant? |
|-------|------------|---------|------------------|
| `CLAUDE.md` | File loaded at conversation start | Universal guidance | No |
| Rules | Files in `.claude/rules/` | Always-on context (keep lean) | No |
| Skills | On-demand instruction files | Domain-specific rules | No (but refreshable) |
| Hooks | Shell scripts before actions | Hard blocks on forbidden actions | Yes |
| Agents | Subprocesses with isolated context | Independent evaluation without drift | Yes |
| Teams | Coordinated parallel instances | Collaborative implementation | Yes |

![Three figures at separate desks, each studying the same document under their own light](assets/images/independent-agents.png)

There's a tension here worth naming. Validation keeps AI honest, but too much of it keeps AI from working. Three hooks firing on every SKILL.md edit means three Claude invocations before anything lands. Skill-builder keeps the hot path cheap. Mechanical checks (grep, regex, checksum) fire on every edit. The agent-heavy validators only run when execution tooling actually reshapes a skill, and even then a deterministic precheck skips the spawn when the change is trivial. The enforcement still happens. It just stops being the bottleneck.

Each layer has its own details and tradeoffs. See [COMMANDS.md § Technical Background](COMMANDS.md#technical-background) for individual agents vs. agent teams, rules vs. skills, the optimization structure that splits SKILL.md and reference.md, and the awareness ledger that turns session knowledge into searchable memory.

## Claude 4.7 Upgrade

Something shifted between Opus 4.6 and 4.7. 4.6 was generous. If you wrote "keep it conversational" in a skill directive, the model read between the lines. It inferred what you meant and did something close to what you wanted. 4.7 doesn't do that. It executes what the text says, nothing more. "Keep it conversational" under-executes because the model won't fill in the missing logic. "IF count < 3 → STOP" executes reliably because there's nothing to infer. The change looks like a cost at first. It's actually a discipline.

This update is what that discipline looks like, applied to every skill in the enforcer. The `convert` command walks through each skill and recalibrates. User directives stay verbatim. Sacred as always. Underneath each soft directive it generates an enforcement annotation, a numbered checkpoint that translates the intent into the explicit steps 4.7 will actually follow. Workflow steps get rewritten from inference-friendly phrasing to literal instructions. A `minimum-effort-level` lands in the frontmatter so 4.7 knows how hard to think. Where vague user input enters a skill, a Phase 0 assessment asks the clarifying questions before execution begins. The upgrade also brought token-efficiency work. Precheck-gated diff auditors. Command-first hooks instead of agent-first. Opt-in agent panels. A `strictness` field that lets a skill author opt up or down on verification cost. Not every piece of this is 4.7-only. But 4.7 is what forced the clarity.

Now the part that matters more than this release. Anthropic shipped Mythos Preview the same month 4.7 became available. Codename Capybara. A new tier, not an Opus upgrade, restricted to a small circle of critical-infrastructure partners through something called Project Glasswing. It found thousands of zero-day vulnerabilities during testing, across every major operating system and web browser. It was kept behind structured access because its autonomous capabilities were judged too dangerous for broad API release. 4.7 is the less-risky sibling that shipped alongside it. Mythos-class capabilities will reach the rest of us eventually. They always do. And the harness this project builds is not 4.7 scaffolding. Sacred directives, mechanical enforcement hooks, fresh-context validators, directive checksums, explicit execution contracts. These are the infrastructure for steering much more capable, much more autonomous models without losing the plot. 4.7 teaches us the vocabulary. Mythos will require fluency. Building the muscle now on a model that forgives less than 4.6 but more than what's coming is preparation, not paranoia.

![A capybara sitting calmly at the edge of a misty river at dawn, birds resting on its back](assets/images/mythos-capybara.png)

### Upgrade in three commands

Stay at the terminal while these run. Each step may pause to ask a follow-up question or wait for your approval before it continues. The upgrade isn't finished until the last prompt clears.

1. Install or Upgrade Claude Enforcer

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/install)"
```

2. Convert every installed skill to 4.7 compatibility

```bash
claude /skill-builder convert --all --execute
```

3. Re-audit every skill after conversion

```bash
claude /skill-builder audit
```

Each skill runs through a per-skill conversion with its own precheck and revert path. See [COMMANDS.md § Upgrading to Opus 4.7](COMMANDS.md#upgrading-to-opus-47) for what each conversion does and how to roll back if a particular skill's result looks off.

### Content generation workaround

Some creative work lands thinner on 4.7. Voice skills, writing skills, anything that leans on the model inferring tone from soft directives. Every skill audited by Claude Enforcer stays backwards compatible with Opus 4.6, so when 4.7's output doesn't sound right, step back to 4.6, rerun the same skill, and compare.

```
/model claude-opus-4-6
```

Read both outputs side by side. If 4.6 produces the voice you recognize, keep that model on for that kind of work and switch back to 4.7 for everything else.

## Learn More

- [Context Is the Interface](https://odysseyalive.com/focus/context-is-the-interface). The insight behind this approach.
- [Mrinank Sharma, Please Come Back to Work](https://odysseyalive.com/focus/mrinank-sharma-please-come-back-to-work). Why adversarial agents outperform consensus.
- [Your AI Has Amnesia](https://odysseyalive.com/focus/your-ai-has-amnesia). Why AI coding assistants forget instructions and what to do about it.

See [COMMANDS.md § Further Reading](COMMANDS.md#further-reading) for the Claude Code documentation, skills guide, agent-teams spec, and the lost-in-the-middle research.

## Acknowledgments

Special thanks to Joe Loudermilk, who helped me understand why giving an LLM a second opinion opens doors. That conversation planted the seed for everything the agent system became.

Thanks also to [Autonomee](https://www.skool.com/autonomee/about?ref=ab20c334980842ac864a041f7c84f88c) for hooking together the greatest minds in the business.

## License

MIT
