# Homebrew audit - perso Mac (phase 1, decided)

Snapshot before migration: 57 leaf formulae, 30 casks, 15 taps, all imperative.

Outcome: brew keeps only GUI apps and JVM build tools; every CLI moves to Nix.

## Final state

### Nix (`modules/common/home.nix`, shared with the work Mac)
Already there: `ripgrep fd jq fzf lazygit gh difftastic curl wget httpie hey gum shellcheck
gawk coreutils cmake ninja neovim pass terraform-docs ansible awscli2 htop tmux rustup uv
fnm bun pnpm pi-coding-agent`
Added by this audit: `gnugrep bat tree watch yq-go just ast-grep gnupg pinentry_mac`

### Nix (`hosts/perso/home.nix`, this Mac only)
`docker-compose kubectx stern cloudflared doppler aws-sam-cli go`

### Homebrew (`modules/common/system.nix`)
casks: `cmux ghostty visual-studio-code zed rectangle t3-code`

### Homebrew (`hosts/perso/system.nix`)
brews: `herdr pandoc maven gradle kotlin`
casks: `raycast slack notion`

## Uninstall list (phase 2)

### Formulae - shadowed by Nix
`awscli bun cmake curl fd fzf gawk gh hey httpie jq lazygit ninja pnpm ripgrep rustup tmux`

### Formulae - superseded by the Nix config itself
| formula | replaced by |
|---|---|
| `git` | `programs.git.enable` (home-manager installs `pkgs.git`) |
| `zsh-syntax-highlighting` | `programs.zsh.syntaxHighlighting.enable` |
| `zsh-completions` | `programs.zsh.enableCompletion` |
| `stow` | retired in `f8d9155` (`mkOutOfStoreSymlink`) |
| `zsh` (5.9, installed 2022) | login shell is `/bin/zsh` (system zsh) |

### Formulae - moved to Nix
`bat tree watch yq just ast-grep gnupg grep docker-compose kubectx stern cloudflared
doppler aws-sam-cli go`

### Formulae - dropped (stale or superseded by a version manager)
`elm leiningen groovy luarocks certbot docutils cocoapods elixir rtk minikube`
`openjdk@11 openjdk@17` (SDKMAN owns JDKs)
`node node@18` (fnm owns node)
`python@3.8 python@3.10 python@3.11` (uv owns python)

### Casks - dropped
`android-ndk android-studio flutter gstreamer-runtime` (mobile stack retired)
`basictex cscreen fuse-t fuse-t-sshfs` (stale)
`graalvm-ce-java11 graalvm-ce-java17 graalvm-ce-lts-java11 temurin8 temurin@8` (SDKMAN owns JDKs)
`iterm2 warp` (Ghostty + cmux are the terminals)
`ollama ollama-app utm pgadmin4` (no longer used)
`cmake cmake-app` (duplicate of the Nix `cmake` CLI)

### Formulae - hidden from `brew leaves`, found during phase 2a
`brew leaves` silently omits formulae from third-party taps. These nine were installed and
unlisted; all dropped:
`clojure coursier heroku ligo quarkus supabase tezos-client tezos-sapling-params sdkman-cli`
(`sdkman-cli` had zero candidates installed; `bootstrap.sh` installs SDKMAN to `~/.sdkman`.
The 21 JDKs under `~/Library/Java/JavaVirtualMachines` are untouched by all of this.)

### Then
`brew autoremove` to sweep orphaned dependencies, and `brew untap` every tap with nothing
installed behind it (keeping `manaflow-ai/cmux`; `oven-sh/bun` goes with `bun` in phase 4).

## Phase 2a result

`/opt/homebrew`: 12 GB -> 4.3 GB. Taps 15 -> 2. Casks 30 -> 9 (the keep list exactly).
Formulae: only the "Nix replaces it" bucket plus `gradle kotlin maven pandoc` remain;
phase 4's `cleanup = "uninstall"` sweeps the rest.

## Notes / follow-ups

- `~/.gnupg` is **not** managed by Nix (user state). `gpg-agent.conf` currently sets only cache
  TTLs and relies on the compiled-in pinentry path. After the switch, if signing prompts break,
  add `pinentry-program <nix-store-path>/bin/pinentry-mac` to `~/.gnupg/gpg-agent.conf` and
  `gpgconf --kill gpg-agent`.
- `opencode` stays hand-installed under `~/.opencode/bin` (PATH entry kept in
  `modules/common/home.nix`).
- SDKMAN candidates (`sdk install java ...`) must be reinstalled after the JDK casks/formulae go.
