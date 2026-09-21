---
name: comment-patterns
description: "Guides writing and reviewing comments in C, Go, Rust, or Zig, including whether a comment belongs and comment-noise audits. Comment format belongs to the language idiom skills; commented-out code to simplicity-patterns."
---

# Comment Patterns (content value and accuracy, C / Go / Rust / Zig)

Grounded in Kent Beck's "Tidy First?" (the "Delete Redundant Comments" and "Explaining Comments" tidyings) and the official language documentation guides. This skill adds the documentation-layer policy below: put each explanation where its reader needs it, and keep every claim true.

## Document at the right layer

**Code → How, Tests → What, Commits → Why, Comments → Why not.**

| Layer | Responsibility |
| --- | --- |
| Code — How | Express the implementation through names, types, control flow, and structure. Improve these before adding prose that narrates the mechanism. |
| Tests — What | Specify observable behavior with concrete inputs, expected results, boundaries, and failure cases. Test names and assertions describe the contract without coupling it to incidental implementation steps. |
| Commits — Why | Explain the problem, motivation, and tradeoffs behind a change. General business rationale and change history belong here, not in implementation comments. |
| Comments — Why not | Preserve local knowledge that prevents a plausible but incorrect edit: why a simpler or idiomatic alternative fails, why a workaround remains necessary, or why an ordering or constraint must not be relaxed. |

Apply this policy to ordinary implementation commentary. **API documentation, safety justifications, constraints, and machine-read comments retain their roles** even when they describe what happens or why an operation is safe. Tests do not replace caller-facing documentation. A precondition or unit need not be rewritten as a rejected alternative.

Distinguish why the change was made from why a future editor must not simplify this particular code. The former belongs in the commit; the latter must remain near the code even if the commit also records it. For example, a partner-import requirement belongs in the commit, while `// strtok drops empty fields and would shift positional columns.` belongs beside a scan that preserves those fields. "Why not" describes useful knowledge, not mandatory negative wording; never invent a rejected alternative to fill the role.

These are placement rules, not a requirement to produce all four artifacts. Stay within the requested task: a comment review recommends destinations without creating tests, making commits, or rewriting history.

## Core principles

### A comment must earn its keep

An ordinary implementation comment is a maintenance liability: it is read on every visit and must be kept true through every change. It is justified when it carries local knowledge the adjacent code cannot express — a rejected alternative, a constraint or invariant the type system cannot enforce, a non-obvious consequence, or a relevant external source (spec, issue, measurement). Being non-derivable alone is insufficient: generic change motivation belongs in the commit. Apply the protected roles above before judging redundancy.

### Make the implementation explain itself

Before adding a comment about how the implementation works, improve its names and structure — rename, extract a function, introduce an explaining variable or constant (Tidy First? tidyings). Keep local constraints and reasons an apparent simplification would fail when no rename or extraction can express them.

### Redundant comments are deletions, not rewrites

Per Tidy First? "Delete Redundant Comments": when a comment says exactly what the code says, delete the comment. Deletion is a tidying — a pure structural change with observable behavior identical. Never fix a redundant comment by expanding it into longer prose.

### A wrong comment is worse than no comment

Comments rot silently and mislead with authority. When changing code, updating or deleting every comment whose claim the change touches is part of the change, not an optional follow-up.

## Ownership boundaries (do not double-cover sibling skills)

- **Format and mandated presence** belong to the language idiom skills: Go doc-comment format (go.dev/doc/comment), Rust `///` sections including `# Safety`/`# Errors`/`# Panics`, Zig `///`/`//!`, `// Deprecated:` markers, safety justifications on `unsafe`, and version-gated option labels. This skill governs content value only. Never flag a mandated comment as redundant; its human-directed claims still undergo the truth check below. When the relevant idiom skill is not loaded, follow the language's official documentation convention directly (Go: go.dev/doc/comment; Rust: the API Guidelines documentation items; Zig: the Zig Style Guide; C: the project's established convention).
- **Commented-out code** is dead code, owned by simplicity-patterns — never a finding under this skill's catalog. When noticed and no simplicity lens is running, mention it as a hand-off note outside the findings.
- **Machine-read comments are code, not prose**: build tags and directives (`//go:build`, `//go:generate`, `//go:embed`, `#cgo`), lint suppressions, Rust doc-tests, Doxygen commands under an established project convention. Never flag them; judge only human-directed prose. The exemption covers the machine-read carrier only — human-directed rationale attached to it (e.g., a trailing justification on a lint suppression) is in scope and judged for truth like any other prose.

