# Zig performance patterns

Verified against Zig 0.16.0; resolve the project baseline (`minimum_zig_version`) per the `zig-idioms` skill before recommending version-gated APIs. Numbers refer to the factor catalog in SKILL.md. Assume `ReleaseFast`/`ReleaseSafe` for cost discussion; Debug-build slowness is not a finding.

## 1. Algorithmic complexity

- `std.mem.indexOf` / linear scan inside a loop over another collection → build a `std.AutoHashMap`/`StringHashMap` once
- `ArrayList.orderedRemove(0)` or front insertion per item (O(n) each) → `std.Deque` (0.16; `std.fifo.LinearFifo` on older versions) or index-based consumption
- Sorting inside a loop → sort once after collection

## 2. Allocations and copies

- `allocator.alloc` / `ArrayList.append` inside loops without `ensureTotalCapacity` when the count is known or estimable (since 0.15 `ArrayList` is unmanaged: both take the allocator explicitly)
- Missing `std.heap.ArenaAllocator` / `FixedBufferAllocator` for scoped, free-all-at-once workloads (per-request, per-frame)
- Struct copies from `for (items) |item|` by value when `|*item|` avoids copying large elements
- `std.fmt.allocPrint` in hot paths where `bufPrint` into a stack buffer works
- Returning freshly allocated slices the caller immediately copies → write into a caller-provided buffer

## 3. Redundant work

- Rebuilding lookup tables or precomputable data per call → compute once at `comptime` when inputs are comptime-known, or once at startup
- Re-parsing/re-validating data an earlier phase already handled
- Loop-invariant field loads/computations repeated per iteration

## 4. I/O and syscalls

- Unbuffered file/socket reads and writes per item → on 0.15+, `std.Io.Reader`/`std.Io.Writer` take a caller-provided buffer: size it for the workload (a zero-length buffer means one syscall per operation) and flush per batch; pre-0.15, wrap in the old `std.io` buffered reader/writer
- `sync` per record instead of per batch

## 5. Memory access patterns [measure]

- Pointer-heavy node structures iterated hotly → contiguous slices or arena + indices
- Array-of-structs iterated for one field → `std.MultiArrayList` (SoA) when profiling shows cache-miss-bound loops
- Struct field ordering that wastes padding across many instances (Zig reorders fields for regular structs, but `extern`/`packed` structs follow declaration order)

## 6. Concurrency costs [measure]

- A mutex acquired per item → batch under one acquisition, shard, or accumulate per-thread and merge
- Spawning a thread per item → thread pool / batched work queues

## 7. Language mechanism costs [measure]

- Function-pointer / vtable-style dispatch in the hottest loops where comptime generics give static dispatch
- Safety-checked builds: bounds/overflow checks dominate some hot loops in `ReleaseSafe` — measure before reaching for `@setRuntimeSafety(false)`, and scope it minimally if used
- `inline for`/`inline` calls only where a profile or comptime-known trip count justifies the code-size cost
