---
name: implement
description: "Implements application changes with testable behavior, including the bare \"go\" reply after a TDD plan. Planning-only requests use tdd-plan; explicit tdd uses tdd; combined implementation, review, and fixes use implement-review-loop."
---

# Implement (TDD orchestrator)

Implement application code from a TDD plan. The parent (this skill) owns the **plan file**, the **execution decision** for each batch (direct or delegated), the **milestone verification** (full suite at phase completion, plan completion, and before a commit suggestion), and the **final report**. Implementers — the parent itself or a sub-agent — write the test and production code for their assigned items under the tdd skill's Red-Green-Refactor discipline and report evidence: the exact commands run, their tier, and their results.

Delegation is a tool, not a default. A sub-agent buys context isolation (catalog reads and long test output stay out of the parent) and independence (work that shares no files with anything else in flight). Small, clear work runs directly in the parent. In both modes, knowledge skills load only when the batch makes a decision they cover — see "Knowledge-skill selection" in `references/implementer-dispatch.md`.

This skill is runtime-neutral: it works in Claude Code and Codex and never depends on runtime-specific named agents or skills.

## Principles

- **The plan is authoritative and parent-written**: The plan file is the single source of truth for what to build. Only the parent edits it — marking items `[x]`, appending discovered tests. Sub-agents never write under `.plans/`.
- **Work-driven delegation**: Decide per batch (step 4). Direct execution is the normal mode for a few small items in one area whose catalog needs are limited; delegation is the normal mode for batches that load several catalogs, produce long output, or start a long plan. Whether dispatch tooling exists does not decide by itself.
- **File ownership, sequential dependence**: A batch owns the files it edits until its result is in. TDD increments build on the previous green state, so implementer batches run one after another; only read-only work (an independent review) fans out.
- **Discipline by reference**: Red-Green-Refactor, Tidy First, and the Test Tiers definition live in the tdd skill. Implementers read that skill; this skill does not restate it.
- **Evidence, not claims**: Every implementer reports, per cycle, the exact command, its tier, and the outcome. The parent reads that evidence and runs the full suite itself at milestones (step 6). A bare "tests pass" is not evidence: missing, inconsistent, or off-command evidence triggers a parent spot-run of the fast tier.
- **Preserve Git history and staging**: Neither the parent nor any sub-agent commits, pushes, stashes, changes branches, or alters refs or staged paths, modes, or content. Authorized working-tree edits, including `.plans/`, and expected test artifacts are allowed; unrelated files remain unchanged. Read-only Git inspection may refresh internal metadata such as index stat caches; byte-for-byte index preservation is not required. When all items are done, suggest a commit (the git-commit skill) and leave the decision to the user.

## Skill locations

Sibling skills live next to this one. Resolve them relative to the directory this `SKILL.md` was read from: `<skills root>/<name>/SKILL.md`, where `<skills root>` is the parent of this skill's directory. Both runtimes link the same checkout, so whichever root this file was loaded from is correct — do not probe for a runtime-specific directory. Pass the resolved absolute paths into every dispatch; a sub-agent never guesses locations.

## When to use

- The user asks to implement a feature, behavior change, or bug fix with automatically testable behavior.
- The user asks to execute an existing TDD plan end-to-end.
- The user says bare `go` after a TDD plan was created in the current session — continue from that plan.

Do not use when:

- The user explicitly invokes `/tdd` to execute the plan inline in the current context — the tdd skill owns that.
- The user asks only to create a plan — the tdd-plan skill owns that.
- The work has no testable application behavior (docs, configuration, CI, housekeeping) — TDD does not apply; the work-plan and work-implement skills own that.
- The goal is reviewing code, not writing it — the local-review skill owns that.

## Workflow

1. **Resolve the plan**: Use the tdd skill's precedence — an explicitly named plan file first, then the plan created in the current session, otherwise look at `.plans/`: exactly one plan matching the request → use it without asking; two or more candidates → list them and ask; none → create one first by following the tdd-plan skill (planning stays in the parent — it needs the user dialog), then continue here. When following tdd-plan from this skill, adopt the interpretation that the request plus the codebase pin down and record it in the plan's Context; ask (or, in a non-interactive run, stop with the questions) only when no defensible interpretation exists — this restates the tdd-plan skill's Step 1 ambiguity threshold, which is the canonical definition. If tdd-plan concludes the request has no testable behavior, this skill does not apply either; say so, suggest the work-plan skill, and stop.

