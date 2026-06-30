# gh review commands

Concrete `gh` / `gh api` commands for submitting a PR review. Referenced from SKILL.md workflow step 5 (submit one review).

## Terminology: review vs comment

- **review**: Carries a verdict (`APPROVE` / `REQUEST_CHANGES` / `COMMENT`) and can bundle multiple inline comments into a single submission. This is what the skill uses.
- **issue comment**: A standalone comment posted with `gh pr comment`, not tied to a line and carrying no verdict. Not used for reviews.

## Fetch the diff and metadata

```bash
# Full diff
gh pr diff "$PR"

# Changed file list
gh pr view "$PR" --json files --jq '.files[].path'

# Metadata
gh pr view "$PR" --json number,title,headRefName,baseRefName,isCrossRepository,state,url
```

## Body-only review (no inline comments)

When no inline comments are needed, `gh pr review` alone is enough.

```bash
# Approve
gh pr review "$PR" --approve --body "LGTM. Assuming CI's quality gates pass, the logic and design look fine."

# Request changes
gh pr review "$PR" --request-changes --body "The following changes are required: ..."

# Neutral comment (e.g., a question)
gh pr review "$PR" --comment --body "One thing to confirm: ..."
```

## Review with inline comments (recommended)

To attach line-anchored comments, POST JSON to the Reviews API via `--input`. The `gh pr review` CLI flags alone cannot specify inline comments, so use this.

```bash
OWNER_REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"   # owner/repo
PR_NUMBER="$(gh pr view "$PR" --json number --jq .number)"

gh api "repos/${OWNER_REPO}/pulls/${PR_NUMBER}/reviews" --method POST --input - <<'JSON'
{
  "event": "REQUEST_CHANGES",
  "body": "Overall summary: 2 blockers, 1 nit.",
  "comments": [
    {
      "path": "src/main.rs",
      "line": 42,
      "side": "RIGHT",
      "body": "This unwrap() panics on empty input. Propagate with ? instead."
    },
    {
      "path": "src/lib.rs",
      "start_line": 10,
      "line": 15,
      "side": "RIGHT",
      "body": "nit: extracting this range into a helper would read better."
    }
  ]
}
JSON
```

### Field reference

| Field                   | Description                                                                              |
| ----------------------- | ---------------------------------------------------------------------------------------- |
| `event`                 | `APPROVE` / `REQUEST_CHANGES` / `COMMENT`. `body` is optional when approving.            |
| `body`                  | Overall review summary. Note blocker counts in one to a few lines.                       |
| `comments[].path`       | Path relative to the repo root. Match the spelling in `gh pr diff`.                      |
| `comments[].line`       | Line number on the **new file side** (the right side of the diff) to anchor the comment. |
| `comments[].side`       | Usually `RIGHT` (added/changed lines). Use `LEFT` to comment on removed lines.           |
| `comments[].start_line` | Start line of a multi-line comment. Omit for single-line comments.                       |
| `comments[].start_side` | Start side of a multi-line comment. Defaults to `side` when omitted; rarely needed.      |

### Anchoring a finding to a line

- Use the line number on the **new file side** (the right side of the diff). When the hunk header's line count disagrees with the visible body, ignore the header math and count the actual `+`/context lines of the new side.
- For a finding that is not tied to one line (a missing test, a cross-lens or file-wide concern), anchor it to the **declaration line of the symbol it is about**, or to the nearest changed line in the relevant hunk. Say in the comment body that the point is file/function-wide so the line is just an anchor.

## Choosing the event (maps to SKILL.md "Approve vs request-changes")

- One or more must-fix issues → `REQUEST_CHANGES`
- Nits only / no issues → `APPROVE`
- Only a question, verdict deferred → `COMMENT` (use sparingly)

## Common errors and fixes

| Symptom                           | Cause / fix                                                                                                           |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `422 Unprocessable Entity` (line) | `line` points at a line not in the diff. Check changed lines with `gh pr diff` and use the new-file-side line number. |
| `path` not found                  | Use the post-rename new path. Confirm the exact path with `gh pr view --json files`.                                  |
| Cannot approve your own PR        | GitHub policy: the author cannot approve. Fall back to `--comment` or tell the user.                                  |
| `Resource not accessible`         | Insufficient permissions. Check the scope (`repo`) with `gh auth status`.                                             |

## Verify after submitting

```bash
# Check the latest review state
gh pr view "$PR" --json reviews --jq '.reviews[-1] | {state: .state, author: .author.login}'
```
