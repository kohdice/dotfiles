---
name: tdd
description: 'This skill should be used when developing features following Kent Beck''s Test-Driven Development (TDD) and Tidy First principles. Triggers when the user says "go" after creating a TDD plan in the same session, invokes `/tdd` with a plan filename from `.plans/`, asks to implement the next test from an existing plan, or requests plan-driven execution. If `/tdd` is invoked without a filename and there is no current-session plan, ask which plan in `.plans/` to use. Do NOT use this skill when the user is asking to create a new TDD plan — that is handled by the tdd-plan skill.'
---

# TDD (Test-Driven Development)

## Overview

Guide development following Kent Beck's TDD and Tidy First principles. Follow an explicit plan file whenever the user provides one. When the user says bare `go` immediately after creating a plan in the same session, continue from that newly created plan. When the user invokes `/tdd <plan-file>` or otherwise supplies a filename, use that plan instead.

## Plan Management

### Plan Location

Plans are stored in the `.plans/` directory. The file name is chosen dynamically at creation time (e.g., `sequence-parser.md`, `mermaid-renderer.md`). Never place plan files at the project root.

### Which Plan File to Use

Use this precedence order:

1. If the user provides a plan filename or path, use it.
2. If the user says bare `go` and a plan was created in the current session, use that most recent current-session plan.
3. If `/tdd` is invoked without a filename and there is no current-session plan, ask the user which existing plan in `.plans/` to use. List the available plan files so the user can choose by name.

Resolve bare filenames such as `watch-refresh.md` relative to `.plans/`, and accept explicit paths such as `.plans/watch-refresh.md`.

### Plan Format

Each test case in the plan uses a checkbox to track progress:

```markdown
- [ ] Test: description of what to test
- [x] Test: already completed test
```

### Finding the Next Test

1. Resolve the plan using the precedence rules above
2. Scan for the first unchecked item (`- [ ]`)
3. That item is the next test to implement

## TDD Cycle: Red, Green, Refactor

Execute each test through three distinct phases. In this skill, "run all tests" means the project's complete test suite, not just the file currently being edited. Run the full suite at every checkpoint. If the suite is prohibitively slow, state the scoped subset you are running and why.

### Phase 1: Red (Write a Failing Test)

1. Write one test that defines a small increment of functionality
2. Use descriptive test names (e.g., `test "parses short option clusters"`)
3. Run all tests to confirm the new test fails
4. Verify the failure message is clear and informative

### Phase 2: Green (Make It Pass)

1. Write the minimum code to make the failing test pass
2. Do not add extra functionality beyond what the test requires
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
- Refactor does not update plan checkboxes. Plan items track behavioral increments; record structural decisions in commit messages or a separate log, not in the plan file.

### Standalone Refactor (No Red/Green This Turn)

When the user requests refactoring outside a Red-Green cycle (for example, all plan tests already pass and the user asks to remove duplication), run Phase 3 on its own. The invariant "all tests pass before AND after" still applies. Do not add or modify tests during a standalone refactor — that would be a behavioral change.

## Tidy First: Structural vs. Behavioral Changes

Separate all changes into two distinct types. Never mix them.

### Structural Changes (no behavior change)

- Renaming variables, functions, or types
- Extracting methods or modules
- Moving code to a different location
- Reorganizing imports

To validate: run all tests before AND after. Results must be identical.

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

When the user says bare `go` right after planning:

1. Open the most recent plan file created in the current session to find the next unmarked test
2. Write a simple failing test for that item (Red)
3. Run all tests to confirm the new test fails
4. Implement the bare minimum to make it pass (Green)
5. Run all tests to confirm they all pass
6. Mark the item as `[x]` in the plan
7. Make any necessary structural changes (Tidy First), running tests after each
8. Report what was done and what the next unmarked test is

When the user says `/tdd watch-refresh.md`:

1. Open `.plans/watch-refresh.md` to find the next unmarked test
2. Write a simple failing test for that item (Red)
3. Run all tests to confirm the new test fails
4. Implement the bare minimum to make it pass (Green)
5. Run all tests to confirm they all pass
6. Mark the item as `[x]` in the plan
7. Make any necessary structural changes (Tidy First), running tests after each
8. Report what was done and what the next unmarked test is
