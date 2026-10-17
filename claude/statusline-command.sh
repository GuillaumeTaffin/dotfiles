#!/bin/sh
input=$(cat)

# DEBUG: uncomment to inspect the full JSON payload
# echo "$input" | jq . > /tmp/statusline-debug.json

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
dir=$(basename "$cwd")
effort_level=$(echo "$input" | jq -r '.effort.level // empty')

# Remote session: surface the host so a VM/SSH shell is never mistaken for local.
ssh_host=""
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CLIENT" ]; then
  ssh_host=$(hostname -s 2>/dev/null || uname -n)
fi

# Fallback to settings if not in JSON
if [ -z "$effort_level" ]; then
  effort_level=$(jq -r '.effortLevel // "default"' "$HOME/.claude/settings.json" 2>/dev/null)
fi

case "$effort_level" in
  max)    effort="max" ;;
  xhigh)  effort="xhigh" ;;
  high)   effort="high" ;;
  medium) effort="med" ;;
  low)    effort="low" ;;
  *)      effort="$effort_level" ;;
esac

# Git branch + working tree status
branch=""
git_counts=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  git_counts=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null | awk '
    BEGIN { ahead = 0; behind = 0 }
    /^# branch\.ab / { ahead = $3 + 0; behind = -($4 + 0) }
    /^[12] / {
      if (substr($2, 1, 1) != ".") staged++
      if (substr($2, 2, 1) != ".") unstaged++
    }
    /^\? / { untracked++ }
    /^u / { conflicts++ }
    END { printf "%d %d %d %d %d %d", staged, unstaged, untracked, conflicts, ahead, behind }
  ')
fi

# Colors
reset="\033[0m"
dim="\033[2m"
cyan="\033[36m"
blue="\033[34m"
yellow="\033[33m"
magenta="\033[35m"
green="\033[32m"
red="\033[31m"

# Context window: use current_usage fields for accurate counts matching /context
window=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
cu=$(echo "$input" | jq '.context_window.current_usage // empty')

used=""
used_pct=""
if [ "$cu" != "" ] && [ "$cu" != "null" ]; then
  cache_read=$(echo "$cu" | jq -r '.cache_read_input_tokens // 0')
  cache_create=$(echo "$cu" | jq -r '.cache_creation_input_tokens // 0')
  input_tok=$(echo "$cu" | jq -r '.input_tokens // 0')
  output_tok=$(echo "$cu" | jq -r '.output_tokens // 0')
  used=$(( cache_read + cache_create + input_tok + output_tok ))
  if [ -n "$window" ] && [ "$window" -gt 0 ] 2>/dev/null; then
    used_pct=$(awk "BEGIN{printf \"%.1f\", $used/$window*100}")
  fi
fi

# Format token count: show as Xkt when >= 1000
fmt_tokens() {
  val=$1
  if [ "$val" -ge 1000 ] 2>/dev/null; then
    printf '%.1fk' "$(echo "$val" | awk '{printf "%.1f", $1/1000}')"
  else
    printf '%s' "$val"
  fi
}

# Format window size
fmt_window() {
  val=$1
  if [ "$val" -ge 1000 ] 2>/dev/null; then
    printf '%.0fk' "$(echo "$val" | awk '{printf "%.0f", $1/1000}')"
  else
    printf '%s' "$val"
  fi
}

# Build git status segment: +staged !unstaged ?untracked ✖conflicts ↑ahead ↓behind
git_seg=""
if [ -n "$git_counts" ]; then
  set -- $git_counts
  staged=$1 unstaged=$2 untracked=$3 conflicts=$4 ahead=$5 behind=$6
  [ "$staged" -gt 0 ] && git_seg="${git_seg} ${green}+${staged}${reset}"
  [ "$unstaged" -gt 0 ] && git_seg="${git_seg} ${yellow}!${unstaged}${reset}"
  [ "$untracked" -gt 0 ] && git_seg="${git_seg} ${dim}?${untracked}${reset}"
  [ "$conflicts" -gt 0 ] && git_seg="${git_seg} ${red}\xE2\x9C\x96${conflicts}${reset}"
  [ "$ahead" -gt 0 ] && git_seg="${git_seg} ${cyan}\xE2\x86\x91${ahead}${reset}"
  [ "$behind" -gt 0 ] && git_seg="${git_seg} ${cyan}\xE2\x86\x93${behind}${reset}"
fi

left=""
[ -n "$ssh_host" ] && left="${magenta}${ssh_host}${reset}  "
left="${left}${cyan}${model}${reset}"
left="${left}  ${dim}${effort}${reset}"
[ -n "$branch" ] && left="${left}  ${blue}${branch}${reset}${git_seg}"
left="${left}  ${yellow}${dir}${reset}"

right=""
if [ -n "$used" ] && [ -n "$window" ] && [ -n "$used_pct" ]; then
  used_fmt=$(fmt_tokens "$used")
  window_fmt=$(fmt_window "$window")
  right="${dim}${used_fmt} / ${window_fmt} ($(printf '%.0f' "$used_pct")%)${reset}"
fi

if [ -n "$right" ]; then
  printf "%b  %b" "$left" "$right"
else
  printf "%b" "$left"
fi
