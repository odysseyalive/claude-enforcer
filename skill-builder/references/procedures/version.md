## Version Command Procedure

<!-- origin: skill-builder | version: 1.0 | modifiable: true -->
## The `version` Command

Report which release of skill-builder (claude-enforcer) is installed. Low-risk,
read-only, headless-compatible. It executes immediately and never writes.

The authoritative version string lives in the shipped anchor
`references/version.md` (semver `version:` + `released:` inside the fenced block).
`plugin.json` mirrors it for the marketplace; this command reads the anchor, not
`plugin.json`, because `plugin.json` is not shipped to installed skills.

### `version` (default)

1. Read `references/version.md` from the loaded skill directory (the installed
   copy at `.claude/skills/skill-builder/references/version.md`, or the source
   `skill-builder/references/version.md` in maintainer mode).
2. Parse the fenced block for `version:` and `released:`.
3. Print exactly:

   > **skill-builder `<version>`** (released `<released>`)
   >
   > Run `/skill-builder version --check` to see whether a newer release is on `main`.

4. IF the anchor file is missing or has no parseable `version:` line → report:
   "Version anchor not found or unparseable at references/version.md. Reinstall
   or run `/skill-builder update`." Do not guess a version.

### `version --check`

1. Do steps 1 and 2 above to get the local `<version>`.
2. Fetch the anchor on `main` (same raw-GitHub base as `update.md`):
   `https://raw.githubusercontent.com/odysseyalive/claude-enforcer/main/skill-builder/references/version.md`
   Use the session's web-fetch tool, and parse its `version:` line as `<remote>`.
3. Compare `<version>` to `<remote>` by semver:
   - equal → "You're on the latest release (`<version>`)."
   - local < remote → "A newer release is available: `<remote>` (you have
     `<version>`). Run `/skill-builder update` to upgrade."
   - local > remote → "Your install (`<version>`) is ahead of `main` (`<remote>`),
     expected in a maintainer/dev checkout."
4. IF the fetch fails (no network, non-200, unparseable) → print the local
   version from step 1 and note: "Could not reach `main` to compare, showing the
   installed version only." Never block or error out on a failed check.

<!-- Self-exclusion note: `version` reports skill-builder's OWN version by design;
     it is a global info command, not a per-skill action, so the Self-Exclusion
     Rule does not apply and no `dev` prefix is needed. -->
<!-- /origin -->
