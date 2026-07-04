---
name: comment-patterns
description: This skill should be used when writing, modifying, refactoring, or reviewing code that carries comments in C, Go, Rust, or Zig — implementing features, "コメントを見直して", deciding whether a comment is worth writing or keeping, or auditing a codebase for comment noise. It defines the comment-must-earn-its-keep principle (a comment carries only what the code cannot say: why, constraints, external references), Kent Beck's "Tidy First?" comment tidyings, ownership boundaries deferring format to the idiom skills and commented-out code to simplicity-patterns, a catalog of comment defects with generation-side rules, required and accepted comments, and the keep-or-delete decision rule, so that generated code contains no noise comments and reviews flag only comments that restate the code, contradict it, or are missing where the code cannot speak for itself.
---

# Comment Patterns (content value and accuracy, C / Go / Rust / Zig)

Grounded in Kent Beck's "Tidy First?" (the "Delete Redundant Comments" and "Explaining Comments" tidyings) and the official language documentation guides. The goal is comments that earn their keep: every comment must carry information the adjacent code cannot express, and every claim it makes must be true.

## Core principles

### A comment must earn its keep

Every comment is a maintenance liability: it is read on every visit and must be kept true through every change. It is justified only when it carries information the adjacent code cannot express — the rationale for a non-obvious choice, a constraint or invariant the type system cannot enforce, a non-obvious consequence, or a pointer to an external source (spec, issue, measurement). A comment that restates the code is a cost with no return.

### Code says what; comments say why

The code states what happens, and naming and structure state it best. Before writing an explaining comment, first try to make the code say it — rename, extract a function, introduce an explaining variable or constant (Tidy First? tidyings). Write the comment only for what no rename or extraction can express.

### Redundant comments are deletions, not rewrites

Per Tidy First? "Delete Redundant Comments": when a comment says exactly what the code says, delete the comment. Deletion is a tidying — a pure structural change with observable behavior identical. Never fix a redundant comment by expanding it into longer prose.

### A wrong comment is worse than no comment

Comments rot silently and mislead with authority. When changing code, updating or deleting every comment whose claim the change touches is part of the change, not an optional follow-up.

## Ownership boundaries (do not double-cover sibling skills)

- **Format and mandated presence** belong to the language idiom skills: Go doc-comment format (go.dev/doc/comment), Rust `///` sections including `# Safety`/`# Errors`/`# Panics`, Zig `///`/`//!`, `// Deprecated:` markers, safety justifications on `unsafe`, and version-gated option labels. This skill governs content value only. A comment an idiom skill mandates is never a finding here.
- **Commented-out code** is dead code, owned by simplicity-patterns — never a finding under this skill's catalog. When noticed and no simplicity lens is running, mention it as a hand-off note outside the findings.
- **Machine-read comments are code, not prose**: build tags and directives (`//go:build`, `//go:generate`, `//go:embed`, `#cgo`), lint suppressions, Rust doc-tests, Doxygen commands under an established project convention. Never flag them; judge only human-directed prose.

## When writing code

- Apply the earn-its-keep test before writing any comment: does it state something a reader of the adjacent code could not derive from it? If not, do not write it. The default number of inline comments in straightforward code is zero.
- Never write process narration: what the change did ("added validation"), what review finding it fixes, or who changed what when — commit messages and version control own that. Never write a comment that restates the next line ("// increment retries").
- Doc comments on public API state the contract, not the signature: units, valid ranges, error and panic conditions, ownership and lifetimes, thread-safety, blocking behavior. The format follows the language's idiom skill.
- When logic is genuinely non-obvious and structure cannot absorb it (rename/extract considered first), write the why-comment — omission is the opposite failure. Constraints the type system cannot express (locking order, required call ordering, the unit of a bare integer) must be written at the site that depends on them.
- When modifying code, treat adjacent comments as part of the edit: update or delete any comment the change invalidates.

