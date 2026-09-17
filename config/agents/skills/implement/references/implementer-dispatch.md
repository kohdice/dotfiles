# Implementer dispatch

Detailed material for SKILL.md workflow steps 4–6. Defines which knowledge skills a batch loads (in a sub-agent or in the parent), the batching rules, the dispatch prompt template, the result schema, the recovery policy, and the direct-execution contract.

## Knowledge-skill selection

Select per batch, by the decisions the batch will make — not per plan, and never "always". The same selection applies when the parent executes a batch directly. Skill paths resolve as `<skills root>/<name>/SKILL.md` (SKILL.md "Skill locations"); list the absolute paths explicitly in a dispatch prompt — the sub-agent must not guess locations.

| Skill                                                   | Assign when                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tdd`                                                   | Every batch. It is the implementation discipline, not a knowledge catalog. The implementer reads its cycle, Test Tiers, and Tidy First sections; plan management belongs to the parent.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| `c-idioms` / `go-idioms` / `rust-idioms` / `zig-idioms` | Every batch that edits code in that language — the one matching the batch's target language. Its Step 0 resolves the project's version baseline and is the minimum read; the catalog sections are consulted for the constructs the batch actually writes.                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| `simplicity-patterns`                                   | The batch introduces or reshapes an abstraction — an interface/trait, generic, builder, wrapper, new layer or module, a config option or flag — or contains a `Refactor:` item. Not for a batch that adds a test and a straight-line function; the dispatch prompt's default rule covers that.                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `comment-patterns`                                      | The batch writes or changes doc comments on public API, adds a why-comment for non-obvious logic, or edits code whose existing comments make claims the change touches. Not for a batch whose only comments are the forms the idiom skill mandates; the dispatch prompt's default rule covers that.                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `performance-patterns`                                  | When the batch touches hot code — code whose call context multiplies its executions: functions run per-request, per-item, or per-frame; recursive calls; code called (directly or transitively) from other hot code; loop bodies iterating over input-sized or unbounded data. Judge by call context (the plan's Goal/Context, named callers), not code shape alone; de-minimis: a single leaf function with no known hot caller and no throughput or latency mention in the plan is cold — do not assign for it. This restates performance-patterns' "Hot path first" definition and is authoritative for this selection — do not read that skill's body to decide. Also read its `references/<lang>.md` for the target language. |
| `architecture-patterns`                                 | When the batch adds a module/package/crate, moves code across layer boundaries, or decides where new code lives.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |

When genuinely uncertain whether a conditional skill applies, assign it — in a dispatch the read lands in the sub-agent's context; in direct execution it is the one catalog the parent reads for that decision. When a skill is not assigned, the "Defaults" block of the dispatch prompt carries the two-line rule that stands in for it.

Files outside C/Go/Rust/Zig (a build script, a fixture) may be edited as the item requires, but no idiom skill is assigned for them.

## Batching rules

- **A batch is a coherent responsibility**: consecutive plan items in one area (the same file, module, or feature slice) that one implementer can hold in a single context. Typical size is two to five items; one item when it is large or its design decision gates what follows; up to a whole phase when the items are small and closely related. There is no one-item-per-worker default.
- **Never batch across a phase boundary** (`### Phase N:` headings, when the plan has them), and never reorder items the plan ordered apart.
- **A `Refactor:` item may share a batch** with the tests around it. Inside the batch it is still its own step with the tdd skill's identical-results check before and after, and the result's `cycles[]` records it separately, so the Tidy First separation stays visible in the parent's records.
- Inside a batch, each `Test:` item is still its own Red-Green-Refactor cycle, run in plan order.
- Keep items that wait on an open design question out of a batch whose other items do not.

## Dispatch contract (per implementer)

Dispatch each implementer with a prompt of this shape. The constraints block is mandatory — it preserves the skill's invariants.

