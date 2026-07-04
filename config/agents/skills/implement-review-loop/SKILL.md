---
name: implement-review-loop
description: This skill should be used when the user asks, in one request, to implement and iterate with review until findings are resolved — "implement <feature> and fix the review findings", "レビューが通るまで実装して", "実装してレビュー指摘を潰して仕上げて", "レビューつきで実装して", "implement with a review loop". It orchestrates a bounded implement → review → fix loop: the implement skill's workflow builds the feature, the local-review skill's workflow reviews the resulting diff with fresh reviewer sub-agents each round, and high-severity (blocking) findings are fixed via fix dispatches (optionally medium too, when the user asks for a stricter gate up front) — capped at 2 fix rounds (3 only when the user explicitly asks for more; 1 in the inline fallback when sub-agent dispatch is unavailable), with a findings ledger that stops the loop when a fixed finding recurs. Findings below the gate are reported, never auto-fixed. Do NOT use for implementation without a review loop (implement skill), review without applying fixes (local-review skill), plan creation only (tdd-plan skill), fixing findings from a review that already happened (follow-up implementation, not a loop), or work with no testable application behavior.
---

# Implement-Review Loop (bounded quality loop orchestrator)

Implement a feature, review it, and fix blocking findings — in a **bounded loop with objective stop conditions**, not "until the reviewers are silent". LLM reviewers do not converge to zero findings: advisory observations never run dry, fresh reviewers surface different issues each round, and chasing silence shapes code to please reviewers instead of users (Goodhart's law). This skill therefore gates only on **high-severity findings** and enforces a **hard cap on fix rounds**; everything else is reported to the user, who decides.

This skill is a thin orchestrator. It owns exactly three things: **loop control** (the gate, the round counter, the stop conditions), the **findings ledger** (cross-round recurrence detection), and the **final report**. The implementation and review phases are not restated here — they run by reference to the implement and local-review skills, whose workflows, dispatch contracts, and invariants apply unchanged.

## Principles

- **Composition by reference, not restatement**: The implement skill owns how code gets written (plan resolution, sequential TDD dispatch, suite verification). The local-review skill owns how code gets reviewed (lens selection, parallel read-only dispatch, synthesis). This skill adds only the loop around them and duplicates neither.
- **Blocking vs advisory**: Only `high`-severity findings block the loop (add `medium` only when the user explicitly asks for a stricter gate). Everything else — including simplicity findings, which are advisory by design — goes into the final report untouched. Auto-fixing advisory findings is how a loop starts optimizing for the reviewer instead of the user.
- **Hard cap, graceful exit**: Reaching the fix-round cap is a normal outcome, not a failure. Exit with the remaining findings listed; never bargain for "one more round".
- **Fresh reviewers every round**: Each review round dispatches new reviewer sub-agents. A reviewer that saw the previous round has learned the code and cannot judge it cold.
- **Verify, don't trust**: The parent re-runs the full test suite after every fix dispatch, exactly as the implement skill requires. A fix that turns the suite red is handled by the recovery policy in `implementer-dispatch.md`, not by parent patching.
- **No git writes**: Neither the parent nor any sub-agent commits, pushes, stashes, or changes branches. At the end, suggest the git-commit skill and leave the decision to the user.

## When to use

- The user asks to implement something **and** to iterate on review findings in the same request.
- The user asks to take an existing TDD plan all the way to "review-clean" in one go.

Do not use when:

- The user asks only to implement — the implement skill owns that (it already suggests a review at the end; the user triggers it).
- The user asks only to review — the local-review skill owns that, and it never applies fixes.
- The user asks to fix findings from a review that already happened — that is a follow-up implementation task, not a loop.
- The work has no testable application behavior — the implement skill does not apply, so neither does this loop.

## Skill and reference locations

Resolve `SKILLS_DIR` once, per the implement skill's "Skill locations" section. This skill's phases use these documents directly (one level of reference from this file — do not hop through the other skills' SKILL.md to reach them):

- `$SKILLS_DIR/implement/SKILL.md` — the implementation workflow (phase 1) and its invariants.
- `$SKILLS_DIR/implement/references/implementer-dispatch.md` — the dispatch contract, result schema, and recovery policy that fix dispatches (phase 4) adapt.
- `$SKILLS_DIR/local-review/SKILL.md` — the review workflow (phase 2) and its read-only invariants.
- `$SKILLS_DIR/local-review/references/review-lenses.md` — the lens catalog, findings schema, and severity definitions the gate (phase 3) depends on.

## Workflow

1. **Implement**: Run the implement skill's workflow end to end (plan resolution, baseline, sequential dispatch, per-batch suite verification). Defer its final commit suggestion — the loop is not done. If the implement skill concludes the request has no testable behavior, this skill does not apply either; say so and stop. Record the baseline commit hash (`git rev-parse HEAD`) and the set of files the loop has changed (`git status --porcelain`) — the file set is the review scope, updated after every fix round. If HEAD differs from the recorded hash at exit, attribute the movement in the report (this loop never moves it; concurrent external activity can).

2. **Review**: Run the local-review skill's workflow over the loop's changes: the working diff when the tree was clean at loop start, otherwise the recorded file list as a path scope (pre-existing unrelated changes must not reach the gate). If the user named a base, use the branch diff instead. Orchestration bookkeeping (the plan file, anything under `.plans/`) is never part of the review scope, regardless of git tracking status. Lens selection, dispatch, and synthesis follow `review-lenses.md` unchanged. Dispatch fresh reviewer sub-agents — never reuse a previous round's.

3. **Gate and ledger**:
   - **Gate**: blocking = findings with severity `high` (plus `medium` only if the user asked for a stricter gate at the start — never tighten the gate mid-loop). Non-blocking findings, however trivial their fixes look, pass through to step 6 unmodified. If there are no blocking findings, go to step 6.
   - **Ledger check**: match each blocking finding against the ledger (format below). A finding that matches one already marked fixed in an earlier round means the fix did not land — **stop the loop** and report it (step 6), flagging the recurrence. Mechanical repetition will not resolve what a targeted fix could not.
   - Record every new blocking finding in the ledger — before the cap check, so a cap exit can mark them.
   - **Cap check**: if the fix-round cap (2 by default; 3 only on explicit user request; 1 in inline fallback) is already spent, mark the recorded findings `unfixed — cap reached` and go to step 6 with them listed.

4. **Fix**: For each blocking finding, dispatch **one** fix sub-agent, sequentially (concurrent edits break the all-tests-green invariant). The dispatch adapts the contract in `implementer-dispatch.md`:
   - The assigned item is the finding — path, line, severity, lens, body, and proposed fix, pasted verbatim from the review report.
   - Knowledge skills: `tdd` + the idiom skill for the file's language + `simplicity-patterns`, plus the finding lens's own knowledge skill when it has one (`performance-patterns`, `architecture-patterns`).
   - Cycle discipline: a `correctness` finding is treated as a `Test:` item — write a failing test that reproduces the defect when feasible, then fix. Findings from the other lenses are treated as `Refactor:` items — structure or idiom changes with test results identical before and after.
   - Hard constraints, result schema, and the recovery policy (one follow-up fix dispatch on parent-verified suite failure, then stop) apply unchanged from `implementer-dispatch.md`.
   - After each fix dispatch, the parent re-runs the full suite before dispatching the next.
   - Mark the finding fixed in the ledger, with the round number.

5. **Loop**: Increment the fix-round counter and return to step 2 for a fresh review of the updated diff.

6. **Report**: One final report containing: rounds used — fix rounds spent out of the cap, plus the number of review rounds run; blocking findings fixed (from the ledger); remaining blocking findings if the cap was hit or a recurrence stopped the loop; all advisory/lower-severity findings from the last review, untouched; the final suite result — the most recent parent-run full-suite result, which is the implement phase's final run when no fix dispatch occurred (do not re-run the suite just for the report; suite re-runs are tied to fix dispatches); and the mode (delegated or inline). Report language precedence: a standing user-level language directive (e.g. the user's CLAUDE.md) > the conversation language; code, identifiers, and paths stay in English (the same rule as local-review's synthesis). State the baseline hash outcome — `HEAD unchanged from baseline <hash>` in the normal case, or the attributed movement. Suggest committing via the git-commit skill. Never commit automatically.

**Inline fallback**: When sub-agent dispatch is unavailable, both phases already define inline modes — use them, cap the loop at 1 fix round (inline context accumulates fast), and state in the report that the run was inline. A fix dispatch (and its one recovery dispatch) degrades to an inline fix pass in the parent under the same constraints, discipline mapping, and one-recovery limit.

## Stop conditions

The loop ends when the **first** of these fires:

| Condition                                                               | Meaning         | Exit                                                        |
| ----------------------------------------------------------------------- | --------------- | ----------------------------------------------------------- |
| A review round returns zero blocking findings                           | Converged       | Normal — report advisory findings and finish                |
| Fix-round cap reached (2 default / 3 on explicit request / 1 inline)    | Resource cutoff | Normal — list remaining blocking findings                   |
| A finding marked fixed in the ledger recurs                             | Fix not landing | Stop — report the recurrence for the user to judge          |
| The suite stays red after a fix dispatch plus its one recovery dispatch | Regression      | Stop — per the recovery policy in `implementer-dispatch.md` |

## Findings ledger

The parent keeps one ledger for the whole loop (in conversation, not on disk). One entry per blocking finding:

```
- <path> [<lens>/<severity>] <one-line defect summary>
  - first seen: round N / fixed: round M / recurred: round K (if ever)
```

When a finding is left unfixed at a cap exit, `unfixed — cap reached` replaces the whole `fixed: round M` segment. One example of each state:

```
- internal/parse.go [correctness/high] nil-map write when header row is absent
  - first seen: round 1 / fixed: round 1
- internal/parse.go [correctness/high] off-by-one skips the final record
  - first seen: round 3 / unfixed — cap reached
```

Matching rule: same `path`, same `lens`, and substantially the same defect. Match on the defect description, **not** the line number — fixes shift lines. When unsure whether a new finding is a recurrence or a genuinely new defect at the same spot, treat it as new (a false recurrence-stop discards a round the cap already limits anyway).

## Red flags (watch for rationalizations)

| Rationalization                                                   | Reality                                                                                                                             |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| "One more round would clear the remaining findings."              | The cap is a hard limit. Reaching it is a normal exit — list what remains and hand it to the user.                                  |
| "This advisory finding is easy — fix it while I'm here."          | Advisory findings are the user's call. Auto-fixing them optimizes for the reviewer, not the user.                                   |
| "Reuse the same reviewers so the findings stay consistent."       | A reviewer that saw the last round cannot judge cold. Fresh dispatch every round; consistency comes from the ledger, not the agent. |
| "The fix is trivial — patch it in the parent, skip the dispatch." | Parent patching loads the knowledge skills this orchestration exists to keep out of the parent, and mixes modes.                    |
| "The recurred finding just needs a slightly different fix."       | A recurrence means the fix class is wrong, not the wording. Stop and report; the user decides the next move.                        |
| "Tighten the gate to medium now that high is clean."              | Moving the gate mid-loop is how a bounded loop becomes unbounded. The gate is fixed before round 1.                                 |
| "Skip the suite re-run; the fix was a one-liner."                 | Every fix dispatch is followed by a parent suite run. A claim in a result object is not evidence.                                   |

## Additional Resources

### Reference Files

- **`$SKILLS_DIR/implement/references/implementer-dispatch.md`** — dispatch contract, result schema, batching, and recovery policy that fix dispatches adapt.
- **`$SKILLS_DIR/local-review/references/review-lenses.md`** — lens catalog, findings schema, and the severity definitions the gate depends on.
- **`agents/openai.yaml`** — UI metadata for this skill only.
