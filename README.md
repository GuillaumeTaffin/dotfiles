# dotfiles

macOS (Apple Silicon) setup, declarative and reproducible via **nix-darwin + home-manager + nix-homebrew**.

- Fresh machine: `git clone https://github.com/GuillaumeTaffin/dotfiles.git && cd dotfiles && ./bootstrap.sh` (run once). The clone can live anywhere; `bootstrap.sh` points `~/.dotfiles` at it.
- Day-to-day: `./rebuild.sh` (after editing any config)

## Managed by nix
- System (`configuration.nix`): Nix daemon, zsh + PATH ordering, macOS defaults (Finder/Dock/keyboard/trackpad), Homebrew. nix-homebrew adopts the existing `/opt/homebrew` (`cleanup = "none"`: never auto-uninstalls). Casks include JetBrains Toolbox.
- User (`home.nix`): CLI packages, git, zsh (aliases, autosuggestion + syntax-highlighting, envExtra/initContent), starship, atuin, direnv.
- Dotfiles: `mkOutOfStoreSymlink` links live repo files into `$HOME` (edit in place, no copy step).

## Intentionally manual (out of nix scope)
- JetBrains Settings Sync + IntelliJ IDEA (installed via Toolbox; `~/.ideavimrc` is symlinked).
- SDKMAN is installed by `bootstrap.sh`; candidates (`sdk install java ...`) are manual.

## Layout
- `flake.nix` — entry point; `darwinConfigurations."mac"`, `user` var.
- `configuration.nix` — system + macOS defaults + Homebrew (taps/brews/casks).
- `home.nix` — user env + the symlink set.
- `bootstrap.sh` / `rebuild.sh` — first switch / re-apply.
- `claude/`, `cmux/`, `git/`, `ideavimrc` — config sources symlinked by home.nix.
- `flake.lock` — pinned inputs (committed).

## Edit in place
Files under `claude/`, `cmux/`, `git/` and `ideavimrc` are the real configs; home.nix symlinks them into `$HOME`, so edits are live. Run `./rebuild.sh` only when changing package lists, macOS defaults, or the symlink set. The repo may live at any path; home.nix resolves configs through the ~/.dotfiles symlink (created by bootstrap.sh), not a hardcoded location.

## Validate without applying
    darwin-rebuild build --flake ~/dev/projects/dotfiles#mac
