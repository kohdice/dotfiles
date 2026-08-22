#!/usr/bin/env bash
# Stop hook: format and lint the files edited during the session.
#
# Each edited file is resolved to its own project root via the build
# manifest, so the tools run against the right project even when the
# session touched several repositories. Exits 2 when a linter reports
# issues, which hands the output back to Claude instead of stopping.

set -uo pipefail

input=$(cat)

# Set once this hook has already blocked, so honouring it avoids a loop.
[ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0

transcript=$(jq -r '.transcript_path // ""' <<<"$input")
[ -f "$transcript" ] || exit 0

# Edit results carry filePath, Write/Edit tool calls carry file_path.
# fromjson? skips lines that are truncated or not valid JSON.
edited_files=$(jq -rR '
  fromjson? // empty
  | objects
  | [ (.toolUseResult | objects | (.file_path // .filePath // empty)),
      (.message | objects | .content | arrays | .[] | objects
        | select(.type == "tool_use")
        | select(.name == "Edit" or .name == "Write" or .name == "MultiEdit")
        | .input | objects | (.file_path // .filePath // empty))
    ]
  | .[]
' "$transcript" 2>/dev/null | sort -u)

[ -n "$edited_files" ] || exit 0

# find_project_root <dir> <marker> - walks up until <marker> is found.
find_project_root() {
  local dir=$1 marker=$2
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -e "$dir/$marker" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

targets=""
while IFS= read -r file; do
  [ -f "$file" ] || continue
  case $file in
  *.rs) lang=rust marker=Cargo.toml ;;
  *.go) lang=go marker=go.mod ;;
  *.zig) lang=zig marker=build.zig ;;
  *) continue ;;
  esac
  root=$(find_project_root "$(dirname "$file")" "$marker") || continue
  targets="${targets}${lang}"$'\t'"${root}"$'\n'
done <<<"$edited_files"

targets=$(printf '%s' "$targets" | sort -u)
[ -n "$targets" ] || exit 0

tool_available() { command -v "$1" >/dev/null 2>&1; }

# run_format <root> <cmd...> - formatting problems are reported, never blocking.
run_format() {
  local root=$1
  shift
  tool_available "$1" || {
    printf '• %s is not installed, skipping format in %s\n' "$1" "$root" >&2
    return 0
  }
  local out
  if ! out=$( (cd "$root" && "$@") 2>&1); then
    printf '• %s failed in %s\n%s\n' "$*" "$root" "$out" >&2
  fi
}

blocked=0

# run_lint <root> <label> <cmd...> - sets blocked when the linter reports issues.
run_lint() {
  local root=$1 label=$2
  shift 2
  tool_available "$1" || {
    printf '• %s is not installed, skipping lint in %s\n' "$1" "$root" >&2
    return 0
  }
  local out status
  out=$( (cd "$root" && "$@") 2>&1)
  status=$?
  if [ "$status" -ne 0 ]; then
    printf '• %s found issues in %s\n%s\n' "$label" "$root" "$out" >&2
    blocked=1
  elif [ "$label" = "cargo clippy" ] && printf '%s' "$out" | grep -q 'warning:'; then
    # clippy can exit 0 while still printing warnings.
    printf '• %s found warnings in %s\n%s\n' "$label" "$root" "$out" >&2
    blocked=1
  fi
}

while IFS=$'\t' read -r lang root; do
  [ -n "$root" ] || continue
  case $lang in
  rust)
    run_format "$root" cargo fmt
    run_lint "$root" "cargo clippy" cargo clippy -- -D warnings
    ;;
  go)
    if tool_available golangci-lint; then
      run_format "$root" golangci-lint fmt
      run_lint "$root" "golangci-lint run" golangci-lint run
    else
      run_format "$root" go fmt ./...
      run_lint "$root" "go vet" go vet ./...
    fi
    ;;
  zig)
    run_format "$root" zig fmt .
    ;;
  esac
done <<<"$targets"

[ "$blocked" -eq 0 ] && exit 0
exit 2
