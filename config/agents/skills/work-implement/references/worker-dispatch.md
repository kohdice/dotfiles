# Worker dispatch

Detailed material for SKILL.md workflow steps 4–6. Defines which knowledge skills a batch loads (in a sub-agent or in the parent), the batching rules, the dispatch prompt template, the result schema, the recovery policy, and the direct-execution contract.

## Knowledge-skill selection

Select per batch, by the decisions the batch will make. Most non-TDD batches (Terraform, Nix, YAML, documentation) select nothing — the verification discipline travels inside the dispatch prompt itself, and no idiom catalog exists for those technologies yet. The same selection applies when the parent executes a batch directly.

| Skill | Assign when |
| --- | --- |
| `c-idioms` / `go-idioms` / `rust-idioms` / `zig-idioms` | The batch edits source files in that language (e.g., a Go helper inside a CI tooling task). Its Step 0 resolves the version baseline; the catalog is consulted for the constructs written. |
| `simplicity-patterns` | An assigned-language batch introduces or reshapes an abstraction (interface/trait, generic, builder, wrapper, new module, config option) or refactors structure. |
| `comment-patterns` | An assigned-language batch writes or changes doc comments on public API, adds a why-comment, or touches code whose comments make claims the change affects. |
| `architecture-patterns` | An assigned-language batch adds a module/package/crate or moves code across layer boundaries. |

Skill paths resolve as `<skills root>/<name>/SKILL.md` (SKILL.md "Skill locations"); list the absolute paths explicitly in a dispatch prompt — the sub-agent must not guess locations. When no skill qualifies, the "Read first" block is omitted entirely. When genuinely uncertain whether a conditional skill applies, assign it.

## Batching rules

- **A batch is a coherent responsibility**: consecutive `Task:` items in one area (the same file, module, or system) that one worker can hold in a single context and whose Verify steps do not depend on each other's results beyond plan order. Typical size is one to four items; one item when it is large or when its Verify result decides what follows; more when the items are small and closely related. There is no one-item-per-worker default.
- Inside a batch each item still runs its own before-check → change → verify sequence, in plan order.
- **`Task (apply):` items are never dispatched.** They always stand alone, run in the parent, and require explicit user confirmation (SKILL.md step 5).
- Never batch across a `Task (apply):` item, and never reorder items the plan ordered apart.
- **Never batch across a phase boundary** (`### Phase N:` headings, when the plan has them).

## Dispatch contract (per worker)

Dispatch each worker with a prompt of this shape. The constraints block is mandatory — it preserves the skill's invariants.

```
You are a worker sub-agent executing work-plan item(s) in the repository at <REPO_ROOT>. Make the change(s) for the assigned item(s) only, following the verification discipline below exactly.

<when any skill is assigned:
## Read first, before making any change
- <SKILLS_ROOT>/<skill>/SKILL.md — <one-line reason from the selection table>
>

## Verification discipline (apply to each assigned item, in order)
1. Before-check: run the item's Verify step first and confirm the expected outcome does NOT hold yet. If it already holds, inspect whether the task's intended state is actually present. Record before_check as "already_satisfied" and make no change: when the intended state is present, report verify.result "pass" and explain the evidence in notes; otherwise the gate is inadequate — return status "blocked", report the unperformed post-change Verify as "not_run", and explain the mismatch in notes. Never rewrite the gate or treat its passing output alone as completed work. If the Verify step cannot run before the change (e.g., it presupposes the change exists), record "not_checkable" and proceed.
2. Change: make the item's change, and nothing beyond it.
3. Verify: run the item's Verify step and compare the OUTPUT against the expected outcome stated in the item — not merely the exit code. Unexpected extra output (an unplanned resource in a plan diff, a new warning) is a fail; report it, do not explain it away.

## Context
- Repository root: <REPO_ROOT>
- Global check command: <GLOBAL_CHECK or "none defined"> — for reference; the parent runs it at phase and plan completion
- Plan goal: <GOAL section pasted verbatim>
- Plan context: <CONTEXT section pasted verbatim>
- Completed so far: <count> item(s) already verified<; optionally add context the next worker needs>
- Assigned item(s), in order:
  <exact plan item text including its Verify bullets, per item>
- Open questions, escalated to the user and still undecided (do not resolve these): <list, or "none">
- Current state: baseline/global check green at the last milestone (verified by the parent)

## Hard constraints
- Execute ONLY the assigned item(s), through the verification discipline above.
- Evidence: report each item's Verify run as the exact command you ran, a one-line summary of what its output showed relative to the expectation, and the result. A run you did not perform is reported as not_run, never as pass.
- Run validation-tier commands only: validate, dry-run, plan, lint, build, read-only queries. NEVER run commands that mutate live state — no `terraform apply`, `nix run .#switch` / `darwin-rebuild switch`, `kubectl apply/delete`, deployments, package installs into the system, DNS/IAM changes, destructive migrations. If an assigned item seems to require one, stop and return status "blocked" — such items are `Task (apply):` and belong to the parent.
- Do NOT write to the plan file or anything under .plans/.
- Do NOT commit, push, stash, branch, or otherwise change git state.
- Do NOT make changes beyond the assigned item(s). Record additional work the goal still needs as discovered_tasks entries instead of doing it.
- If an item cannot be completed (ambiguous, contradicts the current state, requires unplanned work, Verify expectation conflicts with reality), stop and return status "blocked" with the reason. Never weaken or reinterpret a Verify expectation to make it pass.

