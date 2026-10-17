# Migration plan: bring the personal Mac under nix-darwin

## Situation

The repo is already a complete nix-darwin + home-manager + nix-homebrew setup, but it
was authored for the **work** Mac and never applied to this one.

| | work Mac (target of current flake) | this Mac |
|---|---|---|
| user / `$HOME` | `guillaume.taffin` | `guillaumetaffin` |
| git identity | `guillaume.taffin@akur8.com` | `cloudgt.dev@gmail.com` |
| commit signing | SSH key (`key::ssh-ed25519 …`) | GPG `A2AE5B3978A9CF52` |
| screenshots | `/Users/guillaume.taffin/Screenshots` | n/a |
| `safe.directory` | 3 work repos | n/a |
| Nix | installed | **not installed** |

Current state of this machine:

- Homebrew at `/opt/homebrew`: 55 leaf formulae, 28 casks, 15 taps, all imperative.
- `~/.zshrc` is a **dangling symlink** to `dev/projects/dotfiles/home/.zshrc` (dir retired in `f8d9155`).
- `config/dependencies/{zsh-autosuggestions,zsh-syntax-highlighting}` are untracked clones from
  the pre-nix era; home-manager replaces both.
- `~/.dotfiles` pointer does not exist.
- Ghostty: already installed and already listed in `configuration.nix` casks. Nothing to do.
- herdr: **not** installed, **not** in the config. To be added (homebrew-core formula, agent multiplexer).

## Guardrails

Never touched by any phase: `~/dev/projects/**`, `~/.ssh`, `~/.gnupg`, `~/.aws`, `~/Documents`,
`~/Library` app data, browser profiles, IDE licences. Removals are limited to dev tooling
binaries (brew formulae/casks) and shell dotfiles, all of which the flake re-provides.

---

## Phase 0 - Repo refactor: two hosts (no change to the machine)

Goal: one repo, two `darwinConfigurations`, zero duplication of the shared parts.

```
flake.nix                 darwinConfigurations."work" and ."perso"
modules/
  common/system.nix       Nix daemon, zsh + PATH ordering, macOS defaults, nix-homebrew
  common/home.nix         packages, zsh, starship, atuin, direnv, hunk, symlink set
hosts/
  work/system.nix         user, screenshots path, brews/casks for work
  work/home.nix           akur8 identity + SSH signing + safe.directory
  perso/system.nix        user = guillaumetaffin, brews/casks for perso
  perso/home.nix          cloudgt.dev identity + GPG signing A2AE5B3978A9CF52
```

Parametrised out of the common modules (currently hardcoded to work):
`user`, `system.defaults.screencapture.location`, `programs.git.signing`,
`programs.git.settings.user.*`, `safe.directory`, and the brews/casks lists.

Also in this phase:

- `bootstrap.sh` / `rebuild.sh`: take the host as `$1` (default: detect from `whoami`), instead of
  hardcoding `#mac`.
- Add `herdr` to the perso brews.
- Keep the `~/.opencode/bin` PATH entry (opencode stays hand-installed for now).
- Delete `config/` from the working tree (dead pre-nix zsh plugin clones).

Exit criterion: `git diff` reviewed. Nothing applied yet - Nix is not installed, so it cannot
even be evaluated. Validation happens in Phase 3.

---

## Phase 1 - Homebrew audit (interactive, 10 min)

I produce a keep/drop table over the 55 formulae + 28 casks. Three buckets:

1. **Already provided by Nix -> drop from brew.** Uninstalling avoids `/opt/homebrew/bin`
   shadowing the Nix profile:
   `ripgrep fd jq fzf lazygit gh curl httpie hey gawk cmake ninja awscli tmux rustup bun pnpm`
   plus `stow` (retired) and `zsh-syntax-highlighting` (home-manager provides it).
   `git`, `grep`, `zsh`, `gnupg` need a call: Nix does not list them today, so either declare them
   in `home.nix` or leave the brew ones.
2. **Keep, but declare** in `hosts/perso/system.nix` so brew state becomes reproducible.
   Candidates: `raycast slack notion android-studio flutter ollama utm pgadmin4 iterm2 warp
   visual-studio-code zed cmux ghostty t3-code rectangle` + the JVM/toolchain formulae you
   still use (`maven gradle kotlin openjdk@17 …`).
