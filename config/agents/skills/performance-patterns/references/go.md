# Go performance patterns

Verified against Go 1.26; resolve the project baseline (`go` directive in `go.mod`) per the `go-idioms` skill before recommending version-gated APIs. Numbers refer to the factor catalog in SKILL.md. Verify escape-analysis claims with `go build -gcflags=-m` when available.

## 1. Algorithmic complexity

- `slices.Contains` / `slices.Index` on the same slice inside a loop over another collection → build a `map[K]struct{}` once
- `append([]T{x}, s...)` or copy-shifting to insert at the front repeatedly → append and reverse once, or use a ring buffer
- Sorting inside a loop, or re-sorting after each single insertion → sort once after the loop

## 2. Allocations and copies

- Values escaping to the heap unnecessarily: returning pointers to locals, interface conversions in hot loops, capturing loop variables in closures
- `append` in loops without `make([]T, 0, n)` pre-allocation when `n` is known or estimable
- `fmt.Sprintf` / string `+` in hot paths where `strconv` or `strings.Builder` (with `Grow`) suffices
- `[]byte` ↔ `string` conversions that copy on every call (note: `m[string(b)]` map lookups and `switch string(b)` are compiler-optimized and allocation-free)
- Maps recreated per call instead of cleared (`clear`, 1.21) and reused; missing `sync.Pool` for per-request buffers
- `strings.Split`/`Fields` (and `bytes` equivalents) allocating a slice that is only ranged over once → `strings.SplitSeq`/`FieldsSeq` iterators (1.24)
- Boxing into `interface{}`/`any` (e.g., logging or generic containers) inside hot loops
- Large struct receivers/parameters passed by value in hot functions where a pointer avoids the copy

## 3. Redundant work

- `regexp.MustCompile` inside a function called per item → hoist to a package-level `var`
- Rebuilding format strings, lookup tables, or `time.Location` per call
- Repeated `strconv`/`time.Parse` of a value that earlier code already parsed

## 4. I/O and syscalls

- Direct `os.File` / `net.Conn` reads and writes per item → wrap in `bufio.Reader` / `bufio.Writer` and flush per batch
- One database/API round-trip per item where a batched query or pipeline exists
- `os.File.Sync` per record instead of per batch

## 5. Memory access patterns [measure]

- `[]*T` iterated hotly where `[]T` keeps elements contiguous (also reduces GC scan work)
- Struct field ordering that wastes padding in large, numerous structs (checkable with the x/tools `fieldalignment` analyzer — not part of default `go vet`)
- Adjacent counters mutated by different goroutines sharing a cache line (pad or shard)

## 6. Concurrency costs [measure]

- Goroutine or channel created per item → worker pool, `errgroup` with `SetLimit`, or batching
- One `sync.Mutex` guarding a hot map from many goroutines → sharded locks, `sync.Map` (read-mostly), or per-goroutine accumulation with a final merge
- `atomic` counters hammered from many goroutines → per-P/per-worker counters merged at the end

## 7. Language mechanism costs [measure]

- Interface method calls in the hottest loops prevent inlining; a concrete type or generic instantiation enables devirtualization
- `defer` inside a hot loop body accumulates per-iteration overhead → move the deferred cleanup outside the loop
- cgo calls have fixed per-call overhead → batch data across the boundary instead of calling per item
