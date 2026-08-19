---
name: rust-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing Rust code — implementing features in .rs files, "Rust で実装して", "この Rust コードを直して", or auditing Rust for modernization. It defines the mandatory procedure for resolving the project's edition and MSRV from Cargo.toml, plus a version-tagged catalog of modern idioms (Rust 1.65–1.97, 2024 Edition), so that generated code and review recommendations never exceed the project's declared rust-version or edition.
---

# Rust Idioms (edition- and MSRV-aware)

Authority sources: the Rust Edition Guide, Rust release notes (RELEASES.md / blog.rust-lang.org), the Rust API Guidelines, rustfmt defaults, and official clippy lints. Do not invent recommendations: every idiom below traces to one of these sources.

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any Rust code:

1. Read the `Cargo.toml` of the crate being edited: note `edition` and `rust-version` (MSRV).
2. If the field says `edition.workspace = true` or `rust-version.workspace = true`, resolve it from `[workspace.package]` in the workspace root `Cargo.toml`.
3. If `rust-version` is absent, treat the edition's release baseline as the floor and prefer conservative choices; suggest pinning `rust-version` as a low-priority improvement (in reviews, tag it `[recommend]`).
4. State the resolved baseline in the deliverable — the review report's opening or the write-mode summary.

Hard rules derived from the baseline:

- **Never use a language or std feature stabilized strictly after the project MSRV** (a feature stabilized exactly at the MSRV is allowed). When an idiom below is desirable but MSRV-gated, present it as an option labeled with the required Rust version — do not silently use it. When writing code, record the gated option as a brief source comment at the affected line and mention it, with the required version, in the summary to the user.
- **Never use edition-gated syntax outside the matching edition** (e.g. let chains require edition 2024; code relying on 2021 temporary-lifetime behavior must not be rewritten as if 2024 rules applied, and vice versa).
- When recommending a change in review, always cite the stabilizing Rust version so it can be checked against the MSRV.

## Catalog coverage and verification

**Catalog coverage version: Rust 1.97.** The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the official sources when — and only when:

- **Staleness guard**: the resolved MSRV or installed toolchain (`rustc --version`) is newer than the coverage version above. (In a read-only review or when the toolchain cannot be invoked, judge staleness on the resolved MSRV alone — do not block on `rustc --version`.) The catalog is out of date for this project. Do both: (a) check the release notes for everything stabilized between the coverage version and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating to the new version (see Maintenance below).
- A feature or its stabilizing version is **not listed here** AND is **boundary-relevant** — plausibly stabilized at or after the catalog floor (1.65) or near the resolved MSRV: never trust memory for stabilization versions; verify before gating on it. Long-established std APIs that clearly predate the catalog floor (e.g. `map_or`, `min`, `parse`, `checked_*`) need no verification.
- A catalog entry **conflicts with observed compiler behavior**: the compiler wins; report the discrepancy.

Verification sources, in order of authority:

1. Release notes: https://github.com/rust-lang/rust/blob/master/RELEASES.md (exact stabilization versions)
2. Edition Guide: https://doc.rust-lang.org/edition-guide/ (edition-gated semantics)
3. Announcements: https://blog.rust-lang.org/ (context for changes)

**Verification fallback**: if a source is unreachable (offline, sandboxed, restricted), try at most one alternate route, then stop and degrade: prefer a construct whose version is already catalog-listed; if none fits, state the recommendation with an explicit "unverified" label and the assumed stabilizing version. Never let unreachable sources block the deliverable or trigger repeated fetch attempts.

## Maintenance (updating this skill for a new stable Rust)

When asked to update this skill after a new stable release:

1. Read the release notes (RELEASES.md) for every version between the coverage version and the new stable.
2. Add newly stabilized idioms to the catalog with their stabilizing version; add newly std-absorbed dependencies; add new edition semantics if an edition shipped.
3. Remove nothing that older MSRVs may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".

## Review output contract

When the task is a review or audit, structure the report as follows. (Writing new code needs no report; the hard rules in Step 0 — including how to record gated options — still apply.)

1. **Baseline statement first**: the resolved edition and MSRV, and which Cargo.toml (or `[workspace.package]`) they came from.
2. **Findings**, each tagged with exactly one severity. Severity follows from the rule class, not executor judgment:
   - `[error]` — rejected by the compiler under the resolved edition/toolchain (e.g. `#[no_mangle]` without `unsafe(...)` on edition 2024)
   - `[warn]` — compiles but triggers a warn-by-default lint or violates a mandatory guideline (e.g. `unsafe_op_in_unsafe_fn`, missing `# Safety` on an `unsafe fn`)
   - `[recommend]` — legal but officially discouraged, with a within-MSRV replacement (e.g. `static mut` accessed without references → atomics)
   - `[gated-option]` — desirable but above the MSRV or edition; must carry the required Rust version and must never be presented as a direct fix
