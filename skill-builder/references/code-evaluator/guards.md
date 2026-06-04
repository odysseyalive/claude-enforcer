<!-- code-eval-ref-version: 1 -->
<!-- origin: skill-builder | modifiable: true -->
# False-Positive Guards — clear EVERY guard before flagging code dead

"Symbol X has zero references outside its definition → dead" is a *closed-world*
conclusion drawn from *open-world* evidence. ripgrep sees lexical tokens in
tracked files. It does NOT see runtime string construction, the type system, the
build graph, external consumers, generated code, or framework registries.

Each guard below: where the naive conclusion fails, the **signal** to grep for,
and the **action**. Any unresolved guard caps the finding at MEDIUM (or LOW) —
see [cross-file-detection.md](cross-file-detection.md) §3. Default verdict for a
zero-reference symbol is **"unreferenced (candidate)," never "dead."**

| # | Guard | Fails when… | Signal | Action |
|---|-------|-------------|--------|--------|
| 1 | **root-set-precondition** | entry points incomplete | manifests, Dockerfile `CMD`/`ENTRYPOINT`, CI, `func main`/`fn main`/`if __name__`, shebangs | enumerate roots first; abort if you can't |
| 2 | **compiler-defers** | grep contradicts the type system | a native build/typechecker exists | the compiler is source of truth; grep only proposes |
| 3 | **reflection-poison** | name resolved from a runtime string | `getattr`/`setattr`/`eval`/`exec`/`globals()` (Py), `Reflect.`/`obj[key]`/`new Function` (JS), `_G[`/`loadstring` (Lua), `reflect.MethodByName` (Go) | any reflection primitive in the module → downgrade EVERY symbol there to LOW; no auto-delete |
| 4 | **abi-export-root** | called across an ABI boundary | `#[no_mangle]`, `extern "C"`, non-`static` C in a lib, `//export` cgo, N-API/WASM exports, a public `.h` | exported/FFI symbol = root, never deleted |
| 5 | **schema-bound-shield** | field bound to a serializer/ORM/wire format | `#[derive(Serialize/Deserialize)]`, `json:`/`db:`/`gorm:` tags, `@Column`/`@Entity`, pydantic `BaseModel`, `.proto` | schema fields never dead; ORM columns need a migration → human-confirm only |
| 6 | **registry-membership** | wired by a container/registry by token | `@Injectable`/`@Component`/`providers:`, `container.bind(...).to(...)`, `entry_points`, registration maps | registered symbol = used |
| 7 | **interface-conformance** | invoked through an abstract type | method name matches a `trait`/`interface`/abstract decl; `override`; `impl Trait for` | matching method = used. **Go trap:** interface satisfaction is implicit (no `implements`) — cross-check method names against every `interface{...}` |
| 8 | **published-surface-root** | repo is a library; consumer is external | `package.json` `exports`/`main`, `pub` at crate root, capitalized Go ident in a non-`internal` pkg, `__all__`, `@public` | public surface = root; analyze only private symbols; libraries default to display-only |
| 9 | **workspace-scope** | used by a sibling monorepo package | `pnpm-workspace.yaml`, `go.work`, Cargo `[workspace]`, Nx/Turbo, `@scope/pkg` imports | search the whole workspace, not one package |
| 10 | **reexport-resolve** | consumed via a re-export/alias | `pub use`, `export { X as Y } from`, `export * from`, `from .x import *` | build the alias/re-export map; a ref to any alias counts for the original |
| 11 | **cfg-blind-counting** | only caller is in a disabled branch | `#[cfg(...)]`, `#ifdef`, `//go:build`, `TYPE_CHECKING`, env/flag gates | count refs in ALL conditional branches, active or not; platform code = used |
| 12 | **test-tree-included** | referenced only by tests | refs under `test/`/`spec/`/`__tests__/`/`*_test.go`; fixture decorators | never exclude tests from the *reference* search; prod code used only by tests → report, don't auto-delete |
| 13 | **comment-string-filter** | the "reference" is in a comment/doc/string | only occurrences inside `//`,`#`,`/* */`,`"""`, `.md`, or string literals | don't count comment/string matches as code refs; all-comment → LOW |
| 14 | **case-insensitive-resolve** | case-mismatched import on macOS/Windows | import path case differs from on-disk name | resolve file/module refs case-insensitively; flag the smell but count the ref |
| 15 | **scope-exclude-generated** | def/ref lives in vendored/generated dir | `node_modules`/`vendor`/`target`/`dist`/`.venv`/`gen/`, `// Code generated … DO NOT EDIT`, `.gitignore` | exclude generated/vendored from defs+deletion; still count refs there; honor DO NOT EDIT |
| 16 | **lang-trap-table** | language-specific implicit use | Go `init()`/`import _`, Rust `#[used]`/inventory/`build.rs`, C `__attribute__((constructor))`/weak/linker `KEEP`, Py dunders/metaclass/`__init_subclass__`, Bash `source`/`trap`/`case` dispatch/`$cmd` indirection, TS `.d.ts`/decorators/declaration-merging | per-language root lists; these are never dead |
| 17 | **dynamic-import-poison** | module loaded by a built/glob path | `import(var)`, `require(expr)`, `importlib`/`__import__`, `plugin.Open`/`.Lookup`, `dlopen`, `require.context` | treat every module the loader could resolve as used |
| 18 | **macro-codegen-poison** | reference exists only post-expansion | `macro_rules!`/`proc_macro`/derive, C `##` token-paste, `//go:generate`, `.tmpl`/Jinja, `*.pb.go`/`__generated__` | affected symbols used; the real fix is in the generator, not the output |
| 19 | **framework-convention** | invoked by the framework by name/location | `@app.route`/`@task`/`@click`, magic methods (`__call__`, `Dispose`), file-based routing under `pages/`/`app/`/`cmd/`, default exports in framework dirs | convention-invoked symbol = root |
| 20 | **collision-disambiguate** | short/common name collides across scopes | `run`, `id`, `name`, `data`; same identifier defined in multiple files | require scope/qualifier disambiguation; on collision downgrade confidence |

## Hard-forbidden auto-delete (any one → report only, never auto-apply)

1. Reflection primitive in the module or its importers (#3).
2. ABI export / FFI marker (#4).
3. Schema/ORM/wire binding (#5) — ORM columns especially (need migrations).
4. Published/library API surface (#8).
5. Dynamic import / codegen / macro affecting the module (#17, #18).
6. Entry points not fully enumerable (#1).
7. All references are comments/strings only (#13).
8. Symbol crosses a package/language/process boundary (#4, #9).

In any of these cases, downgrade to a report ("possibly dead, manual review") —
never an edit.

## Minimum verification after ANY removal (even HIGH tier)

Green baseline → atomic single-symbol change → compile/typecheck (defer to the
real compiler) → full test suite → revert on any new failure → branch only, never
`main`. Cross-check against native dead-code linters to *raise* confidence; never
let grep alone *lower* it. Dynamic languages (Python/JS/Lua/Bash) have no
compile-time guard — give them an extra confirmation tier.
