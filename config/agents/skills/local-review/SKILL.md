---
name: local-review
description: This skill should be used when the user asks to review local, uncommitted, or unpushed work — "review my changes", "check the diff before I commit", "変更点をレビューして", "コミット前にレビューして" — or to audit a directory or an entire codebase — "audit this package", "コード全体をレビューして". It orchestrates read-only reviewer sub-agents (language idiom, architecture, performance, simplicity, comment, correctness) over a chosen scope — the working diff (default), a branch diff against a base, a specific path, or the whole codebase — and synthesizes one report in the conversation language. It never modifies files, never posts to GitHub, and never runs tests or builds. Do not use it for GitHub PR reviews (the pr-review skill owns those), or when the user asks to fix the findings as part of the same request (the implement-review-loop skill owns that loop).
---

# Local Review (scope-parameterized orchestrator)

Review local code by **orchestrating specialized read-only reviewers** over a caller-chosen scope and returning one consolidated report. Unlike PR review skills, there is no worktree, no GitHub verdict, and no submission: the input is the repository as it sits on disk, and the output is a report to the user.

## Principles

- **Read-only everywhere**: Neither the parent nor any sub-agent edits files, writes git state, or posts anywhere.
- **One report**: The parent synthesizes all findings into exactly one report. Sub-agents return findings only.
- **Named agents preferred, inline fallback**: When the named reviewer agents are loaded (Claude Code links `config/claude/agents/` into `~/.claude/agents`), dispatch them in parallel. When they are not loaded (e.g. a Codex session), run the same selected lenses inline in the parent, single-pass — reading each lens's knowledge skill first (see `references/review-lenses.md`) — and say so in the report.
- **Scale to scope**: A three-line diff does not need seven agents; a whole-codebase audit needs chunking. Select lenses and chunking by the actual surface (see `references/review-lenses.md`).
- **No CI work**: Do not run tests, builds, or formatters. Reviewers may run only the read-only checks their own definitions allow (e.g. `go vet`, `gofmt -l`, `cargo clippy --no-deps`, `zig fmt --check`).

## Workflow

1. **Resolve the scope** from the user's ask:

   | Ask                                   | Scope        | File list                                                               |
   | ------------------------------------- | ------------ | ----------------------------------------------------------------------- |
   | (default) "review my changes"         | working diff | `git diff HEAD --name-only` + untracked from `git status --porcelain`   |
   | "review this branch against `<base>`" | branch diff  | `git diff <base>...HEAD --name-only`                                    |
   | "review my unpushed commits"          | branch diff  | `git diff @{upstream}...HEAD --name-only` (no upstream: ask for a base) |
   | a specific path is named              | path         | files under that path                                                   |
   | "audit the whole codebase"            | all          | all source files, chunked per `references/review-lenses.md`             |

   If the working diff is empty and no other scope was named, tell the user and stop.

2. **Detect languages**: Classify the in-scope files by extension (`.c`/`.h` → C, `.go` → Go, `.rs` → Rust, `.zig` → Zig). Files outside these four languages get only the generic `correctness` lens.

3. **Select lenses and dispatch**: Pick lenses per `references/review-lenses.md` (catalog, selection rules, dispatch contract, chunking). Dispatch one read-only sub-agent per lens in parallel, each given the scope's file list, the diff command, and the report language (the conversation language). For `all` scope, chunk per the reference file and dispatch per chunk — except `architecture`, which always gets the whole language's file set (dependency direction cannot be judged from a fragment).

4. **Synthesize**: Flatten all findings, dedup by `(path, line)` keeping the highest severity, group by severity (High / Medium / Low), and produce one report in the conversation language (code snippets, identifiers, and paths stay in English). End with a coverage summary: lenses run, lenses skipped (one-line reason each), and — for `all` scope — any chunks dropped.

5. **Recommend, do not act**: The report may propose fixes, but this skill never applies them. If the user wants fixes applied, that is a follow-up task outside this skill.

## What not to run

- Test suites (`go test`, `cargo test`, `zig build test`, `nix flake check`, …)
- Builds and formatters that write files (`cargo build`, `zig fmt` without `--check`, `gofmt -w`, …)
- Anything that mutates git state (add, commit, stash, checkout, worktree)
- Interpreters or headless runtimes launched to "verify" a finding (`nvim --headless`, `python`, `node`, …) — they write logs and caches; verify findings by reading code

## Red flags (watch for rationalizations)

| Rationalization                                        | Reality                                                                                      |
| ------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| "I'll fix this small issue while I'm here."            | This skill is read-only. Report it; fixing is a separate, user-approved task.                |
| "The whole codebase fits in one agent prompt."         | It does not. Chunk it, or precision collapses. Log what each chunk covered.                  |
| "Run the tests to confirm the bug."                    | Out of scope. Report the finding with code evidence; the user decides how to verify.         |
| "The named agents are missing, so skip the review."    | Fall back to an inline single-pass over the same lenses and label the result as single-pass. |
| "Simplicity findings justify a harsh overall verdict." | There is no verdict here, and simplicity findings are advisory by default.                   |

## Additional Resources

### Reference Files

- **`references/review-lenses.md`** — The lens catalog (named agents and their focus), lens selection rules, the dispatch contract, the findings schema, whole-codebase chunking, and synthesis rules.
