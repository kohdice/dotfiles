# Review lenses and the dispatch contract

Detailed material for SKILL.md workflow step 3 (fan out the review). Defines the review lenses, the read-only sub-agent dispatch contract, the findings schema sub-agents must return, and how the parent synthesizes them into a single verdict.

## Lenses

Each lens is a focused review concern. Dispatch one read-only sub-agent per lens, in parallel. The lenses are language-agnostic. When the `pr-review-toolkit` agents are installed, prefer them as the dispatch target; otherwise dispatch a generic read-only agent with the lens prompt.

| Lens           | Focus                                                                            | What counts as a blocker                                                  | Preferred agent (if available)            |
| -------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------- | ----------------------------------------- |
| correctness    | Logic errors, off-by-one, edge cases, broken control flow, convention violations | A path that produces wrong results or violates a hard project rule        | `pr-review-toolkit:code-reviewer`         |
| error-handling | Swallowed errors, missing checks, inappropriate fallbacks, silent failures       | An error that is silently dropped or masks a real failure                 | `pr-review-toolkit:silent-failure-hunter` |
| security       | Injection, secret exposure, missing authz, unsafe input handling                 | Any exploitable path or leaked secret                                     | generic read-only agent, security lens    |
| design         | Type/data design, invariants, structure, readability, complexity                 | A type that allows an invalid state, or a structure that will not hold up | `pr-review-toolkit:type-design-analyzer`  |
| tests          | Missing tests, weak assertions, untested edge cases                              | A behavior change with no test and a real regression risk                 | `pr-review-toolkit:pr-test-analyzer`      |
| comments       | Comment accuracy vs code, stale or misleading docs                               | A comment that actively misleads about behavior                           | `pr-review-toolkit:comment-analyzer`      |

Scale the lens set to the PR by its actual surface, not a fixed pair: a pure-logic change may need only `correctness` (+ `error-handling` if it touches error paths); a behavior-preserving refactor that adds/moves docs leans on `comments` + `design`; a large or critical PR warrants the full set. Pick lenses from the focus columns above, not from this example. Always log which lenses were applied and which were skipped (with a one-line reason for each skip).

## Dispatch contract (per sub-agent)

Dispatch each reviewer with a prompt of this shape. The constraints block is mandatory — it preserves the skill's invariants.

```
You are a read-only PR reviewer applying the <LENS> lens. Report findings only; do not change anything.

## Context
- Worktree (already checked out, read-only): <WORKTREE_PATH>
- PR: <PR_NUMBER_OR_URL>
- Get the diff with: gh pr diff "<PR>"
- Inspect context by reading files under the worktree path.

## Lens
<one-paragraph definition of the lens focus and what counts as a blocker, from the table above>

## Hard constraints
- READ-ONLY. Do not edit files, do not create or remove git worktrees, do not push.
- Do not post anything to GitHub (no gh pr review, no gh pr comment, no gh api writes). Read-only gh is fine (gh pr diff, gh pr view).
- Do NOT run tests, formatters, linters, or builds — CI already covers them.
- Reason from the code. Stay within your lens; do not duplicate other lenses' concerns.

## Return (findings only)
Return a JSON array of findings, each:
{ "path": "<repo-relative path>", "line": <new-side line number>, "start_line": <optional>, "severity": "blocker" | "nit", "lens": "<LENS>", "body": "<comment text>" }
Return an empty array if nothing is found. Add a one-line lens summary after the array.
```

When dispatching via the Workflow/Agent tooling with a schema, use the findings schema below so returns are validated rather than parsed.

## Findings schema

```json
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "path": { "type": "string" },
          "line": { "type": "integer" },
          "start_line": { "type": "integer" },
          "severity": { "type": "string", "enum": ["blocker", "nit"] },
          "lens": { "type": "string" },
          "body": { "type": "string" }
        },
        "required": ["path", "line", "severity", "lens", "body"]
      }
    }
  },
  "required": ["summary", "findings"]
}
```

## Synthesis (parent only)

After all lenses return, the parent consolidates — this is the one place that needs every lens's output at once (a barrier), because the overall verdict cannot be decided until all findings are in.

1. **Flatten** all findings from every lens into one list.
2. **Dedup by `(path, line)`**: when multiple lenses flag the same location, merge into a single comment (prefix the body with the contributing lenses) and keep the highest severity.
3. **Classify**: severity is decided by the lens — a finding is a `blocker` when the matching lens's "what counts as a blocker" column flags it (a wrong result, security hole, data loss, API-compatibility break, or an error that is silently dropped or masks a real failure). Everything else is a `nit` = a non-blocking, optional suggestion; prefix its comment body with `nit:`. "Optional" describes nits only — never a lens-defined blocker.
4. **Decide the verdict**:
   - Any `blocker` present → `REQUEST_CHANGES`.
   - No blockers (nits only or empty) → `APPROVE`.
   - Use `COMMENT` only when a lens genuinely needs a question answered before a verdict is possible.
5. **Build one review**: turn the deduped findings into the `comments[]` array and submit a single review via `gh api .../reviews` (see `gh-review-commands.md`). The summary body should note blocker and nit counts and the per-lens coverage.

Never let sub-agents submit reviews — the parent submits exactly one.
