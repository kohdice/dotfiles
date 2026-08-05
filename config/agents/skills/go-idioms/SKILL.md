---
name: go-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing Go code — implementing features in .go files, "Go で実装して", "この Go コードを直して", or auditing Go for idiom modernization. It defines the mandatory procedure for resolving the project's go directive from go.mod, plus a version-tagged catalog of modern idioms and std APIs (Go 1.18–1.26), deprecated APIs, and std-absorbed dependencies, so that generated code and review recommendations never exceed the project's declared Go version.
---

# Go Idioms (go-directive-aware, up to Go 1.26)

Authority sources: the Go release notes (go.dev/doc/go1.NN), the Go blog (go.dev/blog), Effective Go, the Go Doc Comments guide (go.dev/doc/comment), the Go wiki Code Review Comments, gofmt, and the official `go vet` / `go fix` analyzers. Do not invent recommendations: every idiom below traces to one of these sources.

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any Go code:

1. Read the `go.mod` of the module being edited: note the `go` directive version — it gates which recommendations apply. Also note a `toolchain` directive if present.
2. In a multi-module workspace (`go.work`), resolve the `go` directive of the specific module that owns the file, not the workspace file.
3. Since 1.24, tool dependencies belong in `tool` directives instead of a `tools.go` blank-import file — flag the old pattern when the directive version allows.

Hard rules derived from the baseline:

- **Never use a language or std API introduced strictly after the module's `go` directive.** The boundary value is included: an API introduced exactly at the directive version applies now, not as a gated option. When an idiom below is desirable but version-gated, present it as an option labeled with the required Go version — do not silently use it.
- When recommending a change in review, always cite the Go version that introduced the replacement so it can be checked against the `go` directive; if the directive is below that version, present it as an upgrade-gated option instead of a finding. When a replacement spans multiple introduction versions (package vs. specific form), cite the version of the specific form you recommend.

Where to surface these decisions (fixed, not left to judgment):

- **Resolved baseline**: state the `go` directive value and which `go.mod` it came from at the top of the deliverable — the opening lines of a review report, or the summary that accompanies generated code.
- **Gated options, in review**: a separate section headed "Upgrade-gated options" at the end of the report, never mixed into apply-now findings. Intent-conditioned (review-and-decide) items get their own section between the apply-now findings and the gated options.
- **Gated options, when writing code**: list them in the summary accompanying the code, under the same "Upgrade-gated options" heading. Do not scatter them as code comments, except when the within-baseline form would look like a mistake to a later reader (e.g., a pattern a newer Go version makes obsolete) — then one short comment at that site is allowed.

## Catalog coverage and verification

**Catalog coverage version: Go 1.26.** The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the official sources when — and only when:

- **Staleness guard**: the resolved `go` directive or installed toolchain (`go version`) is newer than the coverage version above, comparing minor versions only — a patch release of the covered minor (e.g. go1.26.4 against coverage 1.26) never triggers this guard. The two inputs matter in different modes: the `go` directive always (it gates every recommendation); the installed toolchain only when code will be built or run — in a pure review, if the directive is within coverage, skip the `go version` probe. The catalog is out of date for this project. Do both: (a) check the release notes for everything added between the coverage version and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating to the new version (see Maintenance below).
- An API or its introducing version is **not listed here**: never trust memory for introduction versions; verify before gating on it.
- A catalog entry **conflicts with observed toolchain behavior** (`go vet`, `go fix -diff`): the toolchain wins; report the discrepancy.

Verification sources, in order of authority:

1. Release notes: https://go.dev/doc/go1.26 (and go1.NN for older versions — exact introduction versions)
2. API deprecations: https://pkg.go.dev/ (Deprecated: markers in package docs)
3. Announcements: https://go.dev/blog/ (context for changes)

## Maintenance (updating this skill for a new stable Go)

When asked to update this skill after a new stable release:

1. Read the release notes (go.dev/doc/go1.NN) for every version between the coverage version and the new stable.
2. Add newly introduced idioms to the catalog with their introducing version; add newly std-absorbed dependencies; add newly deprecated APIs.
3. Remove nothing that older `go` directives may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".

## Dependencies absorbed by std

Flag these dependencies when the `go` directive allows the std replacement:

- `golang.org/x/exp/slices` / `x/exp/maps` → `slices` / `maps` (1.21; iterator forms `maps.Keys`/`maps.Values` in 1.23). Not drop-in for `maps.Keys`/`maps.Values`: the x/exp forms return slices, the std forms return iterators — pair with `slices.Collect` / `slices.Sorted` (1.23)
- `github.com/pkg/errors` → `fmt.Errorf` with `%w`, `errors.Is/As/Join` (1.13/1.20)
- Simple third-party routers → `net/http.ServeMux` method + wildcard patterns (1.22), when only basic routing is used

