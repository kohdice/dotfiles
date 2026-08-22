#!/usr/bin/env bash
# PreToolUse hook: deny dangerous Bash commands before they run.
#
# Emits a "deny" permission decision when a rule matches. Safe commands
# produce no output, so each agent's normal permission rules still apply.

set -uo pipefail

input=$(cat)

tool_name=$(jq -r '.tool_name // ""' <<<"$input")
[ "$tool_name" = "Bash" ] || exit 0

command_line=$(jq -r '.tool_input.command // ""' <<<"$input")
[ -n "$command_line" ] || exit 0

# Rule table, tab separated: <pattern>\t<message>\t<suggestion>
# POSIX character classes stand in for \b and \s, which BSD grep and GNU
# grep disagree on.
rules=(
  $'(^|[[:space:];&|(])rm[[:space:]]+(-rf|-fr|-r[[:space:]]+-f|-f[[:space:]]+-r)([[:space:]]|$)\trm -rf can permanently delete files and directories\tConsider a safer alternative or ensure you have backups'
  $'(^|[;&|(][[:space:]]*)(sudo|su|doas)[[:space:]]\tCommands with sudo/su/doas require administrative access\tRun without elevated privileges'
  $'(^|[[:space:];&|(])chmod[[:space:]]+.*777\tchmod 777 gives all users full access to files\tUse more restrictive permissions like 755 or 644'
  $'(^|[[:space:];&(])(curl|wget)[[:space:]][^|]*[|][[:space:]]*(bash|sh)([[:space:]]|$)\tPiping curl/wget to bash/sh executes remote code without inspection\tDownload the script first, review it, then execute it separately'
)

reasons=()
for rule in "${rules[@]}"; do
  IFS=$'\t' read -r pattern message suggestion <<<"$rule"
  if printf '%s\n' "$command_line" | grep -qE "$pattern"; then
    reasons+=("${message}"$'\n'"  → ${suggestion}")
  fi
done

[ ${#reasons[@]} -eq 0 ] && exit 0

reason=$(printf '%s\n\n' "${reasons[@]}")

jq -n --arg reason "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'
