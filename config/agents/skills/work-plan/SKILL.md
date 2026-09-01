---
name: work-plan
description: "This skill should be used when the user asks to plan work that will NOT be implemented with TDD — any task without automatically testable application behavior, regardless of technology: infrastructure (Terraform, Nix, Kubernetes, cloud resources), configuration, CI/CD pipelines, documentation, build scripts, data/schema migrations, repository housekeeping, tooling setup. Triggers on phrases like: 'plan the Terraform setup', 'create a work plan for <task>', 'plan this migration', 'インフラ構築の計画を立てて', '作業プランを作って', 'CI 設定変更を計画して', 'ドキュメント整備の計画を作って'. It produces a checklist plan in `.plans/` where every item carries a verification step with an expected outcome, ready for execution by the work-implement skill. Do NOT use when the requested change has automatically testable application behavior — the tdd-plan skill owns that. Do NOT use to execute a plan — the work-implement skill owns execution, and the tdd skill owns `/tdd`."
---

# Work Plan (non-TDD planning)

## Overview

Create structured plans for work that TDD does not apply to. Analyze the user's request and the target environment, then produce a plan file in `.plans/` containing ordered work items, each with a verification step and its expected outcome, ready for execution by the work-implement skill. Always end by telling the user the exact plan filename that was created so they can continue with `go` in the same session or ask work-implement to execute it later.

This skill is technology-neutral. Terraform, Nix, CI pipelines, documentation, shell tooling, migrations, housekeeping — anything the user chooses not to drive with TDD is in scope. The single routing question is:

> Can an automated test fail before the change and pass after it, and is the user driving the change through that test?

If yes, this is tdd-plan's territory — hand over and stop. If no, plan it here.

## The Verify Requirement

A checklist without completion criteria is a todo list, not a plan. Every item in a work plan must therefore carry a **Verify** step: a command to run (or an observable state to inspect) and the **expected outcome**, stated concretely enough that a fresh executor can decide pass or fail without judgment calls. This is the plan's substitute for TDD's Red-Green gate.

- Prefer commands over manual inspection: `terraform plan`, `nix flake check`, `nix run .#build`, `shellcheck`, `yamllint`, `gh workflow view`, a `curl` health check, `git status --porcelain`.
- The expected outcome names what the output must (or must not) contain — not just "it succeeds". For a change-previewing command, state the exact expected diff (e.g., "`terraform plan` shows exactly `+ aws_s3_bucket.state`, nothing else").
- When no command exists (e.g., documentation), the Verify step names an observable artifact state ("README.md renders the new section; `grep` finds the anchor link").
- An item whose Verify step cannot be written is not plannable yet — split it, clarify it, or escalate it as an open question.

## Plan Creation Workflow

### Step 1: Clarify Requirements

1. Read the request and identify the goal and the affected systems or files.
2. Apply the tdd-plan skill's ambiguity threshold, adapted to this scope: the request is ambiguous only if a decision that produces an observable outcome difference is still unsettled after consulting the request, the codebase/configuration, and the live environment's conventions (existing module layout, naming schemes, environment names, provider versions). Conventions already encoded in the repository resolve otherwise-open points: adopt them and record the interpretation in the plan's Context section.
3. If ambiguous, ask targeted questions before proceeding — only the unsettled points, one question per independent decision. When interactive questioning is not possible, return the questions as the final reply and stop without creating `.plans/` or any file.
4. Route: if the request turns out to have automatically testable application behavior that the user wants driven by tests, state that tdd-plan owns it and stop.

### Step 2: Analyze the Target

1. Read the relevant files, modules, and configuration to understand the current state.
2. Identify the project's check commands: validators (`terraform validate`, `nix flake check`), formatters/linters, dry-run builders (`terraform plan`, `nix run .#build`, `--dry-run` flags), and any full-project check. Record them — the plan's Context names a **global check command** when one exists, and work-implement runs it as a baseline and after every item.
3. Identify prerequisites the executor needs: required CLIs, credentials/authentication, target environment or workspace names, network access. Record them in Context; never record secret values.
4. Note constraints: ordering dependencies, state that must not be touched, maintenance windows, anything irreversible.

### Step 3: Design Work Items

Decompose the work into the smallest independently verifiable increments.

**Ordering:**

