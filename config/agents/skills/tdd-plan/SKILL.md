---
name: tdd-plan
description: "This skill should be used when the user asks to plan the TDD implementation of application code — a new feature, a behavior change, or a bug fix with automatically testable behavior. Triggers on phrases like: 'plan to implement <feature>', 'create an implementation plan for <feature>', 'prepare a TDD plan', 'design a development plan for <feature>'. Do NOT use for planning work with no testable application behavior: writing README or documentation, configuration/CI/infrastructure changes, or repository housekeeping — the work-plan skill owns those. Do NOT use when the user says 'go' or asks to implement the next test — that is handled by the tdd skill."
---

# TDD Plan

## Overview

Create structured implementation plans for TDD-driven development. Analyze the user's requirements and the existing codebase, then produce a plan file in `.plans/` containing ordered test cases ready for execution by the tdd skill. Always end by telling the user the exact plan filename that was created so they can continue with `go` in the same session or `/tdd <filename>` later.

## When NOT to Use This Skill

This skill plans application code changes with automatically testable behavior. Do not create a plan when the request is:

- Writing or restructuring documentation (README, docs/, comments)
- Configuration, CI/CD, or infrastructure changes
- Any task where no test case can fail before the change and pass after it

If the request has no testable application behavior, state that a TDD plan does not apply, suggest the work-plan skill instead, and stop without creating `.plans/` or any plan file.

## Plan Creation Workflow

Execute these steps in order when creating a plan.

### Step 1: Clarify Requirements

1. Read the user's request to understand the desired feature or change
2. Apply the ambiguity threshold: the request is ambiguous only if a decision that produces an observable behavior difference is still unsettled after consulting both the request and the codebase. Conventions already encoded in the code — existing function semantics, pinned tests, naming — implicitly resolve otherwise-open points: adopt the interpretation they pin down and record it in the plan's Context section (Step 4). These resolvers transfer at package/module scope: a convention established by sibling APIs settles the same question for new code in that unit unless the request contradicts it. The public API surface (name, signature, ownership/mutation, return shape) counts as observable behavior under this threshold — convention-resolvable when the codebase exhibits a consistent pattern, otherwise one of the questions; internal organization (data structures, algorithms) is never a question topic and belongs to the executing tdd skill's Green/Refactor phases. Reading the code early for this check is expected and does not replace the full Step 2 analysis. This threshold is the canonical definition; the implement skill's step 1 restates it and defers here
3. If the request is ambiguous under that threshold, ask targeted questions before proceeding — 3–7 items covering only the unsettled points (scope, tech stack, and non-functional requirements insofar as the codebase does not settle them), one question per independent observable-behavior decision, with sub-conditions of the same decision folded into that question rather than split out (two points belong to the same decision when one is meaningless until the other is answered). A low-stakes API-surface element such as the function name may be proposed as a default inside a related question instead of consuming its own item. Each question may cite the codebase evidence showing why the point is unsettled. When interactive questioning is not possible (e.g., running non-interactively), do not fabricate a plan: return the questions as your final reply and stop without creating the `.plans/` directory or any plan / questions file — no filesystem side effects
4. Identify the scope: new feature, extension of existing feature, bug fix, or refactor
5. If no testable application behavior can be identified, do not proceed: explain that TDD planning does not apply, point to the work-plan skill, and stop without filesystem side effects

### Step 2: Analyze the Codebase

1. Identify the modules, files, and types relevant to the requested change
2. Read the existing source code to understand current structure and patterns
3. Read the existing tests to understand testing conventions and coverage. Running the existing test suite to confirm the assumed-green baseline is permitted but optional; planning never modifies source or test files
4. Note any dependencies, interfaces, or constraints that the plan must respect

### Step 3: Design Test Cases

Decompose the feature into the smallest testable increments. Follow these principles:

**Ordering:**

