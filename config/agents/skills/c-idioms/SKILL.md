---
name: c-idioms
description: This skill should be used when writing, modifying, refactoring, or reviewing C code — implementing features in .c/.h files, "C で実装して", "この C コードを直して", or auditing C for C23 migration. It defines the mandatory procedure for resolving the project's target standard from build files, plus a version-tagged catalog of removed constructs (C99–C23), obsolescent constructs with official replacements, and modern C23 facilities, so that generated code and review recommendations never exceed the project's declared -std= baseline.
---

# C Idioms (standard-version-aware, up to C23)

Authority sources: the C23 standard ISO/IEC 9899:2024 (working drafts N3096/N3220), the WG14 proposals it incorporates, and cppreference.com's C23 documentation. Do not invent recommendations: every idiom below traces to one of these sources.

## Step 0: Resolve the project baseline (ALWAYS first)

Before writing or recommending any C code:

1. Determine the target standard: grep build files (Makefile, CMakeLists.txt, meson.build, build.zig, compile_flags.txt, .clang-format/.clang-tidy) for `-std=` flags (`c23`, `c2x`, `gnu23`, `gnu2x`, `c17`, `c11`, ...) or `C_STANDARD 23`.
2. If no explicit standard is declared, treat the compiler default as the floor and write to a conservative subset — assume C99 as the concrete floor unless there is evidence of older toolchains. Suggesting to pin `-std=` as a low-priority improvement is **mandatory output in your response**, exactly like the baseline statement in step 4. In this branch the baseline self-check (see Standard-conformance hygiene) runs with the project's flags as-is, plus one compile at the assumed floor (e.g. `-std=c99 -pedantic`) when a compiler is available.
3. Note compiler reality: near-complete C23 support requires GCC 14+ / Clang 18+ (older compilers accept `-std=c2x`); MSVC support is partial. Mention this when recommending migration.
4. **State the resolved baseline and its source in your response** (e.g. "target: C17, from `Makefile: -std=c17`") before emitting any code or findings. If it came from a compiler-default fallback (step 2), say so. This statement is mandatory output, not an internal step — silent resolution is non-compliance.

Hard rules derived from the baseline:

- **Never use a language or library feature introduced after the project's target standard.** Option labeling for standard-gated items — the trigger is observable, not aesthetic: any occurrence in delivered code of an in-baseline counterpart listed in the trigger table below, when the replacement's version sits above the baseline. Label the gated replacement as an option tagged with its required C version — **once per catalog entry per file**, as a comment at the first affected site, plus a one-line mention in the response. Do not repeat the label at every occurrence; do not silently use the gated feature; do not omit the label entirely when a counterpart pattern appears.

**Trigger table for option labeling** (authoritative extension of the rule above; counterpart-hood is decided by effect, not surface form — a morphologically different equivalent still counts):

| In-baseline counterpart in delivered code                                                                                                                                                                                             | Gated replacement                             | Version |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------- | ------- |
| `{0}` initializer, or `memset(&x, 0, sizeof x)` used for zero-initialization                                                                                                                                                          | empty initializer `{}`                        | C23     |
| a guard detecting overflow of an addition, subtraction, or multiplication that `ckd_*` could subsume (`a > INT_MAX - b`, pre-multiplication caps, wrapping casts) — min/clamp expressions and pure domain range checks do NOT trigger | `<stdckdint.h>` `ckd_add`/`ckd_sub`/`ckd_mul` | C23     |
| any object-like `#define` or enum constant expanding to an integer/float/string literal and used outside the preprocessor — array bounds and loop bounds DO trigger; function-like macros and conditional-compilation flags do NOT    | `constexpr` object definition                 | C23     |
| `NULL` in sentinel/varargs contexts only — ordinary null checks do NOT trigger                                                                                                                                                        | `nullptr`                                     | C23     |
| hand-rolled popcount/clz/ctz loop, or `__builtin_popcount` family                                                                                                                                                                     | `<stdbit.h>` functions                        | C23     |
| `memset` wiping secrets                                                                                                                                                                                                               | `memset_explicit`                             | C23     |
| `_Noreturn` / `noreturn` macro / `<stdnoreturn.h>`                                                                                                                                                                                    | `[[noreturn]]` attribute                      | C23     |

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

Each entry is tagged with the standard that removed or changed it. **Ripple rule for all catalog replacements (this section and the next)**: when the official replacement is not drop-in — different signature, arity, or observable behavior — state the minimal required ripple alongside it: which call sites must change and what the behavioral delta is. Entries below carry a "(not drop-in: ...)" note where this applies.