- Read-only and reversible changes first; state-mutating and hard-to-reverse changes last.
- Validation-producing items (write config → validate/dry-run) come before any item that applies that config to a live system.
- Each item may depend on previous items being complete, never on later ones.

**Granularity:**

- One coherent change per item — one resource, one module, one document section, one pipeline job. If an item's Verify step needs the word "and" more than once, split the item.
- Every item states what changes and how completion is verified (the Verify requirement above).
- No speculative items: plan only what the request needs.

**Apply tier:**

- An item that mutates live state — `terraform apply`, `nix run .#switch`, `kubectl apply`, deployments, DNS or IAM changes, destructive migrations — is marked `Task (apply):` instead of `Task:`.
- Keep apply items to the minimum count and place each one after the dry-run/validation items that gate it.
- Each apply item carries a `Rollback:` line stating how to undo it, or `Rollback: not possible — <why>` when it cannot be undone. work-implement never runs apply items without explicit user confirmation, and never delegates them to sub-agents.

**Phase division (large plans):**

- A large plan may be divided with `### Phase N: <milestone>` headings. A phase boundary is valid only at an independently committable point: all previous Verify steps pass, one coherent increment is complete, and no dangling half-applied state remains.
- Each phase heading is followed by one `After this phase:` line stating what becomes true when the phase completes. If that line cannot be written meaningfully, the boundary is wrong.

### Step 4: Write the Plan File

1. Create `.plans/` if it does not exist (resolved against the project root).
2. Choose a descriptive kebab-case filename (e.g., `s3-state-backend.md`, `ci-release-pipeline.md`).
3. Write the plan using the format below.
4. In the final reply, print the exact filename and `.plans/` path, and mention that a follow-up bare `go` in the same session continues with this plan via the work-implement skill.

## Plan File Format

```markdown
# Plan: <Work Title>

## Goal

<1-3 sentences describing the end state this plan achieves>

## Context

<Background and motivation, decisions from Step 1 with rationale, current state of the
affected files/systems with paths, prerequisites (CLIs, auth, environment names — no
secret values), the global check command if one exists, constraints, and any
interpretation adopted under the ambiguity threshold — detailed enough for a fresh
executor with no session context>

## Work Items

- [ ] Task: <description of the change — smallest increment>
  - Verify: <command or check> — expect: <concrete observable outcome>
- [ ] Task: <description — next increment>
  - Verify: <command> — expect: <outcome>
- [ ] Task (apply): <description — live-state mutation, minimal and gated by the items above>
  - Verify: <command> — expect: <outcome>
  - Rollback: <how to undo, or "not possible — <why>">
```

### Plan File Rules

- Work items use `- [ ] Task:` or `- [ ] Task (apply):` prefixes; the checkbox tracks execution progress.
- Verify and Rollback lines are nested bullets under their item, never checkboxes — the executor scans for the first unchecked `- [ ] Task` item.
- A `Task:` description states what changes; it may name files, resources, and public-facing names, but does not prescribe incidental implementation detail the executor can decide.
- Every item has at least one Verify bullet with an expected outcome. Multiple Verify bullets are allowed when one command cannot cover the item.
- Every `Task (apply):` item has a Rollback bullet.
- Items are listed in execution order. Do not mix an apply-tier mutation into a `Task:` item.
- The Goal section states the end state, not the process.
- The plan file is the single source of truth for execution. Write it so that a fresh executor — a different session, a different agent, or a human — can execute it with zero access to this conversation. Length is not a concern; omitted context is.

## Quality Checklist

Before presenting the plan, verify:

1. Every item is small enough to execute and verify as one step.
2. Every item has a Verify bullet whose expected outcome is concrete enough to decide pass/fail mechanically.
3. Ordering runs from reversible to irreversible; every apply item is gated by prior validation items and carries a Rollback bullet.
4. `Task (apply):` marks every live-state mutation — none hides inside a plain `Task:`.
5. The Context section records prerequisites, the global check command (if any), and constraints, with no secret values.
6. The plan references specific files, resources, and commands from the analyzed target.
7. No item implicitly depends on unplanned work.
8. If the plan has phases, every boundary is independently committable and has its `After this phase:` line.
9. The final reply includes the exact created plan filename and `.plans/` path.
10. Portability: an executor with no access to this conversation could execute the plan using only the plan file and the repository.
