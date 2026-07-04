# Rust performance patterns

Verified against Rust 1.95 (2024 Edition); resolve the project baseline (`edition` / `rust-version` in `Cargo.toml`) per the `rust-idioms` skill before recommending version-gated APIs. Numbers refer to the factor catalog in SKILL.md. All observations assume release builds (`--release`); debug-build slowness is not a finding.

## 1. Algorithmic complexity

- `Vec::contains` / linear `iter().position` inside a loop over another collection → build a `HashSet`/`HashMap` once
- `Vec::remove(0)` / `Vec::insert(0, x)` in a loop (O(n) each) → `VecDeque`
- Sorting inside a loop, or `sort` when only the top-k or a partition is needed (`select_nth_unstable`, 1.49)

## 2. Allocations and copies

- `.clone()` / `.to_owned()` / `.to_string()` where a borrow (`&str`, `&[T]`) or lifetime restructuring would work
- `Vec::new()` / `String::new()` + push in a loop instead of `with_capacity`, or `collect()` without a size hint when one exists
- Chained `collect()` into intermediate `Vec`s where iterator adapters could stay lazy end to end
- `format!` in hot paths where `write!` into a reused `String`/buffer works
- `Box`/`Rc`/`Arc` allocation per iteration when the value could live on the stack or be reused
- Passing large types by value (implicit memcpy) where `&`/`&mut` suffices; `[u8; N]` copies in loops

## 3. Redundant work

- `Regex::new` inside a hot function → `LazyLock<Regex>` (1.80) or `OnceLock` (1.70)
- Re-validating or re-parsing (`str::parse`, UTF-8 checks) data an earlier phase already validated
- Recomputing `len()`-derived bounds or hash keys the loop never changes

## 4. I/O and syscalls

- `File`/`TcpStream` read/written directly per item → `BufReader` / `BufWriter`, flush per batch
- `println!`/`writeln!(io::stdout(), ...)` per line in a hot loop locks stdout each call → lock once (`let mut out = io::stdout().lock()`, `'static` handle since 1.61) and write to the locked handle
- `sync_all`/`flush` per record instead of per batch

## 5. Memory access patterns [measure]

- `Vec<Box<T>>` / boxed-node trees iterated hotly where `Vec<T>` (or an arena + indices) keeps data contiguous
- Array-of-structs iterated for one field → struct-of-arrays when profiling shows cache misses
- Enums with one huge variant inflating every element (`Box` the large variant); check with `std::mem::size_of`

## 6. Concurrency costs [measure]

- `Mutex`/`RwLock` acquired per item → batch under one acquisition, shard, or accumulate thread-locally and merge
- `Arc::clone` per item in a hot loop (refcount contention) → clone once per thread/scope and pass references inward
- Fine-grained atomics hammered from many threads → per-thread counters merged at the end

## 7. Language mechanism costs [measure]

- `dyn Trait` calls in the hottest loops where generics (static dispatch, inlinable) are available without ergonomic cost
- Index-based loops that defeat bounds-check elision → iterators or slice patterns; verify with a profile before contorting code
- Missed `#[inline]` on tiny cross-crate hot functions (only when profiling shows the call overhead)