## When writing code

- Route information by the documentation-layer policy, then apply the earn-its-keep test to ordinary implementation comments. The default number of inline comments in straightforward code is zero.
- Never write process narration: what the change did ("added validation"), what review finding it fixes, or who changed what when — commit messages and version control own that. Never write a comment that restates the next line ("// increment retries").
- Doc comments on public API state the contract, not the signature: units, valid ranges, error and panic conditions, ownership and lifetimes, thread-safety, blocking behavior. The format follows the language's idiom skill.
- When an apparent simplification would be wrong and structure cannot express the reason (rename/extract considered first), write the why-not comment — omission is the opposite failure. State the concrete alternative and the constraint or consequence that rules it out, using verified facts. If the reason is unknown, investigate or report the gap rather than inventing it. Constraints the type system cannot express (locking order, required call ordering, the unit of a bare integer) must be written at the site that depends on them. When the value carrying a constraint is extracted to a named constant or function, attach the rationale to that declaration, once; use sites reference the name — comment a use site only when it depends on the constraint in a way the declaration comment does not cover.
- When modifying code, treat adjacent comments as part of the edit: update or delete any comment the change invalidates.

## Defect catalog (when reviewing; each entry states the write-side rule)

When one comment matches multiple defect classes, classify it under the most severe match — misleading first, where the misleading entry's falsifiability test decides whether a claim qualifies — and choose the fix that leaves the required information present: a public-API doc comment whose contract is wrong or missing is corrected to the true contract, never deleted outright. After correcting a false claim in ordinary implementation commentary, re-run the earn-its-keep test: if the corrected comment would merely restate the code, the fix is deletion.

The findings-report format is owned by the invoking reviewer agent or dispatch contract. When none supplies one, default to severity-ordered findings — each with location, defect class, evidence, and the concrete fix — followed by a list of examined-and-accepted comments with the acceptance class that saved each.

- **Restating comments**: prose that repeats the adjacent code ("// loop over items", "// return error on failure"). Write-side: omit; the code already says it.
- **Journal comments**: change history, dates, author names, "fixed bug" narration. Version control owns this. Write-side: never narrate the change in the code.
- **Misplaced change rationale**: general motivation for a change with no local constraint or rejected alternative for a future editor to preserve. It belongs in commit rationale even when true and not derivable from the code. Write-side: explain the change in its commit; retain only the local knowledge needed to avoid an incorrect edit in the comment.
- **Banner and position comments**: section dividers ("// ---- helpers ----"), closing-brace markers ("} // end for"). Structure — file split, function extraction — owns organization. Write-side: organize with structure, not markers.
- **Crutch comments**: a comment explaining what a better name or an extracted function would say. The fix is the rename or extraction, with the comment deleted — the inverse of the explaining-variable tidying. Write-side: rename first; comment only what naming cannot carry.
- **Echo doc comments**: a doc comment that only restates the identifier and signature while contract information a caller needs (error conditions, nil/zero behavior, boundaries, units) exists and is unstated. An entirely absent doc comment is a presence question owned by the idiom skills, not this class — and the missing-why-not class covers non-obvious logic, not missing API docs. Write-side: state the contract or, when the symbol is genuinely trivial, keep the terse convention-mandated form (see accepted list).
- **Misleading comments**: prose contradicted by the implementation or verified applicable external evidence — a stale condition, an outdated contract, a parameter that no longer exists, or a workaround claim disproved by the supported versions' issue status. The most severe defect in this catalog; state the concrete falsifying evidence in the finding. An unverified claim is not automatically false. A summary that is incomplete but not falsifiable is an echo-doc finding, not misleading (a doc saying "Sends one request." on a function that retries is misleading — the count is falsifiable; "Sends the request." with the contract unstated is echo-doc). Write-side: update comments as part of every change that touches their claims.
- **Dead TODOs**: TODO/FIXME whose described work is already done, or bare TODOs with no actionable content. Write-side: a TODO carries an owner, an issue link, or a concrete completion condition ("remove when MSRV ≥ 1.95").
- **Missing why-not comments**: a workaround, surprising constant, ordering dependency, or deliberate deviation with no comment and no structural way to express why a plausible alternative is wrong. Flag only when the alternative and the constraint that rules it out are supported by evidence. Propose comment text grounded in that evidence; when the reason is unknown, report an investigation question rather than a fabricated explanation or a definite missing-comment finding.

