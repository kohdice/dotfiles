---
name: zig-idioms
description: "Guides Zig implementation, refactoring, review, and modernization using official practices compatible with the project's declared minimum Zig version."
---

# Zig Idioms (version-aware, up to the stated catalog coverage version)

Authority sources: the official release notes for the covered versions (ziglang.org/download/<version>/release-notes.html), the Zig Language Reference, the std library documentation, the Zig Style Guide, and `zig fmt` defaults. Do not invent recommendations: every idiom below traces to one of these sources. Zig 0.17.0 was released 2026-10-01; its headline changes are language stabilization (`@bitCast` semantics, `@backingInt`/`@fromBackingInt`, syntax removals), a reworked build system (configure/make split, cache rework), `std.heap.SafeAllocator`, and C translation moving to the external `translate_c` package. Zig 0.16.0 (released 2026-04-13) introduced "I/O as an Interface" (`std.Io`), which 0.17.0 keeps unchanged apart from additions.

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any Zig code:

1. Read `build.zig.zon` of the project being edited: note `minimum_zig_version`.
2. Check the installed toolchain with `zig version` — Zig has no editions, so the effective baseline is the pair (declared minimum, installed compiler). (In a read-only review or when the toolchain cannot be invoked, judge on the declared minimum alone — do not block on `zig version`.)
3. If `minimum_zig_version` is absent, treat the installed compiler version as the floor and prefer conservative choices — operationally: prefer APIs that clearly predate the catalog floor (0.15.x) or are catalog-listed as valid for the assumed floor (the branches overlap; satisfying either one is sufficient, cite whichever applies). Suggest pinning `minimum_zig_version` as a low-priority improvement (in reviews, tag it `[recommend]`).
4. State the resolved baseline in the deliverable — the review report's opening or the write-mode summary.

Hard rules derived from the baseline:

- **Never use an API or language feature introduced strictly after the project's minimum_zig_version** (one introduced exactly at the minimum version is allowed). When an item below is desirable but version-gated, present it as an option labeled with the required Zig version — do not silently use it. When writing code, record the gated option as a brief source comment at the affected line and mention it, with the required version, in the summary to the user.
- Unlike editioned languages, Zig removes APIs. When support for both the declared minimum and a newer compiler is required, changes must fit their intersection; a newer installed compiler alone does not establish that support requirement. If an API cannot satisfy both versions, state which version introduces or removes it. Unless a migration is explicitly authorized, preserve the declared minimum and the task's public-interface constraints; neither the installed compiler nor an unanswered question authorizes raising the minimum. Continue with compatible edits, leaving incompatible migration as a version-gated option. Report verification limits, distinguish pre-existing compiler incompatibility from introduced failures, and never claim verification with a compiler that was not run.
- If the project targets a version older than the catalog coverage version, items introduced at newer versions are migration options (`[gated-option]`), not violations; removed-API findings still apply relative to the targeted version.
- When recommending a change in review, always cite the Zig version that removed, deprecated, or introduced the API so it can be checked against `minimum_zig_version`.

## Catalog coverage and verification

**Catalog coverage version: Zig 0.17.x (verified against the 0.17.0 release).** Patch releases within a minor series contain bug fixes only, so 0.17.1 and later 0.17.y toolchains are inside coverage. The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the verification sources when — and only when:

- **Staleness guard**: the resolved `minimum_zig_version` or installed toolchain (`zig version`) has a newer minor version than the coverage series above (compare `0.<minor>` only; a newer patch number is not staleness). (When the toolchain cannot be invoked, judge staleness on the resolved minimum alone.) The catalog is out of date for this project. Do both: (a) check the release notes for everything changed between the coverage version and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating to the new version (see Maintenance below).
- An API or its removing/introducing version is **not listed here** AND is **boundary-relevant** — plausibly changed at or after the catalog floor (0.15.x) or near the resolved baseline: never trust memory for Zig's fast-moving std API history; verify before gating on it. Long-established APIs that clearly predate the catalog floor (e.g. `std.mem.eql`, `std.debug.assert`, `std.testing.expect`) need no verification.
- A catalog entry **conflicts with observed compiler behavior or version-matched official sources**: evidence for the relevant version wins; report the discrepancy. Distinguish usable deprecated aliases, declarations that fail with `@compileError`, and absent declarations when verifying an API's history.

