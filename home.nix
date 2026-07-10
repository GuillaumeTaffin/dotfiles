{ config, pkgs, user, ... }:
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    # fast core CLIs
    ripgrep
    fd
    jq
    fzf
    # git & friends
    git
    delta            # Homebrew: git-delta
    lazygit
    gh
    difftastic
    # net / http
    curl
    wget
    httpie
    hey
    # shell / text utils
    gum
    shellcheck
    gawk             # Homebrew: awk (GNU awk)
    coreutils
    # build
    cmake
    ninja
    # editors / misc
    neovim
    pass
    terraform-docs
    ansible
    awscli2          # Homebrew "awscli" is v2
    htop
    stow
    tmux
    # language version managers / runtimes (Nix-installed)
    rustup
    uv
    fnm
    bun
    pnpm
  ];

  programs.home-manager.enable = true;

  # ---------------------------------------------------------------- shell ----
  programs.zsh = {
    enable = true;

    # Replace the two git-submodule plugins (config/dependencies/*).
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      gw = "./gradlew";
      gwq = "./gradlew -q";
      lg = "lazygit";
      clodo = "clear && claude --model claude-opus-4-7";
    };

    # home-manager takes over ~/.zshenv, so re-add the cargo env the old
    # standalone ~/.zshenv sourced (keeps ~/.cargo/bin on PATH).
    envExtra = ''
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    '';

    initContent = ''
      # --- environment ---
      export XDG_CONFIG_HOME="$HOME/.config"
      export EDITOR=idea

      # --- PATH additions ---
      export PATH="$PATH:$HOME/.pub-cache/bin"
      export PATH="$PATH:$HOME/.local/bin"
      export PATH="$HOME/.bun/bin:$PATH"
      export PATH="$HOME/.opencode/bin:$PATH"

      # ZIG
      export ZIG_HOME="$HOME/dev/zig"
      export PATH="$PATH:$ZIG_HOME"

      # pnpm
      export PNPM_HOME="$HOME/Library/pnpm"
      case ":$PATH:" in
        *":$PNPM_HOME/bin:"*) ;;
        *) export PATH="$PNPM_HOME/bin:$PATH" ;;
      esac

      # SDKMAN (invokes brew at shell init)
      export SDKMAN_DIR="$HOME/.sdkman"
      [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

      # worktrunk shell integration
      if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

      # --- lima / remote helpers (kept verbatim; \$SHELL stays escaped) ---
      vcc() { ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -ilc claude"; }
      vci() {
        if [ "$#" -gt 0 ]; then
          ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -ilc '$*'"
        else
          ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -il"
        fi
      }
      wci() {
        if [ "$#" -gt 0 ]; then
          ssh -t lima-cc-dev "cd $PWD && exec \$SHELL -ilc '$*'"
        else
          ssh -t -o ControlPath=none -o SetEnv=LC_WCI_PWD="$PWD" lima-cc-dev
        fi
      }
      vccx() { cmux ssh lima-cc-dev --ssh-option RequestTTY=force -- "cd $PWD && exec \$SHELL -ilc claude"; }
      vcix() { cmux ssh lima-cc-dev --ssh-option RequestTTY=force -- "cd $PWD && exec \$SHELL -il"; }
    '';
  };

  programs.starship.enable = true;

  programs.atuin.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
