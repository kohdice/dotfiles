---
name: architecture-patterns
description: This skill should be used when writing or reviewing code whose structure is at stake in C, Go, Rust, or Zig — adding a module/package/crate, deciding where new code lives, crossing layer boundaries, wiring dependencies between units, "このパッケージ構成で良い?", or auditing a codebase's architecture. It defines the Dependency Rule (volatile detail depends on stable policy), separation of responsibilities, the precedence order (the project's declared architecture wins; conventions require a citable official source), a catalog of dependency violations and responsibility problems with per-language layout guidance and its sources (Go module layout, Google Go Style Guide, Rust API Guidelines, Zig build system docs, C header discipline), and the accepted-structure criteria, so that new code lands in the right unit with dependencies pointing the right way and reviews flag only sourced, evidenced violations.
---

# Architecture Patterns (dependency direction & responsibility placement, C / Go / Rust / Zig)

The goal is structure that holds: responsibilities separated into the right units, dependencies pointing only in allowed directions, and layout that follows the ecosystem's official guidance. Every convention-based claim must trace to a citable source.

## Core principles

### The Dependency Rule

Dependencies point from volatile detail toward stable policy. Domain/core logic must not import infrastructure (database, HTTP, CLI, filesystem, third-party SDKs); the infrastructure adapts to the core, never the reverse. Cycles between modules are always a defect. This is the shared core of layered, hexagonal (Alistair Cockburn), and Clean Architecture (Robert C. Martin) — the de facto standards for dependency direction. When writing code, check the direction of every new import edge before adding it: if core would gain an edge toward infra, define the boundary type in core and adapt at the edge instead.

### Separation of responsibilities

A module/package/crate should have one reason to change. Parsing, business rules, and I/O living in one unit is a violation; so is one concern smeared across many units so that every change touches all of them. When adding code, place it in the unit that shares its reason to change — or create one when none does; do not default to the nearest open file.

### The project's declared architecture wins

Before judging or placing anything, discover what architecture the project claims (README, ARCHITECTURE.md, docs/, ADRs, directory names like `domain/`, `adapters/`, `internal/`). Violations of the project's own declared rules outrank everything else. Do not impose an architecture the project never adopted.

### Official guidance over personal taste

A convention-based claim is only valid with a named source — e.g., go.dev "Organizing a Go module", the Google Go Style Guide, Effective Go, the Rust API Guidelines, The Cargo Book, Zig's build system documentation. Without a source it is an opinion: omit it or mark it explicitly as such.

## Pattern catalog

### Dependency violations (all languages)

- Core/domain code importing infrastructure: database drivers, HTTP frameworks, CLI/flag parsing, environment access, third-party SDKs
- Infrastructure types leaking into core signatures (`*sql.Rows`, `http.Request`, `serde_json::Value`, socket handles) instead of domain types defined at the boundary
- Dependency cycles — including Go cycles "resolved" by duplicating code or laundering through `interface{}`/`any`
- Layer skipping where the project defines layers (handler calling the repository directly past the service layer it claims to have)
- Business rules in transport/entry layers: fat HTTP handlers, `main` functions containing domain logic

### Responsibility problems (all languages)

- God modules mixing parsing, business rules, and I/O in one unit
- `utils`/`common`/`helpers` dumping grounds accumulating unrelated code
- One concern split so every change touches many units (shotgun surgery)
- A unit whose name no longer describes its contents

### Go

Sources: go.dev "Organizing a Go module" (go.dev/doc/modules/layout), Google Go Style Guide (google.github.io/styleguide/go), Effective Go.

- Package names `util`, `common`, `base`, `helpers` — explicitly discouraged by the Google Go Style Guide
- Packages that should be under `internal/` but are importable by anyone
- Interfaces defined next to the producer with one implementation, instead of at the consumer ("accept interfaces, return structs")
- Business logic inside `cmd/` binaries instead of importable packages
- Premature `pkg/`-style deep nesting for a small module — the official layout guidance starts flat

### Rust

Sources: Rust API Guidelines (rust-lang.github.io/api-guidelines), The Cargo Book, The Rust Book ch. 7 & 12 (module system, lib/bin split).

- Binary crates holding the logic: `main.rs` should be a thin shell over `lib.rs` so the logic is testable (Book ch. 12 pattern, de facto standard)
- Workspace crates with mutual or tangled dependencies instead of a DAG
- Domain crates depending on framework/transport crates (axum, tokio, sqlx) when the project separates them
- Public API leaking private internals or overly deep paths without re-exports (C-REEXPORT); missing `#[non_exhaustive]`/newtype boundaries where the guidelines call for future-proofing
- Feature flags abused to fake layering that crate boundaries should express

### Zig

Sources: Zig Build System documentation (ziglang.org/learn/build-system), std library conventions.

- Modules not declared via `build.zig` (`addModule`/`createModule`) but reached through relative-path `@import` across logical boundaries
- A root source file that fails to define the module's public surface, forcing consumers to import deep internals
- `anytype` parameters crossing module boundaries where a declared interface struct (std.Io.Writer-style vtable pattern) is the convention

### C

Sources: standard practice per project conventions (e.g., LKML/kernel style, GNOME/GLib patterns) — name whichever the project follows.

- Public headers exposing struct internals where an opaque pointer (`typedef struct foo foo;`) would enforce the boundary
- Include cycles, or "upward" includes from a lower-level directory into a higher-level one
- A directory layout implying layers (`core/`, `drivers/`, `ui/`) contradicted by the actual include graph

## Accepted structure (do not flag; do not over-build when writing)

- Small programs where formal layering would be over-engineering — do not demand hexagonal architecture from a 500-line CLI, and do not scaffold layers into one; absence of layers is not a defect unless the project claims them
- Deviations the project documents deliberately (an ADR or README note saying why) — acknowledge, don't relitigate
- Conventions you cannot source — no "commonly people do X" without a citable document
- What the compiler already enforces (Go import cycles, Rust orphan rule) — flag only the workarounds that smuggle violations past it
- Style-level concerns (naming case, formatting), simplicity/YAGNI, and runtime cost — owned by other lenses/skills, not this one