## Return (structured result only)
Return a single JSON object matching the result schema below — no diffs, no file dumps, no full command logs. Keep notes to a few sentences. Write notes and discovered_tasks in English (discovered_tasks entries are appended verbatim to the plan file).

<the Result schema block and its Field notes from this reference, pasted verbatim>
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
          "before_check": {
            "type": "string",
            "enum": ["expectation_unmet", "already_satisfied", "not_checkable"]
          },
          "verify": {
            "type": "object",
            "properties": {
              "command": { "type": "string" },
              "result": {
                "type": "string",
                "enum": ["pass", "fail", "not_run"]
              },
              "summary": { "type": "string" }
            },
            "required": ["command", "result", "summary"]
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

- `items[].verify.summary` is a one-line statement of what the output showed relative to the expectation (e.g., `"plan diff: + aws_s3_bucket.state only — matches"`), not the raw output. For a `done` result, the parent compares it against the plan's expected outcome verbatim; a mismatch triggers a parent re-run of that Verify step. A `blocked` result follows SKILL.md step 6's stop path instead.
- `before_check: "already_satisfied"` describes the before-check output, not proof that the task is complete. Set `verify.result` to `"pass"` only when the task's intended state was also confirmed, with no change made and that evidence in `notes`. If the gate passes without the intended state, return `status: "blocked"`, leave the unperformed post-change Verify as `"not_run"`, and explain the mismatch in `notes`.
- `discovered_tasks` entries are full plan-item blocks ready for the parent to append: the `- [ ] Task:` line plus its `- Verify:` bullet(s), each with a concrete expected outcome. An entry that would mutate live state, or that carries an open design question ("decide whether…"), goes into `notes` for the parent to escalate — never into `discovered_tasks`. The parent deduplicates against existing plan items before appending (by outcome, not wording).
- On `status: "blocked"`, `items` covers whatever was completed before the block, `notes` carries the reason, and the blocked item's `verify.result` is `"not_run"` when the block happened before its verification.

When dispatching via tooling that supports a response schema, pass the schema so the return is validated rather than parsed. Otherwise the schema travels inside the prompt itself, as the template's Return section shows. Include the Field notes in the worker prompt in either case; the schema alone does not express their evidence and discovery constraints.

## Recovery policy (a verification fails)

When a `done` result reports a failing Verify step, the parent's re-run of a Verify step fails, or a milestone global check fails:

1. **One fix pass**: for a delegated batch, dispatch one follow-up fix to a fresh sub-agent with the same contract and skill list plus the failure output; for a direct batch, make one direct fix pass in the parent under the same constraints. Scope: "make the item's Verify step (and the global check) pass without changes beyond the assigned item(s)".
2. If verification fails again after the fix pass, **stop**. Leave the batch's items unchecked (for a milestone failure: leave the items marked and state that the phase's global check is red), report the failing state, the files changed, and the failure output. Do not loop further and do not revert files on your own — the user decides between reverting and debugging.

For a failed `Task (apply):` item (parent-executed, so no dispatch is involved): stop immediately, report the failure output, and present the item's Rollback line for the user to decide. Never roll back on your own.

A `blocked` result is not a failure: relay the reason and ask the user how to proceed.

## Direct execution

Direct execution is the mode SKILL.md step 4 chooses for small, clear batches, and the only mode when dispatch tooling is absent or a dispatch attempt fails (nesting inside a sub-agent is a common cause, not a trigger by itself — when dispatch tooling works there, delegation stays available).

- Execute in the parent, following the verification discipline directly.
- Read the knowledge skills the selection table assigns for this batch (if any) — no more.
- All other invariants hold unchanged: parent-only plan writes between items, no git writes, apply items confirmed by the user before running, discovered tasks appended not executed, global check at milestones.
- Record the batch's evidence in the conversation using the result schema's fields (per-item before-check, Verify command/summary/result, files changed, discovered tasks, notes), so step 6 reads the same thing it would read from a sub-agent.
- The final report names the batches that ran directly and, when dispatch tooling was unavailable, says so.
