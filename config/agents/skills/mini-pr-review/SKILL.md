---
name: mini-pr-review
description: Manual-only GitHub PR review workflow. Use only when the user explicitly invokes mini-pr-review for a GitHub PR URL or number, such as $mini-pr-review in Codex or /mini-pr-review in Claude Code. Review the PR in a temporary git worktree, do not use sub-agents or other skills, do not run CI-covered tests/formatters/linters/builds, submit one approve or request-changes review with gh, and always remove the worktree afterward.
---

# Mini PR Review

Review one GitHub pull request in an isolated worktree and submit exactly one GitHub review. Keep the workflow single-pass and runtime-neutral for Codex, Claude Code, and other agentic coding tools.

## Hard Constraints

- Use this skill only after explicit manual invocation, such as `$mini-pr-review` in Codex or `/mini-pr-review` in Claude Code.
- Use exactly one temporary git worktree for the review.
- Do not review on the current branch.
- Do not use sub-agents, named agents, or any other skill.
- Do not run tests, formatters, linters, typecheckers, or builds unless the user explicitly overrides this skill.
- Do not edit files, commit, push, or change the PR branch.
- Submit exactly one final review: approve when there are no blocking issues, request changes when there is at least one blocking issue.
- Always remove the review worktree before finishing, including on errors.
- Write GitHub review bodies and comments in English.

## Workflow

1. Resolve the PR argument from the explicit invocation. If no PR URL or number was provided, ask for it.

2. Run from a local clone of the target repository. If the user gave a PR URL for a different repository, ask them to run the skill from that repository's local clone or provide the correct local path.

3. Fetch PR metadata before creating a worktree:

   ```bash
   gh pr view "$PR" --json number,title,url,state,baseRefName,headRefName,author,isCrossRepository
   ```

   Stop before setup if `state` is not `OPEN`.

4. Create the review worktree with this skill's bundled helper. Resolve `SKILL_DIR` to the directory containing this `SKILL.md`.

   ```bash
   SKILL_DIR="<this skill directory>"
   WORKTREE="$(sh "$SKILL_DIR/scripts/pr-worktree.sh" setup "$PR" | tail -n1)"
   ```

5. Review the PR yourself in `$WORKTREE`.

   Useful read-only commands:

   ```bash
   gh pr diff "$PR" --patch
   gh pr view "$PR" --json files,commits,reviews,comments
   git -C "$WORKTREE" status --short
   rg "<symbol or API name>" "$WORKTREE"
   ```

   Focus on reviewer-only judgment: correctness, security, data loss, API compatibility, migration safety, error handling, and whether the changed behavior matches the PR intent. Read surrounding code and call sites when needed. Treat formatting, lint, tests, and builds as CI's job.

6. Decide the verdict.
   - `APPROVE`: No blocking issues. Minor nits may be mentioned in the review body, but they do not block.
   - `REQUEST_CHANGES`: One or more blocking issues with concrete file/function evidence.

   A blocking issue must be actionable and grounded in the diff or nearby code. Do not request changes for preference-only style, speculative rewrites, or checks CI should own.

7. Write the review body to a temporary file outside the repository, then submit one GitHub review.

   ```bash
   BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/mini-pr-review-body.XXXXXX.md")"
   ```

   For approval:

   ```bash
   gh pr review "$PR" --approve --body-file "$BODY_FILE"
   ```

   For blocking issues:

   ```bash
   gh pr review "$PR" --request-changes --body-file "$BODY_FILE"
   ```

   If the authenticated GitHub user is the PR author and GitHub rejects approval, submit a non-blocking comment with the approval summary and tell the user why approval could not be posted.

   ```bash
   gh pr review "$PR" --comment --body-file "$BODY_FILE"
   ```

8. Remove the worktree before the final response:

   ```bash
   sh "$SKILL_DIR/scripts/pr-worktree.sh" cleanup "$WORKTREE"
   ```

## Review Body Shape

Use concise English. Include:

- Verdict: `Approved` or `Request changes`
- Summary: one or two sentences
- Blocking findings: concrete bullets with file paths or symbols
- Non-blocking notes: only when useful

## Failure Handling

- If worktree setup fails, report the failing command and do not submit a review.
- If review submission fails, keep the review body available in the conversation and still clean up the worktree.
- If cleanup fails, report the path and cleanup error clearly.
