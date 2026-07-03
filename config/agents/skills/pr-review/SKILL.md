---
name: pr-review
description: This skill should be used when the user hands over a GitHub PR URL, PR number, or branch and asks to "review this PR", "review and comment on this PR", "approve it", "request changes", "この PR をレビューして", or "gh でレビューしてコメントして". It orchestrates a multi-agent GitHub PR review: it checks the PR out into one throwaway git worktree, fans out read-only reviewer sub-agents by concern (using the named review agents available in the current runtime, with an inline single-pass fallback), synthesizes their findings, and submits a single approve or request-changes verdict with the gh CLI. It does not re-run tests, formatters, linters, or builds that CI already covers, and always discards the worktree afterward.
---

# PR Review (worktree-isolated orchestrator)

Review a GitHub PR by **orchestrating specialized read-only reviewers** and submitting one consolidated verdict. The parent (this skill) owns three things and never delegates them: the single throwaway **git worktree**, the single **review submission**, and **cleanup**. Sub-agents only read the worktree and the diff and return findings. Assume CI runs the quality gates (tests, formatting, lint, build) and never repeat that work.

This skill is runtime-neutral: it prefers the named review agents loaded in the current runtime (Claude Code or Codex — see `references/review-lenses.md` for the per-runtime catalog) and falls back to an inline single-pass review when none are loaded.

## Principles

- **Centralized writes**: Only the parent creates/destroys the worktree and only the parent submits the verdict to GitHub. Sub-agents are read-only.
- **One worktree**: A single dedicated worktree, never the current branch or in-progress changes. Sub-agents must not create their own.
- **One verdict**: Synthesize all findings into exactly one review submission. Never let sub-agents post to GitHub.
- **Early stop before worktree**: Resolve PR state first. If the PR is not `OPEN`, stop and confirm with the user before fetching the diff, creating a worktree, or dispatching reviewers.
- **Cleanup is mandatory**: Discard the worktree on success, failure, or interruption.
- **Trust CI**: Treat tests, formatting, lint, and build as already verified. Focus the review on what only a reviewer can judge.
- **Submission text**: GitHub review bodies and inline comments are in English. User-facing status and error messages follow the conversation language.

## When to use

- The user provides a PR URL or number and asks to review, approve, or request changes.
- A review benefits from reading the code locally with full context (e.g., checking callers the diff alone does not show).

Do not use when:

- A trivial check needs only the web diff and no local checkout (the worktree cost is not worth it).
- The goal is to edit and push code rather than review it (that is the normal development flow).
- The target is local, uncommitted work rather than a GitHub PR (the local-review skill owns that).

## Workflow

1. **Identify the PR**: Fetch metadata from the given URL or number.

   ```bash
   gh pr view "$PR" --json number,title,url,state,baseRefName,headRefName,author,isCrossRepository
   ```

   If `state` is not `OPEN`, confirm with the user before continuing (and if no worktree was created yet, say no cleanup was needed).

2. **Create the worktree**: Run the bundled `scripts/pr-worktree.sh` with `setup`. Capture the worktree path from the last line of stdout. `gh pr checkout` resolves the head even for fork PRs, and the detached HEAD checkout leaves no stray local branch behind.
   - The script performs git operations, so invoke it **with the target repository root as the cwd**. The script itself lives in **this skill's directory**, so reference it by absolute path (`$SKILL_DIR` is this skill's base directory).
   - This skill reviews a PR **in the repository at the current cwd**. Set the cwd to a local clone of that PR's repository and pass the **bare PR number** in `$PR`. The script builds the worktree from the cwd repo and then runs `gh pr checkout <number>` in that same context, so a cross-repository **URL does not redirect it to another repo** — passing one builds a worktree of the cwd repo while resolving the number elsewhere, which breaks the checkout. To review a PR in a different repository, `cd` into that repository's local clone first, then pass the bare number. Keep this cwd for the rest of the workflow: the diff fetch in step 3, the synthesis in step 4, and the `gh repo view` / `gh pr view` calls that resolve `OWNER_REPO` and the PR number all read the repo from the cwd, so they must run in the same target-repo clone.

   ```bash
   SKILL_DIR="<this skill's base directory>"   # the path shown when the skill loads
   WORKTREE="$(bash "$SKILL_DIR/scripts/pr-worktree.sh" setup "$PR" | tail -n1)"
   ```

