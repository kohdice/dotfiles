# Review lenses and the dispatch contract

Detailed material for SKILL.md workflow step 3 (fan out the review). Defines the review lenses, the per-runtime named agents, the read-only sub-agent dispatch contract, the findings schema sub-agents must return, and how the parent synthesizes them into a single verdict.

## Runtime-aware agent selection

Each lens names its preferred agents per runtime. Use the column matching the current runtime when those agents are loaded; when a preferred agent is not loaded, dispatch a generic read-only sub-agent with the lens prompt instead. If no sub-agent can be dispatched at all, run the selected lenses inline in the parent, single-pass, and label the result single-pass in the review summary.

- **Claude Code** loads `config/claude/agents/` (linked into `~/.claude/agents`) and, when installed, the `pr-review-toolkit` plugin agents.
- **Codex** loads the `pr-review-*` custom agents from `config/codex/agents/`, registered in `config/codex/config.toml`.

## Lenses

Each lens is a focused review concern. Dispatch one read-only sub-agent per lens, in parallel. These lenses are language-agnostic.

| Lens           | Focus                                                                                                  | What counts as a blocker                                                              | Claude Code agent                         | Codex agent                             |
| -------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- | ----------------------------------------- | --------------------------------------- |
| correctness    | Logic errors, off-by-one, edge cases, broken control flow, convention violations                       | A path that produces wrong results or violates a hard project rule                    | `pr-review-toolkit:code-reviewer`         | `pr-review-bug-logic-convention`        |
| error-handling | Swallowed errors, missing checks, inappropriate fallbacks, silent failures                             | An error that is silently dropped or masks a real failure                             | `pr-review-toolkit:silent-failure-hunter` | `pr-review-error-handling`              |
| security       | Injection, secret exposure, missing authz, unsafe input handling, data loss, migrations, compatibility | Any exploitable path, leaked secret, data loss risk, or breaking compatibility change | generic read-only agent                   | `pr-review-security-data-compatibility` |
| design         | Type/data design, invariants, structure, readability, complexity                                       | A type that allows an invalid state, or a structure that will not hold up             | `pr-review-toolkit:type-design-analyzer`  | `pr-review-type-design-invariants`      |
| tests          | Missing tests, weak assertions, untested edge cases                                                    | A behavior change with no test and a real regression risk                             | `pr-review-toolkit:pr-test-analyzer`      | `pr-review-test-coverage`               |
| comments       | Comment accuracy vs code, stale or misleading docs                                                     | A comment that actively misleads about behavior                                       | `pr-review-toolkit:comment-analyzer`      | `pr-review-comment-accuracy`            |

### Language-aware lenses (C / Go / Rust / Zig)

When the PR's diff touches C, Go, Rust, or Zig source files, additionally dispatch from this set. First detect the languages present (`gh pr diff --name-only` + extensions), then dispatch **one idiom reviewer per language present** and the three cross-language reviewers. State the target language(s) and the changed file list explicitly in each dispatch prompt. These named agents exist only in Claude Code; in other runtimes cover the same lenses via generic sub-agents or the inline fallback — in that case each lens's knowledge skill (below) supplies the checklist.

| Lens         | Focus                                                                      | What counts as a blocker                                                                    | Claude Code agent                                                                                                 | Knowledge skill                                                                   |
| ------------ | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| idiom        | Language-version idiom compliance, deprecated/removed APIs, official style | Use of a removed/deprecated API, or a pattern with correctness or security implications     | `c-idiom-reviewer` / `go-idiom-reviewer` / `rust-idiom-reviewer` / `zig-idiom-reviewer` — match the file language | `c-idioms` / `go-idioms` / `rust-idioms` / `zig-idioms` — match the file language |
| architecture | Module boundaries, dependency direction, ecosystem layout conventions      | An inverted dependency edge, a cycle, or a violation of the project's declared architecture | `architecture-reviewer`                                                                                           | `architecture-patterns`                                                           |
| performance  | Runtime cost in hot paths: complexity, allocations/copies, redundant work  | O(n²) growth, or a per-item cost (allocation, copy, syscall) introduced into a hot loop     | `performance-reviewer`                                                                                            | `performance-patterns`                                                            |
| simplicity   | Needless wrappers, speculative abstractions (YAGNI), structural clutter    | — (simplicity findings are nits by default)                                                 | `simplicity-reviewer`                                                                                             | `simplicity-patterns`                                                             |

**Knowledge skills** hold each lens's full checklist (principles, pattern catalog, accepted/not-flagged criteria). They live in `config/agents/skills/` and are linked into `~/.claude/skills/` (Claude Code) and `~/.agents/skills/` (other runtimes). The named agents preload their knowledge skill via frontmatter, so dispatch prompts for them need not restate it. When a lens runs **without** its named agent — a generic sub-agent, or the inline fallback — read the knowledge skill's `SKILL.md` first and apply its catalog and accepted criteria as the checklist; the Focus column above is only a selection summary, not the checklist.

