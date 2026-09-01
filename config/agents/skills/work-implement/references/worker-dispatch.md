# Worker dispatch

Detailed material for SKILL.md workflow steps 4–6. Defines which knowledge skills each dispatch loads, the dispatch prompt template, the result schema, batching rules, the recovery policy, and the inline fallback.

## Knowledge-skill selection

Each dispatch names the skills the sub-agent must read before making changes. Select per batch. Most non-TDD batches (Terraform, Nix, YAML, documentation) select nothing — the verification discipline travels inside the dispatch prompt itself, and no idiom catalog exists for those technologies yet.

| Skill                                                   | When to assign                                                                                                          |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `c-idioms` / `go-idioms` / `rust-idioms` / `zig-idioms` | Only when the batch edits source files in that language (e.g., a Go helper inside a CI tooling task).                    |
| `simplicity-patterns`                                   | Only when a C/Go/Rust/Zig idiom skill is assigned — it covers the same languages.                                        |
| `comment-patterns`                                      | Only when a C/Go/Rust/Zig idiom skill is assigned — same coverage.                                                       |
| `architecture-patterns`                                 | Only when an assigned-language batch adds a module/package/crate or moves code across layer boundaries.                  |

Skill paths resolve as `$SKILLS_DIR/<name>/SKILL.md` (SKILLS_DIR from SKILL.md "Skill locations"). List the paths explicitly in the dispatch prompt — the sub-agent must not guess locations. When no skill qualifies, the "Read first" block is omitted entirely.

## Batching rules

- **Default: one plan item per dispatch.** Fresh context per increment is the normal mode.
- **Up to three consecutive `Task:` items** may share one dispatch when all are small, touch the same file or area, and none depends on a verification result the previous one has not produced yet. Inside the sub-agent each item still runs its own before-check → change → verify sequence, in order. Fall back to the one-item default whenever in doubt.
- **`Task (apply):` items are never dispatched.** They always stand alone, run in the parent, and require explicit user confirmation (SKILL.md step 5).
- Never batch across a `Task (apply):` item, and never batch items the plan ordered apart.
- **Never batch across a phase boundary** (`### Phase N:` headings, when the plan has them).

## Dispatch contract (per worker)

Dispatch each worker with a prompt of this shape. The constraints block is mandatory — it preserves the skill's invariants.

```
You are a worker sub-agent executing work-plan item(s) in the repository at <REPO_ROOT>. Make the change(s) for the assigned item(s) only, following the verification discipline below exactly.

<when any skill is assigned:
## Read first, before making any change
- <SKILLS_DIR>/<skill>/SKILL.md — <one-line reason from the selection table>
>

## Verification discipline (apply to each assigned item, in order)
1. Before-check: run the item's Verify step first and confirm the expected outcome does NOT hold yet. If it already holds, do not change anything for that item — record before_check as "already_satisfied" and explain in notes. If the Verify step cannot run before the change (e.g., it presupposes the change exists), record "not_checkable" and proceed.
2. Change: make the item's change, and nothing beyond it.
3. Verify: run the item's Verify step and compare the OUTPUT against the expected outcome stated in the item — not merely the exit code. Unexpected extra output (an unplanned resource in a plan diff, a new warning) is a fail; report it, do not explain it away.

## Context
- Repository root: <REPO_ROOT>
- Global check command: <GLOBAL_CHECK or "none defined">
- Plan goal: <GOAL section pasted verbatim>
- Plan context: <CONTEXT section pasted verbatim>
- Completed so far: <count> item(s) already verified<; optionally add context the next worker needs>
- Assigned item(s), in order:
  <exact plan item text including its Verify bullets, per item>
- Open questions, escalated to the user and still undecided (do not resolve these): <list, or "none">
- Current state: baseline/global check green (verified by the parent just before this dispatch)

## Hard constraints
- Execute ONLY the assigned item(s), through the verification discipline above.
- Run validation-tier commands only: validate, dry-run, plan, lint, build, read-only queries. NEVER run commands that mutate live state — no `terraform apply`, `nix run .#switch` / `darwin-rebuild switch`, `kubectl apply/delete`, deployments, package installs into the system, DNS/IAM changes, destructive migrations. If an assigned item seems to require one, stop and return status "blocked" — such items are `Task (apply):` and belong to the parent.
- Do NOT write to the plan file or anything under .plans/.
- Do NOT commit, push, stash, branch, or otherwise change git state.
- Do NOT make changes beyond the assigned item(s). Record additional work the goal still needs as discovered_tasks entries instead of doing it.
- If an item cannot be completed (ambiguous, contradicts the current state, requires unplanned work, Verify expectation conflicts with reality), stop and return status "blocked" with the reason. Never weaken or reinterpret a Verify expectation to make it pass.

