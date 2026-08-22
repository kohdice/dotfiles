#!/usr/bin/env bash
# PostToolUse hook: record files edited by Claude Code or Codex.
#
# Stop consumes this session-scoped list instead of parsing agent transcripts,
# whose formats are not stable across tools or releases.

set -uo pipefail

input=$(cat)

session_id=$(jq -r '.session_id // ""' <<<"$input")
case $session_id in
"" | *[!A-Za-z0-9._-]*) exit 0 ;;
esac

state_dir="${TMPDIR:-/tmp}/shared-agent-hooks"
mkdir -p "$state_dir" 2>/dev/null || exit 0
chmod 700 "$state_dir" 2>/dev/null || exit 0
state_file="$state_dir/$session_id.edits"

cwd=$(jq -r '.cwd // "."' <<<"$input")

record_file() {
  local file=$1 candidate dir base resolved_dir
  [ -n "$file" ] || return 0

  case $file in
  /*) candidate=$file ;;
  *) candidate="${cwd%/}/$file" ;;
  esac

  dir=$(dirname -- "$candidate")
  base=$(basename -- "$candidate")
  if resolved_dir=$(cd "$dir" 2>/dev/null && pwd -P); then
    candidate="$resolved_dir/$base"
  fi

  printf '%s\n' "$candidate" >>"$state_file" 2>/dev/null || true
}

tool_name=$(jq -r '.tool_name // ""' <<<"$input")
case $tool_name in
Edit | Write | MultiEdit)
  while IFS= read -r file; do
    record_file "$file"
  done < <(
    jq -r '
      .tool_input
      | [(.file_path // .filePath // empty),
         (.edits[]? | .file_path // .filePath // empty)]
      | .[]
    ' <<<"$input"
  )
  ;;
apply_patch)
  patch=$(jq -r '.tool_input.command // ""' <<<"$input")
  while IFS= read -r file; do
    record_file "$file"
  done < <(
    printf '%s\n' "$patch" | awk '
      /^\*\*\* (Add|Update|Delete) File: / {
        sub(/^\*\*\* (Add|Update|Delete) File: /, "")
        print
        next
      }
      /^\*\*\* Move to: / {
        sub(/^\*\*\* Move to: /, "")
        print
      }
    '
  )
  ;;
esac
