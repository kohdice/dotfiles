# Review lenses (local scope)

Detailed material for SKILL.md workflow step 3. Defines the lens catalog, lens selection, the dispatch contract, the findings schema, whole-codebase chunking, and the parent's synthesis rules.

## Lens catalog

The named agents live in `config/claude/agents/` and are loaded in Claude Code sessions (linked into `~/.claude/agents`). Other runtimes (e.g. Codex) do not load them: run the selected lenses inline in the parent instead, single-pass, using the focus definitions below, and label the result single-pass in the report.

| Lens         | Named agent (if loaded)                                                                 | Focus                                                                        | Severity notes                                                                   |
| ------------ | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| idiom        | `c-idiom-reviewer` / `go-idiom-reviewer` / `rust-idiom-reviewer` / `zig-idiom-reviewer` | Language-version idiom compliance, deprecated/removed APIs, official style   | High = removed/deprecated API or correctness/security implication                |
| architecture | `architecture-reviewer`                                                                 | Module boundaries, dependency direction, ecosystem layout conventions        | High = inverted edge, cycle, or violation of the project's declared architecture |
| performance  | `performance-reviewer`                                                                  | Unnecessary heap allocations, hidden copies, reallocation churn in hot paths | High = per-item allocation/copy in a hot loop, or O(n²) growth                   |
| simplicity   | `simplicity-reviewer`                                                                   | Needless wrappers, speculative abstractions (YAGNI), structural clutter      | Advisory by default; High only for an entire unjustified layer                   |
| correctness  | — (generic read-only sub-agent)                                                         | Logic errors, off-by-one, edge cases, broken control flow, swallowed errors  | High = a path that produces wrong results or silently drops an error             |

## Lens selection

- **working diff / branch diff / path**: dispatch `correctness` + one idiom lens per language present + the three cross-language lenses. Drop `performance` when nothing in scope is hot-path shaped (no loops, parsers, handlers); drop `architecture` when no files moved and no imports changed; note every dropped lens in the report.
- **all (audit)**: dispatch every lens, chunked as described below.
- Files outside C/Go/Rust/Zig get only `correctness`.
- Overlap rules when the named agents are dispatched: `correctness` must not comment on style or idiom (the idiom reviewers own official style), structure (architecture), complexity (simplicity), or allocation cost (performance).

## Dispatch contract (per sub-agent)

Dispatch each reviewer with a prompt of this shape. The constraints block is mandatory.

```
You are a read-only reviewer applying the <LENS> lens to local code (not a GitHub PR). Report findings only; change nothing.

## Context
- Repository root: <REPO_ROOT>
- Scope: <working diff | diff vs <BASE> | path <PATH> | whole-codebase chunk <CHUNK>>
- Files in scope: <file list>
- Language(s): <detected languages for these files>
- Diff (when scope is a diff): git diff HEAD -- <files>  /  git diff <BASE>...HEAD -- <files>. For path or chunk scope, read the files directly.
- Report language: <conversation language>. Keep all code snippets, identifiers, and paths in English.

## Lens
<focus and severity notes for this lens, from the catalog>

## Hard constraints
- READ-ONLY: no file edits, no git writes, no worktrees or branches.
- Do NOT run tests, builds, or anything that writes files. Read-only checks your definition allows (go vet, gofmt -l, cargo clippy --no-deps, zig fmt --check) are fine.
- Stay within your lens; do not duplicate other lenses' concerns.

## Return (findings only)
Return a JSON object matching the findings schema: {"summary": "...", "findings": [{path, line, severity, lens, body, fix?}]}.
Use an empty findings array when the scope is clean — do not invent findings.
Write body, fix, and summary in the report language; keep code in English.
```

The named reviewer agents define their own report formats and default output language in their system prompts; this dispatch prompt overrides both so the parent can merge results mechanically.

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
          "severity": { "type": "string", "enum": ["high", "medium", "low"] },
          "lens": { "type": "string" },
          "body": { "type": "string" },
          "fix": { "type": "string" }
        },
        "required": ["path", "line", "severity", "lens", "body"]
      }
    }
  },
  "required": ["summary", "findings"]
}
```

## Whole-codebase chunking (`all` scope)

A whole codebase does not fit one agent's context; chunk it and log coverage.

- **Units**: Go → one chunk per package; Rust → per crate (per top-level module for a large crate); Zig → per `build.zig` module or top-level directory; C → per directory or library boundary.
- **Per-chunk lenses**: `idiom`, `performance`, `simplicity`, `correctness` run per chunk.
- **Global lens**: `architecture` runs once per language over that language's full file set — dependency direction and cycles are invisible inside a single chunk.
- **Waves**: keep roughly 8–10 concurrent sub-agents; process remaining chunks in successive waves.
- **No silent caps**: if any chunk is skipped (size, time), list it in the report as not covered.

## Synthesis (parent only)

1. Wait for every dispatched lens (or finish the inline single-pass for every selected lens).
2. Flatten all findings into one list; drop findings not grounded in the actual code.
3. Dedup by `(path, line)`: merge bodies, note contributing lenses, keep the highest severity.
4. Group by severity: High → Medium → Low. Each entry: `path:line`, lens, body, and the proposed fix if one was returned.
5. Write one report in the conversation language (code in English): a one-paragraph overall assessment first, then the grouped findings, then coverage (lenses run / skipped with reasons; chunks covered / dropped for `all` scope; whether the run was multi-agent or single-pass).
6. Propose fixes only as recommendations — this skill never applies them.
