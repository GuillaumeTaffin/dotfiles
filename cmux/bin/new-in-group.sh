#!/usr/bin/env zsh
# Create-in-group variant (for the command/palette action). Runs in the CURRENT
# workspace's tab: finds the caller's group, prompts for a title (prefilled with
# "<group> / "), creates a NEW workspace in that group and renames it. Clearing
# the field leaves it unnamed. Deps: jq, gum.
set -e

ws=$(cmux identify --json | jq -r .caller.workspace_ref)
g=$(cmux workspace-group list --json | jq -c --arg w "$ws" '.groups[]|select(.member_workspace_refs|index($w))')
[ -n "$g" ] || { gum style --foreground 196 "No group for $ws"; exit 1; }
gr=$(printf %s "$g" | jq -r .ref)
gn=$(printf %s "$g" | jq -r .name)

clear
gum style --border rounded --padding "0 1" --border-foreground 212 "New workspace in  $gn"
t=$(gum input --value "$gn / " --placeholder "title (clear for default name)") || exit 1
t=$(printf %s "$t" | sed 's/[[:space:]]*$//')

nw=$(CMUX_QUIET=1 cmux workspace-group new-workspace "$gr" --json | jq -r .workspace_ref)
if [ -n "$t" ]; then cmux workspace rename "$nw" --title "$t"; fi
cmux workspace select "$nw"
cmux close-surface --surface "$CMUX_SURFACE_ID"
