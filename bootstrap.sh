#!/usr/bin/env bash
# Fresh Apple-Silicon Mac -> built nix-darwin config. Run ONCE, from inside the
# cloned repo:  git clone <url> && cd dotfiles && ./bootstrap.sh   Idempotent.
set -euo pipefail

# This repo's real location (wherever you cloned it). home.nix resolves its
# edit-in-place symlinks through the stable ~/.dotfiles pointer created below,
# so the clone can live anywhere.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLAKE="$REPO#mac"

# 0. Point ~/.dotfiles at this clone.
echo "==> Linking ~/.dotfiles -> $REPO"
ln -sfn "$REPO" "$HOME/.dotfiles"

# 1. Xcode Command Line Tools (provides git + cc).
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools (accept the GUI prompt)"
  xcode-select --install
  echo "    Re-run ./bootstrap.sh once that install finishes."
  exit 0
fi

# 2. Nix, OFFICIAL multi-user installer.
if ! command -v nix >/dev/null 2>&1; then
  echo "==> Installing Nix (official multi-user)"
  sh <(curl -L https://nixos.org/nix/install)
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
if ! command -v nix >/dev/null 2>&1; then
  echo "    nix still not on PATH. Open a NEW terminal and re-run ./bootstrap.sh."
  exit 1
fi

# 3. Move macOS /etc shell files aside (nix-darwin refuses to overwrite them).
for f in bashrc zshrc; do
  if [ -e "/etc/$f" ] && [ ! -L "/etc/$f" ] && [ ! -e "/etc/$f.before-nix-darwin" ]; then
    echo "==> Backing up /etc/$f -> /etc/$f.before-nix-darwin"
    sudo mv "/etc/$f" "/etc/$f.before-nix-darwin"
  fi
done

# 4. First switch (darwin-rebuild not installed yet; official installer has no
#    flakes yet, so pass the feature flag on THIS call only). sudo strips the
#    nix bin dir from PATH, so resolve nix's absolute path first.
NIX_BIN="$(command -v nix)"
echo "==> First switch (flake attr #mac)"
sudo "$NIX_BIN" --extra-experimental-features 'nix-command flakes' \
  run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake "$FLAKE"

# 5. SDKMAN (replaces the retired brew formula; ~/.sdkman is what zsh sources).
if [ ! -d "$HOME/.sdkman" ]; then
  echo "==> Installing SDKMAN"
  curl -s "https://get.sdkman.io" | bash
fi

cat <<'EOF'

==> Done.
Manual, out-of-nix-scope steps:
  - JetBrains Toolbox (installed as a brew cask): sign in, enable Settings Sync.
  - IntelliJ IDEA: install via Toolbox (~/.ideavimrc is already symlinked).
  - SDKMAN candidates: `sdk install java <ver>` etc. as needed.
Day-to-day changes: edit configs in the repo, then ./rebuild.sh
EOF