2. **Resolve the environment**: Resolve the skills root (above). Detect the target language from the plan's Context section and the files it names. Resolve two test commands from the project's build files or docs, following the tdd skill's Test Tiers definition: the **fast-tier command** (unit tests — `go test ./...`, `cargo test`, `zig build test`, C → `ctest` / `make test` / the Makefile's check target — minus any integration tag, marker, or package the project excludes from routine runs) and the **full-suite command** (fast plus slow tier — the same command with the integration mechanism included; identical to the fast tier when the project has no slow tier). Both go into every dispatch; the parent uses the full-suite command in steps 3 and 6.

3. **Confirm the baseline**: Run the full suite once. If it fails, classify each failure by reading, never by editing: (a) inside the plan's Goal, or in code the plan will change — propose a leading repair item and, when the user's request already covers that code, add it to the plan and proceed; (b) outside the plan's scope — report the failing test names with their output, the plan's untouched state, and how to resume, then ask whether to fix, ignore, or stop; never build on it silently. That minimum — what failed, current plan state, how to resume — is the report contract for every early stop this skill makes (a broken baseline here; a `blocked` result or a failed fix pass in step 6).

4. **Choose the batch and its mode**: Take the first unchecked plan item and form a batch per "Batching rules" in `references/implementer-dispatch.md`: a coherent responsibility — consecutive items in one area, never across a phase boundary — not one item per worker. Then choose the mode:
   - **Direct** when the batch is small and clear: a few items in one area, the idiom skill's baseline check is the only catalog the batch needs (or the catalogs it needs are already in the parent context), and the parent context is still lean.
   - **Delegate** when the batch needs several catalog reads, will produce long test output, or is the first of a long plan (isolation pays over many batches) — or when the user asked for sub-agents.
     Direct execution loads knowledge skills under the same selection rules as a dispatch; it is not a license to read every catalog into the parent. When the runtime exposes no working dispatch tooling (no dispatch tool, or an attempt fails), every batch is direct — say so in the report. Running inside a sub-agent is not by itself a reason to go direct.

5. **Execute the batch**:
   - **Delegated**: send the dispatch prompt from `references/implementer-dispatch.md` — the skills to read, both test commands, the plan's Goal/Context, the item text, the hard constraints, and the result schema. Wait for the result; never start a dependent batch early. When the previous batch's result contained any `red_confirmed=false` cycle, or its notes indicate the implementation generalizes beyond its items, the next dispatch must carry the template's mandatory forewarning on its Completed-so-far line — name the likely-pre-passing item(s) and instruct the implementer to apply the `red_confirmed=false` protocol as verification, not discovery. When the trigger fact touches no item in the next batch, state it as plain Completed-so-far context without the pre-pass instruction.
   - **Direct**: follow the tdd skill in the parent for the assigned items, running the fast tier at every checkpoint, and record the same fields the result schema defines (cycles with evidence, files changed, last suite run, discovered tests, notes) in the conversation so step 6 has the same evidence to read.

