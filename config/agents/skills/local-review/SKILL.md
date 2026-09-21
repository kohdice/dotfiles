---
name: local-review
description: "Reviews local changes, branches, directories, or codebases and reports findings without edits or publication. GitHub PR reviews use pr-review; requests combining implementation, review, and fixes use implement-review-loop."
---

# Local Review (scope-parameterized orchestrator)

Review local code by **applying specialized read-only review lenses** — as independent reviewer sub-agents, or directly in the parent when the scope is small — over a caller-chosen scope and returning one consolidated report. Unlike PR review skills, there is no worktree, no GitHub verdict, and no submission: the input is the repository as it sits on disk, and the output is a report to the user.

## Principles

- **Read-only everywhere**: Neither the parent nor any sub-agent edits files, writes git state, or posts anywhere.
- **One report**: The parent synthesizes all findings into exactly one report. Sub-agents return findings only.
- **Lenses from the change, execution from the scope**: Select lenses by what the change actually touches, not a fixed bundle (see `references/review-lenses.md`). Then choose how to run them: independent reviewer sub-agents (named agents when loaded, generic read-only sub-agents otherwise) when the scope is more than a handful of files or independent perspectives matter; a direct single pass in the parent — reading each selected lens's knowledge skill first — when the scope is small. When dispatch is unavailable, the direct pass is the fallback. Always say in the report which way the review ran.
- **Scale to scope**: A three-line diff does not need seven agents; a whole-codebase audit needs chunking. Select lenses and chunking by the actual surface (see `references/review-lenses.md`).
- **No CI work**: Do not run tests, builds, or formatters. Reviewers may run only the read-only checks their own definitions allow, and only when the check writes nothing into the repository (e.g. `go vet`, `gofmt -l`, `zig fmt --check`). A check that generates files — build artifacts, caches, lockfiles — is not read-only even if it never touches source: `cargo clippy` compiles and writes `target/` (and may create `Cargo.lock`), so skip it and verify by reading instead.

## Workflow

1. **Resolve the scope** from the user's ask:

   | Ask                                   | Scope        | File list                                                                                                                   |
   | ------------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------------------------- |
   | (default) "review my changes"         | working diff | `git diff HEAD --name-only` + untracked from `git status --porcelain`                                                       |
   | "review this branch against `<base>`" | branch diff  | `git diff <base>...HEAD --name-only`                                                                                        |
   | "review my unpushed commits"          | branch diff  | `git diff @{upstream}...HEAD --name-only` (no upstream: ask for a base)                                                     |
   | a specific path is named              | path         | files under that path                                                                                                       |
   | "audit the whole codebase"            | all          | all tracked files — source, configs, manifests, docs; not generated or vendored — chunked per `references/review-lenses.md` |

   If the working diff is empty — both commands in the working-diff row above return nothing — and no other scope was named, tell the user and stop.

2. **Detect languages**: Classify the in-scope files by extension (`.c`/`.h` → C, `.go` → Go, `.rs` → Rust, `.zig` → Zig). Files outside these four languages get only the generic `correctness` lens, except `.sql` and migration files, which also get the `sql` lens; code in the four languages that embeds SQL gets `sql` in addition to its language lenses.

3. **Select lenses and run them**: Pick lenses per `references/review-lenses.md` (catalog, selection rules, execution modes, dispatch contract, chunking). In delegated mode, dispatch one read-only sub-agent per lens in parallel, each given the scope's file list, the diff command, and the report language (the conversation language); in direct mode, read each selected lens's knowledge skill and apply it to the same file list in one pass. For `all` scope, chunk per the reference file and dispatch per chunk — except `architecture`, which always gets the whole language's file set (dependency direction cannot be judged from a fragment).

4. **Synthesize**: Flatten all findings and merge duplicates by root cause, preserving distinct causes even on the same line. Follow `references/review-lenses.md` → "Synthesis" for the single-fix test and severity judgment. Group by severity (High / Medium / Low), and produce one report in the conversation language (code snippets, identifiers, and paths stay in English). End with a coverage summary: lenses run, lenses not selected (one-line reason each), whether the run was delegated or direct, and — for `all` scope — any chunks dropped.

5. **Recommend, do not act**: The report may propose fixes, but this skill never applies them. If the user wants fixes applied, that is a follow-up task outside this skill.

## What not to run

- Test suites (`go test`, `cargo test`, `zig build test`, `nix flake check`, …)
- Builds and formatters that write files (`cargo build`, `zig fmt` without `--check`, `gofmt -w`, …)
- Anything that mutates git state (add, commit, stash, checkout, worktree)
- Interpreters or headless runtimes launched to "verify" a finding (`nvim --headless`, `python`, `node`, …) — they write logs and caches; verify findings by reading code

## Red flags (watch for rationalizations)

| Rationalization | Reality |
| --- | --- |
| "I'll fix this small issue while I'm here." | This skill is read-only. Report it; fixing is a separate, user-approved task. |
| "The whole codebase fits in one agent prompt." | It does not. Chunk it, or precision collapses. Log what each chunk covered. |
| "Run the tests to confirm the bug." | Out of scope. Report the finding with code evidence; the user decides how to verify. |
| "The named agents are missing, so skip the review." | Run the same lenses through generic sub-agents, or directly in the parent, and label the result. |
| "Run every lens every time, to be thorough." | Lenses are selected by what the change touches. A lens with nothing to judge adds noise, not coverage. |
| "Simplicity findings justify a harsh overall verdict." | There is no verdict here, and simplicity findings are advisory by default. |

## Additional Resources

### Reference Files

- **`references/review-lenses.md`** — The lens catalog (named agents and their focus), lens selection rules, execution modes (delegated or direct), the dispatch contract, the findings schema, whole-codebase chunking, and synthesis rules.