## Required and accepted comments (do not flag; do write when the condition holds)

Acceptance exempts a comment from redundancy findings only — truth is orthogonal. Apply the misleading-comment evidence test to every accepted class. Preserve still-valid required information (contracts, units, safety conditions) when correcting false claims. If an explanation's sole purpose was a constraint now disproved, delete the obsolete explanation rather than preserving a citation with no current relevance. If the remaining code's rationale is unknown, report that question separately; do not invent a replacement reason or infer that the code can safely be removed. Acceptance is judged against the code as written: whether a type or structure change could absorb valid information instead is a code-design question outside a comment review.

- **Why-not comments**: verified reasons an apparent simplification would fail, rejected alternatives, workarounds with upstream issue links
- **Constraint comments**: invariants, preconditions, ordering and locking requirements, units — anything the type system cannot enforce
- **Consequence warnings**: properties tests do not pin ("must stay allocation-free; called per frame")
- **External references**: algorithm citations, RFC/spec sections, benchmark results justifying a fast path, issue links in a form the reader can resolve (`#N` for the project's own tracker, a full URL otherwise)
- **Everything an idiom skill mandates**: doc comments on exported/public identifiers in the official format, safety justifications, deprecation markers, version-gated option labels
- **Tracked TODOs**: TODO/FIXME with an owner, issue link, or concrete completion condition

## Per-language notes

- **Go**: doc-comment format and presence per go-idioms (go.dev/doc/comment, Effective Go). A terse doc comment on a trivial exported symbol ("Name returns the name.") is idiomatic and accepted — flag an echo doc comment only when real contract information is missing. `//go:...` directives are code.
- **Rust**: `///` section format per rust-idioms; `//!` module docs accepted. Safety comments on `unsafe` are mandated by rust-idioms — never noise.
- **Zig**: `///` on public decls and `//!` module docs per the Zig Style Guide. The Style Guide's "no commented-out code" rule is enforced via simplicity-patterns.
- **C**: no official doc-comment standard exists; follow the file's or project's established convention (Doxygen, plain block comments). Put public API contracts at the header declaration. For internal functions, first apply the earn-its-keep test: retain caller constraints the code cannot express, not routine behavior summaries. Place any needed contract at the separate declaration or, when there is none, at the definition. Do not duplicate the same contract at a separate declaration and definition.

Judge one language's comments only by that language's conventions.

## Decision rule when uncertain

- **Reviewing**: check protected roles and placement before judging redundancy. Verify before flagging — read the adjacent code; when a claim references another symbol, verify against that symbol's declaration and usage too. An informal but true cross-reference is accepted; apply the misleading entry's evidence test to disputed claims. External references are not redundant merely because they cannot be derived from code, but verified evidence that they no longer apply can invalidate their rationale. If evidence is unavailable, report uncertainty rather than guessing. If redundancy cannot be demonstrated after reading the code, do not flag it as redundant; assess misplaced change rationale separately.
- **Writing**: route mechanisms to code, observable expectations to tests, and change motivation to commits. Keep local why-not knowledge, necessary constraints, and relevant external references beside the code. Preserve the protected roles even when they describe behavior. If ordinary commentary merely re-describes the code, leave it out.
- The fix for a redundant comment is deletion (or the rename it was compensating for) — never a longer comment.

## Official references

The four-layer mapping is this skill's placement policy; these sources support the underlying practices and documentation exceptions, rather than prescribing that exact slogan.

- [Google Engineering Practices — comments, tests, and documentation](https://google.github.io/eng-practices/review/reviewer/looking-for.html)
- [Git contribution guidelines — meaningful commit messages](https://github.com/git/git/blob/master/Documentation/SubmittingPatches#meaningful-message)
- [Go Doc Comments — caller-facing contracts](https://go.dev/doc/comment)
- [Rust API Guidelines — error, panic, and safety documentation](https://rust-lang.github.io/api-guidelines/documentation.html#c-failure)
