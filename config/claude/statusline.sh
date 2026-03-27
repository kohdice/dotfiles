#!/usr/bin/env bash

# Read JSON input from stdin
input=$(cat)

MODEL_DISPLAY=$(echo "$input" | jq -r '.model.display_name // "Claude"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty | round')
CTX_TOKENS=$(echo "$input" | jq -r '
  .context_window.current_usage // null |
  if . == null then empty
  else (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)
  end')
FIVE_HOUR_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty | round')
SEVEN_DAY_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty | round')

# Git branch information
GIT_BRANCH=""
if git rev-parse &>/dev/null; then
  BRANCH=$(git branch --show-current)
  if [ -n "$BRANCH" ]; then
    GIT_BRANCH=" |  $BRANCH"
  else
    COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
    if [ -n "$COMMIT_HASH" ]; then
      GIT_BRANCH=" |  HEAD ($COMMIT_HASH)"
    fi
  fi
fi

# ANSI escape helpers
RST=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'

# colored_pct(pct) - outputs gradient-colored bold percentage
# Gradient: green(0%) -> yellow(50%) -> red(100%)
colored_pct() {
  local pct=${1:-0}
  local r g
  if [ "$pct" -lt 50 ]; then
    r=$(( pct * 51 / 10 ))
    printf '\033[1;38;2;%d;200;80m%d%%\033[0m' "$r" "$pct"
  else
    g=$(( 200 - (pct - 50) * 4 ))
    [ "$g" -lt 0 ] && g=0
    printf '\033[1;38;2;255;%d;60m%d%%\033[0m' "$g" "$pct"
  fi
}

# format_tokens(n) - outputs human-readable token count (e.g., 130.5k, 1.2m)
format_tokens() {
  local tokens=$1
  if [ "$tokens" -ge 1000000 ]; then
    printf '%.1fm' "$(echo "scale=1; $tokens/1000000" | bc)"
  elif [ "$tokens" -ge 1000 ]; then
    printf '%.1fk' "$(echo "scale=1; $tokens/1000" | bc)"
  else
    printf '%d' "$tokens"
  fi
}

# Build metrics section
METRICS=""

if [ -n "$CTX_PCT" ]; then
  if [ -n "$CTX_TOKENS" ]; then
    METRICS="ctx $(format_tokens "$CTX_TOKENS") ($(colored_pct "$CTX_PCT"))"
  else
    METRICS="ctx $(colored_pct "$CTX_PCT")"
  fi
fi
if [ -n "$FIVE_HOUR_PCT" ]; then
  [ -n "$METRICS" ] && METRICS="${METRICS}  "
  METRICS="${METRICS}5h $(colored_pct "$FIVE_HOUR_PCT")"
fi
if [ -n "$SEVEN_DAY_PCT" ]; then
  [ -n "$METRICS" ] && METRICS="${METRICS}  "
  METRICS="${METRICS}7d $(colored_pct "$SEVEN_DAY_PCT")"
fi

# Final output
OUTPUT="󰚩 ${MODEL_DISPLAY} |  ${CURRENT_DIR##*/}${GIT_BRANCH}"
[ -n "$METRICS" ] && OUTPUT="${OUTPUT} |  ${METRICS}"
printf '%s\n' "$OUTPUT"