3. **Fan out the review**: Dispatch read-only reviewer sub-agents in parallel, one per lens, each pointed at `$WORKTREE` and `$PR`. See `references/review-lenses.md` for the lens catalog (including the per-runtime named agents), the dispatch contract, and the findings schema. Hard constraints on every sub-agent (state them in each dispatch):
   - **Read-only**: no file edits, no worktree create/remove, no push.
   - **No GitHub writes**: no `gh pr review` / `gh pr comment` / `gh api` writes. Read-only gh (`gh pr diff`, `gh pr view`) is fine.
   - **No CI work**: do not run tests, formatters, linters, or builds.
   - **Return findings only**: each finding is `{path, line, severity (blocker|nit), lens, body}`.
   - Scale the lens set to the PR's surface (see `references/review-lenses.md`); log which lenses were dispatched and which were skipped.
   - If sub-agents cannot be dispatched (the named agents are not loaded, this skill is itself running inside a sub-agent, the dispatch tooling is unavailable, or the worktree/diff the reviewers depend on cannot be produced — e.g. no network or `gh` access), fall back to a single-pass inline review covering the same lenses yourself, and tell the user the review ran single-pass.

4. **Synthesize**: Once all lenses return, consolidate (this barrier is required — the verdict needs every lens's output). Flatten findings, drop any not grounded in the diff or surrounding code, dedup by `(path, line)` keeping the highest severity, classify must-fix vs nit, and decide the verdict per the table below. Full rules in `references/review-lenses.md`.

5. **Submit one review**: Turn the deduped findings into a single review with inline comments in one API call. See `references/gh-review-commands.md` (including the self-approval guardrails). The summary body should note blocker/nit counts and which lenses ran. Prefix nit comment bodies with `nit:` so the author can spot blockers immediately.

6. **Discard the worktree**: Run this regardless of the outcome, including on error mid-review.

   ```bash
   bash "$SKILL_DIR/scripts/pr-worktree.sh" cleanup "$WORKTREE"
   ```

## Approve vs request-changes

| Verdict           | Condition                                                                                                                                                                                                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| approve           | No blockers across any lens, and the authenticated GitHub user is not the PR author. Attach nits as inline comments but do not let them block approval.                                                                                                                               |
| request-changes   | One or more blockers (correctness, security, data loss, or API compatibility) from any lens.                                                                                                                                                                                          |
| comment (neutral) | No blockers but the authenticated user **is** the PR author (GitHub rejects self-approval) — submit an approval-style summary as COMMENT. Also allowed when a lens genuinely needs a question answered before a verdict is possible. Otherwise default to approve or request-changes. |

## What not to run (CI's job)

Neither the parent nor any sub-agent runs the following during a review, assuming CI handles them:

- Test suites (`go test`, `cargo test`, `nix flake check`, etc.)
- Formatters / linters (`nixfmt`, `stylua`, `gofmt`, `clippy`, etc.)
- Builds (`nix build`, `cargo build`, etc.)

Only when CI is known to be failing or absent, tell the user and decide case by case.

## Additional Resources

### Scripts

- **`scripts/pr-worktree.sh`** — Helper to create (`setup`) and destroy (`cleanup`) an isolated worktree for a PR. Checks out in detached HEAD, handles fork PRs, and refuses to clean up directories it did not create (marker file).

### Reference Files

- **`references/review-lenses.md`** — The lens catalog with per-runtime named agents, the read-only sub-agent dispatch contract, the findings schema, and the parent's synthesis/verdict rules.
- **`references/gh-review-commands.md`** — Concrete `gh` / `gh api` commands for submitting a review with inline comments, the self-approval guardrails, and common error fixes.
- **`agents/openai.yaml`** — UI metadata for this skill only.

## Red flags (watch for rationalizations)

| Rationalization                                                     | Reality                                                                                                         |
| ------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| "Each reviewer can check out its own worktree."                     | Breaks isolation and cleanup discipline. The parent owns exactly one worktree; sub-agents read it.              |
| "Let the reviewers post their own comments."                        | Produces stacked reviews on the PR. The parent submits exactly one consolidated verdict.                        |
| "Run the tests just to be safe."                                    | CI already verified them. Re-running wastes time and breaks this skill's principle — applies to sub-agents too. |
| "Just `gh pr checkout` on the current branch — no worktree needed." | Pollutes in-progress changes and branches. Always use the dedicated worktree.                                   |
| "Leave comments and defer the verdict."                             | A review reaches a verdict. Submit approve or request-changes (or the self-approval COMMENT form).              |
| "An error occurred, so stop here."                                  | Always run worktree cleanup before finishing. A leftover worktree breaks the next review.                       |
