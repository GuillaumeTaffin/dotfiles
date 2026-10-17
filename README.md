# dotfiles

macOS (Apple Silicon) setup, declarative and reproducible via **nix-darwin + home-manager + nix-homebrew**, with **mise** for CLIs and toolchains.

One host, `perso`: account `guillaumetaffin`, `cloudgt.dev@gmail.com`, GPG commit signing.

- Fresh machine: `git clone https://github.com/GuillaumeTaffin/dotfiles.git && cd dotfiles && ./bootstrap.sh` (run once). The clone can live anywhere; `bootstrap.sh` points `~/.dotfiles-mac` at it.
- Day-to-day: `./rebuild.sh` (after editing any nix config)

## Who owns what
- nix-darwin (`system.nix`): Nix daemon, macOS defaults, zsh + PATH ordering, tailscale, Homebrew casks/brews (incl. `mise`). nix-homebrew adopts the existing `/opt/homebrew` (`cleanup = "uninstall"`: unlisted brews/casks are removed on switch).
- home-manager (`home.nix`): dotfile symlinks, git identity + signing, zsh, starship, atuin, machine base CLIs (curl, coreutils, gnupg, tmux...).
- mise global (`mise/config.toml`, symlinked to `~/.config/mise/config.toml`): everyday CLIs (ripgrep, fd, jq, yq, fzf, bat, just, gh, doppler, uv, pi, worktrunk; node only as npm runtime). Update with `mise up`; `mise use -g` edits the repo file.
- Per project `mise.toml`: languages and toolchains (`mise use <tool>@<ver>` in the project).
- Native installers: claude (`~/.local/bin`), opencode (`~/.opencode/bin`).

## Intentionally manual (out of nix scope)
- JetBrains Settings Sync + IntelliJ IDEA (installed via Toolbox; `~/.ideavimrc` is symlinked).

## Layout
- `flake.nix`: entry point, `darwinConfigurations.perso`.
- `system.nix` / `home.nix`: nix-darwin system, home-manager user.
- `bootstrap.sh` / `rebuild.sh`: first switch / re-apply.
- `claude/`, `cmux/`, `pi/`, `mise/`, `ideavimrc`: config sources symlinked by `home.nix`.
- `flake.lock`: pinned inputs (committed).
- `docs/`: design write-ups.

## Edit in place
Files under `claude/`, `cmux/`, `pi/`, `mise/` and `ideavimrc` are the real configs; home-manager symlinks them into `$HOME`, so edits are live. Run `./rebuild.sh` only when changing package lists, macOS defaults, or the symlink set. The repo may live at any path; the symlinks resolve through the `~/.dotfiles-mac` pointer (created by `bootstrap.sh`), not a hardcoded location. The name is `-mac` on purpose: the `dotfiles-linux` repo's bootstrap claims plain `~/.dotfiles`.

## Validate without applying
    darwin-rebuild build --flake ~/dev/projects/dotfiles#perso
