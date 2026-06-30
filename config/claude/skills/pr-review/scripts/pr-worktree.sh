#!/usr/bin/env bash
#
# pr-worktree.sh — create/destroy an isolated git worktree for reviewing a GitHub PR.
#
# The PR head is checked out in DETACHED HEAD so no throwaway local branch is left
# behind, and fork PRs are handled by `gh pr checkout`. Run from within the target
# repository.
#
# Usage:
#   pr-worktree.sh setup <pr-number-or-url>   # creates the worktree, prints its path on the last line
#   pr-worktree.sh cleanup <worktree-path>    # removes the worktree and prunes metadata
#
set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git not found on PATH"
command -v gh  >/dev/null 2>&1 || die "gh not found on PATH"

cmd="${1:-}"
arg="${2:-}"

case "$cmd" in
  setup)
    [ -n "$arg" ] || die "setup requires a PR number or URL"

    # Resolve a bare number or URL to the canonical PR number.
    pr_number="$(gh pr view "$arg" --json number --jq .number)" \
      || die "could not resolve a PR from '$arg'"

    repo_root="$(git rev-parse --show-toplevel)" \
      || die "not inside a git repository"

    # Status messages go to stderr so the caller can capture the path from stdout.
    worktree_dir="$(mktemp -d "${TMPDIR:-/tmp}/pr-review-${pr_number}.XXXXXX")"
    git -C "$repo_root" worktree add --detach "$worktree_dir" HEAD >&2

    # `gh pr checkout` must run inside the worktree; --detach avoids creating a branch.
    ( cd "$worktree_dir" && gh pr checkout "$pr_number" --detach ) >&2 \
      || { git -C "$repo_root" worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true
           die "gh pr checkout failed for PR #$pr_number"; }

    # The worktree path — caller reads this (use `| tail -n1`).
    printf '%s\n' "$worktree_dir"
    ;;

  cleanup)
    [ -n "$arg" ] || die "cleanup requires a worktree path"

    # `git worktree remove` cannot run from inside the worktree being removed and
    # needs the main repo as context. Resolve the main repo from the worktree
    # itself so cleanup works regardless of the caller's cwd.
    main_root=""
    if [ -d "$arg" ]; then
      main_root="$( (cd "$arg" && cd "$(git rev-parse --git-common-dir)/.." && pwd) 2>/dev/null )" || main_root=""
    fi
    [ -n "$main_root" ] || main_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    [ -n "$main_root" ] || die "cannot locate the main repo; run cleanup from inside it or keep the worktree present"

    git -C "$main_root" worktree remove --force "$arg" 2>/dev/null \
      || printf 'warning: worktree remove failed for %s (already gone?)\n' "$arg" >&2
    git -C "$main_root" worktree prune
    ;;

  *)
    die "unknown command '$cmd' (expected: setup | cleanup)"
    ;;
esac
