# dotfiles

macOS (Apple Silicon) setup, declarative and reproducible via **nix-darwin + home-manager + nix-homebrew**.

Two hosts, one repo:

| host | account | identity |
|---|---|---|
| `work` | `guillaume.taffin` | `guillaume.taffin@akur8.com`, SSH commit signing |
| `perso` | `guillaumetaffin` | `cloudgt.dev@gmail.com`, GPG commit signing |

- Fresh machine: `git clone https://github.com/GuillaumeTaffin/dotfiles.git && cd dotfiles && ./bootstrap.sh [host]` (run once). The clone can live anywhere; `bootstrap.sh` points `~/.dotfiles-mac` at it.
- Day-to-day: `./rebuild.sh [host]` (after editing any config)

`host` is optional: both scripts derive it from the current account name (`host.sh`).

## Managed by nix
- System (`modules/common/system.nix`): Nix daemon, zsh + PATH ordering, macOS defaults (Finder/Dock/keyboard/trackpad), Homebrew. nix-homebrew adopts the existing `/opt/homebrew` (`cleanup = "none"`: never auto-uninstalls).
- User (`modules/common/home.nix`): CLI packages, git, zsh (aliases, autosuggestion + syntax-highlighting, envExtra/initContent), starship, atuin, direnv, hunk.
- Per host (`hosts/<host>/`): git identity + signing, host-only brews/casks, host-only symlinks.
- Dotfiles: `mkOutOfStoreSymlink` links live repo files into `$HOME` (edit in place, no copy step).

## Intentionally manual (out of nix scope)
- JetBrains Settings Sync + IntelliJ IDEA (installed via Toolbox; `~/.ideavimrc` is symlinked).
- SDKMAN is installed by `bootstrap.sh`; candidates (`sdk install java ...`) are manual.

## Layout
- `flake.nix` — entry point; `mkHost`, `darwinConfigurations.{work,perso}`.
- `modules/common/{system,home}.nix` — everything shared by both machines.
- `hosts/<host>/{system,home}.nix` — identity, signing, host-specific packages.
- `bootstrap.sh` / `rebuild.sh` / `host.sh` — first switch / re-apply / host resolution.
- `claude/`, `cmux/`, `git/`, `pi/`, `ideavimrc` — config sources symlinked by `modules/common/home.nix`.
- `flake.lock` — pinned inputs (committed).
- `docs/` — migration notes and design write-ups.

## Edit in place
Files under `claude/`, `cmux/`, `git/`, `pi/` and `ideavimrc` are the real configs; home-manager symlinks them into `$HOME`, so edits are live. Run `./rebuild.sh` only when changing package lists, macOS defaults, or the symlink set. The repo may live at any path; the symlinks resolve through the `~/.dotfiles-mac` pointer (created by `bootstrap.sh`), not a hardcoded location. The name is `-mac` on purpose: the `dotfiles-linux` repo's bootstrap claims plain `~/.dotfiles`.

## Validate without applying
    darwin-rebuild build --flake ~/dev/projects/dotfiles#perso