## Defect catalog (when reviewing; each entry states the write-side rule)

- **Restating comments**: prose that repeats the adjacent code ("// loop over items", "// return error on failure"). Write-side: omit; the code already says it.
- **Journal comments**: change history, dates, author names, "fixed bug" narration. Version control owns this. Write-side: never narrate the change in the code.
- **Banner and position comments**: section dividers ("// ---- helpers ----"), closing-brace markers ("} // end for"). Structure — file split, function extraction — owns organization. Write-side: organize with structure, not markers.
- **Crutch comments**: a comment explaining what a better name or an extracted function would say. The fix is the rename or extraction, with the comment deleted — the inverse of the explaining-variable tidying. Write-side: rename first; comment only what naming cannot carry.
- **Echo doc comments**: a doc comment that only restates the identifier and signature while contract information a caller needs (error conditions, nil/zero behavior, boundaries, units) exists and is unstated. Write-side: state the contract or, when the symbol is genuinely trivial, keep the terse convention-mandated form (see accepted list).
- **Misleading comments**: prose contradicting the code it annotates — a stale condition, an outdated contract, a parameter that no longer exists. The most severe defect in this catalog; verify the contradiction against the code before flagging. Write-side: update comments as part of every change that touches their claims.
- **Dead TODOs**: TODO/FIXME whose described work is already done, or bare TODOs with no actionable content. Write-side: a TODO carries an owner, an issue link, or a concrete completion condition ("remove when MSRV ≥ 1.95").
- **Missing why-comments**: genuinely non-obvious logic — a workaround, a surprising constant, an ordering dependency, a deliberate deviation from the idiomatic form — with no comment and no structural way to express the reason. The finding proposes the comment text. Flag only when the non-obviousness is demonstrable (the idiomatic alternative is concrete and the reason for deviating is not in the code).

## Required and accepted comments (do not flag; do write when the condition holds)

- **Why-comments**: rationale for a non-obvious choice, rejected alternatives, workarounds with upstream issue links
- **Constraint comments**: invariants, preconditions, ordering and locking requirements, units — anything the type system cannot enforce
- **Consequence warnings**: properties tests do not pin ("must stay allocation-free; called per frame")
- **External references**: algorithm citations, RFC/spec sections, benchmark results justifying a fast path
- **Everything an idiom skill mandates**: doc comments on exported/public identifiers in the official format, safety justifications, deprecation markers, version-gated option labels
- **Tracked TODOs**: TODO/FIXME with an owner, issue link, or concrete completion condition

## Per-language notes

- **Go**: doc-comment format and presence per go-idioms (go.dev/doc/comment, Effective Go). A terse doc comment on a trivial exported symbol ("Name returns the name.") is idiomatic and accepted — flag an echo doc comment only when real contract information is missing. `//go:...` directives are code.
- **Rust**: `///` section format per rust-idioms; `//!` module docs accepted. Safety comments on `unsafe` are mandated by rust-idioms — never noise.
- **Zig**: `///` on public decls and `//!` module docs per the Zig Style Guide. The Style Guide's "no commented-out code" rule is enforced via simplicity-patterns.
- **C**: no official doc-comment standard exists; follow the file's or project's established convention (Doxygen, plain block comments). Contract documentation belongs at the declaration site (the header); a duplicate at the definition is a restating comment.

Judge one language's comments only by that language's conventions.

## Decision rule when uncertain

- **Reviewing**: verify before flagging — read the adjacent code and check whether every claim in the comment is derivable from it. A reference to anything external (issue, spec, measured number, platform quirk) is not derivable — keep it. If redundancy cannot be demonstrated after reading the code, do not flag.
- **Writing**: prefer making the code say it; if the knowledge is not derivable from the code — a why, a constraint, or an external reference — write the comment; if it merely re-describes the code, leave it out.
- The fix for a redundant comment is deletion (or the rename it was compensating for) — never a longer comment.
