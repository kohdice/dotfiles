---
name: tdd-plan
description: "This skill should be used when the user asks to create an implementation plan, design a development plan, or prepare a TDD plan for a feature. Triggers on phrases like: 'plan to implement X', 'create a plan for X', 'design a development plan', 'prepare a TDD plan', 'make a plan', or any request that involves creating a structured plan file in ./plans/ for later TDD execution. Do NOT trigger when the user says 'go' or asks to implement the next test — that is handled by the tdd skill."
---

# TDD Plan

## Overview

Create structured implementation plans for TDD-driven development. Analyze the user's requirements and the existing codebase, then produce a plan file in `./plans/` containing ordered test cases ready for execution by the tdd skill.

## Plan Creation Workflow

Execute these steps in order when creating a plan.

### Step 1: Clarify Requirements

1. Read the user's request to understand the desired feature or change
2. If the request is ambiguous, ask targeted questions before proceeding
3. Identify the scope: new feature, extension of existing feature, bug fix, or refactor

### Step 2: Analyze the Codebase

1. Identify the modules, files, and types relevant to the requested change
2. Read the existing source code to understand current structure and patterns
3. Read the existing tests to understand testing conventions and coverage
4. Note any dependencies, interfaces, or constraints that the plan must respect

### Step 3: Design Test Cases

Decompose the feature into the smallest testable increments. Follow these principles:

**Ordering:**

- Start with the simplest case (e.g., empty input, zero-length, nil/null)
- Progress to basic valid cases (single element, minimal input)
- Then handle increasingly complex cases (multiple elements, combinations)
- Address edge cases and error conditions last
- Each test should build on the confidence established by previous tests

**Granularity:**

- One behavior per test — each test validates exactly one thing
- A test name must clearly describe what is being verified
- Use descriptive Zig inline test names (e.g., `test "parses empty sequence diagram"`)

**Structural changes:**

- When refactoring or reorganizing code is needed before or during implementation, include it as a separate plan item marked with `Refactor:` instead of `Test:`
- Structural items must not change behavior — they prepare the codebase for the next behavioral change

### Step 4: Write the Plan File

1. Create the `./plans/` directory if it does not exist
2. Choose a descriptive file name based on the feature (e.g., `sequence-parser.md`, `table-renderer.md`)
3. Write the plan file using the format specified below

## Plan File Format

```markdown
# Plan: <Feature Name>

## Goal

<1-3 sentences describing what this plan achieves>

## Context

<Brief description of relevant existing code, modules, and patterns>

## Test Cases

- [ ] Test: <description of what to test — simplest case>
- [ ] Test: <description — next increment>
- [ ] Refactor: <description of structural change if needed>
- [ ] Test: <description — more complex case>
- [ ] Test: <description — edge case>
- [ ] Test: <description — error condition>
```

### Plan File Rules

- All test items use `- [ ] Test:` prefix with a clear description
- All structural-change items use `- [ ] Refactor:` prefix
- Items are listed in implementation order — each item may depend on previous items being complete
- Do not mix behavioral and structural changes in a single item
- The Goal section states the end-state, not the process
- The Context section references specific files and types by name to orient the implementer

## Quality Checklist

Before presenting the plan to the user, verify:

1. Every test case is small enough to implement in a single Red-Green cycle
2. Test names are descriptive and follow the project's naming conventions
3. The ordering progresses from simple to complex
4. Structural changes are separated from behavioral changes
5. Edge cases and error conditions are covered
6. The plan references specific files, types, and functions from the codebase
7. No test case implicitly depends on unplanned work
