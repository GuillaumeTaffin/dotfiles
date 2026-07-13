# Nix for reusable envs: mac + VMs + containers

Reflection note. Can this dotfiles setup become composable Nix "fragments" reused across mac laptops, VMs, and devcontainers?

## Verdict

Yes to all three. The composable fragments already exist as a first-class concept: **Home Manager modules** (user-level) and **NixOS modules** (system-level). VMs are low-friction and common. Containers work but with real friction.

## Reusable unit = Home Manager modules

Split the single `home.nix` by portability, not by tool:

- **`common.nix`** (everywhere): CLI toolbelt (ripgrep, fd, jq, fzf, gh, neovim, tmux...), `programs.zsh`, `starship`, `atuin`, `direnv`, git identity/signing. ~80% of current file is already portable.
- **`darwin.nix`** (mac): `credential.helper = osxkeychain`, `/Users/${user}`, SDKMAN-via-brew, lima `vcc/vci` helpers, `mkOutOfStoreSymlink` paths.
- **`linux.nix`** (VMs + containers): `credential.helper = cache`/libsecret, `/home/${user}`, no brew.

Each consumer imports `common` + its platform module.

## Consumers

| Target | Top layer | Status |
|---|---|---|
| Mac laptop | nix-darwin + HM (current) | done |
| VM | NixOS + HM, image via `nixos-generators` (qcow2/UTM) | common, low friction |
| Container | see below | works, more friction |

## Containers: two distinct goals

1. **Personal toolbelt in any container** (closest to dotfiles intent):
   - **HM standalone**: image installs Nix, runs `home-manager switch`. Reuses exact modules. Cost: Nix in runtime image, bigger/slower.
   - **`dockerTools.buildLayeredImage`**: pure-Nix OCI image, no Dockerfile, good layer caching, reproducible. Best for a shared toolbox image.
2. **Per-project reproducible dev env** (real devcontainer sweet spot): flake **`devShells`** (`nix develop`) or **devenv.sh**, entered via `direnv` (already installed).

Friction: devcontainer spec + VS Code features assume Dockerfile on apt base. Nix works but swims against the current; naive images get large.

## Recommendation

- Refactor into `common` / `darwin` / `linux` modules now. Pure upside.
- VMs: NixOS config + `nixos-generators`.
- Containers: do not reuse whole home config. Use `devShells`/`devenv` per project (leans on existing `direnv`); optionally one `dockerTools` toolbox image. Skip forcing full HM into every devcontainer.

## Caveat: imperative escape hatches

SDKMAN, `.cargo/env`, `.pub-cache`, `~/.opencode` are imperative bits inside Nix. They fight back on Linux. Moving those runtimes to Nix packages or per-project devShells is where reuse pays off.
