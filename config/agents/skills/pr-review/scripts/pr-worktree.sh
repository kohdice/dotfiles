#!/usr/bin/env sh
set -eu

usage() {
  cat >&2 <<'USAGE'
Usage:
  pr-worktree.sh setup <pr-url-or-number>
  pr-worktree.sh cleanup <worktree-path>
USAGE
}

require_arg() {
  if [ $# -lt 1 ] || [ -z "$1" ]; then
    usage
    exit 2
  fi
}

setup() {
  require_arg "${1:-}"

  pr="$1"
  repo_root="$(git rev-parse --show-toplevel)"
  parent="${TMPDIR:-/tmp}/pr-review-worktrees"
  safe_name="$(printf '%s' "$pr" | sed 's/[^A-Za-z0-9._-]/-/g' | cut -c 1-80)"

  if [ -z "$safe_name" ]; then
    safe_name="pr"
  fi

  mkdir -p "$parent"
  worktree="$(mktemp -d "$parent/${safe_name}.XXXXXX")"
  rmdir "$worktree"

  cleanup_on_error() {
    git -C "$repo_root" worktree remove --force "$worktree" >/dev/null 2>&1 || true
    git -C "$repo_root" worktree prune >/dev/null 2>&1 || true
  }

  trap cleanup_on_error INT TERM EXIT

  git -C "$repo_root" worktree add --detach "$worktree" HEAD >/dev/null
  printf '%s\n' "$repo_root" >"$worktree/.pr-review-worktree"
  (cd "$worktree" && gh pr checkout "$pr" --detach >/dev/null)

  trap - INT TERM EXIT
  printf '%s\n' "$worktree"
}

cleanup() {
  require_arg "${1:-}"

  worktree="$1"
  marker="$worktree/.pr-review-worktree"

  if [ ! -f "$marker" ]; then
    echo "Refusing to remove worktree without .pr-review-worktree marker: $worktree" >&2
    exit 1
  fi

  repo_root="$(cat "$marker")"

  if [ ! -d "$repo_root/.git" ] && ! git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
    echo "Refusing to remove worktree because repository root is invalid: $repo_root" >&2
    exit 1
  fi

  git -C "$repo_root" worktree remove --force "$worktree" >/dev/null
  git -C "$repo_root" worktree prune >/dev/null
}

case "${1:-}" in
  setup)
    shift
    setup "$@"
    ;;
  cleanup)
    shift
    cleanup "$@"
    ;;
  *)
    usage
    exit 2
    ;;
esac
