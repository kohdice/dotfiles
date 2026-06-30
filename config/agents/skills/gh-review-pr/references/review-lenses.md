# Review Lenses

Use these lenses to split PR review work across named read-only review agents. In this dotfiles repository, the Codex custom agent files live in `config/codex/agents/` and are registered from `config/codex/config.toml`. If the named agents are not loaded in the current session, run the same selected lenses inline in the parent agent when the user asked for an immediate review, and label the result single-pass. Ask the user to restart the runtime only when they specifically need the named-agent review.

## Lens Catalog

| Lens                          | Review agent                            | Focus                                                                                                                      | Blocker threshold                                                                                                             |
| ----------------------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `bug-logic-convention`        | `pr-review-bug-logic-convention`        | Bugs, logic errors, edge cases, broken control flow, repository convention violations                                      | A path produces wrong results, violates a hard project rule, or can regress a supported workflow                              |
| `error-handling`              | `pr-review-error-handling`              | Swallowed errors, incomplete checks, inappropriate fallbacks, silent failures, missing rollback or cleanup on failure      | An error is silently dropped, masked, retried unsafely, or lets the system continue in an invalid state                       |
| `type-design-invariants`      | `pr-review-type-design-invariants`      | Type design, data modeling, invariants, ownership boundaries, invalid states, maintainability of structure                 | The design allows invalid states, loses required invariants, or creates structure that will not hold up under expected change |
| `security-data-compatibility` | `pr-review-security-data-compatibility` | Authentication, authorization, injection, secret exposure, privacy, data loss, migrations, API/schema/config compatibility | Any exploitable path, leaked secret, authorization bypass, data loss risk, unsafe migration, or breaking compatibility change |
| `test-coverage`               | `pr-review-test-coverage`               | Missing or weak test coverage for behavior changes and edge cases                                                          | A behavior change has no meaningful test or assertion where a regression would be realistic                                   |
| `comment-accuracy`            | `pr-review-comment-accuracy`            | Accuracy of comments, docs, examples, names, and explanatory text against actual behavior                                  | A comment, doc, or name actively misleads the reader about behavior, constraints, or usage                                    |

Select lenses by the PR's actual surface area:

- Use `bug-logic-convention` for most behavior changes.
- Add `error-handling` when the diff touches failure paths, external calls, transactions, retries, cleanup, or fallbacks.
- Add `type-design-invariants` when the diff changes types, schemas, domain models, ownership boundaries, or module structure.
- Add `security-data-compatibility` when the diff touches auth, inputs, secrets, database writes, migrations, API contracts, config, or user data.
- Add `test-coverage` when behavior changes, even though reviewers must not run tests.
- Add `comment-accuracy` when comments, docs, examples, generated messages, or names changed or now describe changed behavior.

For tiny PRs, dispatch only the relevant lenses. For large or critical PRs, dispatch all lenses. Record which lenses ran and which were skipped with one short reason per skipped lens.

## Dispatch Contract

Dispatch one named review agent per selected lens. Each prompt must include the lens name, worktree path, PR identifier, and hard constraints. The review agent already contains the lens-specific developer instructions; the parent still passes task-local context every time.

```text
You are a read-only PR reviewer applying the <LENS> lens. Report findings only; do not change anything.

Context:
- Worktree, already checked out: <WORKTREE_PATH>
- PR: <PR_NUMBER_OR_URL>
- Get the diff with: gh pr diff "<PR>"
- Inspect context by reading files under the worktree path.

Lens:
<Use the focus and blocker threshold for this lens from the catalog. Stay within this lens.>

Hard constraints:
- READ-ONLY. Do not edit files, do not create or remove git worktrees, and do not push.
- Do not post anything to GitHub. No gh pr review, gh pr comment, or gh api writes. Read-only gh commands are allowed.
- Do not run tests, formatters, linters, builds, or package install commands. CI owns those checks.
- Return findings only. Do not decide the final PR verdict.

Return:
Return a JSON object:
{
  "summary": "<one sentence lens summary>",
  "findings": [
    {
      "path": "<repo-relative path>",
      "line": <new-side line number>,
      "start_line": <optional new-side start line>,
      "severity": "blocker" | "nit",
      "lens": "<LENS>",
      "body": "<English review comment>"
    }
  ]
}

Use an empty findings array when there are no findings.
```

## Findings Schema

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

## Synthesis

The parent agent alone synthesizes findings and decides the final review event.

1. Wait for every selected lens to return, or complete the inline fallback for every selected lens.
2. Flatten all findings into one list.
3. Drop findings that cannot be grounded in the diff or surrounding code.
4. Deduplicate by `(path, line, body meaning)`. When multiple lenses flag the same issue, keep one comment and mention the contributing lenses.
5. Keep the highest severity when duplicate findings disagree.
6. Prefix non-blocking comments with `nit:` or `optional:`.
7. Decide the event:
   - Any `blocker` finding -> `REQUEST_CHANGES`
   - No blockers and the authenticated GitHub user is not the PR author -> `APPROVE`
   - No blockers and the authenticated GitHub user is the PR author -> `COMMENT` with an approval-style summary
   - Use `COMMENT` for other cases only when a verdict is impossible without an answer.
8. Build one summary body that states the verdict, blocker count, nit count, lenses run, and any lenses skipped.

Never let review agents submit reviews or comments. The parent submits exactly one consolidated review.
