---
name: tdd
description: 'This skill should be used only when the user explicitly invokes `/tdd` (with or without a plan filename) to execute a TDD plan from `.plans/` inline in the current context, or when the implement skill falls back to inline execution because sub-agent dispatch is unavailable. It defines Kent Beck''s Red-Green-Refactor and Tidy First discipline, and serves as the discipline reference that the implement skill''s implementer sub-agents read before writing code. Do NOT use this skill when the user says bare "go" or asks to implement a feature or plan — the implement skill owns those and dispatches sub-agents that read this skill. Do NOT use when the user is asking to create a new TDD plan — that is handled by the tdd-plan skill.'
---

# TDD (Test-Driven Development)

## Overview

Guide development following Kent Beck's TDD and Tidy First principles. Follow an explicit plan file whenever the user provides one. Bare `go` does not trigger this skill (the implement skill owns it); however, when this skill is already executing as the implement skill's inline fallback and the user said bare `go` right after creating a plan in the same session, continue from that newly created plan. When the user invokes `/tdd <plan-file>` or otherwise supplies a filename, use that plan instead. User-facing questions and reports follow the ambient conversation language conventions (e.g., CLAUDE.md); this skill's English examples do not override them.

## Plan Management

### Plan Location

Plans are stored in the `.plans/` directory (created by the tdd-plan skill). Resolve bare filenames relative to `.plans/`.

### Which Plan File to Use

Use this precedence order:

1. If the user provides a plan filename or path, use it.
2. If the user said bare `go` (reaching this skill via the implement skill's inline fallback) and a plan was created in the current session, use that most recent current-session plan.
3. If `/tdd` is invoked without a filename and there is no current-session plan, ask the user which existing plan in `.plans/` to use. List, at minimum, each plan file's name together with its title line (reading the plan files for this is a sanctioned read-only step; adding further read-only context such as remaining-item counts is welcome) so the user can choose by name. While waiting for the answer, any read-only inspection is fine; make no writes and no state-changing runs.

Resolve bare filenames such as `watch-refresh.md` relative to `.plans/`, and accept explicit paths such as `.plans/watch-refresh.md`.

### Plan Format

Each plan item uses a checkbox to track progress. Plans contain two item types:

```markdown
- [ ] Test: description of what to test
- [x] Test: already completed test
- [ ] Test (integration): resource-heavy test (containers, database, network) — see Test Tiers and Run Cost
- [ ] Refactor: structural change that prepares for the next test
```

Large plans may group items under `### Phase N: <milestone>` headings, each followed by an `After this phase:` line (created per the tdd-plan skill's phase-division rules). Headings are structure only — finding the next item still means scanning for the first unchecked checkbox across the whole file.

### Finding the Next Item

1. Resolve the plan using the precedence rules above
2. Scan for the first unchecked item (`- [ ]`)
3. If it is a `Test:` or `Test (integration):` item, implement it through the Red-Green-Refactor cycle below (for `Test (integration):`, apply the Test Tiers and Run Cost rules)
4. If it is a `Refactor:` item, run all tests to confirm they pass (a cached pass is acceptable for this before-run — see the TDD Cycle section), apply the structural change without altering behavior, run all tests again to confirm identical results — identical meaning the same set of test names with all of them passing (see Structural Changes) — then mark it `[x]` and proceed to the next item
5. When marking an item `[x]` completes a phase (it is the last unchecked item before the next phase heading or the end of the list), report the phase as complete with its `After this phase:` outcome and suggest committing the phase as one logical unit (Commit Discipline applies; never commit uninvited)

### Discovered Tests (Keep the Plan a Living List)

While implementing, you may discover behavior that needs a test but is not in the plan — an edge case, an error path, a missing increment. Do not implement it immediately, and do not silently drop it:

1. Append it to the plan as a new unchecked `- [ ] Test:` item at the appropriate position (usually right after the current item; in a phased plan, inside the current phase — it belongs to the behavior increment in progress)
2. Continue the current Red-Green-Refactor cycle without expanding its scope
3. Mention the appended item in the turn summary

A discovered item must describe observable application behavior required by the feature under development. Do not append speculative tests unrelated to the requested behavior. Never append a test that verifies a third-party library's or the standard library's own responsibility — test only this project's code (Kent Beck's rule: test third-party code only if you have reason to distrust it).

### When the Plan Is Complete

If no unchecked item remains, do not invent new work. Report that all plan items are complete, summarize the final state, and suggest either committing the finished work or creating a new plan with the tdd-plan skill.

## TDD Cycle: Red, Green, Refactor

Execute each test through three distinct phases. In this skill, "run all tests" means the fast tier of the project's test suite (see Test Tiers and Run Cost below), not just the file currently being edited. Run that tier in full at every checkpoint. If even the fast tier is prohibitively slow, state the scoped subset you are running and why. A cached passing result (e.g., Go's `(cached)`) is acceptable only for runs that confirm an unchanged state, such as the baseline before Red or before a `Refactor:` item; any run whose purpose is to observe the effect of a change just made — the Red confirmation, the Green pass, the post-refactor check — must actually execute the tests (e.g., `go test -count=1`).

### Test Tiers and Run Cost

Split the suite into two tiers and run each at the right time:

- **Fast tier** (unit tests: no containers, no network, no real external services): this is what "run all tests" means at every Red-Green-Refactor checkpoint.
- **Slow tier** (integration/E2E tests using containers, databases, or the network — typically behind build tags, `-short` exclusions, or markers): run only when a plan item marked `Test (integration):` is itself the current item, when the plan is complete, or before a commit. Never run the slow tier as part of a routine checkpoint.

