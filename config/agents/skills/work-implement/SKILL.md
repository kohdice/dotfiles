---
name: work-implement
description: 'This skill should be used when the user asks to execute a non-TDD work plan or to carry out work without automatically testable application behavior — "execute the work plan", "run the infrastructure plan", "作業プランを実行して", "インフラプランを実装して", "この設定変更をやって" — or says bare "go" after a work plan was created in the same session. It orchestrates plan execution, resolving (or first creating via the work-plan skill) a plan in `.plans/`, dispatching worker sub-agents sequentially for change-and-validate items, re-running every item''s Verify step in the parent before marking it done, executing `Task (apply):` live-state mutations only in the parent and only after explicit user confirmation, and keeping all plan-file writes in the parent. Runtime-neutral (Claude Code, Codex) with an inline fallback when sub-agent dispatch is unavailable. Do NOT use for plan creation only (work-plan skill), for work with automatically testable application behavior (implement skill), or for bare "go" after a TDD plan — the implement skill owns that.'
---

# Work Implement (non-TDD delegation orchestrator)

Execute a work plan by **orchestrating worker sub-agents**, each carrying out a small batch of plan items under the verification discipline below. The parent (this skill) owns five things and never delegates them: the **plan file**, the **dispatch sequence**, the **Verify re-run** after every batch, **every `Task (apply):` execution**, and the **final report**. Sub-agents edit files for their assigned items only, run validation-tier commands only, and return a compact structured result.

The counterpart of TDD's Red-Green gate here is the plan's Verify steps (see the work-plan skill): each item names a command or observable state and its expected outcome. This skill's job is to make those gates actually gate — before-check, change, verify, and parent re-verification — instead of trusting that an edit "should work".

## Verification discipline (per item)

1. **Before-check (Red analog)**: run the item's Verify step before changing anything and confirm the expected outcome does **not** hold yet. If it already holds, that is a signal, not a success — either the work is already done (report it, mark the item `[x]`, move on) or the Verify step does not check what it claims (stop and escalate; never "fix" a Verify step to force a pass). When a before-check is meaningless for the item's nature (e.g., a change-previewing command that errors before the config exists), record it as not checkable and proceed.
2. **Change**: make the item's change, and nothing beyond it.
3. **Verify (Green analog)**: run the Verify step and compare the output against the expected outcome stated in the plan — not merely the exit code. A pass with unexpected extra output (an unplanned resource in a `terraform plan` diff, an extra warning) is a fail until explained.

## Principles

- **Verify, don't trust**: After every dispatch the parent re-runs the batch's Verify steps itself — and the plan's global check command, when Context defines one — before marking any item complete. A sub-agent's "verified" claim is a report, not evidence.
- **Apply stays in the parent**: `Task (apply):` items — live-state mutations — are never dispatched to sub-agents and never run without explicit user confirmation. Sub-agents are constrained to validation-tier commands (validate, dry-run, plan, lint, build).
- **Centralized plan writes**: Only the parent edits the plan file — marking items `[x]`, appending discovered tasks. Sub-agents never write under `.plans/`.
- **Sequential dispatch**: Exactly one worker is in flight at any time. Items build on each other, and concurrent edits break the verified-state invariant.
- **Context economy**: Knowledge-skill bodies load into sub-agent contexts, not the parent (selection table in `references/worker-dispatch.md`). Sub-agents return the structured result, never diffs or full logs.
- **No git writes**: Neither the parent nor any sub-agent commits, pushes, stashes, or changes branches. Build artifacts from mandated verification runs and the plan file under `.plans/` are expected side effects, not violations. When all items are done, suggest a commit (the git-commit skill) and leave the decision to the user.

## Skill locations

Resolve once at the start and reuse:

```bash
SKILLS_DIR="$HOME/.claude/skills"                       # Claude Code
[ -d "$SKILLS_DIR" ] || SKILLS_DIR="$HOME/.agents/skills"  # Codex and other runtimes
```

Every skill referenced below resolves as `$SKILLS_DIR/<name>/SKILL.md` in both runtimes.

## When to use

- The user asks to execute an existing work plan end-to-end.
- The user asks to carry out multi-step work without automatically testable application behavior (infrastructure, configuration, CI/CD, documentation, migrations, housekeeping) — create the plan first via the work-plan skill, then execute it here.
- The user says bare `go` after a work plan was created in the current session.

Do not use when:

- The work has automatically testable application behavior — the implement skill (and the tdd stack) owns that.
- The user asks only to create a plan — the work-plan skill owns that.
- The task is a single trivial step with no plan value (one file edit, one command) — do it directly.
- The goal is reviewing, not executing — the local-review skill owns review.

## Workflow

1. **Resolve the plan**: An explicitly named plan file first, then the plan created in the current session, otherwise look at `.plans/`: exactly one plan matching the request → use it without asking; two or more candidates → list them and ask; none → create one first by following the work-plan skill (planning stays in the parent — it needs the user dialog), then continue here. If work-plan concludes the request belongs to the TDD stack, this skill does not apply either; say so and stop.

