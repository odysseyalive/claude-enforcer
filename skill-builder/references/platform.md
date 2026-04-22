# Claude Code Skill Platform Architecture

<!-- origin: skill-builder | version: 1.5 | modifiable: true -->

Reference for how Claude Code discovers, loads, and executes skills internally.
Use this when creating or optimizing skills to work *with* the platform rather than against it.

## Skill Discovery

Skills are loaded from multiple sources in priority order:
1. **Managed skills** — policy-enforced (`/path/managed/.claude/skills/`)
2. **User skills** — user home (`~/.claude/skills/`)
3. **Project skills** — project directory (`.claude/skills/`)
4. **Additional directories** — via `--add-dir` flag
5. **Legacy commands** — `.claude/commands/` (deprecated)

Each skill must be a **directory** containing `SKILL.md` (case-insensitive). Single `.md` files are not supported in `/skills/`.

Deduplication uses `realpath()` — symlinks and overlapping parent directories are handled. First-wins.

## Skill Invocation Flow

### Slash Command (`/skill-name`)
1. User types `/skill-name args`
2. Claude Code calls `getPromptForCommand(args, context)`
3. Content injected as a **user message** (not system prompt)
4. Variable substitution applied: `${CLAUDE_SKILL_DIR}`, `${CLAUDE_SESSION_ID}`, named arguments
5. Inline `!` shell blocks executed at load time (non-MCP skills only)

### Model Invocation (SkillTool)
1. Claude calls `Skill` tool with `{ skill: "name", args?: "..." }`
2. Validates: skill exists, is prompt-type, model invocation not disabled
3. **Inline** (default): content expands into conversation, shares token budget
4. **Forked** (`context: 'fork'`): runs in isolated sub-agent with own token budget

## Frontmatter Fields

| Field | Type | Purpose |
|-------|------|---------|
| `name` | string | Display name (overrides directory name) |
| `description` | string | Brief description — max **250 chars** shown in listing |
| `when_to_use` | string | Tells Claude when to proactively invoke via SkillTool |
| `model` | string | Model override (`'inherit'`, `'haiku'`, `'sonnet'`, `'opus'`) |
| `effort` | string | Reasoning effort (`'low'`, `'medium'`, `'high'`, `'xhigh'`, `'max'`) |
| `context` | `'inline'` \| `'fork'` | Execution context |
| `agent` | string | Agent type for forked execution |
| `user-invocable` | string | Can user type `/skill-name`? (default: `true`) |
| `disable-model-invocation` | string | Prevent model from using via SkillTool |
| `allowed-tools` | string/array | Tools this skill can use |
| `disallowedTools` | string/array | Tools explicitly denied to this skill |
| `argument-hint` | string | Hint for command arguments in menu |
| `arguments` | string/array | Named argument substitution |
| `hooks` | object | Hook configurations (PreToolUse, PostToolUse, PostCompact, etc.) |
| `paths` | string/array | Glob patterns — skill activates only when matching files touched |
| `version` | string | Skill version |
| `shell` | `'bash'` \| `'powershell'` | Shell for `!` code blocks |
| `memory` | `'project'` \| `'local'` \| `'user'` | Persistent cross-session memory for subagents |
| `background` | boolean | Run without blocking parent (subagents only) |
| `isolation` | `'worktree'` | Git worktree isolation for parallel editing |
| `initialPrompt` | string | Auto-submitted first turn for subagents |
| `color` | string | Visual identification in task list |
| `skills` | string/array | Skills available to this subagent |
| `mcpServers` | object | MCP servers scoped to this subagent |

## Listing Budget

Skills are listed in system reminders using **1% of context window** (~8,000 chars for 200k context).
- Each skill gets max **250 characters** for its description
- `when_to_use` is what Claude reads to decide proactive invocation
- Descriptions extracted from first markdown line if not in frontmatter
- Bundled skills never truncated; other skills truncated if budget exceeded

### Per-Project Skill-Count Discipline

Every installed skill's frontmatter loads into the listing on every turn, whether the skill is used in the session or not. In a project with 30 installed skills the roster preamble alone costs thousands of tokens per turn, compounding into real money over long sessions. Guidance:

- **Target fewer than 15 active skills per project.** Projects that routinely exceed this number are usually carrying skills relevant to a different project's workflow (e.g., voice/edit/writing/text-eval installed in a software-engineering repo that never produces prose content).
- **Disable rather than uninstall when in doubt.** Renaming `.claude/skills/skill-name/` to `.claude/skills/.disabled-skill-name/` or moving it to a sibling directory takes the skill out of the listing without destroying its config. Re-enable by renaming back.
- **Prefer `paths:` frontmatter for domain-specific skills.** A skill scoped to `"**/*.ts"` only loads when TypeScript files are touched. This is strictly better than always-active for language- or directory-specific work. See [templates.md](templates.md) § "Conditional Activation".
- **Audit skills after copying a stack between projects.** When a skill stack is copied from one project to another (as voice/edit often is), review whether each skill is actually needed in the new project before leaving it in the listing.

The `/skill-builder audit` output includes a skill-count check when the installed count exceeds 15, flagging skills that appear unused in recent work.

## Context & Lifecycle

- Skill content is loaded **on-demand** when invoked, not preloaded
- Invoked skills survive **compaction** — tagged with source ID, restored mid-session
- Agent-scoped via `agentId` to prevent cross-agent leaks
- Forked skills cleared from parent context on completion
- `getSkillDirCommands()` is memoized by `cwd`, cleared on file operations

## Conditional Skills (paths field)

Skills with `paths` frontmatter are held separately until matching files are touched:
- Stored in `conditionalSkills` Map
- Promoted to active when file matching glob pattern is edited
- Persists across cache clears within same session

## Permission Model

- Deny rules evaluated first (deny always wins)
- Allow rules support prefix matching (`review:*`)
- Skills with only "safe" properties auto-approve without user prompt
- Unsafe properties (hooks, allowed-tools, context) require user permission

## Inline Shell Blocks

`!` code blocks in SKILL.md are **executed at skill load time**:
- Output replaces the block in the injected content
- MCP skills **never** execute shell blocks (security boundary)
- Useful for dynamic content loading at invocation time
- Shell selection controlled by `shell` frontmatter field

## Design Implications for Skill-Builder

1. **Keep descriptions under 250 chars** — anything longer is truncated in the listing
2. **Use `when_to_use`** — without it, Claude won't proactively invoke your skill
3. **`context: 'fork'` for heavy operations** — prevents consuming main conversation context
4. **`paths` for contextual skills** — only activate when relevant files are being worked on
5. **Inline `!` blocks for dynamic loading** — load procedure content at invocation time instead of requiring explicit Read steps
6. **PostToolUse over PreToolUse for validation** — PostToolUse agents see the actual result and can warn; PreToolUse agents block before the action, which is more expensive and can create false denials
7. **`effort` for cost control** — use `low` for simple lookups, `high` for complex reasoning
8. **`memory` for learning agents** — enable cross-session learning for agents that benefit from pattern recognition
9. **`background: true` for non-blocking validation** — let long-running checks complete while work continues
10. **`isolation: worktree` for parallel editing** — prevent merge conflicts in agent teams
11. **`if` field over bash scoping** — more efficient, declarative, platform-independent
<!-- /origin -->
