---
name: implement
description: This skill should be used when the user asks to implement application code with testable behavior — "implement <feature>", "〜を実装して", "execute the TDD plan", "プランを実装して", "サブエージェントで実装して" — or says bare "go" after a TDD plan was created in the same session. It orchestrates TDD implementation, resolving (or first creating via the tdd-plan skill) a plan in `.plans/`, dispatching implementer sub-agents sequentially — each following the tdd skill's Red-Green-Refactor discipline and loading the required knowledge skills in its own context so the parent context stays flat — re-running the full test suite after every dispatch, and keeping all plan-file writes in the parent. Runtime-neutral (Claude Code, Codex) with an inline fallback when sub-agent dispatch is unavailable. Do NOT use for plan creation only (tdd-plan skill), an explicit `/tdd` invocation for inline execution (tdd skill), or requests to implement and iterate on review findings in one go (implement-review-loop skill).
---

# Implement (TDD delegation orchestrator)

Implement application code by **orchestrating implementer sub-agents**, each executing a small batch of TDD plan items under the tdd skill's Red-Green-Refactor discipline. The parent (this skill) owns four things and never delegates them: the **plan file**, the **dispatch sequence**, the **full-suite verification** after every batch, and the **final report**. Sub-agents edit source and test files for their assigned items only and return a compact structured result.

The point is context economy. Writing code correctly requires the language idiom skill (`c-idioms` / `go-idioms` / `rust-idioms` / `zig-idioms`) plus `simplicity-patterns` plus, where relevant, `performance-patterns` and `architecture-patterns` — catalogs that would otherwise all load into the parent context and stay there for the whole session. This skill moves those loads into each sub-agent's fresh context: the parent never reads a knowledge-skill body, and every dispatch starts clean.

This skill is runtime-neutral: it works in Claude Code and Codex, prefers sub-agent dispatch when the runtime offers it, and falls back to inline implementation otherwise. It never depends on runtime-specific named agents or skills.

## Principles

- **Context economy first**: The parent never reads knowledge-skill bodies; sub-agents load them fresh per dispatch. Sub-agents return the structured result defined in `references/implementer-dispatch.md` — never diffs, file dumps, or full test logs.
- **Centralized plan writes**: Only the parent edits the plan file — marking items `[x]`, appending discovered tests. Sub-agents never write under `.plans/`.
- **Sequential dispatch**: Exactly one implementer is in flight at any time. TDD increments build on each other, and concurrent source edits break the all-tests-green invariant. This differs deliberately from review orchestrators, which fan out in parallel.
- **Discipline by reference, not restatement**: The Red-Green-Refactor rules live in the tdd skill; each sub-agent reads that skill's `SKILL.md` and follows it. This skill defines orchestration only and does not duplicate the discipline.
- **Verify, don't trust**: After every dispatch the parent re-runs the full test suite itself before marking any item complete. A sub-agent's "tests pass" claim is a report, not evidence.
- **No git writes**: Neither the parent nor any sub-agent commits, pushes, stashes, or changes branches. When all items are done, suggest a commit (the git-commit skill) and leave the decision to the user.

## Skill locations

Shared skills live in one directory per runtime. Resolve once at the start and reuse:

```bash
SKILLS_DIR="$HOME/.claude/skills"                       # Claude Code
[ -d "$SKILLS_DIR" ] || SKILLS_DIR="$HOME/.agents/skills"  # Codex and other runtimes
```

Every skill referenced below (`tdd`, `tdd-plan`, the idiom skills, the pattern skills) resolves as `$SKILLS_DIR/<name>/SKILL.md` in both runtimes.

## When to use

- The user asks to implement a feature, behavior change, or bug fix with automatically testable behavior.
- The user asks to execute an existing TDD plan end-to-end.
- The user says bare `go` after a TDD plan was created in the current session — continue from that plan, delegating item by item.

Do not use when:

- The user explicitly invokes `/tdd` to execute the plan inline in the current context — the tdd skill owns that.
- The user asks only to create a plan — the tdd-plan skill owns that.
- The work has no testable application behavior (docs, configuration, CI, housekeeping) — TDD does not apply; handle it directly without this skill.
- The goal is reviewing code, not writing it — the local-review skill owns that.