```
You are an implementer sub-agent executing TDD plan item(s) in the repository at <REPO_ROOT>. Write the test(s) and production code for the assigned item(s) only, following Kent Beck's Red-Green-Refactor exactly as the tdd skill specifies.

## Read first, in this order, before writing any code
- <SKILLS_ROOT>/tdd/SKILL.md — the implementation discipline: the TDD Cycle section (Red-Green-Refactor phases, Test Tiers, Green strategies) and Tidy First. Ignore its plan-management sections: the parent owns the plan file.
- <SKILLS_ROOT>/<idiom skill>/SKILL.md — run its Step 0 to resolve the project's language baseline; generated code must respect it. Consult its catalog for the constructs you write.
<when assigned: - <SKILLS_ROOT>/simplicity-patterns/SKILL.md — this batch decides on an abstraction or refactors; introduce nothing that does not earn its keep.>
<when assigned: - <SKILLS_ROOT>/comment-patterns/SKILL.md — this batch writes doc comments or why-comments; write only what the code cannot say.>
<when assigned: - <SKILLS_ROOT>/performance-patterns/SKILL.md and its references/<lang>.md — avoid the known cost patterns in hot paths.>
<when assigned: - <SKILLS_ROOT>/architecture-patterns/SKILL.md — place new code per the Dependency Rule and the project's declared layout.>

## Context
- Repository root: <REPO_ROOT>
- Fast-tier command: <FAST_COMMAND> — this is what "run all tests" means at every tdd checkpoint
- Full-suite command: <SUITE_COMMAND> — for reference only; the parent runs it at phase and plan completion. Run it yourself only if a `Test (integration):` item's own test cannot be selected more narrowly
- Plan goal: <GOAL section pasted verbatim>
- Plan context: <CONTEXT section pasted verbatim>
- Completed so far: <count> item(s) already green<; optionally add context the next implementer needs>. <Mandatory forewarning — include whenever the previous batch's result contained any red_confirmed=false cycle or its notes indicate the implementation generalizes beyond its items: name the assigned item(s) likely to already pass and instruct "expect red_confirmed=false there; apply that protocol as verification, not discovery — never force an artificial failure", e.g. "the batch-1 implementation already generalizes over all whitespace, so this item likely already passes". When the trigger fact touches no item assigned in this dispatch, state it as plain context without the pre-pass instruction>
- Assigned item(s), in order:
  <exact plan item text, one per line>
- Open design questions, escalated to the user and still undecided (do not resolve these, and do not propose discovered_tests for them): <list, or "none">
- Current state: full suite green at the last milestone; fast tier green after the previous batch (both verified by the parent)

## Hard constraints
- Implement ONLY the assigned item(s): one Red-Green-Refactor cycle per `Test:` item; a `Refactor:` item changes structure with test results identical before and after.
- Run the fast-tier command (<FAST_COMMAND>) at every checkpoint the tdd skill defines. For a `Test (integration):` item, also run that integration test for its Red and Green runs. An equivalent-or-stricter variant (e.g. a cache-busting flag) is fine; report what you actually ran.
- Evidence: for every cycle, record each checkpoint run as "<phase>: <command> → <outcome>" in cycles[].evidence, and put the batch's last run in suite. A run you did not perform is reported as not run, never as pass.
- Defaults for decisions whose skill is not in your read list: introduce no interface, trait, generic, builder, wrapper, or option that a need present in the assigned items does not justify; write no comment that restates the code — a comment carries only a why, a constraint the types cannot express, or an external reference; a doc comment on public API states the contract (errors, ranges, ownership), in the idiom skill's mandated format. If an item turns out to hinge on one of these decisions, say so in notes instead of guessing.
- If a new test passes without any production change, distinguish the two cases per the tdd skill: if the test does not exercise what it claims, fix the test until it fails for the right reason; only if the behavior genuinely already exists, do not force an artificial failure — report it with red_confirmed=false and explain in notes (the parent marks the item).
- Do NOT write to the plan file or anything under .plans/.
- Do NOT commit, push, stash, branch, or otherwise change git state.
- Do NOT add behavior beyond the assigned item(s). Record behavior the feature still needs as discovered_tests entries instead of implementing it. Behavior your implementation happens to satisfy but no test pins is also a valid discovered_tests entry (expect red_confirmed=false when it is dispatched). A discovered_tests entry must be a decidable, implementable test behavior stated as input → expected output, containing nothing but the plan-item line itself (rationale or commentary goes in notes); an entry containing "or", "decide", or an unchosen alternative is a design question and goes into notes for the parent to escalate, never into discovered_tests.
- If an item cannot be completed (ambiguous, contradicts existing behavior, requires unplanned work), stop and return status "blocked" with the reason. Do not improvise around it.

## Return (structured result only)
Return a single JSON object matching the result schema below — no diffs, no file dumps, no full test logs. Keep notes to a few sentences. Write notes and discovered_tests in English (discovered_tests entries are appended verbatim to the plan file).

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
          "refactor": { "type": "string" },
          "evidence": { "type": "string" }
        },
        "required": ["item", "evidence"]
      }
    },
    "files_changed": { "type": "array", "items": { "type": "string" } },
    "suite": {
      "type": "object",
      "properties": {
        "command": { "type": "string" },
        "tier": { "type": "string", "enum": ["fast", "fast+integration", "full"] },
        "result": { "type": "string", "enum": ["pass", "fail", "not_run"] },
        "failures": { "type": "array", "items": { "type": "string" } }
      },
      "required": ["command", "tier", "result"]
    },
    "discovered_tests": { "type": "array", "items": { "type": "string" } },
    "notes": { "type": "string" }
  },
  "required": ["status", "cycles", "files_changed", "suite"]
}
```