6. **Verify and record**: Read the batch's evidence. It is complete when every cycle reports its command, tier, and outcome, and the batch's last run is a fast-tier pass (plus the integration test itself for a `Test (integration):` item). When evidence is missing, fields contradict each other, or the reported command is not the resolved one (an equivalent-or-stricter variant is fine), run the fast tier in the parent before deciding.
   - **Pass**: mark the batch's items `[x]` — a cycle returned with `red_confirmed=false` still counts as completed; mark it and surface its note in the final report. Then append `discovered_tests` from the result as new unchecked `Test:` items right after the current position (the tdd skill's living-list rule; in a phased plan, inside the current phase — never past its boundary), with two gates. Skip any entry whose tested behavior an existing plan item, checked or unchecked, already covers — compare behaviors, not wording, and skip when the existing item subsumes the entry — noting the skip in the final report. Append only decidable, implementable test behaviors within the plan's Goal — an entry carrying an open design question ("decide whether…") is never appended; collect it for the final report, or ask the user right away when the remaining items depend on the answer. An entry that answers or presupposes an already-escalated question is treated as the question itself, not as a test. Keep a running list of escalated open questions and pass it into every later dispatch's Context (the template's "Open design questions" line), so fresh sub-agents do not re-propose them.
   - **Fail** (the implementer reports a failing run, or the parent's spot-run fails): one fix pass — a fix dispatch for a delegated batch, a direct fix for a direct batch — then stop if it fails again, per the recovery policy in `references/implementer-dispatch.md`.
   - **`blocked` result**: stop and relay the sub-agent's reason to the user, following the early-stop report contract (step 3).
   - **Milestone**: when the batch completes a phase or the plan, run the full-suite command in the parent. A failure is handled by the recovery policy; a pass is recorded together with the phase's `After this phase:` outcome. The full suite also runs before the final commit suggestion — the plan-completion run is that run unless files changed after it.

7. **Repeat** steps 4–6 until no unchecked item remains — appended discovered tests join the loop. Phase completion is reported, not paused on: state the phase outcome and the full-suite result, then continue with the next phase. Pause only when the user asked for a checkpoint (e.g. "stop after each phase", "let me commit between phases") or when a decision or permission the next batch depends on is still open — and say which instruction or question causes the pause. One growth guard, evaluated before each append in step 6: if appending an entry would make the appended items outnumber the plan's original unchecked items, do not append it — hand it (and any later discoveries) to the user as proposed follow-ups, and finish only the items already in the plan (doubling the plan's scope is the user's decision, not the orchestrator's). The dedup gate compares against the union of plan items and already-collected follow-up proposals; once the guard has tripped, every later discovery routes to the follow-up list after that same dedup. Then **report**: items completed, files changed (`git status --porcelain`), the final full-suite result, items appended along the way (plus discovered entries skipped as duplicates or escalated as design questions), any cycles returned with `red_confirmed=false` or a skipped refactor (with their notes — the tdd skill treats both as signals to surface; a `red_confirmed=false` cycle that changed no production code is one signal — "behavior already existed, test kept as a regression guard" — not additionally a skipped refactor), and which batches ran directly versus delegated (and whether dispatch tooling was unavailable). User-facing reports — this one and every early-stop report — are written in the conversation language; repository artifacts (plan items, notes, code, comments) stay in English. Suggest committing via the git-commit skill and, if a review is wanted, the local-review skill. Never commit automatically.

## Red flags (watch for rationalizations)

| Rationalization | Reality |
| --- | --- |
| "Dispatch tooling exists, so every item goes to a sub-agent." | Delegation is chosen per batch by what it buys. Small, clear work runs directly in the parent. |
| "Read every catalog in the parent so no dispatch is ever needed." | Load only the catalogs the batch's decisions need (the selection table). Reading everything defeats the reason delegation exists. |
| "Dispatch several implementer batches in parallel to finish faster." | Increments build on the previous green state and share files. Implementer batches are sequential; only read-only work fans out. |
| "The result says pass — no need to read the evidence." | Read the command, tier, and outcome of every cycle. Missing or inconsistent evidence means a parent spot-run, not trust. |
| "Re-run the full suite after every batch to be safe." | The full suite runs at phase completion, plan completion, and before a commit suggestion. The fast tier is the per-checkpoint scope (tdd skill). |
| "Let the sub-agent tick its own checkbox." | Plan writes are parent-only. Centralized writes keep the plan trustworthy. |
| "The suite failed; keep patching until it is green." | One fix pass, then stop and report. The user decides between reverting and debugging. |
| "Commit after each green cycle to be safe." | Committing is the user's call. Suggest the git-commit skill at the end; never commit inside this skill. |
| "The plan is short, so skip the baseline run." | A broken baseline invalidates every Red signal after it. Always confirm green before the first batch. |
| "A phase just finished — wait for the user before continuing." | Report the phase and continue. Pause only for a checkpoint the user asked for or a decision that blocks the next batch. |

## Additional Resources

### Reference Files

- **`references/implementer-dispatch.md`** — The knowledge-skill selection table (used for direct execution too), batching rules, the dispatch prompt template, the result schema, the recovery policy, and the direct-execution contract.
- **`agents/openai.yaml`** — UI metadata for this skill only.
