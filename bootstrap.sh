#!/usr/bin/env bash
# Fresh Apple-Silicon Mac -> built nix-darwin config. Run ONCE, from inside the
# cloned repo:  git clone <url> && cd dotfiles && ./bootstrap.sh [host]
# host is work|perso; omitted, it is derived from the current account name.
# Idempotent.
set -euo pipefail

# This repo's real location (wherever you cloned it). modules/common/home.nix
# resolves its edit-in-place symlinks through the stable ~/.dotfiles-mac pointer
# created below, so the clone can live anywhere.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=host.sh
. "$REPO/host.sh"
HOST="$(resolve_host "${1:-}")"
FLAKE="$REPO#$HOST"
echo "==> host: $HOST"

# Run unattended: accept the nixConfig that flake inputs declare, and ask for
# the sudo password once instead of at every brew cask that writes to /Library.
export NIX_CONFIG="accept-flake-config = true"
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT

# 0. Point ~/.dotfiles-mac at this clone.
echo "==> Linking ~/.dotfiles-mac -> $REPO"
ln -sfn "$REPO" "$HOME/.dotfiles-mac"

# 1. Xcode Command Line Tools (provides git + cc).
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools (accept the GUI prompt)"
  xcode-select --install
  echo "    Re-run ./bootstrap.sh once that install finishes."
  exit 0
fi

# 2. Nix, OFFICIAL multi-user installer. If Nix is already installed but not
#    on PATH (this script moved the /etc shell hooks aside for nix-darwin on a
#    previous, partially-failed run), source the daemon profile instead of
#    reinstalling: the installer aborts on its own leftover backups.
if ! command -v nix >/dev/null 2>&1 && [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
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

# 3a. /etc/synthetic.conf: nix-darwin's activation needs a `run` entry there to
#     create the /run symlink, and aborts if the file is absent. Recent Nix
#     installers (>= 2.35) no longer create it, so ensure it exists ourselves.
#     apfs.util -t applies it immediately, no reboot needed.
if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
  echo "==> Adding run entry to /etc/synthetic.conf"
  printf 'run\tprivate/var/run\n' | sudo tee -a /etc/synthetic.conf >/dev/null
  sudo chmod 644 /etc/synthetic.conf
  sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || true
fi

# 3a-bis. Same file, `nix` entry: the /nix mount point at the sealed root only
#     exists because it is recreated at boot from this line. Plain reboots
#     survive without it (the firmlink persists), but a macOS UPDATE rebuilds
#     the sealed snapshot and silently deletes /nix if the line is missing
#     (bit the perso Mac on the 26.6 update, 2026-07-29).
if ! grep -qx 'nix' /etc/synthetic.conf 2>/dev/null; then
  echo "==> Adding nix entry to /etc/synthetic.conf"
  printf 'nix\n' | sudo tee -a /etc/synthetic.conf >/dev/null
  sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || true
fi

# 3a-ter. Boot-time mount of the Nix Store volume. The installer is supposed to
#     leave this LaunchDaemon behind; it was missing on the perso Mac, so make
#     sure it exists whenever the volume does. Passphrase lives in the system
#     keychain under the volume UUID (installer convention).
if [ ! -f /Library/LaunchDaemons/org.nixos.darwin-store.plist ] \
   && diskutil info "Nix Store" >/dev/null 2>&1; then
  echo "==> Creating org.nixos.darwin-store LaunchDaemon"
  VOL_UUID="$(diskutil info "Nix Store" | awk '/Volume UUID/{print $3}')"
  if diskutil info "Nix Store" | grep -q 'FileVault: *Yes'; then
    MOUNT_CMD="/usr/bin/security find-generic-password -s '$VOL_UUID' -w /Library/Keychains/System.keychain | /usr/sbin/diskutil apfs unlockVolume '$VOL_UUID' -mountpoint /nix -stdinpassphrase"
  else
    MOUNT_CMD="/usr/sbin/diskutil mount -mountPoint /nix '$VOL_UUID'"
  fi
  sudo tee /Library/LaunchDaemons/org.nixos.darwin-store.plist >/dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>RunAtLoad</key>
  <true/>
  <key>Label</key>
  <string>org.nixos.darwin-store</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/sh</string>
    <string>-c</string>
    <string>$MOUNT_CMD</string>
  </array>
</dict>
</plist>
EOF
  sudo chown root:wheel /Library/LaunchDaemons/org.nixos.darwin-store.plist
  sudo chmod 644 /Library/LaunchDaemons/org.nixos.darwin-store.plist
  sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.darwin-store.plist 2>/dev/null || true
fi

# 3b. Move macOS /etc shell files aside (nix-darwin refuses to overwrite them).
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
echo "==> First switch (flake attr #$HOST)"
sudo "$NIX_BIN" --extra-experimental-features 'nix-command flakes' \
  --accept-flake-config \
  run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
  switch --flake "$FLAKE" --option accept-flake-config true

# 5. SDKMAN (replaces the retired brew formula; ~/.sdkman is what zsh sources).
#    - needs Bash 4+: macOS ships 3.2, nix-darwin ships bash 5
#    - SDKMAN_DIR forced: a stale env var would redirect the install
#    - ZDOTDIR diverted: the installer appends to $ZDOTDIR/.zshrc, but ours is a
#      read-only nix store symlink (zshrc already sources sdkman-init.sh anyway)
if [ ! -d "$HOME/.sdkman" ]; then
  echo "==> Installing SDKMAN"
  ZDOT_TMP="$(mktemp -d)" && touch "$ZDOT_TMP/.zshrc"
  curl -s "https://get.sdkman.io" \
    | SDKMAN_DIR="$HOME/.sdkman" ZDOTDIR="$ZDOT_TMP" /run/current-system/sw/bin/bash
  rm -rf "$ZDOT_TMP"
fi

cat <<'EOF'

==> Done.
Manual, out-of-nix-scope steps:
  - JetBrains Toolbox (installed as a brew cask): sign in, enable Settings Sync.
  - IntelliJ IDEA: install via Toolbox (~/.ideavimrc is already symlinked).
  - SDKMAN candidates: `sdk install java <ver>` etc. as needed.
Day-to-day changes: edit configs in the repo, then ./rebuild.sh
EOF
