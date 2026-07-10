{ config, pkgs, user, ... }:
let
  repo = "${config.home.homeDirectory}/.dotfiles";
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
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
    tmux
    # language version managers / runtimes (Nix-installed)
    rustup
    uv
    fnm
    bun
    pnpm
  ];

  programs.home-manager.enable = true;

  # ---- Phase 4: edit-in-place symlinks back into the dotfiles repo ----
  home.file = {
    ".ideavimrc".source = mkOutOfStoreSymlink "${repo}/ideavimrc";

    ".claude/settings.json".source          = mkOutOfStoreSymlink "${repo}/claude/settings.json";
    ".claude/CLAUDE.md".source              = mkOutOfStoreSymlink "${repo}/claude/CLAUDE.md";
    ".claude/statusline-command.sh".source  = mkOutOfStoreSymlink "${repo}/claude/statusline-command.sh";
    ".claude/hooks".source                  = mkOutOfStoreSymlink "${repo}/claude/hooks";
    ".claude/skills/dust".source            = mkOutOfStoreSymlink "${repo}/claude/skills/dust";
    ".claude/skills/setup-worktrunk".source = mkOutOfStoreSymlink "${repo}/claude/skills/setup-worktrunk";

    ".config/cmux/cmux.json".source = mkOutOfStoreSymlink "${repo}/cmux/cmux.json";
    ".config/cmux/bin".source       = mkOutOfStoreSymlink "${repo}/cmux/bin";
    ".config/cmux/git".source       = mkOutOfStoreSymlink "${repo}/cmux/git";

    ".config/git/allowed_signers".source = mkOutOfStoreSymlink "${repo}/git/allowed_signers";

    "Screenshots/.keep".text = "";
  };

  programs.git = {
    enable = true;

    signing = {
      format = "ssh";
      key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9GnREAGTw8JMmTrGjM975t9eQOtqnUJmvMi5qBk0Ak guillaume.taffin@akur8.com";
      signByDefault = true;
    };

    settings = {
      user.name = "Guillaume Taffin";
      user.email = "guillaume.taffin@akur8.com";
      init.defaultBranch = "main";
      core.autocrlf = "input";
      rerere.enabled = true;
      credential.helper = "osxkeychain";
      tag.gpgSign = true;
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.config/git/allowed_signers";
      url."git@github.com:".insteadOf = "https://github.com/";
      safe.directory = [
        "/Users/guillaume.taffin/dev/projects/work-projections"
        "/Users/guillaume.taffin/dev/projects/ai-transformation.plain-sandcastle-review-pipeline"
        "/Users/guillaume.taffin/dev/projects/ai-transformation.triage-workflow"
      ];
      include.path = "${config.home.homeDirectory}/.config/cmux/git/git-experience.gitconfig";
    };
  };

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