Verification sources, in order of preference:

1. **Installed std sources (local, prefer this)**: run `zig env` to find `std_dir` (the output is ZON, not JSON — read the raw output rather than assuming a format), then Read/Grep there to confirm whether an API exists and what its current signature is
2. Release notes: https://ziglang.org/download/<version>/release-notes.html — one page per covered version, substituting the verified release of the coverage series (currently 0.17.0) and, for older removals, the removing version (exact removal/introduction versions and official migration guidance)
3. Zig Language Reference: https://ziglang.org/documentation/<version>/ — substitute the verified release of the coverage series (currently 0.17.0) (language rules)

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
   - `[error]` — rejected by the resolved baseline's compiler (e.g. `usingnamespace` or `async`/`await` keywords on a ≥0.15 baseline, `@Type()` on 0.16, `@cImport` or `void{}` on 0.17). Catalog entries marked `silent-break@<version>` also take `[error]`: the code compiles on that baseline but its meaning changed (e.g. the `containsAtLeastScalar` argument order or `@hasDecl` visibility on 0.17), so the finding must say the breakage is silent
   - `[warn]` — compiles on the baseline but is deprecated with an official replacement (e.g. `@cImport` or the `fs.path` alias on 0.16; `std.heap.DebugAllocator` or `@intFromEnum` on 0.17)
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
- C header translation: `@cImport` is deprecated in 0.16 and removed in 0.17. On a 0.16 baseline use `b.addTranslateC()`; on 0.17 `b.addTranslateC()` / `std.Build.Step.TranslateC` are deprecated (→ [warn]) in favor of the official external package (verified call shape from the 0.17.0 release notes):

  ```zig
  // zig fetch --save git+https://codeberg.org/ziglang/translate-c#zig-0.17.x
  const Translator = @import("translate_c").Translator;
  const translator: Translator = .init(b.dependency("translate_c", .{}), .{
      .c_source_file = b.path("src/c.h"),
      .target = target,
      .optimize = optimize,
      // replaces c_module.linkSystemLibrary("glfw", .{}); further options:
      // https://codeberg.org/ziglang/translate-c#options
      .link_system_libs = &.{ .{ .name = "glfw" } },
  });
  // then: .imports = &.{ .{ .name = "c", .module = translator.mod } }
  // (or some_module.addImport("c", translator.mod)); translator.output_file
  // is the generated .zig as a LazyPath
  ```

- 0.17 build API changes (each verified against the installed 0.17.0 `std.Build`): `b.build_root` removed → `b.root` (a `Cache.Path`) [error]; `b.lazyDependency` deprecated → `b.dependencyLazy` (returns `error.LazyDependencyNeeded`) [warn]; `Step.Run.addOutputFileArg`/`addFileArg`/`addArtifactArg` and their `addPrefixed*` variants deprecated → the `*Arg2` forms taking `PathArgOptions` [warn]; `b.findProgram` runs at configure time and poisons the configure cache → prefer `b.findProgramLazy` (returns a `LazyPath`); `Step.Options.addOptionPath` now accepts files only → `addOptionPathDirectory` for directories, `addOptionPathUntracked` to opt out of tracking; passing user args to a run step via `b.args` → `Step.Run.addPassthruArgs`; Fmt step `paths`/`exclude_paths` are `LazyPath` lists built with `b.pathList`; overriding the build runner is no longer possible
- New 0.17 capabilities to mention where relevant: configure/make process split and reworked cache (`--cache-poison[=pure|poisoned|disallowed|ignored]`, `--print-configuration`, `zig cache-cat`), `b.dependOnFileContents`/`dependOnFileMetadata`/`dependOnDirectoryContents`/`dependOnDirectoryMetadata` for configure-time inputs, Build Server Protocol (`zig build --listen=-`), package path override and global-vs-local fetching (`ZIG_LOCAL_PKG_DIR`), `zig fmt --complexity` (token/AST-node counts)
- New 0.16 capabilities to mention where relevant: incremental compilation (`-fincremental --watch`), unit test timeouts, project-local package fetching

