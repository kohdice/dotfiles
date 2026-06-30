# GH Review Commands

Use these commands to submit one consolidated GitHub review after the parent agent synthesizes all findings.

## Fetch Metadata

```bash
gh pr view "$PR" --json number,title,url,state,baseRefName,headRefName,author,isCrossRepository
gh pr view "$PR" --json files --jq '.files[].path'
gh pr diff "$PR" --patch
```

## Body-Only Review

Use `gh pr review` when there are no line-anchored findings or when GitHub cannot anchor the relevant point to the diff.

```bash
gh pr review "$PR" --approve --body "$BODY"
gh pr review "$PR" --request-changes --body "$BODY"
gh pr review "$PR" --comment --body "$BODY"
```

Use `--comment` sparingly. Prefer `--approve` or `--request-changes`.

## Event Guardrails

Choose the review event after synthesis, before submitting:

```bash
AUTH_LOGIN="$(gh api user --jq .login)"
PR_AUTHOR="$(gh pr view "$PR" --json author --jq .author.login)"
```

- Use `REQUEST_CHANGES` when any blocker must be fixed before merge.
- Use `APPROVE` when there are no required fixes and `AUTH_LOGIN` differs from `PR_AUTHOR`.
- Use `COMMENT` with an approval-style summary when there are no required fixes and `AUTH_LOGIN` equals `PR_AUTHOR`. Do not try `--approve` first if the self-review condition is already known.
- If GitHub still rejects an approval attempt with `Cannot approve your own PR`, retry only as one `COMMENT` review with the same approval-style summary.

## Inline Review

Use the Reviews API through `gh api` when comments should be line-anchored. Submit one review containing every inline comment.

```bash
OWNER_REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
PR_NUMBER="$(gh pr view "$PR" --json number --jq .number)"

gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/reviews" --method POST --input - <<'JSON'
{
  "event": "REQUEST_CHANGES",
  "body": "Requesting changes: 1 blocker, 1 nit. Lenses run: bug-logic-convention, error-handling.",
  "comments": [
    {
      "path": "src/example.rs",
      "line": 42,
      "side": "RIGHT",
      "body": "This branch returns success after the write failed, so callers can observe committed state that does not exist."
    },
    {
      "path": "src/example.rs",
      "start_line": 50,
      "line": 55,
      "side": "RIGHT",
      "body": "nit: this block would be easier to audit if the validation and mutation steps were split."
    }
  ]
}
JSON
```

## Inline Comment Fields

| Field                   | Use                                                |
| ----------------------- | -------------------------------------------------- |
| `event`                 | `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`         |
| `body`                  | Overall review summary                             |
| `comments[].path`       | Repo-relative path from the PR diff                |
| `comments[].line`       | New-side line number for the comment anchor        |
| `comments[].side`       | Usually `RIGHT`; use `LEFT` only for removed lines |
| `comments[].start_line` | Optional start line for a multi-line comment       |
| `comments[].start_side` | Optional; defaults to `side`                       |

## Anchoring Rules

- Anchor to a changed line on the new side whenever possible.
- For file-wide concerns, anchor to the nearest relevant changed declaration or hunk and say the issue is broader than that line.
- If an inline submission fails with a line error, re-check the hunk with `gh pr diff "$PR" --patch`; if the issue is still valid but cannot be anchored, submit it in the review body.

## Common Failures

| Failure                               | Response                                                                                                |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `422 Unprocessable Entity` for a line | The line is not anchorable in the PR diff. Use a changed new-side line or move the finding to the body. |
| `path` not found                      | Use the post-rename path shown by `gh pr view "$PR" --json files`.                                      |
| Cannot approve your own PR            | Use `COMMENT` with the approval summary or tell the user GitHub rejected self-approval.                 |
| `Resource not accessible`             | Tell the user the authenticated account lacks permission; do not retry with unrelated credentials.      |

## Verify Submission

```bash
gh pr view "$PR" --json reviews --jq '.reviews[-1] | {state: .state, author: .author.login}'
```
