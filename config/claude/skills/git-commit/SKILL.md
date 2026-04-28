---
name: git-commit
description: Use this skill to commit Git changes. If staged files exist, commit only those in a single commit. If nothing is staged, split working-tree changes into meaningful units and commit them sequentially. Triggers on user requests such as "commit", "git commit", "commit my changes", "commit staged files", "コミットして", "変更をコミット", or "split commits". Never pushes — even if the user asks to commit and push, this skill performs the commit only and defers push to explicit user confirmation.
---

# Git Commit

Commits Git changes using the Conventional Commits format (`type(scope): message`).

> [!IMPORTANT]
> **Never push.** Any `git push` variant (`push`, `push --force`, `push origin <branch>`, `push -u`, etc.) is out of scope for this skill. If the user requests "commit and push", perform only the commit and explicitly confirm with the user before any push happens.

## When to Use

- User asks to commit ("commit", "git commit", "commit my changes", "コミットして", "変更をコミット")
- A logical chunk of work is complete and changes should be recorded in Git history, regardless of whether files are pre-staged
- User asks for a "commit and push" — handle only the commit half and ask the user about push afterward

Do not use when:

- The goal is to rewrite history (rebase, amend, reset)
- The user only wants to inspect diffs without committing

## Workflow

### Step 1: Inspect repository state (always first)

Run these in parallel:

- `git status` — overall view of staged, modified, and untracked files
- `git diff --cached --stat` — summary of staged changes
- `git log -5 --oneline` — recent commit style for the repo

Branch on whether `git diff --cached --stat` is empty.

### Step 2A: Staged files exist (single commit)

If even one file is staged, commit **only the staged contents** as a single commit.

1. Run `git diff --cached` to read the actual staged changes
2. **Do not run `git add` for unstaged changes.** The user may have deliberately excluded them
3. Compose a message summarizing the staged diff and run `git commit -m "type(scope): message"`
4. Run `git status` to verify the commit succeeded

### Step 2B: Nothing is staged (split commits)

Do not lump all changes into one commit. Break them into meaningful units.

1. Read `git diff` and the contents of any untracked files to understand the full set of changes
2. **Plan the split**:
   - By kind: feature / bug fix / refactor / formatting / config / docs
   - By scope: module A changes and module B changes go in separate commits
   - By file role: implementation and tests for the same feature usually belong together; independent fixes do not
3. **Order the commits logically** (dependencies first):
   - Example: config addition → implementation → tests → docs
   - Example: refactor of existing code → new feature built on top of it
4. For each unit, repeat:
   1. `git add <files>` — stage exactly the files for this unit
   2. `git diff --cached` — verify the staged set matches the intent
   3. `git commit -m "type(scope): message"`
5. Run `git status` at the end to confirm the working tree is clean (or that any remaining changes are intentionally left)

If unexpected changes appear during the process, stop and confirm with the user before proceeding.

## Commit Message Specification

### Format

```
type(scope): message
```

- `type`: change category (one of the values below)
- `scope`: affected module, directory, or file (e.g., `auth`, `api`, `nvim`, `darwin`). Omit if the change is genuinely cross-cutting
- `message`: concise English summary. Lowercase start, imperative mood, no trailing period

### Types

- `feat`: a new feature
- `fix`: a bug fix
- `refactor`: code change that neither fixes a bug nor adds a feature
- `test`: adding or correcting tests
- `style`: changes that do not affect code meaning (whitespace, formatting, missing semicolons, etc.)
- `chore`: build process, auxiliary tools, library updates (including doc-generation tooling)
- `docs`: documentation-only changes
- `ci`: changes to CI configuration files and scripts
- `perf`: performance improvements

### Message guidelines

- Read recent commits via `git log -5 --oneline` and match the project's conventions (scope naming, tone)
- Aim for ~50 characters on the subject line
- Prefer "why" over "what" when both are non-obvious; otherwise keep it short
- For multi-line bodies, pass the message via HEREDOC

## Hard Rules

### Top priority: no push

- **Never run any `git push` variant** (`git push`, `git push --force`, `git push -u`, `git push origin <branch>`, `git push <remote> ...`, etc.)
- Even if the user requests a push, this skill commits only. After committing, ask the user "Should I push now?" and let them authorize the push as a separate step
- Push must always be an explicit, separate, user-confirmed action — never bundled silently with a commit

### Commit hygiene

- Do not bypass hooks with `--no-verify` or `--no-gpg-sign`. Fix the underlying problem and recommit
- When a pre-commit hook fails, create a **new commit** rather than `--amend` (the failed run did not produce a commit, so amend would rewrite the previous one and risk data loss)
- In Case A (something is staged), never auto-stage unstaged files
- Never commit secrets (`.env`, credential files, tokens). If detected, warn the user instead of committing
- Commit messages must be written in English
- Stage files explicitly by name. Avoid `git add -A` and `git add .` to prevent unintended inclusion of secrets or large binaries