- **K&R (identifier-list) function definitions and non-prototype declarations** (removed in C23): `int f(a, b) int a, b; {...}` no longer compiles; every function must have a full prototype
- **Empty parentheses semantics changed** (C23): `void f()` now means `void f(void)` (no arguments), not "unspecified arguments". Flag call sites that relied on the old semantics to pass arguments
- **Trigraphs** (removed in C23): `??=` etc. no longer translate
- **`ATOMIC_VAR_INIT`** (deprecated in C17, removed in C23) → direct initialization of the atomic object
- **`realloc(ptr, 0)`** (undefined behavior since C23; was implementation-defined) → use `free` explicitly, or guard the zero-size case
- **`gets`** (removed in C11) → `fgets` (not drop-in: callers must supply the buffer size, and `fgets` retains the trailing `'\n'` — strip it where `gets` semantics were relied on)
- **Implicit `int` and implicit function declarations** (removed in C99, still tolerated by lax compiler flags): flag any occurrence
- **Two's complement mandated** (C23): sign-magnitude/ones'-complement fallback code paths are dead code

## Obsolescent constructs with official replacements

Version default for this section, citable verbatim in reviews: each construct below became **obsolescent in C23** and each replacement was **introduced in C23**, unless a different version is noted on the entry:

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
- **Baseline self-check before delivering C code** (applies to generated files AND to replacement snippets presented in reviews): verify the code matches the resolved baseline, and report which check was run. The authoritative check is compiling with the project's exact `-std=` flags — use it whenever a compiler is available and the deliverable is a complete file. Otherwise (no compiler, or snippet-only deliverable) fall back to scanning the **code itself — comments and strings are exempt** — for above-baseline constructs; on a pre-C23 baseline: `nullptr`, `constexpr`, `typeof`, `[[...]]` attributes, `<stdckdint.h>`, `<stdbit.h>`, `#embed`, empty initializer `{}`, `%b`/`%wN` format specifiers. Scan hits are candidates for contextual confirmation, not automatic violations; in particular, version-labeled option mentions in comments (mandated by the hard rules above) are expected and are non-findings. When the baseline equals the catalog coverage version (currently C23), no catalog construct sits above the baseline and the scan is vacuous — state that explicitly instead of improvising scan content.
- **Review-only deliverables**: the self-check applies to the replacement snippets you present — scan them against the resolved baseline. Compiling the _reviewed_ file with the project's flags to confirm findings is optional, never required: the version-tagged catalog is authoritative for removed/obsolescent status. If you do verify by compiling and the project-declared compiler is unavailable, substitute the nearest equivalent with the same `-std=` flag and disclose the substitution in the review.

## Review output contract (review-mode deliverables only)

A review report contains these sections, in this order — the mandatory statements defined elsewhere in this skill live in fixed slots so they cannot be dropped:

1. **Baseline header**: the resolved standard and its source (the Step 0 item 4 statement), plus the compiler-reality note when migration is being recommended.
2. **Findings**, grouped into severity tiers. Default severity = catalog section membership; an entry's own severity note (e.g. `NULL` → `nullptr`: Medium only in varargs/sentinel contexts, otherwise Low) overrides the section default.
   - **Critical** — removed constructs relative to the baseline (build breakers or newly undefined behavior)
   - **High** — obsolescent constructs with official replacements
   - **Medium/Low** — modern facilities to prefer (optional modernization). Tie-break within this tier: Medium when the legacy form carries a correctness, portability, or security cost (hand-rolled bit loops, untyped constant macros, non-reentrant time functions); Low when purely cosmetic (`{0}` vs `{}`, spelling variants)
     Each finding states: file:line, the construct, its version tag (removed/deprecated/introduced in X — copy it from the catalog), the concrete replacement, and the ripple note when the replacement is not drop-in.
3. **Non-findings**: what was deliberately not reported and why — at minimum the naming/formatting exclusion from the hygiene section when style-adjacent items are present in the reviewed code.
4. **Baseline self-check statement**: which check was run, per the hygiene section.

Headings may be worded and localized freely; the section order, tier definitions, and per-finding fields are fixed.

## Generation output contract (code-writing deliverables)

When delivering written or modified C code, the response carries these statements in fixed slots, so no mandatory output depends on executor discipline:

1. **Baseline statement** (the Step 0 item 4 statement) — before any code is emitted.
2. **Pin suggestion** — only when Step 0 item 2's compiler-default fallback branch was taken.
3. **Option-label mentions** — one line per triggered trigger-table row. When the baseline equals or exceeds the replacement's version for every row, the labeling rule is vacuous: no labels, no mention required.
4. **Self-check statement** — which check was run (authoritative compile, or scan fallback), per the hygiene section.

In-file artifacts stay as the rules define them (option-label comment at the first affected site). Wording and language are free; the presence and order of the slots are fixed.