Identify the project's tier mechanism (build tags, test markers, separate packages) during the first baseline run and state which tier each subsequent run covers. A `Test (integration):` plan item goes through the same Red-Green-Refactor cycle, but its Red and Green confirmation runs execute that integration test (plus the fast tier), not the whole slow tier.

### Phase 1: Red (Write a Failing Test)

Before writing the new test, run all tests once. If the suite is already failing, stop and report the failures instead of building on a broken baseline.

1. Write one test that defines a small increment of functionality
2. Use descriptive test names (e.g., `test "parses short option clusters"`)
3. Run all tests to confirm the new test fails
4. Verify the failure message is clear and informative. In a compiled language, a compile/build error caused by the not-yet-implemented symbol IS a valid Red failure — do not write production stubs just to turn it into an assertion failure
5. If the new test passes without any production code change, stop — that is a signal, not a success. Either the behavior already exists (report this, mark the item `[x]`, and move on) or the test does not exercise what it claims to (fix the test until it fails for the right reason). To decide which, inspect the production code path the test exercises: if it genuinely implements the planned behavior, the behavior already exists; if the assertions do not reach or do not constrain that path, the test is at fault. Never write production code for a test that never failed

### Phase 2: Green (Make It Pass)

1. Write the minimum code to make the failing test pass, using Kent Beck's Green strategies: **Obvious Implementation** when the real code is trivially clear, **Fake It** (return a constant, generalize in a later cycle) when it is not, and **Triangulation** (generalize only when a second example demands it) when the right abstraction is uncertain
2. Do not add extra functionality beyond what the test requires. This applies to API signatures too: choose the minimal signature the current test demands, even when a later plan item will predictably force a change (e.g., adding an error return) — signature churn between cycles is an expected cost of the discipline, not a defect to pre-empt
3. Run all tests to confirm they all pass
4. Mark the test as complete in the plan (`- [ ]` to `- [x]`)

### Phase 3: Refactor (Tidy First)

1. Refactor only when all tests are passing
2. Apply one refactoring change at a time
3. Run all tests after each refactoring step
4. Stop refactoring when the code is clean enough

### When to Skip or Stop Phase 3

- **Skip entirely** when the Green code has no visible duplication, names already express intent, and each method has a single responsibility. Phase 3 is optional per cycle, not mandatory — report it as skipped in the final turn summary (e.g., "Phase 3 skipped: code already meets the bar") rather than inventing trivial refactors.
- **"Clean enough" = stop** when all three hold: no duplication across the code just written, names express intent, methods have single responsibility. Do not chase subjective polish beyond this bar.
- Ad-hoc Phase 3 refactoring does not update plan checkboxes — record such structural decisions in commit messages or a separate log, not in the plan file. Only planned `- [ ] Refactor:` items get marked `[x]`, as described in Finding the Next Item.

### Standalone Refactor (No Red/Green This Turn)

When the user requests refactoring outside a Red-Green cycle (for example, all plan tests already pass and the user asks to remove duplication), run Phase 3 on its own. The invariant "all tests pass before AND after" still applies. Do not add or modify tests during a standalone refactor — that would be a behavioral change.

## Tidy First: Structural vs. Behavioral Changes

Separate all changes into two distinct types. Never mix them.

### Structural Changes (no behavior change)

- Renaming variables, functions, or types
- Extracting methods or modules
- Moving code to a different location
- Reorganizing imports

To validate: run all tests before AND after, capturing test names on both runs (e.g., verbose or list output) so the sets can be compared. Results must be identical, meaning the same set of test names with all of them passing — a run that passes because tests were accidentally deleted is not identical. Tests are the only required gate for a structural change; compiler/linter warnings need to be resolved by commit time (see Commit Discipline), not at every refactor step, though running such checks early is welcome.

### Behavioral Changes (new or modified functionality)

- Adding a new test
- Implementing code to pass a test
- Fixing a defect

To validate: a new test must fail before (Red) and pass after (Green).

## Commit Discipline

This section applies only when a commit is being created (the user requests a commit, or a logical unit is complete and a commit is intended). If the current task does not involve committing, skip this section entirely — do not invent commits on your own.

Commit only when ALL of the following are true:

1. All tests pass
2. All compiler/linter warnings are resolved
3. The change represents a single logical unit of work
4. The commit message states whether the change is structural or behavioral

Use small, frequent commits. Structural and behavioral commits are always separate.

## Defect Fix Workflow

When fixing a defect, follow this specific order:

1. Write an API-level failing test that demonstrates the defect
2. Write the smallest possible test that replicates the root cause
3. Implement the fix to make both tests pass

## Code Quality Standards

- Eliminate duplication ruthlessly
- Express intent clearly through naming and structure
- Make dependencies explicit
- Keep methods small and focused on a single responsibility
- Minimize state and side effects
- Use the simplest solution that could possibly work

## Refactoring Guidelines

- Use established refactoring patterns with their proper names
- Prioritize refactorings that remove duplication or improve clarity
- Make one refactoring change at a time
- Run tests after each refactoring step

## Complete Workflow Example

Resolve the plan per the precedence rules (bare `go` → most recent current-session plan; `/tdd <file>` → that file in `.plans/`), then:

1. Open the resolved plan file to find the next unmarked item (handle a `Refactor:` item as described in Finding the Next Item)
2. For a `Test:` item, write a simple failing test (Red)
3. Run all tests to confirm the new test fails
4. Implement the bare minimum to make it pass (Green)
5. Run all tests to confirm they all pass
6. Mark the item as `[x]` in the plan
7. Make any necessary structural changes (Tidy First), running tests after each
8. Report what was done and what the next unmarked item is
