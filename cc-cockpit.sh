#!/bin/sh
# cc-cockpit — Claude Code statusline with colored usage gauges
# Reads Claude Code's native statusline stdin JSON (rate_limits, context_window)
# and renders 5h / 7d / context usage as colored bar gauges.
#
# Concept inspired by claude-hud (github.com/jarrodwatts/claude-hud); this is an
# independent implementation, not a fork.

input=$(cat)

five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage | numbers? // empty' 2>/dev/null)
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at | numbers? // empty' 2>/dev/null)
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage | numbers? // empty' 2>/dev/null)
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at | numbers? // empty' 2>/dev/null)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage | numbers? // empty' 2>/dev/null)
exceeds=$(echo "$input" | jq -r '.exceeds_200k_tokens // false' 2>/dev/null)

format_reset_time()     { [ -n "$1" ] && TZ="Asia/Tokyo" date -r "$1" "+%-H:%M" 2>/dev/null || echo ""; }
format_reset_datetime() { [ -n "$1" ] && TZ="Asia/Tokyo" date -r "$1" "+%-m/%-d %-H:%M" 2>/dev/null || echo ""; }

# ゲージバー生成: $1=パーセント(0-100) $2=バー幅(文字数、既定8)
gauge_bar() {
  pct="$1"
  width="${2:-8}"
  [ -z "$pct" ] && return
  pct_int=$(printf "%.0f" "$pct")
  [ "$pct_int" -gt 100 ] && pct_int=100
  [ "$pct_int" -lt 0 ] && pct_int=0
  filled=$(( pct_int * width / 100 ))
  empty=$(( width - filled ))

  if   [ "$pct_int" -ge 80 ]; then color="\033[31m"  # 赤
  elif [ "$pct_int" -ge 50 ]; then color="\033[33m"  # 黄
  else                             color="\033[32m"  # 緑
  fi
  reset="\033[0m"

  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i+1)); done
  i=0
  while [ "$i" -lt "$empty" ]; do bar="${bar}░"; i=$((i+1)); done

  printf "%b%s %3d%%%b" "$color" "$bar" "$pct_int" "$reset"
}

parts=""

# 5h ゲージ
if [ -n "$five_used" ]; then
  five_time=$(format_reset_time "$five_reset")
  gauge=$(gauge_bar "$five_used" 5)
  [ -n "$five_time" ] && parts="${parts}5h:${gauge}(${five_time})  " || parts="${parts}5h:${gauge}  "
fi

# 7d ゲージ（常時表示）
if [ -n "$week_used" ]; then
  week_dt=$(format_reset_datetime "$week_reset")
  gauge=$(gauge_bar "$week_used" 5)
  [ -n "$week_dt" ] && parts="${parts}7d:${gauge}(${week_dt})  " || parts="${parts}7d:${gauge}  "
fi

# コンテキスト使用率ゲージ
if [ -n "$used_pct" ]; then
  gauge=$(gauge_bar "$used_pct" 5)
  parts="${parts}ctx:${gauge}  "
fi

# ⚡ 警告: ctx 90%以上 or 200k超過
alert=""
if [ "$exceeds" = "true" ]; then
  alert="  ⚡OVER"
elif [ -n "$used_pct" ]; then
  ctx_int=$(printf "%.0f" "$used_pct")
  [ "$ctx_int" -ge 90 ] && alert="  ⚡MAX"
  [ "$ctx_int" -ge 80 ] && [ "$ctx_int" -lt 90 ] && alert="  ⚠️"
fi

printf "%b%b\n" "$parts" "$alert"