## Workflow

1. **Resolve the plan**: Use the tdd skill's precedence — an explicitly named plan file first, then the plan created in the current session, otherwise list `.plans/` and ask. If no plan exists for the requested feature, create one first by following the tdd-plan skill (planning stays in the parent — it needs the user dialog), then continue here. If tdd-plan concludes the request has no testable behavior, this skill does not apply either; say so and stop.

2. **Resolve the environment**: Determine `SKILLS_DIR` (above). Detect the target language from the plan's Context section and the files it names. Resolve the project's full-suite test command from its build files or docs (`go.mod` → `go test ./...`, `Cargo.toml` → `cargo test`, `build.zig` → `zig build test`, C → `ctest` / `make test` / the Makefile's check target). Both values go into every dispatch.

3. **Confirm the baseline**: Run the full suite once. If it is already failing, stop and report the failures instead of dispatching onto a broken baseline (the tdd skill's own rule).

4. **Form the next batch**: Take the first unchecked plan item. Default is one item per dispatch — full batching rules in `references/implementer-dispatch.md`.

5. **Dispatch one implementer**: Send the dispatch prompt from `references/implementer-dispatch.md` — it names the skills to read (tdd + the knowledge skills selected for this batch), pastes the plan's Goal/Context and the item text, and states the hard constraints and the result schema. Wait for the result; never start the next batch early.
   - If sub-agents cannot be dispatched at all (the runtime exposes no dispatch tooling, or this skill is itself running inside a sub-agent), fall back to inline mode: implement in the parent following the tdd skill, read the same knowledge skills directly (accepting the context cost), and tell the user the run was inline.

6. **Verify and record**: Run the full suite in the parent.
   - **Pass**: mark the batch's items `[x]` in the plan; append any `discovered_tests` from the result as new unchecked `Test:` items right after the current position (the tdd skill's living-list rule).
   - **Fail**: dispatch one follow-up fix, then stop if it fails again — per the recovery policy in `references/implementer-dispatch.md`.
   - **`blocked` result**: stop and relay the sub-agent's reason to the user.

7. **Repeat** steps 4–6 until no unchecked item remains, then **report**: items completed, files changed (`git status --porcelain`), final suite result, items appended along the way, any cycles returned with `red_confirmed=false` or a skipped refactor (with their notes — the tdd skill treats both as signals to surface), and the mode (delegated or inline). Suggest committing via the git-commit skill and, if a review is wanted, the local-review skill. Never commit automatically.

## Red flags (watch for rationalizations)

| Rationalization                                                   | Reality                                                                                                                                |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| "Read the idiom/pattern skills in the parent to save dispatches." | That recreates the exact context accumulation this skill exists to avoid. Only sub-agents (or the declared inline fallback) read them. |
| "Dispatch several items in parallel to finish faster."            | Concurrent edits conflict and break the all-tests-green invariant. Dispatch is strictly sequential.                                    |
| "The sub-agent already ran the suite — skip re-running it."       | The parent verifies every batch itself. A claim in a result object is not evidence.                                                    |
| "Let the sub-agent tick its own checkbox."                        | Plan writes are parent-only. Centralized writes keep the plan trustworthy.                                                             |
| "The suite failed; I'll just patch it up in the parent."          | One fix dispatch, then stop and report. Parent patching mixes modes and silently loads the skills it must not.                         |
| "Commit after each green cycle to be safe."                       | Committing is the user's call. Suggest the git-commit skill at the end; never commit inside this skill.                                |
| "The plan is short, so skip the baseline run."                    | A broken baseline invalidates every Red signal after it. Always confirm green before the first dispatch.                               |

## Additional Resources

### Reference Files

- **`references/implementer-dispatch.md`** — The knowledge-skill selection table, the dispatch prompt template, the result schema, batching rules, the fix-dispatch recovery policy, and the inline fallback contract.
- **`agents/openai.yaml`** — UI metadata for this skill only.