## Return (structured result only)
Return a single JSON object matching the result schema below — no diffs, no file dumps, no full command logs. Keep notes to a few sentences; the parent re-runs verification itself. Write notes and discovered_tasks in English (discovered_tasks entries are appended verbatim to the plan file).

<the Result schema block from this reference, pasted verbatim>
```

## Result schema

```json
{
  "type": "object",
  "properties": {
    "status": { "type": "string", "enum": ["done", "blocked"] },
    "items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "item": { "type": "string" },
          "before_check": { "type": "string", "enum": ["expectation_unmet", "already_satisfied", "not_checkable"] },
          "verify": {
            "type": "object",
            "properties": {
              "command": { "type": "string" },
              "result": { "type": "string", "enum": ["pass", "fail", "not_run"] },
              "summary": { "type": "string" }
            },
            "required": ["command", "result"]
          }
        },
        "required": ["item", "before_check", "verify"]
      }
    },
    "files_changed": { "type": "array", "items": { "type": "string" } },
    "discovered_tasks": { "type": "array", "items": { "type": "string" } },
    "notes": { "type": "string" }
  },
  "required": ["status", "items", "files_changed"]
}
```

Field notes:

- `items[].verify.summary` is a one-line statement of what the output showed relative to the expectation (e.g., `"plan diff: + aws_s3_bucket.state only — matches"`), not the raw output.
- On `before_check: "already_satisfied"`, `verify.result` is `"pass"` with no change made; `notes` explains what was found already in place.
- `discovered_tasks` entries are full plan-item blocks ready for the parent to append: the `- [ ] Task:` line plus its `- Verify:` bullet(s), each with a concrete expected outcome. An entry that would mutate live state, or that carries an open design question ("decide whether…"), goes into `notes` for the parent to escalate — never into `discovered_tasks`. The parent deduplicates against existing plan items before appending (by outcome, not wording).
- On `status: "blocked"`, `items` covers whatever was completed before the block, `notes` carries the reason, and the blocked item's `verify.result` is `"not_run"` when the block happened before its verification.

When dispatching via tooling that supports a response schema, pass the schema so the return is validated rather than parsed. Otherwise the schema travels inside the prompt itself, as the template's Return section shows.

## Recovery policy (parent verification fails)

When the parent's own Verify re-run (or global check) fails after a `done` result:

1. Dispatch **one** follow-up fix to a fresh sub-agent: the same contract and skill list, plus the parent's failure output, scoped to "make the item's Verify step and the global check pass without changes beyond the assigned item(s)".
2. If verification fails again after the fix dispatch, **stop**. Leave the batch's items unchecked, report the failing state, the files changed, and the failure output. Do not loop further, do not patch inline in the parent, and do not revert files on your own — the user decides between reverting and debugging.

For a failed `Task (apply):` item (parent-executed, so no dispatch is involved): stop immediately, report the failure output, and present the item's Rollback line for the user to decide. Never roll back on your own.

A `blocked` result is not a failure: relay the reason and ask the user how to proceed.

## Inline fallback

Use inline mode only when dispatch is genuinely unavailable: no dispatch tooling is exposed, or a dispatch attempt fails. Nesting (running as a sub-agent) is a common cause of unavailability, not a trigger by itself — when dispatch tooling works in a nested context, stay in delegated mode.

- Execute in the parent, following the verification discipline directly.
- Read the knowledge skills selected by the table above (if any) before making changes — the context cost is accepted, not skipped.
- All other invariants hold unchanged: parent-only plan writes between items, no git writes, apply items confirmed by the user before running, discovered tasks appended not executed.
- State clearly in the final report that the run was inline and why.