## std.Io migration (0.16.0 headline change)

Anything touching the file system, processes, timers, synchronization, or entropy now takes an `Io` parameter. **Migration cost**: these are not mechanical renames — an `Io` instance must be threaded as a parameter through the call chain from the entry point; state that reshape cost in findings (the error renames at the bottom of this list are the only drop-in items).

**Io bootstrap and high-frequency forms** (verified by compiling and running against Zig 0.17.0; the `std.Io` shapes are unchanged since 0.16.0 — use these directly instead of re-deriving them from std sources):

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
// Allocator on a 0.17+ baseline: `std.heap.SafeAllocator` (thread-safe; this is
// what `std.process.Init.gpa` uses in Debug). `deinit` returns the leak count.
var safe_allocator: std.heap.SafeAllocator = .init(std.heap.page_allocator, .{});
defer _ = safe_allocator.deinit();
const gpa = safe_allocator.allocator();
// On a 0.14–0.16 baseline (SafeAllocator does not exist; DebugAllocator is the
// 0.14+ name of GPA, deprecated in 0.17):
//   var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
//   defer _ = debug_allocator.deinit();
//   const gpa = debug_allocator.allocator();
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

**State classifiers**: every old name in this table was **removed** in 0.16.0 — findings against a ≥0.16 baseline are `[error]` — unless marked `(deprecated alias remains → [warn])`. The classifiers are verified against the installed 0.16.0 and 0.17.0 std (the aliases marked as remaining are still present in 0.17.0); when an entry carries one, use it to decide severity directly — do not re-grep std sources for that. These APIs are replaced in 0.16.0:

- **File system**: `std.fs.cwd()` → `std.Io.Dir.cwd()`; `fs.File.readToEndAlloc` / `fs.Dir.readFileAlloc` → `Io.Dir.readFileAlloc(io, sub_path, gpa, limit)` (convenience read-to-end); `fs.Dir.makeDir/makePath/makeOpenDir` → `Io.Dir.createDir/createDirPath/createDirPathOpen`; `fs.File.read/pread/write/pwrite(+v/All)` → `Io.File.readStreaming/readPositional/writeStreaming/writePositional(+All)`; `fs.File.setEndPos/getEndPos` → `Io.File.setLength/length`; `chmod/chown` → `setPermissions/setOwner`; `fs.realpath*` → `Io.Dir.realPathFile*`; `fs.*Absolute` helpers → `Io.Dir.*Absolute`; `fs.path` → `Io.Dir.path` (deprecated alias remains → [warn])
- **Process**: `std.process.Child.init/run` → `std.process.spawn/run`; `execv` → `replace`; `fs.selfExePath*` / `openSelfExe` → `std.process.executablePath*` / `openExecutable`; `fs.Dir.setAsCwd` → `std.process.setCurrentDir`; `std.process.argsAlloc` (removed 0.16.0) → CLI args come from the `std.process.Init` main signature (see the bootstrap block above)
- **Synchronization**: `std.Thread.Mutex/Condition/RwLock/Semaphore/Futex/ResetEvent/WaitGroup` → `std.Io.Mutex/Condition/RwLock/Semaphore/Futex/Event/Group`; `std.Thread.Mutex.Recursive` and `std.once` removed; `std.Io.Semaphore.waitTimeout(io, timeout)` added in 0.17.0 (`[gated-option]` below 0.17)
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
- `@cImport` deprecated → `b.addTranslateC()` in build.zig (removed in 0.17; see the 0.17.0 section)

## Language-level changes (0.17.0)

Each entry is verified against the 0.17.0 release notes and the installed 0.17.0 compiler (`zig build-exe -fno-emit-bin` / `zig ast-check` on scratch files):

