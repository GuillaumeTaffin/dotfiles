#!/usr/bin/env zsh
# Order cmux workspace groups alphanumerically by name (case-insensitive).
# Deps: cmux, jq.
# Usage:
#   sort-spaces.sh            # resort ALL groups A -> Z
#   sort-spaces.sh <group>    # place one group in its alpha slot
#                             #   (ref/name; assumes the rest already sorted)
# Note: pinned groups are pinned to the top by cmux; this only orders the rest.
set -e

list() { cmux workspace-group list --json; }

if [ $# -eq 0 ]; then
  # Full sort: move each group to its target index in alpha order.
  i=0
  list | jq -r '.groups[] | "\(.name)\t\(.ref)"' | sort -f | while IFS=$'\t' read -r name ref; do
    cmux workspace-group move "$ref" --to-index "$i" --json >/dev/null
    i=$((i + 1))
  done
  exit 0
fi

# Insert one: find the first group whose name sorts after the target's, move before it.
json=$(list)
row=$(jq -r --arg t "$1" '.groups[] | select(.ref==$t or .name==$t) | "\(.ref)\t\(.name)"' <<<"$json" | head -1)
[ -n "$row" ] || { print -u2 "sort-spaces: no group matches '$1'"; exit 1; }
target="${row%%$'\t'*}"; name="${row#*$'\t'}"

before=""
while IFS=$'\t' read -r n r; do
  [ "$r" = "$target" ] && continue
  if [[ "${n:l}" > "${name:l}" ]]; then before="$r"; break; fi
done < <(jq -r '.groups[] | "\(.name)\t\(.ref)"' <<<"$json" | sort -f)

if [ -n "$before" ]; then
  cmux workspace-group move "$target" --before "$before" --json >/dev/null
else
  count=$(jq '.groups | length' <<<"$json")
  cmux workspace-group move "$target" --to-index "$((count - 1))" --json >/dev/null
fi
