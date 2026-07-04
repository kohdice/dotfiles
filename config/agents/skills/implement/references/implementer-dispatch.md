# Implementer dispatch

Detailed material for SKILL.md workflow steps 4–6. Defines which knowledge skills each dispatch loads, the dispatch prompt template, the result schema, batching rules, the recovery policy, and the inline fallback.

## Knowledge-skill selection

Each dispatch names the skills the sub-agent must read before writing code. Select per batch, not per plan — a batch that only touches a parser does not need `architecture-patterns`.

| Skill                                                   | When to assign                                                                                                                                                                                                                                                |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tdd`                                                   | Always. It is the implementation discipline, not a knowledge catalog.                                                                                                                                                                                         |
| `c-idioms` / `go-idioms` / `rust-idioms` / `zig-idioms` | Always — the one matching the batch's target language. Its Step 0 resolves the project's version baseline.                                                                                                                                                    |
| `simplicity-patterns`                                   | Always. Whether an abstraction is justified is a question every implementation faces.                                                                                                                                                                         |
| `comment-patterns`                                      | Always. Every batch writes comments or edits code that carries them; the skill decides which comments earn their keep and which to omit.                                                                                                                      |
| `performance-patterns`                                  | When the batch touches hot code per performance-patterns' "Hot path first" definition: loop bodies, per-item/per-request/per-frame functions, recursive calls, code called from other hot code. Also read its `references/<lang>.md` for the target language. |
| `architecture-patterns`                                 | When the batch adds a module/package/crate, moves code across layer boundaries, or decides where new code lives.                                                                                                                                              |

Skill paths resolve as `$SKILLS_DIR/<name>/SKILL.md` (SKILLS_DIR from SKILL.md "Skill locations"). List the paths explicitly in the dispatch prompt — the sub-agent must not guess locations.

Files outside C/Go/Rust/Zig (a build script, a fixture) may be edited as the item requires, but no idiom skill is assigned for them.

## Batching rules

- **Default: one plan item per dispatch.** Fresh context per increment is the normal mode.
- **Up to three consecutive `Test:` items** may share one dispatch when all are small, touch the same file or area, and none depends on a design decision the previous one has not made yet. Inside the sub-agent each item is still its own Red-Green-Refactor cycle.
- **`Refactor:` items always dispatch alone.** Keeping structural changes in their own dispatch preserves the Tidy First separation in the parent's records.
- Never batch across a `Refactor:` item, and never batch items the plan ordered apart.

## Dispatch contract (per implementer)

Dispatch each implementer with a prompt of this shape. The constraints block is mandatory — it preserves the skill's invariants.

```
You are an implementer sub-agent executing TDD plan item(s) in the repository at <REPO_ROOT>. Write the test(s) and production code for the assigned item(s) only, following Kent Beck's Red-Green-Refactor exactly as the tdd skill specifies.

## Read first, in this order, before writing any code
- <SKILLS_DIR>/tdd/SKILL.md — the implementation discipline (Red-Green-Refactor phases, Green strategies, Tidy First). Ignore its plan-management sections: the parent owns the plan file.
- <SKILLS_DIR>/<idiom skill>/SKILL.md — run its Step 0 to resolve the project's language baseline; generated code must respect it.
- <SKILLS_DIR>/simplicity-patterns/SKILL.md — introduce no abstraction that does not earn its keep.
- <SKILLS_DIR>/comment-patterns/SKILL.md — write only comments that carry what the code cannot say; never restate the code.
<when assigned: - <SKILLS_DIR>/performance-patterns/SKILL.md and its references/<lang>.md — avoid the known cost patterns in hot paths.>
<when assigned: - <SKILLS_DIR>/architecture-patterns/SKILL.md — place new code per the Dependency Rule and the project's declared layout.>

## Context
- Repository root: <REPO_ROOT>
- Full test suite command: <SUITE_COMMAND> (this is what "run all tests" means at every tdd checkpoint)
- Plan goal: <GOAL section pasted verbatim>
- Plan context: <CONTEXT section pasted verbatim>
- Completed so far: <count> item(s) already green
- Assigned item(s), in order:
  <exact plan item text, one per line>