- `@cImport` removed (deprecated 0.16) → `[error]`; migrate to the `translate_c` package (Build system conventions above)
- `@intFromEnum`/`@enumFromInt` deprecated → `@backingInt`/`@fromBackingInt` (`[warn]`; `zig fmt` rewrites them automatically, so suggest running it rather than hand-editing); `std.meta.BackingInt(T)` added; an empty enum must declare `noreturn` as its backing integer
- `@intFromFloat` remains deprecated (Language Reference: "Deprecated. Equivalent to `@trunc`") → `[warn]`, same replacement as the 0.16 entry
- `@bitCast` now reinterprets the *logical* bit representation: casts involving `extern struct`/`extern union` are rejected → `[error]`, use `@ptrCast` or an `extern union` for type punning; array/vector `@bitCast` may change meaning without a compile error → `silent-break@0.17`, audit each site; `@bitCast` to an `enum` now safety-checks the tag value
- `@hasDecl` returns `true` only for `pub` declarations (previously also for same-file private ones) → `silent-break@0.17`
- Array multiplication `a ** b` removed → `@splat` (e.g. `var buf: [n]u8 = @splat(0);`) `[error]`
- `void{}` removed → `{}` `[error]`
- `errdefer |err| { ... }` capture removed `[error]` → move the body into an inner function returning an error union and call it as `inner() catch |err| ...`
- `i0` removed → `u0` `[error]`; `std.lang.GlobalLinkage` tags `internal`/`link_once` removed `[error]`
- Added: `@divCeil`, `@SpirvType`; `comptime`-length slices may now be dereferenced (`slice.*`) or coerced to `*const [N]T`

## Standard library changes (0.17.0)

State classifiers verified against the installed 0.17.0 std; `removed` entries are `[error]` on a ≥0.17 baseline, `deprecated` entries `[warn]`. Below a 0.17 baseline the new names are `[gated-option]`.

