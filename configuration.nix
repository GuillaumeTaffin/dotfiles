{ pkgs, user, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Official multi-user Nix is installed, so nix-darwin manages the daemon.
  nix.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.primaryUser = user;
  system.stateVersion = 6;

  # home-manager's nixos/common.nix derives home.homeDirectory from
  # config.users.users.<name>.home, which is null on nix-darwin unless
  # declared here.
  users.users.${user}.home = "/Users/${user}";

  # nix-darwin manages /etc/zshrc, /etc/zprofile, /etc/zshenv.
  # (Default is already true; stated explicitly for intent.)
  programs.zsh.enable = true;

  # PATH-ordering fix vs Homebrew.
  #
  # /etc/zshenv -> set-environment puts the Nix profile dirs first, but the
  # user's ~/.zprofile then runs `eval "$(brew shellenv)"`, which prepends
  # /opt/homebrew/bin AHEAD of them. zsh sources /etc/zshrc AFTER ~/.zprofile
  # for a login+interactive shell, so re-asserting the Nix dirs here makes Nix
  # win. Hardcoded (not read from set-environment) so this ALSO repairs nested
  # shells that inherited __NIX_DARWIN_SET_ENVIRONMENT_DONE=1 (e.g. shells
  # spawned inside the cmux app), where set-environment is skipped.
  programs.zsh.interactiveShellInit = ''
    path=(
      $HOME/.nix-profile/bin
      /etc/profiles/per-user/$USER/bin
      /run/current-system/sw/bin
      /nix/var/nix/profiles/default/bin
      $path
    )
    typeset -U path PATH
  '';

  # First Phase-2 switch: home-manager takes over ~/.zshrc (stow symlink) and
  # ~/.zshenv (regular file). Back up pre-existing targets instead of aborting.
  home-manager.backupFileExtension = "hm-bak";
}
