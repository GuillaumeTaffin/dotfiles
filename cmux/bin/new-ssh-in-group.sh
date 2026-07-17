#!/usr/bin/env zsh
# Create a new cmux SSH workspace into the lima VM, placed in the CALLER's
# workspace group, landing in the caller's current directory (lima mounts the
# mac home at the same path). Prints the new workspace_ref on stdout.
# Side-effect-clean: no focus change, no close-surface (GUI glue does that).
# Deps: cmux, jq.
# Usage: new-ssh-in-group.sh [ssh-destination]   # default: lima-cc-dev
set -e

dest="${1:-lima-cc-dev}"

id=$(cmux identify --json)
ws=$(jq -r .caller.workspace_ref <<<"$id")
win=$(jq -r .caller.window_ref <<<"$id")

# Caller's group (fail if ungrouped).
groups=$(cmux workspace-group list --json)
gr=$(jq -r --arg w "$ws" '.groups[]|select(.member_workspace_refs|index($w))|.ref' <<<"$groups" | head -1)
[ -n "$gr" ] || { print -u2 "new-ssh-in-group: caller $ws is not in a workspace group"; exit 1; }
gn=$(jq -r --arg g "$gr" '.groups[]|select(.ref==$g)|.name' <<<"$groups")

# Caller's cwd, mirrored onto the VM. Semicolon (not &&) so a missing dir just
# lands in the VM home instead of leaving no shell.
cwd=$(cmux workspace list --window "$win" --json | jq -r --arg w "$ws" '.workspaces[]|select(.ref==$w)|.current_directory // ""')
remote='exec $SHELL -il'
[ -n "$cwd" ] && remote="cd '$cwd' 2>/dev/null; $remote"

# Create the SSH workspace (lands outside the group), without stealing focus.
new=$(cmux ssh "$dest" --ssh-option RequestTTY=force --no-focus --name "$gn / ${dest#lima-}" --json -- "$remote" | jq -r .workspace_ref)
[ -n "$new" ] || { print -u2 "new-ssh-in-group: cmux ssh did not return a workspace_ref"; exit 1; }

# Move it into the caller's group.
cmux workspace-group add --group "$gr" --workspace "$new" >/dev/null

print "$new"
