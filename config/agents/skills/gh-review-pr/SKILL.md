---
name: gh-review-pr
description: Orchestrate GitHub pull request reviews through the gh CLI using a disposable git worktree and named read-only review agents when available. Use when the user provides a GitHub PR URL, PR number, or branch and asks an agent to review the PR, comment on it, approve it when acceptable, or request changes when fixes are required. The parent agent owns worktree setup, synthesis, one final review submission, and cleanup. The review must not run tests, formatters, linters, or builds that CI is expected to cover.
---

# GH Review PR

## Overview

Review a GitHub pull request locally with `gh` and a disposable git worktree, then submit exactly one PR review. The parent agent owns the worktree, reviewer dispatch, finding synthesis, final verdict, review submission, and cleanup.

Use the named review agents when they are available in the current agent runtime. In this dotfiles repository, the Codex custom agents live under `config/codex/agents/` and are registered from `config/codex/config.toml`. If those agents are not loaded, default to running the selected lenses inline when the user asked for an immediate review, and say the review was single-pass. Ask the user to restart the runtime only when they specifically need the named-agent review.

Treat CI as responsible for tests, formatting, linting, and builds. Do not run those commands unless the user explicitly asks or CI is unavailable and the user approves.

## Principles

- **One worktree**: Create one disposable worktree for the PR. Never checkout the PR in the user's current branch.
- **Read-only reviewers**: Review agents only inspect `$WORKTREE` and read-only `gh` output. They never edit files, create worktrees, push, or post to GitHub.
- **One verdict**: Submit exactly one consolidated review. Never let review agents submit comments or reviews.
- **Early stop before worktree**: Resolve PR state before fetching the diff, creating a worktree, or dispatching reviewers. If the PR is not open, stop and ask for confirmation before continuing.
- **Cleanup is mandatory**: Remove the disposable worktree on success, failure, or interruption.
- **Trust CI**: Do not run tests, formatters, linters, or builds during review.
- **Submission text**: Keep GitHub review bodies and review comments in English. User-facing status or error messages should follow the conversation and repository instructions.

## Workflow

1. Resolve the PR metadata with `gh`.

   ```bash
   gh pr view "$PR" --json number,title,url,state,baseRefName,headRefName,author,isCrossRepository
   ```

   Run this skill from a local clone of the target repository. If the PR is not open, stop before fetching the diff, creating a worktree, dispatching reviewers, or submitting a review unless the user confirms. If no worktree was created, say that no cleanup was needed.

   After the PR is open or the user confirms reviewing a non-open PR, fetch the diff:

   ```bash
   gh pr diff "$PR" --patch
   ```

2. Create a disposable worktree from the target repository clone.

   ```bash
   SKILL_DIR="<path to this skill>"
   WORKTREE="$(bash "$SKILL_DIR/scripts/pr-worktree.sh" setup "$PR")"
   ```

   Keep all code reading and diff inspection inside `$WORKTREE`. Do not checkout the PR in the user's current branch.

3. Dispatch or run review lenses.

   Read `references/review-lenses.md`. Select lenses by PR surface area, then dispatch the matching named review agent for each selected lens. Use these default agents unless the PR is clearly narrower:
   - `pr-review-bug-logic-convention`
   - `pr-review-error-handling`
   - `pr-review-type-design-invariants`
   - `pr-review-security-data-compatibility`
   - `pr-review-test-coverage`
   - `pr-review-comment-accuracy`

   If the named agents are unavailable, run the selected lenses inline in the parent agent using the same prompts and findings schema, then label the final review summary as single-pass.

4. Synthesize findings and decide the verdict.
   - Use `REQUEST_CHANGES` when at least one issue must be fixed before merge.
   - Use `APPROVE` when there are no required fixes and the authenticated GitHub user is not the PR author. Optional nits may be included as non-blocking comments.
   - Use `COMMENT` with an approval-style summary when there are no required fixes but the authenticated GitHub user is the PR author or GitHub rejects self-approval.
   - Avoid a neutral comment-only review unless a verdict is impossible without an answer.

5. Submit one consolidated review with `gh`.

   Read `references/gh-review-commands.md`. Use `gh pr review` for body-only reviews. Use `gh api repos/.../pulls/.../reviews` when line-anchored comments are needed.

   For a body-only approval:

   ```bash
   gh pr review "$PR" --approve --body "$BODY"
   ```

   For body-only required fixes:

   ```bash
   gh pr review "$PR" --request-changes --body "$BODY"
   ```

   Use clear, actionable comments. Include file and line references when useful. Do not submit multiple reviews unless the first submission failed.

6. Always discard the worktree before finishing, even if review submission fails.

   ```bash
   bash "$SKILL_DIR/scripts/pr-worktree.sh" cleanup "$WORKTREE"
   ```

## Review Comment Rules

- Keep review comments in English.
- Lead with blocking findings when requesting changes.
- Mark optional suggestions as `nit:` or `optional:` so they are not confused with required fixes.
- Prefer precise, minimal comments over broad style advice.
- Do not ask the author to run commands that CI already runs.

## Resources

- `scripts/pr-worktree.sh`: Create and clean up the disposable worktree used during the review.
- `references/review-lenses.md`: Reviewer roles, dispatch prompts, findings schema, and synthesis rules.
- `references/gh-review-commands.md`: `gh pr review` and `gh api` commands for one consolidated review.
- `agents/openai.yaml`: UI metadata for this skill only; Codex custom agent definitions live in `config/codex/agents/`.
