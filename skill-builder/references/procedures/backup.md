# Backup Command Procedure

<!-- Relocated verbatim from SKILL.md (2026-07-01 optimize): this command's always-loaded overview now lives here, one file-read away per the grounding pattern. -->
<!-- origin: skill-builder | version: 1.5 | modifiable: true -->
## The `backup` / `restore` Commands

Snapshot and restore the project's Claude configuration so a clean uninstall of claude-enforcer is always recoverable. The audit's Step 0.2 question offers a backup right after the disclaimer; both are also standalone commands.

- `/skill-builder backup` — zip `CLAUDE.md` + `.claude/` into `.claude-backups/` at the repo root (a sibling of `.claude/`, never nested). Keeps the last **3 rotating** snapshots and one pinned **baseline** (the first-ever backup, never rotated out — the original CLAUDE.md and skill set). Adds `.claude-backups/` to `.gitignore` only if a `.gitignore` already exists. Low-risk/additive (writes only into `.claude-backups/`) → executes immediately. Atomic (temp → verify → rename) so an interrupted run never leaves a poisoned snapshot. Also drops a host-generated restore kit (`RESTORE-README.md` + `restore.sh`/`.ps1`) into `.claude-backups/` so the baseline restores even after the skill is uninstalled.
- `/skill-builder restore [snapshot]` — restore `CLAUDE.md` + `.claude/` from a chosen snapshot (baseline, rotating, or a pre-restore safety snapshot). **Destructive** (overwrites the live tree) → display mode by default (lists snapshots + a blast-radius diff), `--execute` plus a confirmation to apply. Always takes an automatic pre-restore snapshot first (its own undo, exempt from rotation), checks VCS like audit Step 0.5, and verifies the source's integrity before trusting it. **Audit NEVER auto-fires restore** (destructive — always a deliberate, separate act).

No script ships: both are markdown procedures driving host-generated commands, cross-platform via the session `Platform:` line (bash `zip`/`unzip`, Windows `Compress-Archive`/`Expand-Archive`). The audit's Step 0.2 backup runs FIRST in the auto-execution phase so the snapshot captures pre-audit state; it is skipped in headless / `audit --quick` and never blocks.

**Grounding:** Read [references/procedures/backup.md](references/procedures/backup.md) (create / rotation / baseline / gitignore / restore-kit) and [references/procedures/restore.md](references/procedures/restore.md) (snapshot enumeration, integrity verify, pre-restore snapshot, VCS precondition, blast-radius diff, atomic extract).
<!-- /origin -->

---

Snapshot the project's `CLAUDE.md` and `.claude/` directory into a date-stamped zip under
`.claude-backups/` at the repo root, keep a rotation of the last 3 rotating snapshots, preserve a
pinned **baseline** (the first-ever backup) that rotation never removes, and keep `.claude-backups/`
out of version control.

**Risk tier:** low-risk / additive (writes only into `.claude-backups/`, never touches `CLAUDE.md`
or `.claude/`). `/skill-builder backup` executes immediately. The audit calls this same procedure as
its Step 0.2 AUTO task when the user accepts the backup offer.

**No shipped scripts.** This is a markdown procedure that drives host commands at runtime (the
checksums.md precedent: "scripts generated on the target system, not shipped"). It writes a small
restore kit into `.claude-backups/` on the host, but nothing here is ever added to `manifest.txt`
(SKILL.md § Directives → No-Distribute-Hooks Gate).

**Grounding:** author every shell command pitfall-safe per [shell-safety.md](shell-safety.md) and
[../shell-safety/rules.md](../shell-safety/rules.md). The restore side is [restore.md](restore.md).

---

## Preflight

1. **Repo root.** Anchor every path to `${CLAUDE_PROJECT_DIR}` (the project root) — never assume the
   current working directory (shell-safety R1). The backup dir is `${CLAUDE_PROJECT_DIR}/.claude-backups`.
2. **Platform.** Read the session `Platform:` line (a concrete read, no agent — the checksums.md /
   code-eval.md precedent): `linux` / `darwin` / Windows+Git Bash → the **bash** branch; `windows` /
   `win32` (native PowerShell) → the **PowerShell** branch. The two branches are behaviorally identical.
3. **Nothing to capture?** If `${CLAUDE_PROJECT_DIR}/CLAUDE.md` is absent AND `.claude/` is absent →
   report "nothing to back up" and stop (not an error).

## Capture targets and exclusions

