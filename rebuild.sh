#!/usr/bin/env bash
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  echo "note: $REPO has uncommitted changes (building from working tree)"
fi
exec sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$REPO#mac" "$@"
