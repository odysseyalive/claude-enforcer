<!-- origin: skill-builder | modifiable: true -->
# skill-builder / claude-enforcer version

This file is the **authoritative, shipped version anchor** for the whole
skill-builder distribution (claude-enforcer). It answers one question: *which
release of skill-builder is installed?* The `/skill-builder version` command
reads the string below and prints it; `/skill-builder version --check` compares
it against the copy on `main` to report whether the install is behind.

Unlike the per-set drift anchors (`references/creative-integrity/version.md`,
`references/code-evaluator/version.md`), which carry monotonic **integers** for
audit drift-sync of one reference set, this file carries the **semver product
version** of the entire distribution.

```
version: 1.6.0
released: 2026-07-08
```

`plugin.json`'s `version` field MIRRORS this string for the marketplace. Bump
BOTH together. See CLAUDE.md "Versioning" for the release ritual.

## Changelog

- **1.6.0** (2026-07-08). Added the `version` command (`/skill-builder version`
  prints the installed version and release date; `--check` reports whether `main`
  is newer). Introduced this authoritative shipped version anchor, and corrected
  the long-stale `plugin.json` version (1.0.0 to 1.6.0) so it now mirrors this
  file.
<!-- /origin -->
