---
name: zig-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing Zig code — implementing features in .zig files, "Zig で実装して", "この Zig コードを直して", or auditing Zig for 0.16.0 migration. It defines the mandatory procedure for resolving the project's minimum_zig_version from build.zig.zon, plus a version-tagged catalog of the std.Io interface migration, removed language features and std APIs (0.15.x–0.16.0), build system conventions, and the official style guide, so that generated code and review recommendations never exceed the project's declared Zig version.
---

# Zig Idioms (version-aware, up to Zig 0.16.0)

Authority sources: the official release notes (ziglang.org/download/0.16.0/release-notes.html and 0.15.1), the Zig Language Reference, the std library documentation, the Zig Style Guide, and `zig fmt` defaults. Do not invent recommendations: every idiom below traces to one of these sources. Zig 0.16.0 was released 2026-04-13; its headline change is "I/O as an Interface" (`std.Io`).

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any Zig code:

1. Read `build.zig.zon` of the project being edited: note `minimum_zig_version`.
2. Check the installed toolchain with `zig version` — Zig has no editions, so the effective baseline is the pair (declared minimum, installed compiler).
3. If `minimum_zig_version` is absent, treat the installed compiler version as the floor and prefer conservative choices; suggest pinning `minimum_zig_version` as a low-priority improvement.

Hard rules derived from the baseline:

- **Never use an API or language feature introduced after the project's minimum_zig_version.** When an item below is desirable but version-gated, present it as an option labeled with the required Zig version — do not silently use it.
- If the project targets a version older than 0.16.0, 0.16-only items are migration options, not violations; removed-API findings still apply relative to the targeted version.
- When recommending a change in review, always cite the Zig version that removed, deprecated, or introduced the API so it can be checked against `minimum_zig_version`.

## Catalog coverage and verification

**Catalog coverage version: Zig 0.16.0.** The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the verification sources when — and only when:

- **Staleness guard**: the resolved `minimum_zig_version` or installed toolchain (`zig version`) is newer than the coverage version above. The catalog is out of date for this project. Do both: (a) check the release notes for everything changed between the coverage version and the actual version, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating to the new version (see Maintenance below).
- An API or its removing/introducing version is **not listed here**: never trust memory for Zig's fast-moving std API history; verify before gating on it.
- A catalog entry **conflicts with observed compiler behavior**: the compiler wins; report the discrepancy.

Verification sources, in order of preference:

1. **Installed std sources (local, prefer this)**: run `zig env` to find `std_dir`, then Read/Grep there to confirm whether an API exists and what its current signature is
2. Release notes: https://ziglang.org/download/0.16.0/release-notes.html and https://ziglang.org/download/0.15.1/release-notes.html (exact removal/introduction versions and official migration guidance)
3. Zig Language Reference: https://ziglang.org/documentation/0.16.0/ (language rules)

## Maintenance (updating this skill for a new Zig release)

When asked to update this skill after a new Zig release:

1. Read the release notes for every version between the coverage version and the new release.
2. Add newly removed/deprecated APIs and language rules with their version tags; add new std facilities and build system capabilities; update the std.Io migration table if the interface evolved.
3. Remove nothing that older baselines may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".

## Build system conventions (build.zig / build.zig.zon)

- Modules must be created via `b.createModule` / `b.addModule` and passed as `root_module` to `addExecutable`/`addTest`
- C header translation must use `b.addTranslateC()` — `@cImport` is deprecated in 0.16
- New 0.16 capabilities to mention where relevant: incremental compilation (`-fincremental --watch`), unit test timeouts, project-local package fetching

## std.Io migration (0.16.0 headline change)

Anything touching the file system, processes, timers, synchronization, or entropy now takes an `Io` parameter. These APIs are superseded in 0.16.0:

- **File system**: `std.fs.cwd()` → `std.Io.Dir.cwd()`; `fs.Dir.makeDir/makePath/makeOpenDir` → `Io.Dir.createDir/createDirPath/createDirPathOpen`; `fs.File.read/pread/write/pwrite(+v/All)` → `Io.File.readStreaming/readPositional/writeStreaming/writePositional(+All)`; `fs.File.setEndPos/getEndPos` → `Io.File.setLength/length`; `chmod/chown` → `setPermissions/setOwner`; `fs.realpath*` → `Io.Dir.realPathFile*`; `fs.*Absolute` helpers → `Io.Dir.*Absolute`; `fs.path` → `Io.Dir.path` (deprecated alias)
- **Process**: `std.process.Child.init/run` → `std.process.spawn/run`; `execv` → `replace`; `fs.selfExePath*` / `openSelfExe` → `std.process.executablePath*` / `openExecutable`; `fs.Dir.setAsCwd` → `std.process.setCurrentDir`
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

Code claiming 0.16 support must not contain these:

- `usingnamespace` (removed 0.15) → explicit re-declarations or namespaced access
- `async`/`await` keywords (removed 0.15) → `std.Io` async APIs
- Managed containers: `std.ArrayList(T)` is unmanaged since 0.15 — `append` etc. take an explicit allocator; flag `std.array_list.Managed` and stored-allocator patterns
- Old stream API ("Writergate", 0.15): `std.io.getStdOut()/getStdIn()`, `GenericReader`/`AnyReader`, `null_writer`, `CountingReader` → `std.Io.Reader`/`std.Io.Writer` with caller-provided buffers
- Formatting: `format` methods take `*std.Io.Writer` and are selected with `{f}`; `fmt.Formatter` → `fmt.Alt`; `fmt.format` → `Io.Writer.print`; `fmt.FormatOptions` → `fmt.Options`; `fmt.bufPrintZ` → `fmt.bufPrintSentinel`
- `std.BoundedArray` (removed 0.15) and `std.SegmentedList` (removed 0.16) → fixed arrays + length, or `ArrayList` with a fixed buffer
- `std.mem.split`/`tokenize` → explicit `splitScalar`/`splitSequence`/`splitAny` variants
- `BitSet`/`EnumSet` `initEmpty()`/`initFull()` → declaration literals (e.g. `.initEmpty`)

## Official style (Zig Style Guide + zig fmt)

- Naming: `TitleCase` for types (and callables returning types), `camelCase` for functions, `snake_case` for variables/fields/constants; file names: `snake_case.zig`, `TitleCase.zig` only when the file is itself a struct with fields
- Doc comments `///` on public decls; `//!` for module-level docs; no commented-out code
- Allocator hygiene: take `std.mem.Allocator` (and now `Io`) as parameters instead of storing globals; `errdefer` for cleanup on error paths; `defer` immediately after acquisition
- Prefer slices over sentinel pointers at API boundaries unless C interop requires them; use `error{...}!T` inferred or explicit error sets per public-API clarity
- The Zig Style Guide is the only official style source — when a convention is merely popular in the community (not in the Style Guide or enforced by `zig fmt`), label it as a community convention, not an official recommendation