When these language-aware agents are dispatched, narrow the overlapping generic lenses to avoid duplicate findings: limit `design` to type/data design (structure belongs to `architecture`, complexity to `simplicity`), and skip generic style commentary (the idiom reviewers own official style).

Scale the lens set to the PR by its actual surface, not a fixed pair: a pure-logic change may need only `correctness` (+ `error-handling` if it touches error paths); a behavior-preserving refactor that adds/moves docs leans on `comments` + `design`; a large or critical PR warrants the full set. Pick lenses from the focus columns above, not from this example. Always log which lenses were applied and which were skipped (with a one-line reason for each skip).

## Dispatch contract (per sub-agent)

Dispatch each reviewer with a prompt of this shape. The constraints block is mandatory — it preserves the skill's invariants.

```
You are a read-only PR reviewer applying the <LENS> lens. Report findings only; do not change anything.

## Context
- Worktree (already checked out, read-only): <WORKTREE_PATH>
- PR: <PR_NUMBER_OR_URL>
- Get the diff with: gh pr diff "<PR>"
- Inspect context by reading files under the worktree path.

## Lens
<one-paragraph definition of the lens focus and what counts as a blocker, from the table above>
<generic sub-agent covering a language-aware lens: "Before reviewing, Read the knowledge skill at ~/.claude/skills/<knowledge skill>/SKILL.md (other runtimes: ~/.agents/skills/<knowledge skill>/SKILL.md) and apply its pattern catalog and accepted criteria as your checklist." Omit for named agents — they preload it — and for lenses with no knowledge skill.>

## Hard constraints
- READ-ONLY. Do not edit files, do not create or remove git worktrees, do not push.
- Do not post anything to GitHub (no gh pr review, no gh pr comment, no gh api writes). Read-only gh is fine (gh pr diff, gh pr view).
- Do NOT run tests, formatters, linters, or builds — CI already covers them.
- Reason from the code. Stay within your lens; do not duplicate other lenses' concerns.

## Return (findings only)
Return a JSON array of findings, each:
{ "path": "<repo-relative path>", "line": <new-side line number>, "start_line": <optional>, "severity": "blocker" | "nit", "lens": "<LENS>", "body": "<comment text>" }
Return an empty array if nothing is found. Add a one-line lens summary after the array.
Write every finding body and the summary in English — finding bodies become GitHub PR comments.
```

When dispatching via the Workflow/Agent tooling with a schema, use the findings schema below so returns are validated rather than parsed.

Named reviewer agents (the `pr-review-toolkit:*`, `pr-review-*`, and the language-aware agents above) define their own report formats and default output language in their system prompts. The dispatch prompt overrides both for this workflow: state explicitly that the agent must return the findings JSON below instead of its usual report, written in English (finding bodies become GitHub PR comments), so the parent can merge results mechanically.

## Findings schema

```json
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "path": { "type": "string" },
          "line": { "type": "integer" },
          "start_line": { "type": "integer" },
          "severity": { "type": "string", "enum": ["blocker", "nit"] },
          "lens": { "type": "string" },
          "body": { "type": "string" }
        },
        "required": ["path", "line", "severity", "lens", "body"]
      }
    }
  },
  "required": ["summary", "findings"]
}
```

## Synthesis (parent only)

After all lenses return, the parent consolidates — this is the one place that needs every lens's output at once (a barrier), because the overall verdict cannot be decided until all findings are in.

1. **Flatten** all findings from every lens into one list.
2. **Drop ungrounded findings**: discard anything that cannot be grounded in the diff or the surrounding code.
3. **Dedup by `(path, line)`**: when multiple lenses flag the same location, merge into a single comment (prefix the body with the contributing lenses) and keep the highest severity.
4. **Classify**: severity is decided by the lens — a finding is a `blocker` when the matching lens's "what counts as a blocker" column flags it (a wrong result, security hole, data loss, API-compatibility break, or an error that is silently dropped or masks a real failure). Everything else is a `nit` = a non-blocking, optional suggestion; prefix its comment body with `nit:`. "Optional" describes nits only — never a lens-defined blocker.
5. **Decide the verdict**:
   - Any `blocker` present → `REQUEST_CHANGES`.
   - No blockers and the authenticated GitHub user is not the PR author → `APPROVE`.
   - No blockers and the authenticated GitHub user **is** the PR author → `COMMENT` with an approval-style summary (GitHub rejects self-approval; see the guardrails in `gh-review-commands.md`).
   - Use `COMMENT` otherwise only when a lens genuinely needs a question answered before a verdict is possible.
6. **Build one review**: turn the deduped findings into the `comments[]` array and submit a single review via `gh api .../reviews` (see `gh-review-commands.md`). The summary body should note blocker and nit counts and the per-lens coverage.

Never let sub-agents submit reviews — the parent submits exactly one.
