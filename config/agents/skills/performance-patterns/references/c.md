# C performance patterns

Verified against C23; resolve the project baseline (`-std=` in the build files) per the `c-idioms` skill before recommending version-gated constructs. Numbers refer to the factor catalog in SKILL.md. Assume optimized builds (`-O2`); do not flag what the optimizer provably handles, but remember pointer aliasing often blocks hoisting the programmer expects.

## 1. Algorithmic complexity

- `strlen` in a loop condition over an unchanging string, `strcat` in a loop (O(n²) — Schlemiel the Painter) → track the end pointer/length
- Linear search (`for`/`strcmp` scan) inside another loop → sort once + `bsearch`, or a hash table
- Shifting array contents (`memmove`) to insert/remove at the front per item → ring buffer or tombstones

## 2. Allocations and copies

- `malloc`/`free` pairs inside loops where the buffer could be allocated once and reused
- `realloc` growth one element at a time instead of geometric growth or a pre-counting pass
- Repeated `memcpy` of data that could be referenced (pointer + length) instead of duplicated
- Large structs passed or returned by value in hot functions → pass a pointer (`const T *`)
- `snprintf` into a fresh heap buffer per item where a reused stack buffer suffices

## 3. Redundant work

- Loop-invariant expressions the compiler cannot hoist because of possible aliasing → hoist manually or use `restrict`
- Re-parsing or re-validating input per item that an earlier phase already handled
- Rebuilding lookup tables per call instead of computing them once (static init)

## 4. I/O and syscalls

- Raw `read(2)`/`write(2)` per record → buffered `fread`/`fwrite`, or a manual buffer flushed per batch
- `fflush`/`fsync` per record instead of per batch
- One small `write` per field where a single `writev` or one composed buffer works

## 5. Memory access patterns [measure]

- Linked lists / pointer-chasing structures on hot iteration paths → contiguous arrays (or array + index links)
- Struct field ordering that wastes padding across many instances (`sizeof` check; order members largest-to-smallest)
- Array-of-structs iterated for one field → struct-of-arrays when cachegrind/perf shows miss-bound loops
- False sharing: per-thread data adjacent in one cache line → pad/align (`alignas(64)` — keyword in C23, `_Alignas`/`<stdalign.h>` in C11–C17)

## 6. Concurrency costs [measure]

- A mutex around each tiny operation → batch under one lock, shard, or use thread-local accumulation with a merge
- Shared atomic counters updated from many threads → per-thread counters merged at the end

## 7. Language mechanism costs [measure]

- Function-pointer calls (qsort-style callbacks, vtables-by-hand) in the hottest loops prevent inlining → specialized loops or macros/inline functions when a profile justifies it
- Missing `restrict` on hot-loop pointer parameters that provably don't alias, blocking vectorization
