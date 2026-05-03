#!/bin/bash
# Hook: register skill-bundled author agents into .claude/agents/
# Skill: /skill-builder
# Event: SessionStart (startup, resume, clear)
# Rule reference: shell-safety R1 path resolution, R2 paths with spaces, R3 trap-don't-set-e
#
# Why this exists: Claude Code discovers project-level subagents at
# .claude/agents/<name>.md (flat, project root). It does NOT walk
# .claude/skills/<skill>/agents/<name>/AGENT.md. Without registration,
# Agent(subagent_type: "<name>") fails with "Agent type not found" and the
# bookending pattern silently regresses to parent-on-4.7 prose.
#
# This hook ensures every skill-bundled AGENT.md has a corresponding symlink
# under .claude/agents/, and removes orphan symlinks for deleted agents.
# Idempotent. Silent on no-op.

trap 'echo "{\"systemMessage\":\"register-skill-agents.sh crashed (non-fatal)\"}" 2>/dev/null; exit 0' ERR

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SKILLS_DIR="$ROOT/.claude/skills"
AGENTS_DIR="$ROOT/.claude/agents"

[ -d "$SKILLS_DIR" ] || exit 0

mkdir -p "$AGENTS_DIR" 2>/dev/null || true

CREATED=0
ORPHANS_REMOVED=0

# Pass 1: ensure .claude/agents/<name>.md symlinks exist for every skill-bundled AGENT.md
while IFS= read -r -d '' agent_file; do
    name=$(awk '/^---$/{c++; next} c==1 && /^name:[[:space:]]/{sub(/^name:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit}' "$agent_file" 2>/dev/null)
    [ -n "$name" ] || continue

    target="$AGENTS_DIR/${name}.md"
    rel_source=$(python3 -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$agent_file" "$AGENTS_DIR" 2>/dev/null)
    [ -n "$rel_source" ] || rel_source="$agent_file"

    if [ -L "$target" ]; then
        existing=$(readlink "$target" 2>/dev/null || true)
        [ "$existing" = "$rel_source" ] && continue
    elif [ -e "$target" ]; then
        # A real file (not a symlink) already lives at the registration path.
        # Don't overwrite — the user may have intentionally placed it there.
        continue
    fi

    if ln -sfn "$rel_source" "$target" 2>/dev/null; then
        CREATED=$((CREATED + 1))
    fi
done < <(find "$SKILLS_DIR" -path '*/agents/*/AGENT.md' -print0 2>/dev/null)

# Pass 2: remove orphan symlinks (target no longer exists)
while IFS= read -r -d '' link; do
    if [ -L "$link" ] && ! [ -e "$link" ]; then
        if rm "$link" 2>/dev/null; then
            ORPHANS_REMOVED=$((ORPHANS_REMOVED + 1))
        fi
    fi
done < <(find "$AGENTS_DIR" -maxdepth 1 -type l -print0 2>/dev/null)

if [ "$CREATED" -gt 0 ] || [ "$ORPHANS_REMOVED" -gt 0 ]; then
    echo "{\"systemMessage\":\"register-skill-agents: registered ${CREATED}, cleaned ${ORPHANS_REMOVED} orphan(s)\"}"
fi

exit 0