Field notes:

- `cycles[].evidence` lists the checkpoint runs of that cycle, one per phase, as `<phase>: <exact command> → <outcome>` (e.g. `red: go test ./... -count=1 → fail (TestParsesEmpty); green: go test ./... -count=1 → pass; refactor: skipped`). This is what the parent reads instead of re-running the suite.
- `cycles[].refactor` is `"applied: <one-line what>"` or `"skipped: <one-line why>"` — mirroring the tdd skill's rule that Phase 3 is skippable when the code already meets the bar.
- `suite` is the batch's last run: the command as executed, its tier, and the outcome.
- `discovered_tests` entries are full plan-item lines (e.g. `- [ ] Test: rejects duplicate keys with an error`), ready for the parent to append — exactly the plan-item line, with no trailing commentary or rationale (that belongs in `notes`). Verbatim means character-for-character as returned: escape-sequence text such as a literal backslash-u sequence in an entry stays source text — never decode or re-encode it when appending. Entries must name decidable, implementable behaviors; open design questions travel in `notes` instead. The parent deduplicates against existing plan items before appending (by tested behavior, not wording).
- On `status: "blocked"`, `cycles` covers whatever was completed before the block, `notes` carries the reason, and `suite.result` is `"not_run"` when the block happened before any suite run.

When dispatching via tooling that supports a response schema, pass the schema so the return is validated rather than parsed. Otherwise the schema travels inside the prompt itself, as the template's Return section shows.

## Recovery policy (a run fails)

When a `done` result reports a failing run, the parent's spot-run of the fast tier fails, or a milestone full-suite run fails:

1. **One fix pass**: for a delegated batch, dispatch one follow-up fix to a fresh sub-agent with the same contract and skill list plus the failure output; for a direct batch, make one direct fix pass in the parent under the same constraints. Scope: "make the failing command pass without changing behavior beyond the assigned item(s)". A milestone failure additionally says whether the failing tests belong to the slow tier only.
2. If the run fails again after the fix pass, **stop**. Leave the batch's items unchecked (for a milestone failure: leave the items marked and state that the phase's full suite is red), report the failing state, the files changed, and the failure output. Do not loop further and do not revert files on your own — the user decides between reverting and debugging.

A `blocked` result is not a failure: relay the reason and ask the user how to proceed.

## Direct execution

Direct execution is the mode SKILL.md step 4 chooses for small, clear batches, and the only mode when dispatch tooling is absent or a dispatch attempt fails (nesting inside a sub-agent is a common cause, not a trigger by itself — when dispatch tooling works there, delegation stays available).

- Implement in the parent, following the tdd skill directly (its plan-management sections apply again, since parent and implementer are now the same context).
- Read the knowledge skills the selection table assigns for this batch — no more. The parent's context is the cost; the table bounds it.
- All other invariants hold unchanged: fast tier at every checkpoint, full suite at milestones, plan writes only between items, no git writes, discovered tests appended not implemented.
- Record the batch's evidence in the conversation using the result schema's fields (cycles with evidence, files changed, last run, discovered tests, notes), so step 6 reads the same thing it would read from a sub-agent.
- The final report names the batches that ran directly and, when dispatch tooling was unavailable, says so.