- Current state: full suite green (verified by the parent just before this dispatch)

## Hard constraints
- Implement ONLY the assigned item(s): one Red-Green-Refactor cycle per `Test:` item; a `Refactor:` item changes structure with test results identical before and after.
- Run the full suite (<SUITE_COMMAND>) at every checkpoint the tdd skill defines. Do not substitute a narrower test scope.
- If a new test passes without any production change, distinguish the two cases per the tdd skill: if the test does not exercise what it claims, fix the test until it fails for the right reason; only if the behavior genuinely already exists, do not force an artificial failure — report it with red_confirmed=false and explain in notes (the parent marks the item).
- Do NOT write to the plan file or anything under .plans/.
- Do NOT commit, push, stash, branch, or otherwise change git state.
- Do NOT add behavior beyond the assigned item(s). Record behavior the feature still needs as discovered_tests entries instead of implementing it.
- If an item cannot be completed (ambiguous, contradicts existing behavior, requires unplanned work), stop and return status "blocked" with the reason. Do not improvise around it.

## Return (structured result only)
Return a single JSON object matching the result schema below — no diffs, no file dumps, no full test logs. Keep notes to a few sentences; the parent re-runs the suite itself. Write notes and discovered_tests in English (discovered_tests entries are appended verbatim to the plan file).

<the Result schema block from this reference, pasted verbatim>
```

## Result schema

```json
{
  "type": "object",
  "properties": {
    "status": { "type": "string", "enum": ["done", "blocked"] },
    "cycles": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "item": { "type": "string" },
          "test_name": { "type": "string" },
          "red_confirmed": { "type": "boolean" },
          "green": { "type": "boolean" },
          "refactor": { "type": "string" }
        },
        "required": ["item"]
      }
    },
    "files_changed": { "type": "array", "items": { "type": "string" } },
    "suite": {
      "type": "object",
      "properties": {
        "command": { "type": "string" },
        "result": { "type": "string", "enum": ["pass", "fail", "not_run"] },
        "failures": { "type": "array", "items": { "type": "string" } }
      },
      "required": ["command", "result"]
    },
    "discovered_tests": { "type": "array", "items": { "type": "string" } },
    "notes": { "type": "string" }
  },
  "required": ["status", "cycles", "files_changed", "suite"]
}
```

Field notes:

- `cycles[].refactor` is `"applied: <one-line what>"` or `"skipped: <one-line why>"` — mirroring the tdd skill's rule that Phase 3 is skippable when the code already meets the bar.
- `discovered_tests` entries are full plan-item lines (e.g. `- [ ] Test: rejects duplicate keys with an error`), ready for the parent to append.
- On `status: "blocked"`, `cycles` covers whatever was completed before the block, `notes` carries the reason, and `suite.result` is `"not_run"` when the block happened before any suite run.

When dispatching via tooling that supports a response schema, pass the schema so the return is validated rather than parsed. Otherwise the schema travels inside the prompt itself, as the template's Return section shows.

## Recovery policy (parent verification fails)

When the parent's own suite run fails after a `done` result:

1. Dispatch **one** follow-up fix to a fresh sub-agent: the same contract and skill list, plus the parent's failure output, scoped to "make the full suite pass without changing behavior beyond the assigned item(s)".
2. If the suite fails again after the fix dispatch, **stop**. Leave the batch's items unchecked, report the failing state, the files changed, and the failure output. Do not loop further, do not patch inline in the parent, and do not revert files on your own — the user decides between reverting and debugging.

A `blocked` result is not a failure: relay the reason and ask the user how to proceed.

## Inline fallback

Use inline mode only when dispatch is genuinely unavailable: the runtime exposes no sub-agent tooling, or this skill is itself already running inside a sub-agent.

- Implement in the parent, following the tdd skill directly (its plan-management sections apply again, since parent and implementer are now the same context).
- Read the same knowledge skills selected by the table above before writing code — the context cost is accepted, not skipped.
- All other invariants hold unchanged: full-suite checkpoints, plan writes only between items, no git writes, discovered tests appended not implemented.
- State clearly in the final report that the run was inline and why.
