<!-- code-eval-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# Cross-File Detection — dead code, duplication, complexity (language-agnostic)

Reimplements a code-intelligence tool's *method* (module-graph reachability,
re-export resolution, duplication modes, complexity scoring) as AI instructions
that work in ANY language using ripgrep + file reads + opportunistic native
tools. No compiled analyzer required.

**Governing thesis: ripgrep is a _candidate generator_, never a _verdict engine_.**
Textual reference-counting only proposes; the verdict belongs to (a) a native
compiler/linter when one exists, and (b) the destructive verify gate (build +
full tests, atomic, revert-on-fail) when it doesn't. No procedure may let grep
alone authorize a deletion — most acutely in dynamic languages (Python/JS/Lua/
Bash) where no compile step catches a wrong call before it ships.

Read [guards.md](guards.md) (the 20 named false-positive guards) before flagging
anything dead. Read [native-tool-map.md](native-tool-map.md) for the per-language
tool table and [mistake-taxonomy.md](mistake-taxonomy.md) for what to look for.

---

## 0. Two modes — same steps, different candidate set

| | **Mode A — Review (post-write)** | **Mode B — Sweep (full codebase)** |
|---|---|---|
| Trigger | Just wrote/edited code; a diff/PR | Explicit whole-tree audit |
| Candidate set | Symbols/files **touched in the diff** + direct callers | **Every** exported/top-level symbol and file |
| Cost | Cheap by construction | Batch candidates; cap reads; sample hotspots; fan out per directory |
| Default action | Inline notes; HIGH-tier fixes only | **Report-only** at scale |

Mode A is Mode B with the candidate set pre-filtered to the diff:

```bash
git diff --name-only HEAD                 # or origin/main...HEAD for a PR
git diff --unified=0 HEAD | rg '^\+'      # added/changed lines → new symbols
```

Every step below is written for Mode B; for Mode A substitute "candidate set"
with "diff-touched set."

---

## 1. Native-tool gate (run FIRST, every time)

Native analyzers use real ASTs/type info and avoid most false positives. Detect
the language, prefer a real tool, fall back to ripgrep heuristics only when none
is available. **Always reconcile tool output against [guards.md](guards.md)** —
tools have blind spots too (dynamic imports, reflection, public APIs).

```bash
# Fingerprint the project
ls package.json pyproject.toml Cargo.toml go.mod pom.xml composer.json *.csproj 2>/dev/null
rg --files -g '!**/{node_modules,vendor,dist,build,target,.git}/**' \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head    # extension histogram
```

Gate logic:
1. Native dead-code tool present → run it; treat findings as *candidates*; use
   ripgrep (§2) to cross-check, not replace.
2. None present → run the ripgrep pipeline (§2–§5) as primary.
3. Never trust a single tool's "unused" verdict for an auto-fix; confirm with an
   independent ripgrep reference trace and the §3 safety cycle.

See [native-tool-map.md](native-tool-map.md) for the table (knip/fallow, vulture/
ruff, clippy/cargo-machete, go deadcode/staticcheck, lizard, jscpd, ast-grep).

---

## 2. Cross-file dead code via ripgrep

Reachability without a real graph: **entry points are roots; a symbol/file with
no reference path back to a root is a candidate dead node.**

### 2.1 Identify entry points (graph roots) — PRECONDITION
Dead-code analysis is meaningless without a complete root set. Enumerate from
build manifests, framework conventions, Docker/CI, and shebangs. If you cannot
confidently enumerate entry points, **abort** — do not guess reachability.