- **Include:** `CLAUDE.md` and the entire `.claude/` directory.
- **Exclude (never captured):** `.claude-backups/` is a **sibling** of `.claude/` (NOT nested inside
  it) — this sibling placement is the primary defense against the zip swallowing its own growing
  output; no recursion is structurally possible. Additionally exclude OS cruft (`*.DS_Store`,
  `Thumbs.db`) and any `.claude/skills/*/node_modules/*` trees. Keep the exclude list short and
  conservative — over-excluding risks dropping something a restore needs.

## Naming scheme (prefix-disjoint so rotation is glob-safe)

- **Rotating:** `claude-backup-YYYY-MM-DD.zip`. A second backup on the same day appends a counter:
  `claude-backup-YYYY-MM-DD-2.zip`, `-3.zip`, …
- **Baseline (pinned):** `claude-baseline-YYYY-MM-DD.zip` — a **distinct prefix**, so the rotation
  glob `claude-backup-*.zip` can never match it. No sidecar marker is needed to spare the baseline:
  the rotation glob is structurally blind to it (prefix-disjoint beats marker-based — no read/delete
  race).
- **Pre-restore safety snapshots** (written by [restore.md](restore.md), never by this procedure):
  `claude-prerestore-YYYY-MM-DD-HHMMSS.zip` — a third distinct prefix, also invisible to rotation.

Sort/compare snapshots by the **date embedded in the filename**, lexicographically — `YYYY-MM-DD`
sorts correctly as a plain string and the `-N` counter sorts after the bare name. **Never sort by
mtime** (unreliable across copies, restores, and clock skew).

## Procedure

### Step 1 — Ensure the backup dir and gitignore it

Create `.claude-backups/` if absent. Then, **only if a `.gitignore` already exists** at the repo root
(honor "check `.gitignore` if it exists" — do NOT create one where none exists), ensure it contains
the line `.claude-backups/`, idempotently and newline-safely.

```bash
ROOT="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR unset}"
BK_DIR="$ROOT/.claude-backups"
mkdir -p "$BK_DIR" || exit 1

GI="$ROOT/.gitignore"
LINE=".claude-backups/"
if [ -f "$GI" ]; then
  # -F fixed-string, -x whole-line anchor (so a comment/partial match never counts as present)
  if ! grep -qxF "$LINE" "$GI" 2>/dev/null; then
    # Guarantee a trailing newline before appending so the line never fuses onto the last one
    if [ -s "$GI" ] && [ "$(tail -c1 "$GI" 2>/dev/null)" != "" ]; then printf '\n' >> "$GI"; fi
    printf '%s\n' "$LINE" >> "$GI"
  fi
fi
```

```powershell
$root = $env:CLAUDE_PROJECT_DIR
$bk   = Join-Path $root '.claude-backups'
New-Item -ItemType Directory -Force -Path $bk | Out-Null
$gi = Join-Path $root '.gitignore'
if (Test-Path $gi) {
  if ((Get-Content $gi -ErrorAction SilentlyContinue) -notcontains '.claude-backups/') {
    Add-Content -Path $gi -Value '.claude-backups/'
  }
}
```

### Step 2 — Decide baseline vs. rotating (first-ever detection)

The backup is the **baseline** iff no valid `claude-baseline-*.zip` already exists in `.claude-backups/`.
A valid baseline existing is a one-shot property: **a second first-run NEVER overwrites a valid
baseline** (re-capturing after the user has edited files would silently replace the real original).
If a `claude-baseline-*.zip` exists but fails the Step 4 integrity check, treat it as absent and
allow a fresh baseline.

- No valid baseline present → `OUT = claude-baseline-<date>.zip`, `IS_BASELINE=1`.
- Valid baseline present → `OUT = claude-backup-<date>[-N].zip` (rotating), `IS_BASELINE=0`.

### Step 3 — Atomic create (temp → verify → rename)

Write to a temp path, verify (Step 4), and only then atomically move into the final name. An
interrupted backup leaves a `.tmp` file that the rotation glob and every restore picker ignore — a
truncated zip can never become a trusted restore source (atomic-or-absent, the project's ratified
discipline).

```bash
cd "$ROOT" || exit 1
TMP="$BK_DIR/.inflight-$$.zip.tmp"
if command -v zip >/dev/null 2>&1; then
  zip -r -q "$TMP" "CLAUDE.md" ".claude" \
      -x "*.DS_Store" -x "Thumbs.db" -x ".claude/skills/*/node_modules/*" || { rm -f -- "$TMP"; exit 1; }
else
  tar -a -c -f "$TMP" --exclude="*.DS_Store" --exclude="Thumbs.db" "CLAUDE.md" ".claude" \
      || { rm -f -- "$TMP"; exit 1; }
fi
```

