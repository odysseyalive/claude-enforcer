# Restore Command Procedure

Command overview for the backup / restore pair (moved from SKILL.md 2026-07-01): see [backup.md](backup.md), section "The `backup` / `restore` Commands".

Restore `CLAUDE.md` and the `.claude/` directory from a snapshot in `.claude-backups/` — a rotating
backup, the pinned baseline, or a pre-restore safety snapshot. The counterpart to
[backup.md](backup.md).

**Risk tier:** HIGH-RISK / DESTRUCTIVE. Restore is `strip`'s mirror image — a bulk **overwrite** of
the live tree, not a delete, and equally irreversible. It therefore inherits strip's discipline:
**display mode by default** (an impact report, no writes), **`--execute` to apply**, and a
**confirmation gate** before anything is overwritten.

- Display (default): `/skill-builder restore [snapshot]` — list snapshots / show the impact report; change nothing.
- Execute: `/skill-builder restore [snapshot] --execute` — apply, after the pre-restore snapshot and confirmation.

**Audit NEVER auto-fires restore.** It overwrites live files, so — exactly like `strip` deletions —
it stays out of the Audit Autonomy Gate's AUTO tier and is never appended to an audit task list. The
audit only ever *creates* backups (Step 0.2); restoring is always a deliberate, separate act.

**No shipped scripts.** Markdown procedure driving host commands at runtime; cross-platform via the
session `Platform:` line. **Grounding:** [backup.md](backup.md) (naming scheme, kit), [strip.md](strip.md)
(the destructive-command gate this mirrors), [shell-safety.md](shell-safety.md) /
[../shell-safety/rules.md](../shell-safety/rules.md) (pitfall-safe commands).

---

## Step 1 — Enumerate snapshots (legible, sorted by embedded date)

Read `${CLAUDE_PROJECT_DIR}/.claude-backups/`. List every snapshot, grouped and sorted by the date
embedded in the filename (never mtime):

- the pinned **baseline** (`claude-baseline-*.zip`) — always offered, labeled "original / first-ever";
- **rotating** snapshots (`claude-backup-*.zip`, newest first);
- **pre-restore** safety snapshots (`claude-prerestore-*.zip`, if any).

If the directory is absent or empty → report "no snapshots found; run `/skill-builder backup` first"
and stop. If a `[snapshot]` argument was given, resolve it to exactly one file (ambiguous/missing →
report and stop — never guess).

## Step 2 — Verify the source's integrity BEFORE trusting it

A snapshot that exists but is corrupt is worse than one visibly absent (the inert-artifact lesson). For
the chosen snapshot: confirm it is a readable zip whose listing is non-empty and contains `CLAUDE.md`
and/or `.claude/` (`unzip -l` / `Expand-Archive`-list / `tar -tf`). On failure → REFUSE this snapshot,
report the corruption, and offer the next-newest valid one. A `.tmp` in-flight file is never a
restore candidate.

## Step 3 — Impact report (blast radius made legible) — DISPLAY MODE STOPS HERE

Before any write, show what the restore would change (the strip impact-report pattern — legibility
before action):

- snapshot identity: filename, embedded date, baseline/rotating/pre-restore, verified size;
- **diff against the current live tree**: skills / directives / hooks present NOW but absent from the
  snapshot ("restoring removes these N items"), and items in the snapshot absent now ("restoring adds
  these M"). The deletions are the dangerous half — name them explicitly.
- the exact paths that will be overwritten (`CLAUDE.md`, `.claude/`).

In **display mode (default)** STOP here — print the report and the exact apply command
(`/skill-builder restore <snapshot> --execute`). Nothing is written.

## Step 4 — Pre-restore safety snapshot (always, the undo) — EXECUTE MODE

Before overwriting anything, capture the CURRENT state to
`claude-prerestore-YYYY-MM-DD-HHMMSS.zip` in `.claude-backups/` (the backup.md create+verify
mechanism, distinct `claude-prerestore-` prefix → **exempt from the keep-last-3 rotation**, so a
restore can never evict its own undo). This converts an irreversible overwrite into a reversible one —
restore's one advantage over `strip`, which leaned on git. If this safety snapshot cannot be written
and verified → REFUSE the restore (no recovery path); do not overwrite.

## Step 5 — VCS / acknowledgement precondition

Mirror audit Step 0.5 branching:

- **Clean repo** → proceed to the confirmation.
- **Dirty repo** → the impact report already named the uncommitted files at risk; require the
  confirmation to explicitly acknowledge them (the Step 4 snapshot is the rollback).
- **No VCS** → proceed only because the Step 4 pre-restore snapshot succeeded; that snapshot is the
  sole recovery path, so its success is a hard precondition (already enforced in Step 4).

## Step 6 — Confirmation gate, then atomic extract

`--execute` plus an explicit confirmation are BOTH required (the strip `--confirm` discipline). On
confirmation, extract the verified snapshot over the repo root:

```bash
ROOT="${CLAUDE_PROJECT_DIR:?}"
SNAP="$ROOT/.claude-backups/<chosen>.zip"
if command -v unzip >/dev/null 2>&1; then
  unzip -o -q "$SNAP" -d "$ROOT" || exit 1
else
  tar -xf "$SNAP" -C "$ROOT" || exit 1
fi
```

```powershell
$root = $env:CLAUDE_PROJECT_DIR
Expand-Archive -Path (Join-Path $root '.claude-backups\<chosen>.zip') -DestinationPath $root -Force
```

After extract, confirm `CLAUDE.md` and `.claude/` are present and parseable. Report what was restored,
from which snapshot, and where the pre-restore undo snapshot lives.

---

## Restore after uninstall (no skill loaded)

The headline use case — "uninstall, then restore the original" — is the one moment `/skill-builder`
(and this procedure) may be gone. The restore does **not** depend on the skill being loaded: the
host-generated restore kit that [backup.md](backup.md) § Step 5 drops into `.claude-backups/`
(`RESTORE-README.md` + `restore.sh` / `restore.ps1`) performs the same verified, pre-snapshotted
extract standalone, and the README documents the literal `unzip`/`Expand-Archive`/`tar` one-liners so
the **baseline is recoverable by hand even if both helper scripts are lost**. Point the user there when
the skill itself is being removed (the `strip` self-removal precedent: a tool cannot drive its own
restore once removed).