```bash
rg -n '"(main|bin|exports|module|browser)"\s*:' package.json
rg -n '\[\[bin\]\]|\[lib\]' Cargo.toml
rg -n '^func main\(' -t go ; rg -n 'if __name__\s*==\s*["'\'']__main__' -t py
rg --files -g '**/{main,index,app,cli,server,__main__,wsgi,asgi}.*' \
   -g '**/{routes,pages,handlers,commands,migrations}/**'
```
Also roots: test files, build/config scripts, anything matched by the
published-surface guard (library exports — see [guards.md](guards.md) #8).

### 2.2 Enumerate candidate symbols/files
```bash
rg -n 'export\s+(const|function|class|type|interface|enum|default)\s+\w+' -t ts
rg -n '^(pub\s+)?(fn|struct|enum|trait)\s+\w+' -t rust
rg -n '^(def|class)\s+\w+' -t py
rg -n '^func\s+[A-Z]\w*' -t go              # exported = Capitalized
```

### 2.3 Trace references (the `-w` flag is load-bearing)
Without `--word-regexp`, `rg user` matches `userId`, `currentUser`. For each
symbol `S` in file `F`:
```bash
rg -nw 'S' -g '!F'          # cross-file uses — 0 hits => candidate dead
rg -nwc 'S'                 # total occurrences (sum the per-file counts)
```
For each candidate file, search for any import of its module path/basename:
```bash
base=$(basename "$F" | sed 's/\.[^.]*$//')
rg -n "(import|require|include|use|from).*['\"./]$base(['\"/.]|$)"
```
`> 0` cross-file refs → reachable (pending barrel check). `0` → continue to 2.4.

### 2.4 Resolve re-export / barrel chains (critical guard)
A symbol used *through* `index.ts` / `mod.rs` / `__init__.py` looks unreferenced
at its definition. Follow the chain (max depth ~5) before flagging:
```bash
rg -n "export\s+\{[^}]*\bS\b[^}]*\}\s+from" -t ts
rg -n "export\s+\*\s+from\s+['\"].*$base" -t ts
rg -n "pub use .*::($base|S)" -t rust
rg -n "from\s+\.($base)\s+import" -t py
```
If a barrel re-exports `S`, re-run 2.3 against the barrel's export name and
recurse. Dead only if the entire chain is unreferenced from the root set.
Aliased re-exports (`X as Y`) break name matching — build the alias map first.

### 2.5 Classify
- **Reachable:** any path from a root (direct or via barrel) → drop.
- **Unreachable:** none after barrel resolution → carry to §3 guards + tiering.

---

## 3. Confidence tiers & the safety cycle

Assign every unreachable candidate exactly one tier:

| Tier | Conditions (ALL must hold) |
|---|---|
| **HIGH** | 0 cross-file refs; barrel chain fully traced & empty; **all [guards.md](guards.md) cleared**; not an entry point; internal/private (not public API); single language & package; native tool (if any) agrees |
| **MEDIUM** | 0 refs but ≥1 guard uncertain (string-keyed access, possible reflection), OR native tool and rg disagree, OR common/colliding name |
| **LOW** | Dynamic-language member, plugin/registry/DI, public API surface, FFI, or refs found only as bare strings/comments |

**Hard rule:** only **HIGH**, guard-cleared findings are auto-fix eligible.
MEDIUM/LOW are reported for human decision — never auto-deleted. Default to
report mode; deletion requires explicit `--execute`.

### Safety cycle (per finding — never batch-delete blind)
1. **Dry-run:** list file, symbol, line range, traced chain, tier. Change nothing.
2. **Baseline:** confirm the project currently builds and tests pass (or record
   the existing failure set) — you cannot attribute breakage without a baseline.
3. **Fix (HIGH only):** remove the smallest reversible unit; one deletion per commit.
4. **Verify:** re-run the §2 trace; re-run the native tool; run build + typecheck.
   A grep tool MUST defer to a real compiler when one exists.
5. **Test:** run the full suite; compare to baseline. **Any new failure → revert**
   and demote the finding to MEDIUM.
6. Dynamic languages (no compiler) get an **extra confirmation tier** — step 4
   can't protect them.

```bash
npm run build && npm test          # JS/TS
cargo build && cargo test          # Rust
go build ./... && go test ./...    # Go
pytest -q && ruff check .          # Python
```

---

## 4. Duplication

Modes mirror a clone detector: strict (exact) → mild (whitespace-normalized) →
weak (literal-normalized) → semantic (identifier-renamed). Prefer `jscpd` /
`pmd cpd` / `lizard --duplicate` when present; ripgrep covers strict/mild.

```bash
jscpd --min-tokens 50 --reporters console --silent \
  --ignore '**/{node_modules,vendor,dist,build,target,.git,*.min.*}/**' .
```
Ripgrep heuristic when no tool: fingerprint a distinctive line (magic number,
error/log string, unusual expression) with `rg -F`; multiple cross-file hits =
copy-paste. `rg -U -F` a 3–5 line block to catch multi-line clones. Semantic
(renamed-variable) clones are punted to a real tool — never guessed.

**Duplication is a refactor signal, never auto-deduplicated.** Apply the rule of
three (extract at ≥3 occurrences of *one* concept that must change together).
Leave coincidental similarity, test duplication, and cross-boundary cases — a
wrong abstraction costs more than duplication. Report; let a human merge.

---

## 5. Complexity hotspots

Cheap proxies for cyclomatic + cognitive complexity, ranked by the CRAP insight
(**complexity × low test coverage = risk**) and churn.

```bash
# Decision-point density (cyclomatic proxy): >10 watch, >15 refactor, >20 high risk
rg -c '\b(if|else if|elif|for|while|case|when|catch|&&|\|\||\?)\b' \
   -g '!**/{node_modules,vendor,dist,target}/**' | sort -t: -k2 -rn | head -20
# Churn (change frequency)
git log --since='12 months ago' --name-only --pretty=format: \
  | rg -v '^$' | sort | uniq -c | sort -rn | head -20
```
Also flag: functions >50 lines (scrutinize >100), nesting depth ≥4, >4–5 params.
Cross-reference complex functions against whether any test references them
(`rg -t test -w 'funcName'`); **complex AND untested = top of the report.**
Prefer `lizard` (CCN/NLOC/params across ~16 languages), `radon cc`, `gocyclo`/
`gocognit`, or eslint's `complexity` rule when present. **Report-only — complexity
is never auto-fixed.**

---

## 6. Output contract

For each finding emit: `kind` (dead/dup/complexity), `location` (file:line[-line]),
`tier` (HIGH/MEDIUM/LOW), `evidence` (ref counts, traced barrel chain, tool
agreement), `guards_cleared` (the [guards.md](guards.md) checklist), and
`recommendation` (auto-fix vs human-decide). The auto-fix section lists **only
HIGH dead-code** items and references the §3 safety cycle. Duplication and
complexity are **always** human-decide. End with a one-line summary: counts per
kind per tier.
