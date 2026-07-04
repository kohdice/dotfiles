---
name: zig-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing Zig code — implementing features in .zig files, "Zig で実装して", "この Zig コードを直して", or auditing Zig for 0.16.0 migration. It defines the mandatory procedure for resolving the project's minimum_zig_version from build.zig.zon, plus a version-tagged catalog of the std.Io interface migration, removed language features and std APIs (0.15.x–0.16.0), build system conventions, and the official style guide, so that generated code and review recommendations never exceed the project's declared Zig version.
---

# Zig Idioms (version-aware, up to Zig 0.16.0)

Authority sources: the official release notes (ziglang.org/download/0.16.0/release-notes.html and 0.15.1), the Zig Language Reference, the std library documentation, the Zig Style Guide, and `zig fmt` defaults. Do not invent recommendations: every idiom below traces to one of these sources. Zig 0.16.0 was released 2026-04-13; its headline change is "I/O as an Interface" (`std.Io`).

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any Zig code:

1. Read `build.zig.zon` of the project being edited: note `minimum_zig_version`.
2. Check the installed toolchain with `zig version` — Zig has no editions, so the effective baseline is the pair (declared minimum, installed compiler). (In a read-only review or when the toolchain cannot be invoked, judge on the declared minimum alone — do not block on `zig version`.)
3. If `minimum_zig_version` is absent, treat the installed compiler version as the floor and prefer conservative choices — operationally: prefer APIs that clearly predate the catalog floor (0.15.x) or are catalog-listed as valid for the assumed floor (the branches overlap; satisfying either one is sufficient, cite whichever applies). Suggest pinning `minimum_zig_version` as a low-priority improvement (in reviews, tag it `[recommend]`).
4. State the resolved baseline in the deliverable — the review report's opening or the write-mode summary.

Hard rules derived from the baseline:

- **Never use an API or language feature introduced strictly after the project's minimum_zig_version** (one introduced exactly at the minimum version is allowed). When an item below is desirable but version-gated, present it as an option labeled with the required Zig version — do not silently use it. When writing code, record the gated option as a brief source comment at the affected line and mention it, with the required version, in the summary to the user.
- Unlike editioned languages, Zig removes APIs: when the installed compiler is newer than the declared minimum, code must stay within the intersection of the two — no APIs introduced after the declared minimum, and no APIs removed at or before the installed version. If a construct cannot satisfy both ends of the range, surface the conflict to the user (with the version that breaks each side) instead of silently picking one end. When no user answer is available (non-interactive run), surface the conflict in the deliverable, then proceed with the side the installed toolchain can verify — keeping the change reversible (reasoned comment on any `minimum_zig_version` edit) and stating in the summary how to undo it.
- If the project targets a version older than 0.16.0, 0.16-only items are migration options (`[gated-option]`), not violations; removed-API findings still apply relative to the targeted version.
- When recommending a change in review, always cite the Zig version that removed, deprecated, or introduced the API so it can be checked against `minimum_zig_version`.

## Catalog coverage and verification

**Catalog coverage version: Zig 0.16.0.** The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the verification sources when — and only when:

- **Staleness guard**: the resolved `minimum_zig_version` or installed toolchain (`zig version`) is newer than the coverage version above. (When the toolchain cannot be invoked, judge staleness on the resolved minimum alone.) The catalog is out of date for this project. Do both: (a) check the release notes for everything changed between the coverage version and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating to the new version (see Maintenance below).
- An API or its removing/introducing version is **not listed here** AND is **boundary-relevant** — plausibly changed at or after the catalog floor (0.15.x) or near the resolved baseline: never trust memory for Zig's fast-moving std API history; verify before gating on it. Long-established APIs that clearly predate the catalog floor (e.g. `std.mem.eql`, `std.debug.assert`, `std.testing.expect`) need no verification.
- A catalog entry **conflicts with observed compiler behavior**: the compiler wins; report the discrepancy.

Verification sources, in order of preference:

1. **Installed std sources (local, prefer this)**: run `zig env` to find `std_dir` (the output is ZON, not JSON — read the raw output rather than assuming a format), then Read/Grep there to confirm whether an API exists and what its current signature is
2. Release notes: https://ziglang.org/download/0.16.0/release-notes.html and https://ziglang.org/download/0.15.1/release-notes.html (exact removal/introduction versions and official migration guidance)
3. Zig Language Reference: https://ziglang.org/documentation/0.16.0/ (language rules)