```powershell
Set-Location $root
$tmp = Join-Path $bk ('.inflight-' + $PID + '.zip.tmp')
$targets = @()
if (Test-Path 'CLAUDE.md') { $targets += 'CLAUDE.md' }
if (Test-Path '.claude')   { $targets += '.claude' }
Compress-Archive -Path $targets -DestinationPath $tmp -Force
```

### Step 4 — Verify before trusting

Confirm the temp archive is a readable zip whose listing is non-empty and includes `CLAUDE.md` and/or
`.claude/` (a test-list, e.g. `unzip -l "$TMP"` / `Expand-Archive`-list or `tar -tf`). On failure →
delete the temp file and report the backup failed (do NOT rename, do NOT rotate). Only on success →
atomically rename `"$TMP"` to `"$BK_DIR/$OUT"` (`mv -f` / `Move-Item -Force`).

### Step 5 — Refresh the restore kit (host-generated, never shipped)

After a successful create, (re)write a small self-contained restore kit into `.claude-backups/` so the
**baseline is restorable even after `/skill-builder` is uninstalled** (the headline use case). These
are host-generated into the user's tree and never added to `manifest.txt` (No-Distribute-Hooks Gate):

- `RESTORE-README.md` — documents the literal hand-restore one-liners (so even total loss of the
  helper scripts leaves the baseline restorable):
  - Linux/macOS: `unzip -o claude-baseline-<date>.zip -d <repo-root>`
  - Windows: `Expand-Archive -Path claude-baseline-<date>.zip -DestinationPath <repo-root> -Force`
  - `tar` fallback: `tar -xf claude-baseline-<date>.zip -C <repo-root>`
  - States plainly that the baseline is the first-ever backup and is never auto-deleted by rotation.
- `restore.sh` / `restore.ps1` — ~15-line helpers that pick the baseline (or a named snapshot
  argument), confirm, and extract over the repo root (`unzip -o` / `Expand-Archive -Force`, `tar`
  fallback), shell-safety-clean. Write them idempotently each run so they track the current name
  scheme. **Never place the kit inside the zip** — it lives beside the zips.

### Step 6 — Rotate (only after the new backup is verified)

Rotation runs **only after** Step 4 verified the new file, so a failed/truncated capture can never
trigger eviction of a good one. Keep the newest **3 rotating** zips; delete older ones. The rotation
set is `claude-backup-*.zip` ONLY — the baseline (`claude-baseline-*`) and pre-restore snapshots
(`claude-prerestore-*`) are prefix-disjoint and never counted or deleted. The just-created file sorts
newest, so it is always in the keep set — rotation can never delete a file the same run created.

```bash
KEEP=3
mapfile -t all < <(cd "$BK_DIR" && printf '%s\n' claude-backup-*.zip 2>/dev/null | sort)
count=${#all[@]}
if [ "$count" -gt "$KEEP" ]; then
  drop=$(( count - KEEP ))
  for f in "${all[@]:0:drop}"; do
    case "$f" in
      claude-backup-*.zip) [ -f "$BK_DIR/$f" ] && rm -f -- "$BK_DIR/$f" ;;  # delete inside BK_DIR only
    esac
  done
fi
```

```powershell
$keep = 3
$rot = Get-ChildItem -Path $bk -Filter 'claude-backup-*.zip' | Sort-Object Name
if ($rot.Count -gt $keep) {
  $rot | Select-Object -First ($rot.Count - $keep) | Remove-Item -Force
}
```

### Step 7 — Report

Report one line: the file written (baseline vs rotating), its size, the gitignore action (added /
already present / no `.gitignore`), and the rotation result (kept N, deleted M). Never block.

---

## Standalone invocation

`/skill-builder backup` runs Steps 1–7 immediately (low-risk; executes without `--execute`). It is the
manual path to take a snapshot any time, independent of an audit.

## Audit integration

The audit's **Step 0.2 backup offer** (audit.md § Step 0.2) asks once, right after the disclaimer.
On "yes," this procedure runs as the **first** task of the Step 6 auto-execution phase — before any
AUTO edit, before `code-eval`/`route`, and before any `strip` — so the snapshot captures the
true pre-audit state. It is skipped in headless / non-interactive / `audit --quick` runs (no
interactive question can render), and a zip failure is a one-line warning, never a block (the audit
proceeds; the disclaimer was accepted).
