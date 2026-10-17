#!/usr/bin/env bash
# Re-apply the config:  ./rebuild.sh [extra darwin-rebuild args...]
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  echo "note: $REPO has uncommitted changes (building from working tree)"
fi
export NIX_CONFIG="accept-flake-config = true"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
trap 'kill %1 2>/dev/null || true' EXIT

echo "==> switch --flake $REPO#perso"
sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$REPO#perso" --option accept-flake-config true "$@"