3. **Drop entirely** - stale experiments (`elm leiningen groovy luarocks certbot
   graalvm-ce-java11 temurin8 basictex cscreen fuse-t …`), your call per line.

Output: the exact `brews`/`casks` lists for the perso host, plus an explicit uninstall list.

---

## Phase 2a - Cleanup of conflicts (destructive, scoped)

Tools that Nix *replaces* (git, gnupg, ripgrep, fd, ...) stay installed through the migration,
so the machine keeps working if phase 3 stalls. Phase 4's `cleanup = "uninstall"` sweeps them
once the switch has succeeded (that is "phase 2b", and it needs no manual step).

Run in this order, all reversible by reinstalling:

1. `rm ~/.zshrc` (dangling symlink; home-manager will own the path).
2. `rm -rf config/` in the repo.
3. `brew uninstall` the *dropped outright* lists from `docs/brew-audit.md` (stale formulae,
   JDKs, node/python, the retired mobile stack, the duplicate terminals).
4. `brew autoremove`, then `brew untap` every tap no longer backing anything installed.
5. Leave `~/.zshenv` and `~/.zprofile` in place: `home-manager.backupFileExtension = "hm-bak"`
   moves `~/.zshenv` aside on the first switch, and `~/.zprofile` is not managed at all.
   Note: `~/.zprofile` here does **not** run `brew shellenv` (it only appends `/opt/homebrew/bin`),
   so the PATH-ordering fix in `common/system.nix` still applies - just for a milder conflict.
6. `~/.claude/settings.json` (regular file today) gets backed up to `.json.hm-bak` automatically;
   confirm the repo copy in `claude/settings.json` is the version you want before switching.

`/etc/zshrc` and `/etc/bashrc` are moved to `.before-nix-darwin` by `bootstrap.sh` itself - no
manual step.

Exit criterion: `brew leaves` and `brew list --cask` match the Phase 1 keep lists.

---

## Phase 3 - Install Nix and first switch

```
cd ~/dev/projects/dotfiles && ./bootstrap.sh perso
```

What it does: links `~/.dotfiles` -> this clone, checks Xcode CLT, installs official multi-user
Nix, backs up `/etc/{zshrc,bashrc}`, then `darwin-rebuild switch --flake .#perso`, then SDKMAN.

Two known re-run points, both handled by the script's idempotency:

- Xcode CLT missing -> script exits, re-run after the GUI install.
- `nix` not yet on PATH -> open a new terminal, re-run.

`nix-homebrew` adopts the existing `/opt/homebrew` in place (`autoMigrate = true`,
`mutableTaps = true`): Cellar, Caskroom and taps survive, only the brew repo is relinked.

Optional dry run once Nix exists, before the switch:
`nix build .#darwinConfigurations.perso.system`

---

## Phase 4 - Verify, then lock brew down

Checks:

- `which -a rg fd jq gh lazygit` -> Nix profile paths first, no `/opt/homebrew` duplicates.
- `readlink ~/.ideavimrc ~/.claude/settings.json ~/.config/cmux/cmux.json` -> point into the repo.
- `git config --get user.email` -> `cloudgt.dev@gmail.com`; a test commit is GPG-signed.
- `herdr --version`, `ghostty` launches, `starship` / `atuin` / `direnv` active in a new shell.
- macOS defaults applied (Finder list view, Dock autohide, key repeat).

Then flip `homebrew.onActivation.cleanup` from `"none"` to `"uninstall"` in the common module and
re-run `./rebuild.sh perso`. From that point brew state is fully declarative: anything not in the
lists is removed on switch. Do this **only** after Phase 1's keep list is confirmed correct.

Finally: commit the refactor, and re-run `./rebuild.sh work` on the work Mac to confirm the
two-host split did not regress it.

---

## Sequencing summary

| Phase | Machine impact | Reversible |
|---|---|---|
| 0 Repo refactor | none | yes (git) |
| 1 Brew audit | none | n/a |
| 2 Cleanup | uninstalls dev tools, removes 1 dotfile symlink | yes (brew reinstall) |
| 3 Bootstrap + switch | installs Nix, applies full config | yes (`darwin-rebuild --rollback`, `/nix` uninstall) |
| 4 Verify + `cleanup = "uninstall"` | brew becomes declarative | yes (revert the flag) |
