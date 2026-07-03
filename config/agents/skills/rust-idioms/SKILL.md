---
name: rust-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing Rust code — implementing features in .rs files, "Rust で実装して", "この Rust コードを直して", or auditing Rust for modernization. It defines the mandatory procedure for resolving the project's edition and MSRV from Cargo.toml, plus a version-tagged catalog of modern idioms (Rust 1.65–1.95, 2024 Edition), so that generated code and review recommendations never exceed the project's declared rust-version or edition.
---

# Rust Idioms (edition- and MSRV-aware)

Authority sources: the Rust Edition Guide, Rust release notes (RELEASES.md / blog.rust-lang.org), the Rust API Guidelines, rustfmt defaults, and official clippy lints. Do not invent recommendations: every idiom below traces to one of these sources.

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any Rust code:

1. Read the `Cargo.toml` of the crate being edited: note `edition` and `rust-version` (MSRV).
2. If the field says `edition.workspace = true` or `rust-version.workspace = true`, resolve it from `[workspace.package]` in the workspace root `Cargo.toml`.
3. If `rust-version` is absent, treat the edition's release baseline as the floor and prefer conservative choices; suggest pinning `rust-version` as a low-priority improvement.

Hard rules derived from the baseline:

- **Never use a language or std feature stabilized after the project MSRV.** When an idiom below is desirable but MSRV-gated, present it as an option labeled with the required Rust version — do not silently use it.
- **Never use edition-gated syntax outside the matching edition** (e.g. let chains require edition 2024; code relying on 2021 temporary-lifetime behavior must not be rewritten as if 2024 rules applied, and vice versa).
- When recommending a change in review, always cite the stabilizing Rust version so it can be checked against the MSRV.

## Catalog coverage and verification

**Catalog coverage version: Rust 1.95.** The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the official sources when — and only when:

- **Staleness guard**: the resolved MSRV or installed toolchain (`rustc --version`) is newer than the coverage version above. The catalog is out of date for this project. Do both: (a) check the release notes for everything stabilized between the coverage version and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating to the new version (see Maintenance below).
- A feature or its stabilizing version is **not listed here**: never trust memory for stabilization versions; verify before gating on it.
- A catalog entry **conflicts with observed compiler behavior**: the compiler wins; report the discrepancy.

Verification sources, in order of authority:

1. Release notes: https://github.com/rust-lang/rust/blob/master/RELEASES.md (exact stabilization versions)
2. Edition Guide: https://doc.rust-lang.org/edition-guide/ (edition-gated semantics)
3. Announcements: https://blog.rust-lang.org/ (context for changes)

## Maintenance (updating this skill for a new stable Rust)

When asked to update this skill after a new stable release:

1. Read the release notes (RELEASES.md) for every version between the coverage version and the new stable.
2. Add newly stabilized idioms to the catalog with their stabilizing version; add newly std-absorbed dependencies; add new edition semantics if an edition shipped.
3. Remove nothing that older MSRVs may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".

## Dependencies absorbed by std

Flag these dependencies when the MSRV allows the std replacement:

- `lazy_static` / `once_cell` → `std::sync::OnceLock` (1.70) / `std::sync::LazyLock` (1.80)
- `cfg-if` → `cfg_select!` macro (1.95)
- `async-trait` → native `async fn` in traits where dyn-compatibility is not required (1.75)

## 2024 Edition semantics

These apply only when `edition = "2024"`:

- **Unsafe hygiene**: `unsafe fn` bodies must use explicit inner `unsafe {}` blocks (`unsafe_op_in_unsafe_fn` is warn-by-default). Attributes `no_mangle`, `export_name`, `link_section` must be written `#[unsafe(no_mangle)]` etc. `extern` blocks must be `unsafe extern`.
- **Static mut**: references to `static mut` are disallowed — use atomics, `Mutex`, `OnceLock`, or raw pointers with documented invariants.
- **Environment mutation**: `std::env::set_var` / `remove_var` are `unsafe` — a safety comment must justify thread-safety.
- **RPIT lifetime capture**: implicit capture rules changed; use precise capturing `use<'a, T>` syntax where over-capture causes borrow errors or API leakage.
- **Temporary lifetimes**: `if let` and tail-expression temporary scopes changed — do not write code relying on old drop timing (e.g. lock guards in `if let` conditions).
- **Prelude**: `Future` and `IntoFuture` are in the prelude — do not import them redundantly.

## Modern idiom catalog (Rust 1.65 → 1.95)

Prefer these over older equivalents, subject to the MSRV/edition rules above:

- `let-else` for early returns instead of nested `match`/`if let` (1.65)
- `Option::is_some_and` / `is_none_or`, `div_ceil`, inline `const {}` blocks where they simplify code
- C-string literals `c"..."` instead of `CStr::from_bytes_with_nul` on literals (1.77)
- `core::error::Error` in `no_std` contexts (1.81)
- Async closures `async || {}` instead of closures returning `async move {}` blocks (1.85)
- Trait upcasting instead of manual `as_any`-style workarounds (1.86)
- Let chains (`if let Some(x) = a && x > 0`) instead of nested `if let` — edition 2024 only (1.88)
- `if let` guards in match arms instead of guard + re-destructure in the body (1.95)
- `cfg_select!` instead of `cfg-if` or long `#[cfg]` if-else towers (1.95)
- `Vec::push_mut` / `insert_mut` when code pushes then immediately re-borrows via `last_mut().unwrap()` (1.95)
- Atomic `update` / `try_update` instead of manual `compare_exchange` loops for simple read-modify-write (1.95)
- Do NOT use `core::hint::cold_path` or other perf hints unless profiling-driven intent is already evident

## Official style and API guidelines

- Naming per RFC 430 / API Guidelines: `as_`/`to_`/`into_` conversion prefixes, getter names without `get_`, iterator method naming (`iter`, `iter_mut`, `into_iter`)
- Error types implement `std::error::Error + Send + Sync` where crossing API boundaries; use `?` with `From` conversions instead of manual `map_err` chains
- Doc comments: `///` with `# Examples`, `# Errors`, `# Panics`, `# Safety` sections per API Guidelines; `# Safety` is mandatory on `unsafe fn` and unsafe trait impls
- Follow rustfmt defaults; run `cargo fmt` rather than hand-formatting