2. **Resolve the environment**: Determine `SKILLS_DIR`. From the plan's Context, note the global check command (if any) and the prerequisites (CLIs, auth, environment/workspace names). Confirm the prerequisites hold with read-only commands (`terraform workspace show`, `nix --version`, `gh auth status`, …). A missing prerequisite is an early stop: report what is missing, the plan's untouched state, and how to resume — that minimum is the report contract for every early stop this skill makes.

3. **Confirm the baseline**: Run the global check command once, if defined, and snapshot `git status --porcelain`. If the check already fails, stop and report per the early-stop contract instead of building on a broken baseline. The stop report may include a one-line factual diagnosis, but never proposes or performs fixes — deciding is the user's call.

4. **Form the next batch**: Take the first unchecked `- [ ] Task` item. Default is one item per dispatch — batching rules in `references/worker-dispatch.md`. A `Task (apply):` item always stands alone and is never dispatched. A batch never spans a phase boundary.

5. **Execute the batch**:
   - **`Task:` items** — dispatch one worker with the prompt from `references/worker-dispatch.md`: it names the knowledge skills selected for this batch, pastes the plan's Goal/Context and the item text (including Verify bullets), states the verification discipline, the hard constraints, and the result schema. Wait for the result; never start the next batch early.
   - **`Task (apply):` items** — no dispatch. Present the item to the user: what will run, the Verify expectation, and the Rollback line. Proceed only on explicit confirmation; a confirmation may cover consecutive apply items the user approves together, but silence or a prior general "run the plan" never counts. On confirmation, run the command in the parent, then its Verify step. On refusal, leave the item unchecked and either continue with independent later items or stop and report, as the user directs.
   - Inline fallback is gated on capability, not position: fall back only when the runtime exposes no working dispatch tooling or a dispatch attempt fails. In inline mode, execute in the parent under the same discipline, read the selected knowledge skills directly, and tell the user the run was inline. Apply gating is unchanged.

6. **Verify and record**: Re-run the batch's Verify steps in the parent and compare against the plan's expected outcomes; run the global check command if defined.
   - **Pass**: mark the batch's items `[x]`. An item whose before-check found the outcome already satisfied still counts as completed; mark it and surface the note in the final report. Then append `discovered_tasks` from the result as new unchecked `Task:` items (with their Verify bullets) right after the current position — in a phased plan, inside the current phase. Two gates: skip any entry whose outcome an existing item already covers (compare outcomes, not wording), and never append an entry carrying an open design question or a live-state mutation — an apply-tier discovery is always escalated to the user, never self-appended. Growth guard: if appended items would outnumber the plan's original unchecked items, route further discoveries to a follow-up list for the user instead.
   - **Fail**: dispatch one follow-up fix per the recovery policy in `references/worker-dispatch.md`, then stop if it fails again. Never revert files or roll back applied state on your own — for a failed apply item, present the item's Rollback line and let the user decide.
   - **`blocked` result**: stop and relay the reason per the early-stop contract.

7. **Repeat** steps 4–6 until no unchecked item remains. **Phase checkpoint**: when the plan has phase headings and a verified batch completes a phase, pause — report the phase's `After this phase:` outcome and the verification results, suggest committing the phase via the git-commit skill, and continue only after the user responds (skip the pause only when the user already asked to run the whole plan without stopping — this never waives apply confirmations). Then **report**: items completed, files changed (`git status --porcelain`), Verify and global-check results, apply items executed (with confirmations) or refused, items appended or routed to the follow-up list, before-checks that found work already done, and the mode (delegated or inline). User-facing reports are written in the conversation language; repository artifacts (plan items, code, comments) stay in English. Suggest committing via the git-commit skill. Never commit automatically.

## Red flags (watch for rationalizations)

| Rationalization                                                  | Reality                                                                                                          |
| ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| "The apply is small — run it without asking."                    | Live-state mutations always get explicit confirmation. Small applies have large blast radii.                     |
| "The sub-agent can run the apply; it has the context."           | Apply items never leave the parent. A sub-agent cannot be interrupted by the user mid-mutation.                  |
| "The command exited 0 — the item is verified."                   | The gate is the expected outcome, not the exit code. Compare the output against what the plan says it must show. |
| "Skip the before-check; the change obviously isn't applied yet." | An already-satisfied expectation is exactly the signal the before-check exists to catch. Run it.                 |
| "The sub-agent already verified — skip the parent re-run."       | The parent re-verifies every batch itself. A claim in a result object is not evidence.                           |
| "The Verify step is too strict; loosen it so the item passes."   | Weakening a gate to pass it defeats the plan. Stop and escalate the mismatch instead.                            |
| "Verification failed; I'll just patch it up in the parent."      | One fix dispatch, then stop and report. Parent patching mixes modes.                                             |
| "Roll back the failed apply so the report looks clean."          | Rollback is a state mutation like any other: present the Rollback line and let the user decide.                  |
| "Commit after each phase to be safe."                            | Committing is the user's call. Suggest the git-commit skill at checkpoints; never commit inside this skill.      |

## Additional Resources

### Reference Files

- **`references/worker-dispatch.md`** — The knowledge-skill selection table, the dispatch prompt template, the result schema, batching rules, the fix-dispatch recovery policy, and the inline fallback contract.
- **`agents/openai.yaml`** — UI metadata for this skill only.
