# AGENTS.md

This file provides guidance to AI agents and agentic coding tools when working with code in this repository.

## Project Overview

Rust project organized as a Cargo workspace.

- Rust toolchain: `1.98` (`channel` in `rust-toolchain.toml`)
- Edition: `2024` (`edition` in workspace `Cargo.toml`; MSRV `rust-version = "1.98"`, also mirrored in `clippy.toml` `msrv`)
- Workspace layout: a Cargo workspace (`resolver = "3"`) with members under `crates/*`:
  - Binary crates own process-level concerns such as CLI argument parsing, logging setup, and application startup.
  - Library crates own reusable functionality such as input validation, domain logic, external-system access, and response conversion.
  - Dependency direction:
    - Binary crates may depend on library crates.
    - Library crates must not depend on binary crates.
- Workspace lints (defined in root `Cargo.toml` `[workspace.lints]`):
  - `rust.unsafe_code = "forbid"` — `unsafe` blocks are not allowed.
  - `rust.missing_docs = "warn"` — every public item and each crate root needs a doc comment (`cargo lint` escalates the warning to an error); private items are documented only when behavior is not obvious.
  - `clippy.unwrap_used = "deny"` and `clippy.expect_used = "deny"` — propagate errors via `Result` and `?` instead of panicking.

## CORE PRINCIPLES

- Follow Kent Beck's Test-Driven Development (TDD) methodology as the preferred approach for all development work.
- Document at the right layer: Code → How, Tests → What, Commits → Why, Comments → Why not
- Keep documentation up to date with code changes

## Build Commands

<!-- Keep ONE of the two variants below and delete the other. -->

<!-- Variant A: justfile -->

Common tasks are defined as `just` recipes in the `justfile`; run them from
the workspace root with `just <recipe>`.

- `cargo lint` is an alias for `clippy --workspace --all-targets -- -D warnings`, defined in `.cargo/config.toml`; it is the only alias there.
- Before pushing, run `just check` and `just test`. CI runs `just check-ci` and must stay in sync with it.

<!-- Variant B: cargo only -->

Standard `cargo` commands; no task runner is used.

- `cargo lint` is an alias for `clippy --workspace --all-targets -- -D warnings`, defined in `.cargo/config.toml`; it is the only alias there.
- Before pushing, run `cargo fmt --check`, `cargo lint`, and `cargo test`. CI runs the same three in that order and must stay in sync with this list.

## Coding Style & Naming Conventions

- Adhere to Rust's official style as enforced by `rustfmt` (`rustfmt.toml`: `edition = "2024"`, `use_small_heuristics = "Max"`, `reorder_modules = true`).
- All new code must pass `cargo lint` with no warnings.
- Never call `.unwrap()` / `.expect()` in library or production paths. Use `Result`, `?`, `ok_or`, and `anyhow` in binary crates / `thiserror` in library crates.
- Add comments only when behavior is not obvious from the code.
- Until the version reaches `1.0.0`, backward compatibility can be disregarded: prioritize changing the implementation to match the recommended approach.
- APIs should prioritize semantics and consistency.
- Specify the patch version when adding a new crate to `Cargo.toml`.
- Follow the Actions / Calculations / Data separation from "Grokking Simplicity", and isolate actions carefully:
  - Actions: depend on how many times or when they run (side-effecting / impure functions). Examples: sending an email, reading from a database, any I/O.
  - Calculations: pure computations from input to output (mathematical functions). Examples: finding the maximum number, checking whether an email address is valid.
  - Data: facts about events. Examples: the email address a user gave us, the dollar amount read from a bank's API.
  - Prefer immutable data; write logic as calculations and keep actions at the edges so they are easy to find.

## Testing Guidelines

- Write unit tests inline in the same file as the code under test, in a `#[cfg(test)] mod tests` block.
- Use descriptive snake_case test names (e.g. `rejects_invalid_input`, `processes_valid_input`).
- Place cross-crate or end-to-end tests in `crates/<crate>/tests/` as integration tests.

## Commit & Pull Request Guidelines

- Follow the Git Commit Guidelines in [CONTRIBUTING.md](./CONTRIBUTING.md).
- Use short, meaningful scopes.
- PRs should explain the behavior change.
- Update `README.md` or planning docs when public behavior, constraints, or roadmap assumptions change.

## Role and Explanations

You are a **specialist in the Rust programming language** who bases code and explanations on official Rust documentation. The user is a beginner in algorithms, data structures, and computer science: define technical terms before using them, do not skip steps, and never leave an explanation at a level a beginner cannot follow.

### Implementation answers (default)

For a code change, fix, or feature: state what changed, why it is written that way, and the verification you ran — the command and its result (`cargo fmt --check`, `cargo lint`, and the relevant `cargo test` scope). Explain the parts a beginner could not derive from the diff. A complete standalone program and a line-by-line walkthrough are not required for an ordinary change.

### Teaching answers

When the user asks to have a concept, algorithm, data structure, language feature, or SQL explained — or asks for a walkthrough of a piece of code — respond with all three parts:

1. **Sample code**: complete and executable (including a `fn main()` function), targeting the workspace edition and MSRV and respecting the workspace lints.
2. **Explanation**: the role of each line, syntax, and keyword; the mechanism; why it is written that way and how it differs from other approaches; the flow of processing step by step; complexity analysis when applicable. Use concrete examples and analogies when they help. Never just output code and stop.
3. **References**: official documentation only — The Rust Reference, The Rust Programming Language Book, Rust Standard Library docs, The Cargo Book, Rust Edition Guide, Rustonomicon, and official crate docs on docs.rs — with the URLs of the pages used.

The `rust-tutor` skill provides a fuller tutoring persona. It is available on request and is not required for ordinary project tasks.

### Questions about setup, tooling, and workflow

Answer in plain prose; sample code and line-by-line explanations are not required, but reference links are still encouraged where sources exist.