- **Allocators**: `std.heap.DebugAllocator`, `DebugAllocatorConfig`, `std.heap.Check` deprecated → `std.heap.SafeAllocator` (`.init(backing_allocator, .{})`; `deinit()` returns the leak count as `usize`); `std.heap.StackFallbackAllocator`/`std.heap.stackFallback` removed → `std.heap.BufferFirstAllocator` (`.init(buffer, fallback_allocator)`); `std.heap.memory_pool.AlignedManaged`/`ExtraManaged` removed → `Aligned`/`Extra`
- **Formatting**: `std.fmt.allocPrint` deprecated → `Allocator.print` (`try gpa.print("{s}={d}", .{ x, y })`); `std.fmt.bufPrintZ` removed (alias since 0.15) → `bufPrintSentinel`; `{qf}` added (double-quote-escapes a `format()` result); `{q}` now passes UTF-8 through unescaped
- **ArrayList**: `getLast`/`getLastOrNull` deprecated → `last()` (`?T`; use `.last().?` for the asserting form); `lastPtr()` (`?*T`) added; safe builds now check element-pointer stability across growth
- **Namespaces**: `std.builtin` deprecated → `std.lang`; `std.lang.OptimizeMode` deprecated → `std.lang.Optimize` with tags `.debug/.safe/.fast/.small` (`.Debug/.ReleaseSafe/.ReleaseFast/.ReleaseSmall` remain as deprecated decls "to be removed after 0.18.0"; `==`/`!=` against the old names no longer compile → `switch` or the new tags); prefer `std.lang.Optimize.runtimeSafety()` (`builtin.mode.runtimeSafety()`) over `std.debug.runtime_safety` because it reflects the calling module; `std.gpu` removed → `std.spirv`; the `zig build -O`/`-O` CLI still accepts `ReleaseFast` etc. but documents `debug/safe/fast/small`
- **`@import("builtin")`**: `.cpu`/`.os`/`.abi`/`.object_format` deprecated → `.target.cpu`/`.target.os`/`.target.abi`/`.target.ofmt` (removal announced for 0.18.0)
- **Reflection**: `std.meta.fieldInfo`/`fieldNames`/`fieldTypes` deprecated → `@typeInfo` ("to be removed after 0.17.0 is tagged"); `@typeInfo(T).@"struct"` and `.@"union"` are struct-of-arrays: `.fields` removed → iterate `info.field_names` and `info.field_types` together (`inline for (info.field_names, info.field_types) |name, FieldType|`), with per-field attributes in `info.field_attrs`
- **mem**: `containsAtLeastScalar(T, list, element, minimum)` — the former `containsAtLeastScalar2` took over the name and the old `(…, minimum, element)` order is gone → `silent-break@0.17`, check argument order at every call; `readPackedIntNative`/`readPackedIntForeign`/`writePackedIntNative`/`writePackedIntForeign` removed → `readPackedInt`/`writePackedInt` with an explicit `Endian`; `std.mem.eql`/`findDiff` no longer short-circuit on float slices (NaN-correct); `indexOf`/`indexOfScalar` remain deprecated aliases of `find`/`findScalar` (`[warn]`, unchanged from 0.16)
- **ascii**: `indexOfIgnoreCase`/`indexOfIgnoreCasePos`/`indexOfIgnoreCasePosLinear` removed → `findIgnoreCase`/`findIgnoreCasePos`/`findIgnoreCasePosLinear`
- **bit_set / enums**: `IntegerBitSet`→`Integer`, `ArrayBitSet`→`Array`, `StaticBitSet`→`Static`, `DynamicBitSetUnmanaged`→`Dynamic`, `DynamicBitSet`→`DynamicManaged` (deprecated aliases remain, including the `std.*BitSet` re-exports → `[warn]`); the `.initEmpty`/`.initFull` declaration literals of `bit_set.Integer`, `bit_set.Array`, and `enums.EnumSet` removed → `.empty`/`.full` (the allocating `Dynamic.initEmpty(allocator, n)`/`initFull` keep their names)
- **Containers**: `std.DoublyLinkedList.pop` absent in the 0.17.0 std (the release notes list it as deprecated) → `popLast`
- **Uri / net**: `std.Uri.getHost`/`getHostAlloc` removed → `std.Io.net.HostName.fromUri(uri, &buffer)`
- **zon**: `std.zon.parse.fromSliceAlloc` removed → `fromSlice`; the old non-allocating `fromSlice` → `fromSliceNoAlloc`; both now take `(T, options)` with `.gpa`, `.arena`, `.source`, `.diagnostics` fields; `updateFromSlice`/`updateFromSliceNoAlloc` added
- **Io**: no interface changes; `std.Io.Semaphore.waitTimeout` added (see the std.Io table)
- **Target**: `std.Target.parseCpuModel` returns an optional instead of an error; `std.lang.Optimize.runtimeSafety` added

## Legacy removals (0.15.x–0.16.0)

Code claiming 0.16 support must not contain these. Each entry carries its own version tag and state classifier — cite those, not this section's range:

- `usingnamespace` (removed 0.15) → explicit re-declarations or namespaced access
- `async`/`await` keywords (removed 0.15) → `std.Io` async APIs
- `std.ArrayList(T)` is unmanaged since 0.15 (removed: `.init(allocator)`, allocator-less `append`/`deinit`) — initialize with the `.empty` declaration literal; `append`/`deinit` take an explicit allocator
- `std.array_list.Managed` (deprecated alias remains in 0.16 and 0.17 → [warn]) → migrate to unmanaged `std.ArrayList`; also flag stored-allocator patterns
- Old stream API ("Writergate", deprecated 0.15; the `std.io` namespace is fully removed in 0.16): `std.io.getStdOut()/getStdIn()`, `GenericReader`/`AnyReader`, `null_writer`, `CountingReader` → `std.Io.Reader`/`std.Io.Writer` with caller-provided buffers (concrete stdout form: the "Io bootstrap and high-frequency forms" block above)
- Formatting (0.15, "Writergate"): `format` methods take `*std.Io.Writer` and are selected with `{f}`; `fmt.Formatter` → `fmt.Alt` (removed 0.16); `fmt.format` → `Io.Writer.print`; `fmt.FormatOptions` → `fmt.Options` (removed 0.16); `fmt.bufPrintZ` → `fmt.bufPrintSentinel` (deprecated alias remains through 0.16 → [warn]; removed 0.17 → [error])
- `std.BoundedArray` (removed 0.15) and `std.SegmentedList` (removed 0.16) → fixed arrays + length, or `ArrayList` with a fixed buffer
- `std.mem.split`/`tokenize`: explicit variants introduced 0.11; old names remain usable deprecated aliases from 0.11 through [0.13](https://github.com/ziglang/zig/blob/0.13.0/lib/std/mem.zig) → [warn], become `@compileError` stubs in [0.14](https://github.com/ziglang/zig/blob/0.14.0/lib/std/mem.zig) → [error], and are absent in [0.15.1](https://github.com/ziglang/zig/blob/0.15.1/lib/std/mem.zig) → [error]. Use `splitScalar`/`splitSequence`/`splitAny`, `tokenizeScalar`/`tokenizeSequence`/`tokenizeAny`. Semantics-preserving choice: old `split` treated the delimiter as a sequence (single element → `splitScalar`, multi → `splitSequence`); old `tokenize` treated it as a set of single characters → `tokenizeAny` (or `tokenizeScalar` for one char). For a single split at the first delimiter (e.g. `key=value`), use `std.mem.findScalar` + slicing on a 0.16+ baseline; use `std.mem.indexOfScalar` + slicing on older baselines. In 0.16 and 0.17, `indexOfScalar` remains a usable deprecated alias → [warn] ([official rename](https://ziglang.org/download/0.16.0/release-notes.html#mem-introduce-cut-functions-rename-index-of-to-find)). Splitting iterators cut at every delimiter
- `BitSet`/`EnumSet` `initEmpty()`/`initFull()` → declaration literals `.initEmpty`/`.initFull` (0.15–0.16); those literals are in turn removed in 0.17 → `.empty`/`.full` (see the 0.17.0 std section)

## Official style (Zig Style Guide + zig fmt)

- Naming: `TitleCase` for types (and callables returning types), `camelCase` for functions, `snake_case` for variables/fields/constants; file names: `snake_case.zig`, `TitleCase.zig` only when the file is itself a struct with fields
- Doc comments `///` on public decls; `//!` for module-level docs; no commented-out code
- Allocator hygiene: take `std.mem.Allocator` (and now `Io`) as parameters instead of storing globals; `errdefer` for cleanup on error paths; `defer` immediately after acquisition
- Prefer slices over sentinel pointers at API boundaries unless C interop requires them; use `error{...}!T` inferred or explicit error sets per public-API clarity
- Run `zig fmt` rather than hand-formatting — check-first: on tasks touching existing files, run `zig fmt --check` and reformat only what you wrote unless asked to reformat the file. When it is not run for any reason (unavailable, sandboxed, or disallowed), match its defaults manually and note it. Since 0.17 `zig fmt` also rewrites deprecated builtins (`@intFromEnum` → `@backingInt`, `@enumFromInt` → `@fromBackingInt`), so running it on a file is a source change, not only whitespace — say so when reporting what was reformatted
- The Zig Style Guide is the only official style source — when a convention is merely popular in the community (not in the Style Guide or enforced by `zig fmt`), label it as a community convention, not an official recommendation

## Maintenance (updating this skill for a new Zig release)

When asked to update this skill after a new Zig release:

1. Read the release notes for every version between the coverage version and the new release.
2. Add newly removed/deprecated APIs and language rules with their version tags; add new std facilities and build system capabilities; update the std.Io migration table if the interface evolved.
   Every entry must carry an entry-level version tag and a state classifier (removed@version / deprecated-alias-remains); a section-level range is not a substitute — the review contract's citation rule depends on this.
3. Remove nothing that older baselines may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".
5. **Floor raise** (only when both hold: SKILL.md is approaching ~300 lines, AND the floor-end entries target versions that virtually no maintained project still declares as `minimum_zig_version`): raise the catalog floor instead of deleting. Move entries whose state classifier predates the new floor — version tags and classifiers intact — to `references/archive.md`, bump the floor version wherever it is stated in this file, and amend the boundary-verification rule so the archive is consulted for below-floor API history before descending into std sources or release notes. This keeps rule 3 satisfied: nothing is removed from the skill's knowledge, only demoted out of the always-loaded window.
