---
name: performance-patterns
description: This skill should be used when writing, modifying, refactoring, or reviewing performance-sensitive code in C, Go, Rust, or Zig — parsers, encoders, request handlers, per-item/per-request/per-frame loops, "パフォーマンスを意識して実装して", or auditing a codebase for runtime cost. It defines the hot-path-first principle, a cost-ordered catalog of performance factors (algorithmic complexity, allocations and copies, redundant work, I/O and syscalls, memory access patterns, concurrency costs, language mechanism costs), an evidence-tier rule separating statically verifiable issues from measurement-required ones, and per-language pattern references, so that generated code avoids known cost patterns from the start and reviews never report speculative micro-optimizations.
---

# Performance Patterns (hot-path-aware, C / Go / Rust / Zig)

## Cross-cutting principles

### Hot path first

Cost = (cost per execution) × (execution count). Before optimizing or flagging anything, establish how often the code runs:

- **Hot**: loop bodies, per-item/per-request/per-frame functions, recursive calls, code called from other hot code.
- **Cold**: initialization, configuration loading, error paths, CLI argument parsing, test code.

Apply this catalog at full strength in hot paths. In cold paths, fix only egregious waste (e.g., O(n²) growth); never sacrifice clarity for micro-optimizations in code that runs once.

### Measure, don't guess

When a claim about cost is cheap to check statically, check it (e.g., `go build -gcflags=-m` for escape analysis). When it is not — cache behavior, contention, branch prediction — measure before acting: `perf`, `valgrind --tool=cachegrind`, `hyperfine` for whole programs; Go `pprof`/`benchstat`; Rust `criterion`; Zig `poop` or `std.Io.Timestamp`-based micro-benchmarks (0.16; `std.time.Timer` on older versions). Never present an unmeasured tier-[measure] concern as a fact.

### Respect the project's language baseline

Version resolution is owned by the matching idiom skill (`c-idioms`, `go-idioms`, `rust-idioms`, `zig-idioms`): resolve the baseline from the build manifest (`-std=`, `go.mod` go directive, `Cargo.toml` edition/rust-version, `build.zig.zon` minimum_zig_version) before recommending version-gated APIs. The per-language references below are verified against C23, Go 1.26, Rust 1.95 (2024 Edition), and Zig 0.16.0; entries gated on a newer version than the project's baseline must be presented as upgrade-gated options, not applied silently.

### Correctness before speed

Never trade semantics for speed: aliasing rules, lifetime requirements, thread/goroutine ownership, and error behavior must survive any optimization. Do not remove idiomatic allocations the language expects (e.g., a single `Vec` at a Rust API boundary, error-path `fmt.Errorf` in Go). If a safe optimization requires restructuring, say so explicitly rather than forcing it.

## Cost-ordered factor catalog

Factors are ordered by typical impact. Address a higher factor before descending to a lower one — a better algorithm routinely beats any amount of allocation tuning. Each factor is tagged with its evidence tier (see below).

### 1. Algorithmic complexity [static]

- Repeated linear search inside a loop (O(n²)) where a map/set gives O(n)
- Insert/remove at the front of a contiguous container inside a loop
- Sorting or re-scanning inside a loop when one pass outside suffices
- O(n²) hidden behind convenience APIs (string concatenation, repeated `contains` on a list)
- Wrong data structure for the dominant operation (list scanned by key, array used as a queue)

### 2. Allocations and copies [static]

- Allocation inside a loop where the buffer/object could be hoisted out and reused
- Growing containers without pre-sizing when the final size is known or estimable
- Building strings by repeated concatenation instead of a builder/buffer
- Copying a large struct/array by value where a pointer/reference/slice suffices
- Temporary collections built only to be iterated once and discarded (could stream)
- Allocating to return data the caller immediately copies again (double buffering)

### 3. Redundant work [static]

- Loop-invariant expressions recomputed every iteration (lengths, lookups, conversions the compiler cannot hoist)
- Compiling regexes, building lookup tables, or parsing configuration inside a function called per item
- Parsing or serializing the same data more than once along one code path
- Recomputing a value that an earlier phase already produced and could have passed along

### 4. I/O and syscalls [static]

- Unbuffered reads/writes in a loop — one syscall per item instead of one per buffer
- Missing batching of network/database round-trips that could be coalesced
- Flushing or syncing (`fflush`, `fsync`) per record instead of per batch
- Reading a file in tiny chunks when the whole file (or a large window) is the unit of work

### 5. Memory access patterns [measure]

- Pointer-chasing structures (linked lists, trees of boxed nodes) iterated hotly where contiguous arrays would serve
- Array-of-structs iterated for one field where struct-of-arrays keeps the cache line full
- Struct field ordering that wastes space to padding, inflating the working set
- False sharing: unrelated data mutated by different threads on the same cache line

### 6. Concurrency costs [measure]

- A lock acquired per item where batching or sharding would cut contention
- Spawning a thread/goroutine or creating a channel per item instead of using a worker pool
- Shared atomic counters hammered from many threads (contention, cache-line ping-pong)
- Synchronization guarding data that could be thread-local or partitioned

### 7. Language mechanism costs [measure]

- Dynamic dispatch (interface/`dyn`/function-pointer calls) in the hottest loops where static dispatch is available
- Per-language mechanism costs — bounds checks, escape analysis, runtime safety modes — detailed in the references below

## Evidence tiers

- **[static]** (factors 1–4): verifiable by reading the code. When writing, apply these by default in hot paths. When reviewing, these are reportable findings at full severity.
- **[measure]** (factors 5–7): real, but usually invisible to code reading. When writing, prefer the cheaper design when it costs no clarity (contiguous over pointer-chasing, batched over per-item locking) — do not contort code for unmeasured wins. When reviewing, report as Notes/design observations unless profiling data is available or the structure makes the cost unmistakable.

## Per-language references

After identifying the languages involved, read the matching reference for concrete patterns and the idiomatic fixes:

- `references/go.md`, `references/rust.md`, `references/c.md`, `references/zig.md`

The references live in this skill's directory (deployed at `~/.claude/skills/performance-patterns/references/`).