## Modern idiom catalog (Go 1.18 → 1.26)

Prefer these over older equivalents, subject to the version rules above. Entries conditioned on intent ("where X matters", "for X needs") are questions to the author in review — flag them as review-and-decide items, not definite findings — and in generated code apply them only when the intent is stated or observable:

- `interface{}` → `any` (1.18); `strings.Index`+slicing → `strings.Cut` / `CutPrefix` / `CutSuffix` (1.18/1.20)
- `sort.Slice` / `sort.Sort` with ad-hoc `Less` → `slices.Sort` / `slices.SortFunc` / `slices.SortStableFunc` (1.21); manual search loops → `slices.Contains` / `slices.Index` / `slices.BinarySearch`
- Hand-written `min`/`max` helpers → builtins (1.21); map-clearing loops → `clear` (1.21)
- `sync.Once` + wrapper function → `sync.OnceFunc` / `OnceValue` / `OnceValues` (1.21)
- `log.Printf` for structured/leveled logging needs → `log/slog` (1.21); fan-out to multiple handlers → `slog.NewMultiHandler` (1.26)
- `math/rand` → `math/rand/v2` (1.22): `rand.N`, `rand.IntN`, no seeding boilerplate
- `for i := 0; i < n; i++` where `i` is only an index → `for i := range n` (1.22); loop-variable copies (`i := i`, `v := v`) are obsolete since per-iteration scoping (1.22) — flag them for removal. When generating new code at a pre-1.22 baseline, write the copy only when the closure actually outlives the iteration (goroutine, stored callback, parallel subtest) — never as a reflex
- Channel-based generators or callback iteration → `iter.Seq` / `iter.Seq2` range-over-func (1.23), with `slices.Collect` / `maps.Collect`
- `runtime.SetFinalizer` → `runtime.AddCleanup` (1.24)
- Path traversal-sensitive file access → `os.Root` (1.24)
- JSON struct tags using `omitempty` where zero-vs-empty distinction matters → `omitzero` (1.24)
- `wg.Add(1); go func() { defer wg.Done(); ... }()` → `wg.Go` (1.25)
- `errors.As` with a declared target variable → `errors.AsType[T]` (1.26)
- Pointer-helper generics (`func ptr[T any](v T) *T`) or throwaway variables just to take an address → `new(expr)` with an expression operand (1.26)

## Deprecated and removed APIs

- `io/ioutil` → `os` / `io` equivalents (deprecated since 1.16, still common in old code)
- `net/http/httputil.ReverseProxy.Director` → `Rewrite` (Director deprecated in 1.26 as unsafe)
- `crypto/rsa` PKCS #1 v1.5 encryption (`EncryptPKCS1v15`, `DecryptPKCS1v15`, `DecryptPKCS1v15SessionKey`) — deprecated in 1.26; recommend OAEP
- `crypto/ecdsa` `PublicKey`/`PrivateKey` direct `big.Int` field access (deprecated in 1.26)

## Testing modernizations

These entries apply to `_test.go` files only — never flag the same patterns in production code (e.g., `context.Background()` in `main` is fine).

- `for i := 0; i < b.N; i++` → `b.Loop()` (1.24)
- `context.Background()` in tests → `t.Context()` (1.24; also added to `B` and `F` — use `b.Context()` / `f.Context()` in benchmarks and fuzz targets)
- `os.Chdir` in tests → `t.Chdir` (1.24)
- Consider `testing/synctest` for concurrency tests (1.25) and `T.ArtifactDir` for test outputs (1.26)

## Official style and documentation

- Naming per Effective Go / Code Review Comments: MixedCaps, no `Get` prefix on getters, short receiver names, `Err`/`err` conventions, package names lowercase without underscores
- Error handling: error strings lowercase without trailing punctuation; wrap with `%w` when callers need `errors.Is/As`; sentinel errors named `ErrXxx`
- Doc comments per go.dev/doc/comment: begin with the identifier name, full sentences; deprecation marked with `// Deprecated:`
- When the request leaves observable behavior unspecified (ordering ties, degenerate inputs like zero/negative counts, random distributions), choose the conventional option, document the chosen contract in the doc comment, and report it as a discretionary decision in the summary — never leave it implicit in code. When conventions conflict, classify by consequence: a bad value that would deadlock, corrupt state, or hide a bug is a caller programming error — fail loud (error return; if the signature has no error slot, panic); a bad value with an obvious harmless meaning (empty result, no-op) is data-shaped — use the deterministic default
- Follow gofmt; run `gofmt`/`goimports` rather than hand-formatting