- Start with the simplest case (e.g., empty input, zero-length, nil/null)
- Progress to basic valid cases (single element, minimal input)
- Then handle increasingly complex cases (multiple elements, combinations)
- Address edge cases and error conditions last — only those the requested behavior actually requires, not speculative ones
- Each test should build on the confidence established by previous tests
- This simple-to-complex progression is the default heuristic, not a hard rule — when a different order clearly teaches more about the problem sooner (Kent Beck's criterion: the next test is the one you learn the most from and are confident you can make pass), prefer that order

**Granularity:**

- One behavior per test — each test validates exactly one thing
- Test observable behavior through the public API — never implementation details (private functions, internal call order, interactions with mocks). Implementation-coupled tests break under legitimate refactoring, violating the Tidy First invariant that structural changes keep test results identical
- Plan only new or changed behavior — do not include tests for behavior already covered by existing passing tests (discovered in Step 2). Such a test can never fail in the Red phase, so it adds no information and violates the rule that every test must fail before the change
- Test only code this project owns. Do not plan tests that verify the responsibilities of third-party libraries, frameworks, or the standard library (e.g., that an ORM escapes SQL, that a JSON library parses JSON). Kent Beck's rule: test third-party code only if you have reason to distrust it
- Prefer unit-level tests that run fast and in isolation. Plan a resource-heavy test (containers, real databases, network, end-to-end) only when the requested behavior cannot be verified any other way, keep such tests to the minimum count, place them last in the plan, and mark them `Test (integration):` so the executing skill can run them sparingly
- A test name must clearly describe what is being verified
- Follow the target project's existing test naming convention, discovered in Step 2 (e.g., Zig inline tests `test "parses empty sequence diagram"`, Rust `#[test] fn parses_empty_sequence_diagram`, Go `TestParsesEmptySequenceDiagram`)

**Structural changes:**

- When refactoring or reorganizing code is needed before or during implementation, include it as a separate plan item marked with `Refactor:` instead of `Test:`
- Structural items must not change behavior — they prepare the codebase for the next behavioral change
- Placement: put a `Refactor:` item immediately before the first `Test:` item that depends on that structural change. Consecutive `Refactor:` items may be grouped together only when they all gate the same next behavioral test — this group goes right before that test, not at the top of the Test Cases list. Do not interleave structural items with unrelated behavioral tests

**Phase division (large plans):**

- A large plan may be divided into phases with `### Phase N: <milestone>` headings inside the Test Cases section. The boundary criterion is strictly semantic: a phase boundary is valid only at a point that is independently committable — all tests green, one coherent observable behavior increment completed (a vertical slice), and no un-generalized Fake It implementation or pending `Refactor:` dependency left dangling. This mirrors the tdd skill's Commit Discipline: a phase is a single logical unit of work, planned in advance
- Item count is never the boundary criterion. A large item count (roughly more than 10) is only a trigger to look for natural semantic seams; when no such seam exists, keep the plan as a single phase rather than forcing a split
- Each phase heading is followed by one line stating what becomes possible when the phase completes (e.g., `After this phase: the parser accepts all valid sequence diagrams`). If that line cannot be written meaningfully, the boundary is wrong — move or remove it

**Bug fixes:**

- When the scope identified in Step 1 is a bug fix, the first two plan items must follow the tdd skill's Defect Fix Workflow: (1) `Test:` an API-level test that demonstrates the defect from the caller's perspective, then (2) `Test:` the smallest test that replicates the root cause
- Add further `Test:` items only if the fix also requires new behavior beyond making these two tests pass

### Step 4: Write the Plan File

1. Create the `.plans/` directory if it does not exist (resolved against the current working directory, which should be the project root)
2. Choose a descriptive kebab-case file name based on the feature (e.g., `sequence-parser.md`, `table-renderer.md`)
3. Write the plan file using the format specified below
4. In the final reply, print the exact created filename and `.plans/` path, and mention that a follow-up bare `go` in the same session should continue with that plan

## Plan File Format

```markdown
# Plan: <Feature Name>

## Goal

<1-3 sentences describing what this plan achieves>

## Context

<Background and motivation of the request, decisions from Step 1 clarification with their rationale, relevant existing code, modules, and patterns with paths, the project's test command and conventions, constraints, and any interpretation adopted under the Step 1 ambiguity threshold — detailed enough for a fresh implementer with no session context>

## Test Cases

- [ ] Test: <description of what to test — simplest case>
- [ ] Test: <description — next increment>
- [ ] Refactor: <description of structural change if needed>
- [ ] Test: <description — more complex case>
- [ ] Test: <description — edge case>
- [ ] Test: <description — error condition>
- [ ] Test (integration): <description — resource-heavy verification, minimal and last>
```

### Plan File Rules

- All test items use `- [ ] Test:` prefix with a clear description
- A `Test:` description states the scenario (input or situation) and the expected observable outcome — it must not prescribe implementation strategy (data structures, algorithms, internal organization). Design decisions belong to the Green and Refactor phases of the executing tdd skill. A convention-following test name inside the description is required naming, not implementation prescription — e.g., `- [ ] Test: TestCountWordsEmpty — empty string yields an empty map`. Likewise a public-API-visible type named there (the returned map) states observable outcome; the ban covers internal data structures and algorithms only
- All structural-change items use `- [ ] Refactor:` prefix
- Phase headings (`### Phase N: <milestone>` plus its `After this phase:` line) are optional structure for large plans, governed by the phase-division rules in Step 3; items keep the same checkbox format within phases
- Items are listed in implementation order — each item may depend on previous items being complete
- Do not mix behavioral and structural changes in a single item
- The Goal section states the end-state, not the process
- The Context section references specific files and types by name to orient the implementer
- The plan file is the single source of truth for implementation. Write it so that a fresh implementer — a different session, a different AI agent, or a human — can execute it with zero access to this conversation. The Context section must therefore include: the background and motivation of the request, every decision made during Step 1 clarification with the user's answers and their rationale, relevant files/types/functions with paths, the project's test command and conventions, and known constraints. Length is not a concern; omitted context is

## Quality Checklist

Before presenting the plan to the user, verify (for a pure-refactor plan consisting only of `Refactor:` items, test-related checks apply to any characterization tests added to pin current behavior):

1. Every test case is small enough to implement in a single Red-Green cycle
2. Test names are descriptive and follow the project's naming conventions
3. The ordering progresses from simple to complex
4. Structural changes are separated from behavioral changes
5. Edge cases and error conditions required by the requested behavior are covered — no speculative tests beyond the requirement
6. The plan references specific files, types, and functions from the codebase
7. No test case implicitly depends on unplanned work
8. Every `Test:` item states scenario and expected observable outcome without prescribing implementation, and none duplicates behavior already covered by existing passing tests
9. The final reply includes the exact created plan filename and `.plans/` path
10. No item tests a third-party library's or the standard library's own responsibility, and any `Test (integration):` items are minimal in count and placed last
11. Portability: an implementer with no access to this conversation could execute the plan using only the plan file and the codebase
12. If the plan has phases, every phase boundary lands on an independently committable point (all tests green, one coherent behavior increment, no dangling Fake It or `Refactor:` dependency), and each phase has its `After this phase:` line
