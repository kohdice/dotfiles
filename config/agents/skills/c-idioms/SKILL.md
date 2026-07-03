---
name: c-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing C code — implementing features in .c/.h files, "C で実装して", "この C コードを直して", or auditing C for C23 migration. It defines the mandatory procedure for resolving the project's target standard from build files, plus a version-tagged catalog of removed constructs (C99–C23), obsolescent constructs with official replacements, and modern C23 facilities, so that generated code and review recommendations never exceed the project's declared -std= baseline.
---

# C Idioms (standard-version-aware, up to C23)

Authority sources: the C23 standard ISO/IEC 9899:2024 (working drafts N3096/N3220), the WG14 proposals it incorporates, and cppreference.com's C23 documentation. Do not invent recommendations: every idiom below traces to one of these sources.

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any C code:

1. Determine the target standard: grep build files (Makefile, CMakeLists.txt, meson.build, build.zig, compile_flags.txt, .clang-format/.clang-tidy) for `-std=` flags (`c23`, `c2x`, `gnu23`, `gnu2x`, `c17`, `c11`, ...) or `C_STANDARD 23`.
2. If no explicit standard is declared, treat the compiler default as the floor and prefer conservative choices; suggest pinning `-std=` as a low-priority improvement.
3. Note compiler reality: near-complete C23 support requires GCC 14+ / Clang 18+ (older compilers accept `-std=c2x`); MSVC support is partial. Mention this when recommending migration.

Hard rules derived from the baseline:

- **Never use a language or library feature introduced after the project's target standard.** When an item below is desirable but standard-gated, present it as an option labeled with the required C version — do not silently use it.
- If the project targets C17 or older, C23-only items are migration options, not violations; removed-construct findings still apply relative to the targeted standard.
- When recommending a change in review, always cite the C standard version that removed, deprecated, or introduced the construct so it can be checked against the project's `-std=` flag.

## Catalog coverage and verification

**Catalog coverage version: C23 (ISO/IEC 9899:2024, `__STDC_VERSION__ == 202311L`).** The catalogs below are verified against official sources up to this version. They are the default checklist; do not re-derive them from documentation when the project baseline falls within coverage. Go to the official sources when — and only when:

- **Staleness guard**: the project targets a standard newer than the coverage version above (e.g. a future `-std=c2y`). The catalog is out of date for this project. Do both: (a) check official sources for changes between the coverage version and the targeted standard, and follow those newer official recommendations now; (b) tell the user this skill's catalog needs updating (see Maintenance below).
- A construct or its removing/introducing standard version is **not listed here**: never trust memory for standard-version history; verify before gating on it.
- A catalog entry **conflicts with observed compiler behavior**: verify against the sources; if the conflict stands, report the discrepancy.

Verification sources, in order of authority:

1. cppreference C23 overview: https://en.cppreference.com/w/c/23 (feature-by-feature status and versions)
2. WG14 working drafts N3096/N3220 and proposal documents (exact normative wording)
3. Compiler release notes (GCC/Clang) for implementation status

## Maintenance (updating this skill for a new C standard)

When asked to update this skill after a new standard is published:

1. Review the official change list between the coverage version and the new standard (cppreference compatibility pages, WG14 editor's reports).
2. Add newly removed constructs, newly obsolescent constructs, and newly standardized facilities with their C version tags.
3. Remove nothing that older baselines may still need — the catalog is version-tagged precisely so old and new baselines coexist.
4. Bump the coverage version at the top of "Catalog coverage and verification".

## Removed constructs (hard errors or changed semantics)

Each entry is tagged with the standard that removed or changed it:

- **K&R (identifier-list) function definitions and non-prototype declarations** (removed in C23): `int f(a, b) int a, b; {...}` no longer compiles; every function must have a full prototype
- **Empty parentheses semantics changed** (C23): `void f()` now means `void f(void)` (no arguments), not "unspecified arguments". Flag call sites that relied on the old semantics to pass arguments
- **Trigraphs** (removed in C23): `??=` etc. no longer translate
- **`ATOMIC_VAR_INIT`** (deprecated in C17, removed in C23) → direct initialization of the atomic object
- **`realloc(ptr, 0)`** (undefined behavior since C23; was implementation-defined) → use `free` explicitly, or guard the zero-size case
- **`gets`** (removed in C11) → `fgets`
- **Implicit `int` and implicit function declarations** (removed in C99, still tolerated by lax compiler flags): flag any occurrence
- **Two's complement mandated** (C23): sign-magnitude/ones'-complement fallback code paths are dead code

## Obsolescent constructs with official replacements

All replacements below are C23 unless noted:

- **`_Noreturn`, `<stdnoreturn.h>`, `noreturn` macro** (obsolescent) → `[[noreturn]]` attribute
- **`<stdbool.h>`**: `bool`/`true`/`false` are keywords now; the header and `__bool_true_false_are_defined` are obsolescent → drop the include, use the keywords. Same for `_Bool` → `bool`
- **`<stdalign.h>`**: `alignas`/`alignof` are keywords → drop the include; `_Alignas`/`_Alignof` are alternative spellings, prefer the keywords
- **`_Static_assert`** → `static_assert` keyword (message argument now optional); **`_Thread_local`** → `thread_local` keyword
- **`DECIMAL_DIG`** (deprecated) → type-specific `FLT_DECIMAL_DIG`/`DBL_DECIMAL_DIG`/`LDBL_DECIMAL_DIG`
- **`NULL`** → `nullptr` (`nullptr_t`): type-safe, especially in variadic calls and `_Generic`; NULL remains valid, so severity is Medium only where type safety matters (varargs, sentinel arguments), otherwise Low
- **`memset` for wiping secrets** → `memset_explicit` (guaranteed not optimized away)
- **GNU/Clang extensions now standardized**: `__typeof__` → `typeof`/`typeof_unqual`; `__attribute__((fallthrough/unused/warn_unused_result/deprecated/noreturn))` → `[[fallthrough]]`/`[[maybe_unused]]`/`[[nodiscard]]`/`[[deprecated]]`/`[[noreturn]]`; `__builtin_unreachable()` → `unreachable()` from `<stddef.h>` (keep extensions only when older compilers must be supported, and say so)

## Modern C23 facilities to prefer

- **Checked integer arithmetic**: manual overflow checks (`a > INT_MAX - b`, wrapping casts) → `<stdckdint.h>` `ckd_add`/`ckd_sub`/`ckd_mul`
- **Bit manipulation**: hand-rolled popcount/clz/ctz loops and `__builtin_popcount` family → `<stdbit.h>` `stdc_count_ones`, `stdc_leading_zeros`, `stdc_trailing_zeros`, `stdc_bit_width`, `stdc_has_single_bit`, endian macros `__STDC_ENDIAN_NATIVE__`
- **Compile-time constants**: `#define MAX_LEN 128` and enum-constant hacks for typed constants → `constexpr` object definitions
- **Enums with fixed underlying type**: `enum E : uint8_t {...}` where the width matters (ABI, serialization) instead of casts and `assert(sizeof)`
- **Bit-precise integers**: `_BitInt(N)` where exact widths beyond standard types are needed, instead of bitfield structs or manual masking
- **Empty initializer `{}`**: replaces `{0}` and `memset(&s, 0, sizeof s)` for zero-initialization (also valid for VLAs)
- **Binary literals `0b...` and digit separators `'`**: prefer over hex masks with explanatory comments where binary form is clearer
- **Preprocessor**: `#embed` instead of xxd-generated byte arrays; `#elifdef`/`#elifndef`; `#warning`; `__has_include`/`__has_c_attribute` for feature detection
- **printf/scanf**: `%b` for binary output; `wN` length modifiers (`"%w32d"`) for exact-width types instead of `PRId32` macros where C23 is guaranteed
- **Library additions**: `strdup`/`strndup`/`memccpy` now standard (no POSIX guard needed); `gmtime_r`/`localtime_r`/`timegm` now standard — flag non-reentrant `gmtime`/`localtime` in multithreaded code
- **Variadics**: `va_start(ap)` takes one argument; a named parameter before `...` is no longer required
- Do NOT recommend `auto` type inference or `[[unsequenced]]`/`[[reproducible]]` proactively; mention them only when the code already uses them incorrectly

## Standard-conformance hygiene

- Every function declared with a full prototype; internal linkage (`static`) for file-local functions
- Feature-test discipline: code using optional features guards with the standard macros (`__STDC_NO_ATOMICS__`, `__STDC_NO_THREADS__`, `__STDC_NO_VLA__`, `__STDC_VERSION_STDCKDINT_H__` etc.), not compiler-name checks, where portability is intended
- No reliance on undefined behavior that C23 newly clarifies or that reviewers commonly miss: signed shift into the sign bit is still UB, `realloc` size 0 (see Removed constructs), modifying string literals
- The C standard has no official style guide for naming/formatting — do not report naming or brace style as violations; if asked, label such feedback as community convention (e.g., project-local .clang-format)
