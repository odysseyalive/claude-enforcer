<!-- code-eval-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# Native-Tool Map — prefer a real analyzer when present

Native tools use real ASTs/type info and avoid most of the false positives in
[guards.md](guards.md). The procedure in [cross-file-detection.md](cross-file-detection.md)
§1 detects the language and prefers these over ripgrep heuristics when the binary
and the ecosystem marker file are present. Always reconcile tool output against
the guards — tools are also blind to dynamic imports, reflection, and external
consumers.

## Detection

Check for both the binary and the marker file:
`package.json` → JS/TS · `pyproject.toml`/`setup.py` → Python · `Cargo.toml` →
Rust · `go.mod` → Go · `pom.xml`/`build.gradle` → Java/Kotlin · `*.csproj` → .NET.

## Per-ecosystem

| Ecosystem | Dead code | Duplication | Complexity | Notes / limits |
|-----------|-----------|-------------|------------|----------------|
| **JS/TS** | `knip` (primary — unused files/exports/deps/types), `fallow`, `ts-prune` (exports only) | `jscpd` | `eslint` `complexity` rule | `ts-prune`/`depcheck` archived 2025 → prefer `knip`. `eslint no-unused-vars` is intra-file only |
| **Python** | `vulture` (`--min-confidence`, `--make-whitelist`), `ruff` (`F401`/`F811`/`F841`) | `jscpd`, `pylint` dup | `radon cc -s`, `ruff` | vulture is static-only → misses DI/reflection; pair with guards |
| **Rust** | compiler `dead_code` lint + `clippy`, `cargo machete` (deps, fast), `cargo +nightly udeps` (deps, accurate) | `jscpd` | `clippy` cognitive-complexity | `pub` items exempt from `dead_code` by design (treated as API) |
| **Go** | `golang.org/x/tools/cmd/deadcode` (whole-program from `main`; `-test`, `-whylive`), `staticcheck` `U1000` | `dupl`, `jscpd` | `gocyclo`, `gocognit` | `deadcode` can't analyze a library pkg (no `main`); reflection assumed broad |
| **Java/Kotlin** | `pmd` (UnusedX rules) | `pmd cpd`, `jscpd` | `pmd` | — |
| **Any / fallback** | — | `jscpd`, `pmd cpd` (token clones incl. renamed vars) | `lizard` (CCN/NLOC/params, ~16 langs; `--duplicate` also finds clones) | `ast-grep`/`sg` for structural grep when comment/string noise defeats plain ripgrep |

## Decision rule

Native tool present → run it, use ripgrep only to triage/contextualize its output.
No native tool → fall back to the ripgrep + entry-point + guard pipeline, and
**always report dead-code findings as candidates with a confidence band**, never
as auto-deletions — every text-only method is blind to the [guards.md](guards.md)
categories. Use a tool's verdict to *raise* confidence; never let grep alone
*lower* it below a tool's "used."