3. Every finding cites the authority it rests on: the stabilizing Rust version, the edition rule, or — for version-independent guidance — the official guideline item (e.g. API Guidelines C-GETTER), so it can be checked against the baseline.
4. Report prose follows the conversation language; code snippets, identifiers, and severity tags stay in English. This language policy applies to every deliverable, including write-mode summaries.
5. When one finding's fix supersedes another (e.g. an atomics rewrite removes an `unsafe fn` and its `# Safety` obligation), report both and cross-reference which fix subsumes which.

## Dependencies absorbed by std

Flag these dependencies (severity: `[recommend]` when the replacement is within MSRV). When the MSRV allows the std replacement, recommend it directly; when it does not, present it as `[gated-option]` with the required version — and note a within-MSRV alternative (or "keep as-is") explicitly:

- `lazy_static` / `once_cell` → `std::sync::OnceLock` (1.70; not drop-in — initialization moves to `get_or_init` at the access site) / `std::sync::LazyLock` (1.80; drop-in for `Lazy`). State the migration cost in the finding.
- `cfg-if` → `cfg_select!` macro (1.95); within-baseline fallback: keep `cfg-if`, or expand to plain `#[cfg]` attributes
- `async-trait` → native `async fn` in traits where dyn-compatibility is not required (1.75)
- `assert_matches` crate → std `assert_matches!` / `debug_assert_matches!` (1.96)

## 2024 Edition semantics

These apply only when `edition = "2024"`:

- **Unsafe hygiene**: `unsafe fn` bodies must use explicit inner `unsafe {}` blocks (`unsafe_op_in_unsafe_fn` is warn-by-default). Attributes `no_mangle`, `export_name`, `link_section` must be written `#[unsafe(no_mangle)]` etc. `extern` blocks must be `unsafe extern`.
- **Static mut**: references to `static mut` are disallowed — use atomics, `Mutex`, `OnceLock`, or raw pointers with documented invariants.
- **Environment mutation**: `std::env::set_var` / `remove_var` are `unsafe` — a safety comment must justify thread-safety.
- **RPIT lifetime capture**: implicit capture rules changed; use precise capturing `use<'a, T>` syntax where over-capture causes borrow errors or API leakage.
- **Temporary lifetimes**: `if let` and tail-expression temporary scopes changed — do not write code relying on old drop timing (e.g. lock guards in `if let` conditions).
- **Prelude**: `Future` and `IntoFuture` are in the prelude — do not import them redundantly.

## Modern idiom catalog (Rust 1.65 → 1.97)

Prefer these over older equivalents, subject to the MSRV/edition rules above:

- `let-else` for early returns instead of nested `match`/`if let` (1.65)
- `Option::is_some_and` (1.70) / `is_none_or` (1.82), `div_ceil` (1.73), inline `const {}` blocks (1.79) where they simplify code
- C-string literals `c"..."` instead of `CStr::from_bytes_with_nul` on literals (1.77)
- `core::error::Error` in `no_std` contexts (1.81)
- Async closures `async || {}` instead of closures returning `async move {}` blocks (1.85)
- Trait upcasting instead of manual `as_any`-style workarounds (1.86)
- Let chains (`if let Some(x) = a && x > 0`) instead of nested `if let` — edition 2024 only (1.88); pre-gate fallback: keep the nesting, or use `matches!` / `Option` combinators (`map_or`, `is_some_and`)
- `if let` guards in match arms instead of guard + re-destructure in the body (1.95)
- `cfg_select!` instead of `cfg-if` or long `#[cfg]` if-else towers (1.95)
- `Vec::push_mut` / `insert_mut` when code pushes then immediately re-borrows via `last_mut().unwrap()` (1.95)
- Atomic `update` / `try_update` instead of manual `compare_exchange` loops for simple read-modify-write (1.95)
- `assert_matches!` / `debug_assert_matches!` instead of `assert!(matches!(...))` when asserting on a pattern (1.96)
- `core::range` Copy-able range types (`Range`, `RangeFrom`, `RangeInclusive`, `RangeToInclusive`) when storing a range in a `Copy` type, instead of splitting into separate start/end fields (1.96); note: range syntax (`a..b`) still produces the legacy `core::ops` types, so conversion is explicit — do not flag ordinary use of `core::ops` ranges
- Integer bit-query methods `bit_width`, `highest_one`, `lowest_one`, `isolate_highest_one`, `isolate_lowest_one` (also on `NonZero`) instead of manual `leading_zeros`/`trailing_zeros` arithmetic (1.97)
- Do NOT use `core::hint::cold_path` or other perf hints unless profiling-driven intent is already evident

## Official style and API guidelines

- Naming per RFC 430 / API Guidelines: `as_`/`to_`/`into_` conversion prefixes, getter names without `get_`, iterator method naming (`iter`, `iter_mut`, `into_iter`)
- Error types implement `std::error::Error + Send + Sync` where crossing API boundaries; use `?` with `From` conversions instead of manual `map_err` chains
- Doc comments: `///` with `# Examples`, `# Errors`, `# Panics`, `# Safety` sections per API Guidelines; `# Safety` is mandatory on `unsafe fn` and unsafe trait impls
- Follow rustfmt defaults; run `cargo fmt` rather than hand-formatting (when `cargo fmt` is not run for any reason — unavailable, sandboxed, or disallowed — match rustfmt defaults manually and note it)
