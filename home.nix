{ config, pkgs, user, inputs, ... }:
let
  # Deliberately not ~/.dotfiles: the dotfiles-linux repo's bootstrap claims
  # that name too, and whichever ran last wins, silently repointing every
  # edit-in-place symlink below at the wrong clone.
  repo = "${config.home.homeDirectory}/.dotfiles-mac";
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "26.05";

  # Machine base only. Global CLIs live in mise/config.toml, toolchains per project.
  home.packages = with pkgs; [
    # net
    curl
    wget
    mosh
    # GNU userland (Homebrew-equivalent names: awk, grep)
    gawk
    gnugrep
    coreutils
    # shell utils
    tree
    watch
    htop
    tmux
    # crypto (GPG commit signing) + password store
    gnupg
    pinentry_mac
    pass
  ];

  programs.home-manager.enable = true;

  # ---- edit-in-place symlinks back into the dotfiles repo ----
  home.file = {
    ".ideavimrc".source = mkOutOfStoreSymlink "${repo}/ideavimrc";

    ".claude/settings.json".source          = mkOutOfStoreSymlink "${repo}/claude/settings.json";
    ".claude/CLAUDE.md".source              = mkOutOfStoreSymlink "${repo}/claude/CLAUDE.md";
    ".claude/statusline-command.sh".source  = mkOutOfStoreSymlink "${repo}/claude/statusline-command.sh";
    ".claude/hooks".source                  = mkOutOfStoreSymlink "${repo}/claude/hooks";
    ".claude/skills/setup-worktrunk".source = mkOutOfStoreSymlink "${repo}/claude/skills/setup-worktrunk";
    ".claude/output-styles".source          = mkOutOfStoreSymlink "${repo}/claude/output-styles";

    # pi coding agent: version settings + extensions, keep auth/sessions local
    ".pi/agent/settings.json".source = mkOutOfStoreSymlink "${repo}/pi/settings.json";
    ".pi/agent/extensions".source    = mkOutOfStoreSymlink "${repo}/pi/extensions";

    ".config/cmux/cmux.json".source = mkOutOfStoreSymlink "${repo}/cmux/cmux.json";
    ".config/cmux/bin".source       = mkOutOfStoreSymlink "${repo}/cmux/bin";
    ".config/cmux/git".source       = mkOutOfStoreSymlink "${repo}/cmux/git";

    # global mise tools: `mise use -g` edits the repo file
    ".config/mise/config.toml".source = mkOutOfStoreSymlink "${repo}/mise/config.toml";

    "Screenshots/.keep".text = "";
  };

  programs.git = {
    enable = true;

    signing = {
      format = "openpgp";
      key = "A2AE5B3978A9CF52";   # Guillaume Taffin <cloudgt.dev@gmail.com>, rsa3072, expires 2027-08-17
      signByDefault = true;
    };

    settings = {
      user.name = "Guillaume Taffin";
      user.email = "cloudgt.dev@gmail.com";
      tag.gpgSign = true;
      init.defaultBranch = "main";
      core.autocrlf = "input";
      rerere.enabled = true;
      credential.helper = "osxkeychain";
      # diff/merge quality-of-life (formerly from the cmux git-experience include)
      diff.colorMoved = "default";
      merge.conflictstyle = "zdiff3";
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
      clodo = "clear && claude --model claude-opus-4-7";
    };

    initContent = ''
      # --- environment ---
      export XDG_CONFIG_HOME="$HOME/.config"
      export EDITOR=idea

      # --- PATH additions ---
      export PATH="$PATH:$HOME/.pub-cache/bin"
      export PATH="$PATH:$HOME/.local/bin"
      export PATH="$HOME/.opencode/bin:$PATH"

      # mise: global CLIs + per-project toolchains (before wt, which mise installs)
      if command -v mise >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi

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
}
