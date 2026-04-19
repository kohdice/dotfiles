---
name: tdd
description: 'This skill should be used when developing features following Kent Beck''s Test-Driven Development (TDD) and Tidy First principles. Triggers when the user says "go", asks to follow TDD, requests plan-driven development, or wants to implement the next test from a plan file. Also triggers when the user asks to create a TDD plan, write tests first, or follow Red-Green-Refactor workflow.'
---

# TDD (Test-Driven Development)

## Overview

Guide development following Kent Beck's TDD and Tidy First principles. Always follow the plan file created in the current session. When the user says "go", find the next unmarked test in that plan, implement the test, then implement only enough code to make that test pass.

## Plan Management

### Plan Location

Plans are stored in the `./plans/` directory. Claude Code dynamically creates this directory and plan files when needed. The file name is chosen dynamically at creation time (e.g., `sequence-parser.md`, `mermaid-renderer.md`). Never place plan files at the project root.

### Which Plan File to Use

Use the plan file that was created in the current session. If no plan was created in the current session, ask the user which existing plan in `./plans/` to use.

### Plan Format

Each test case in the plan uses a checkbox to track progress:

```markdown
- [ ] Test: description of what to test
- [x] Test: already completed test
```

### Finding the Next Test

1. Open the plan file for this session
2. Scan for the first unchecked item (`- [ ]`)
3. That item is the next test to implement

## TDD Cycle: Red, Green, Refactor

Execute each test through three distinct phases:

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

When the user says "go":

1. Open the plan file created in this session to find the next unmarked test
2. Write a simple failing test for that item (Red)
3. Run all tests to confirm the new test fails
4. Implement the bare minimum to make it pass (Green)
5. Run all tests to confirm they all pass
6. Mark the item as `[x]` in the plan
7. Make any necessary structural changes (Tidy First), running tests after each
8. Report what was done and what the next unmarked test is
