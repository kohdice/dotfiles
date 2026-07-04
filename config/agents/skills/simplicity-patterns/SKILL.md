---
name: simplicity-patterns
description: This skill should be used when writing, modifying, refactoring, or reviewing code in C, Go, Rust, or Zig — implementing features, "シンプルに実装して", deciding whether an interface/trait, generic, builder, or wrapper layer is justified, or auditing a codebase for over-engineering. It defines the YAGNI principle, Kent Beck's "Tidy First?" discipline separating structural from behavioral change, the four justifications an abstraction must meet to earn its keep, a catalog of wrapper-only code, speculative abstractions, and structural clutter (with per-language variants), and the accepted-abstraction criteria, so that generated code introduces no unearned indirection and reviews flag only removable implementation.
---

# Simplicity Patterns (YAGNI / Tidy First?, C / Go / Rust / Zig)

Grounded in Kent Beck's "Tidy First?" and the YAGNI principle. The goal is implementation that earns its keep: every wrapper, abstraction, and layer must be justified by a need that exists today.

## Core principles

### YAGNI (You Aren't Gonna Need It)

Code must justify itself by a need that exists today. An abstraction paid for now but used "maybe later" is a cost with no return: it must be read, tested, and maintained until the imagined future arrives — which it usually never does in that shape. When writing code, this means: start with the direct call, the plain struct, the concrete type; introduce the seam when the second consumer actually appears.

### Tidy First? (Kent Beck)

Structure changes and behavior changes are separated. A tidying is a pure structural change — deleting dead code, inlining a needless wrapper, removing an unused parameter — that leaves observable behavior identical. A change that alters behavior (e.g., removing a public API) is not a tidying and needs its own decision. Keep the two in separate commits/steps, tidyings first.

### Abstraction must earn its keep

Indirection is justified by at least one of:

- (a) it enforces an invariant
- (b) it is a genuine seam used today (multiple implementations, or a test double that actually exists in the test suite)
- (c) it isolates a volatile dependency at a real boundary (FFI, I/O, third-party API)
- (d) it is a published API whose stability is a stated requirement

Absent all four, prefer the direct call. When writing new code, apply this test before introducing the indirection; when reviewing, apply it to every abstraction in scope.

## Pattern catalog

### Wrapper-only code (all languages)

- Functions that only call another function with the same arguments (pass-through), possibly renaming it
- Structs/types wrapping a single field and forwarding all methods without adding an invariant
- Getter/setter pairs that expose the field with no validation or encapsulation benefit
- One-line helpers with a single call site whose name adds nothing the callee's name doesn't say
- Modules/packages that only re-export another module's contents

### YAGNI violations (all languages)

- Interfaces/traits with exactly one implementation and no test double in the test suite
- Type parameters / generics instantiated with only one concrete type in the entire codebase
- Parameters always passed the same value at every call site; boolean flags nobody sets to the other value
- Config options, feature flags, hooks, and callbacks with no real consumer
- "Manager" / "Provider" / "Factory" layers with a single caller and a single product
- Dead code: unreferenced functions, unread struct fields, unused error variants, commented-out blocks
- Builder patterns for structs with few fields where a literal or plain constructor suffices
- Public API surface (exported symbols) exceeding actual external usage in binaries/internal code

### Tidy First? opportunities (structural clutter)

- Over-fragmented code: logic shattered into tiny single-use functions that must be read together anyway — inline into "one pile" so it can be understood, then re-split along real seams if any emerge
- Missing guard clauses: deep nesting where early returns would flatten the flow
- Explaining helpers/variables that no longer explain anything (name restates the expression)
- Symmetry violations: the same idea written two different ways in the same file

### Go

- Interfaces defined next to the producer instead of the consumer, with one implementation ("accept interfaces, return structs" inverted)
- Wrapper packages around the standard library that only rename functions
- `New*` constructors that only do `&T{}` with no validation or defaulting
- Embedding plus manual forwarding methods that embedding already provides

### Rust

- Newtypes that add no invariant, no trait impl, and no type-safety distinction actually relied upon (legitimate newtypes enforce units, validity, or orphan-rule workarounds — those earn their keep)
- Traits with a single impl and no `dyn`/generic use site that needs the abstraction
- `impl Trait`/generic parameters where a concrete type is the only instantiation
- Builder + `Default` + constructor all present for a small config struct

### Zig

- `comptime` generic functions instantiated with a single type
- Wrapper structs around an allocator or writer that only forward calls
- Options structs where every call site passes `.{}`

### C

- Function-pointer tables (vtable-style) with a single implementation ever installed
- Opaque handle layers around a struct used in only one translation unit
- Macro wrappers that only rename a function; `#ifdef` branches for platforms never built

## Accepted abstractions (do not flag; do write when the condition holds)

- Wrappers that enforce invariants, however thin (validation, unit safety, locking discipline)
- Interfaces/traits with a test double genuinely used in the test suite — that seam is in use today
- Boundaries around FFI, I/O, clocks, randomness, or third-party APIs — isolation of volatility is a present need
- Published library APIs where stability is a stated requirement (note the constraint instead)
- Idiomatic ceremony the language expects (e.g., `Default` impls, error type boilerplate)
- Anything where the simplification would change observable behavior — that is a design question, not a tidying

Judge one language's idioms only by that language's conventions — a Rust newtype convention does not apply to Go, and vice versa.