**Verification fallback**: if a source is unreachable or a tool cannot be run for any reason (offline, sandboxed, restricted), try at most one alternate route, then stop and degrade: prefer a construct whose version is already catalog-listed; if none fits, state the recommendation with an explicit "unverified" label and the assumed Zig version. Never let unreachable sources block the deliverable or trigger repeated fetch attempts.

## Write-mode output (writing or modifying code)

Writing code needs no report, but the deliverable summary must contain, in one place:

1. The resolved baseline and where it came from (Step 0).
2. Any version-gated option that was considered: a brief source comment at the affected line, plus a mention with the required Zig version in the summary.
3. What verification ran (`zig build` / `zig build test` / `zig fmt`, or the project-shape equivalent — e.g. `zig test <file>` for a single-file utility; the list is representative, not exhaustive) — or an explicit note that it was skipped and why. When tests do not reference the entry point, also run the program once if possible (tests alone leave `main`'s I/O wiring unverified), or note that this was skipped.
4. Summary prose follows the conversation language; code, identifiers, and tags stay in English.

## Review output contract

When the task is a review or audit, structure the report as follows.

1. **Baseline statement first**: the resolved `minimum_zig_version` and installed compiler version, and where each came from (`build.zig.zon`, `zig version`).
2. **Findings**, each tagged with exactly one severity. Severity follows from the rule class, not executor judgment:
   - `[error]` — rejected by the resolved baseline's compiler (e.g. `usingnamespace` or `async`/`await` keywords on a ≥0.15 baseline, `@Type()` on 0.16)
   - `[warn]` — compiles on the baseline but is deprecated with an official replacement (e.g. `@cImport` or the `fs.path` alias on 0.16)
   - `[recommend]` — legal but officially discouraged, with a within-baseline replacement (e.g. sentinel pointers at API boundaries without C interop)
   - `[gated-option]` — desirable but requires a Zig version above the declared minimum; must carry the required version and must never be presented as a direct fix

   Severity is decided by the state classifier of the name the reviewed code actually uses; classifiers of replacement or alternative routes appear only in the recommendation text, never as the finding's tag.

3. Every finding cites the authority it rests on: the Zig version that removed, deprecated, or introduced the API, or — for version-independent guidance — the Style Guide rule, so it can be checked against the baseline.
4. Report prose follows the conversation language; code snippets, identifiers, and severity tags stay in English. This language policy applies to every deliverable, including write-mode summaries.
5. When one finding's fix supersedes another, report both and cross-reference which fix subsumes which. Criterion: finding X subsumes finding Y when applying X's fix makes Y's flagged code disappear (e.g. replacing `openFile` + `readToEndAlloc` with a single `Io.Dir.readFileAlloc` call removes both flagged lines); merely touching the same function is not subsumption.

Compile-checking the reviewed code is optional corroboration, never required — the catalog's state classifiers already decide severity. If you do compile, treat it as a weak oracle: Zig's lazy analysis skips unreferenced declarations (force full analysis on a scratch copy with a `std.testing.refAllDecls(@This())` test), and a parse error such as `usingnamespace` masks every later error.

Exception to the unlisted-API verification rule: an unlisted API on a line that a subsuming fix deletes needs no independent verification or finding — mention it inside the subsuming finding instead.

## Build system conventions (build.zig / build.zig.zon)

- Modules must be created via `b.createModule` / `b.addModule` and passed as `root_module` to `addExecutable`/`addTest`
- C header translation must use `b.addTranslateC()` — `@cImport` is deprecated in 0.16
- New 0.16 capabilities to mention where relevant: incremental compilation (`-fincremental --watch`), unit test timeouts, project-local package fetching

## std.Io migration (0.16.0 headline change)

Anything touching the file system, processes, timers, synchronization, or entropy now takes an `Io` parameter. **Migration cost**: these are not mechanical renames — an `Io` instance must be threaded as a parameter through the call chain from the entry point; state that reshape cost in findings (the error renames at the bottom of this list are the only drop-in items).

**Io bootstrap and high-frequency forms** (verified against Zig 0.16.0; use these directly instead of re-deriving them from std sources):

```zig
// Variant 1 — CLI executables (preferred): main takes std.process.Init,
// which supplies the allocator, the Io instance, and the CLI args directly:
pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa; // general-purpose allocator, leak-checked in Debug
    const io = init.io;
    var args = try init.minimal.args.iterateAllocator(gpa);
    defer args.deinit();
    _ = args.skip(); // program name
    // init.arena (process-lifetime arena) and init.environ_map also exist
}

// Variant 2 — zero-arg `pub fn main() !void`, libraries, tests: manual bootstrap.
// Allocator (`std.heap.DebugAllocator` is the 0.14+ name of GPA):
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
defer _ = debug_allocator.deinit();
const gpa = debug_allocator.allocator();
// Obtain the one Io instance and pass it down the call chain:
var threaded: std.Io.Threaded = .init(gpa, .{});
defer threaded.deinit();
const io = threaded.io();

// stdout: caller-provided buffer, print via .interface, flush at the end:
var stdout_buffer: [4096]u8 = undefined;
var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
const out = &stdout_writer.interface; // *std.Io.Writer
try out.print("{s}\n", .{value});
try out.flush();

// Whole-file read (replaces openFile + readToEndAlloc in one call; exceeding
// the limit fails with error.StreamTooLong rather than truncating):
const contents = try std.Io.Dir.cwd().readFileAlloc(io, "path", gpa, .limited(1024 * 1024));

// In-memory writer for tests: std.Io.Writer.fixed(&buf), inspect via .buffered()
```

Buffer sizes and `.limited(...)` bounds above are example values — pick the largest input you are willing to accept for the task. Everything else — receivers, argument order, and the `.{}` default-options literals — is the verified call shape; copy it as-is.

**State classifiers**: every old name in this table was **removed** in 0.16.0 — findings against a 0.16 baseline are `[error]` — unless marked `(deprecated alias remains → [warn])`. The classifiers are verified against the installed 0.16.0 std; when an entry carries one, use it to decide severity directly — do not re-grep std sources for that. These APIs are replaced in 0.16.0:

- **File system**: `std.fs.cwd()` → `std.Io.Dir.cwd()`; `fs.File.readToEndAlloc` / `fs.Dir.readFileAlloc` → `Io.Dir.readFileAlloc(io, sub_path, gpa, limit)` (convenience read-to-end); `fs.Dir.makeDir/makePath/makeOpenDir` → `Io.Dir.createDir/createDirPath/createDirPathOpen`; `fs.File.read/pread/write/pwrite(+v/All)` → `Io.File.readStreaming/readPositional/writeStreaming/writePositional(+All)`; `fs.File.setEndPos/getEndPos` → `Io.File.setLength/length`; `chmod/chown` → `setPermissions/setOwner`; `fs.realpath*` → `Io.Dir.realPathFile*`; `fs.*Absolute` helpers → `Io.Dir.*Absolute`; `fs.path` → `Io.Dir.path` (deprecated alias remains → [warn])
- **Process**: `std.process.Child.init/run` → `std.process.spawn/run`; `execv` → `replace`; `fs.selfExePath*` / `openSelfExe` → `std.process.executablePath*` / `openExecutable`; `fs.Dir.setAsCwd` → `std.process.setCurrentDir`; `std.process.argsAlloc` (removed 0.16.0) → CLI args come from the `std.process.Init` main signature (see the bootstrap block above)
- **Synchronization**: `std.Thread.Mutex/Condition/RwLock/Semaphore/Futex/ResetEvent/WaitGroup` → `std.Io.Mutex/Condition/RwLock/Semaphore/Futex/Event/Group`; `std.Thread.Mutex.Recursive` and `std.once` removed
- **Time**: `std.time.Instant` / `std.time.Timer` / `std.time.timestamp()` → `std.Io.Timestamp` / `Io.Timestamp.now()`
- **Entropy**: `std.crypto.random` / `std.posix.getrandom` → `io.random()` (`std.Random.IoSource`)
- **posix layer**: most mid-level `std.posix` / `std.os.windows` wrappers are removed — use `std.Io` (high level) or `std.posix.system` (raw syscalls)
- **Error renames**: `RenameAcrossMountPoints`/`NotSameFileSystem` → `CrossDevice`; `SharingViolation` → `FileBusy`; `EnvironmentVariableNotFound` → `EnvironmentVariableMissing`
- **Async semantics**: `io.async` starts work immediately (no executor polling); cancellation surfaces as `error.Canceled`. Code must not assume lazy futures, and `error.Canceled` must be propagated, not swallowed.

## Language-level changes (0.16.0)

- `@Type()` removed → per-kind builtins: `@Int`, `@Struct`, `@Union`, `@Enum`, `@Fn`, `@Pointer`, `@EnumLiteral`; `@Float` → `std.meta.Float`, arrays/optionals/error unions via ordinary type syntax
- `@intFromFloat` deprecated → `@trunc`/`@round`/`@floor`/`@ceil` now convert directly to integer types
- `extern` contexts forbid enums with inferred tag types and packed structs/unions with inferred backing types → require explicit `enum(u8)` / `packed struct(u32)`; `packed union(T)` backing type syntax is now allowed and its `@bitSizeOf` must match every field
- Pointers in `packed struct`/`packed union` forbidden → store `usize` and convert with `@ptrFromInt`/`@intFromPtr`
- Runtime vector indexing forbidden (coerce to array first); vector↔array in-memory coercion removed; returning the address of a local is a compile error
- `@cImport` deprecated → `b.addTranslateC()` in build.zig

## Legacy removals (0.15.x–0.16.0)

Code claiming 0.16 support must not contain these. Each entry carries its own version tag and state classifier — cite those, not this section's range:

- `usingnamespace` (removed 0.15) → explicit re-declarations or namespaced access
- `async`/`await` keywords (removed 0.15) → `std.Io` async APIs
- `std.ArrayList(T)` is unmanaged since 0.15 (removed: `.init(allocator)`, allocator-less `append`/`deinit`) — initialize with the `.empty` declaration literal; `append`/`deinit` take an explicit allocator
- `std.array_list.Managed` (deprecated alias remains → [warn]) → migrate to unmanaged `std.ArrayList`; also flag stored-allocator patterns
- Old stream API ("Writergate", deprecated 0.15; the `std.io` namespace is fully removed in 0.16): `std.io.getStdOut()/getStdIn()`, `GenericReader`/`AnyReader`, `null_writer`, `CountingReader` → `std.Io.Reader`/`std.Io.Writer` with caller-provided buffers (concrete stdout form: the "Io bootstrap and high-frequency forms" block above)
- Formatting (0.15, "Writergate"): `format` methods take `*std.Io.Writer` and are selected with `{f}`; `fmt.Formatter` → `fmt.Alt` (removed 0.16); `fmt.format` → `Io.Writer.print`; `fmt.FormatOptions` → `fmt.Options` (removed 0.16); `fmt.bufPrintZ` → `fmt.bufPrintSentinel` (deprecated alias remains → [warn])
- `std.BoundedArray` (removed 0.15) and `std.SegmentedList` (removed 0.16) → fixed arrays + length, or `ArrayList` with a fixed buffer
- `std.mem.split`/`tokenize` (generic forms removed 0.12; explicit variants introduced 0.11) → `splitScalar`/`splitSequence`/`splitAny`, `tokenizeScalar`/`tokenizeSequence`/`tokenizeAny`. Semantics-preserving choice: old `split` treated the delimiter as a sequence (single element → `splitScalar`, multi → `splitSequence`); old `tokenize` treated it as a set of single characters → `tokenizeAny` (or `tokenizeScalar` for one char). For a single split at the first delimiter (e.g. `key=value`), use `std.mem.indexOfScalar` + slicing — splitting iterators cut at every delimiter
- `BitSet`/`EnumSet` `initEmpty()`/`initFull()` → declaration literals (e.g. `.initEmpty`)

## Official style (Zig Style Guide + zig fmt)

- Naming: `TitleCase` for types (and callables returning types), `camelCase` for functions, `snake_case` for variables/fields/constants; file names: `snake_case.zig`, `TitleCase.zig` only when the file is itself a struct with fields
- Doc comments `///` on public decls; `//!` for module-level docs; no commented-out code
- Allocator hygiene: take `std.mem.Allocator` (and now `Io`) as parameters instead of storing globals; `errdefer` for cleanup on error paths; `defer` immediately after acquisition
- Prefer slices over sentinel pointers at API boundaries unless C interop requires them; use `error{...}!T` inferred or explicit error sets per public-API clarity
- Run `zig fmt` rather than hand-formatting — check-first: on tasks touching existing files, run `zig fmt --check` and reformat only what you wrote unless asked to reformat the file. When it is not run for any reason (unavailable, sandboxed, or disallowed), match its defaults manually and note it
- The Zig Style Guide is the only official style source — when a convention is merely popular in the community (not in the Style Guide or enforced by `zig fmt`), label it as a community convention, not an official recommendation

## Maintenance (updating this skill for a new Zig release)

When asked to update this skill after a new Zig release:

1. Read the release notes for every version between the coverage version and the new release.
2. Add newly removed/deprecated APIs and language rules with their version tags; add new std facilities and build system capabilities; update the std.Io migration table if the interface evolved.
   Every entry must carry an entry-level version tag and a state classifier (removed@version / deprecated-alias-remains); a section-level range is not a substitute — the review contract's citation rule depends on this.
3. Remove nothing that older baselines may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".
