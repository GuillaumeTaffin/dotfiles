{ inputs, pkgs, user, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Official multi-user Nix is installed, so nix-darwin manages the daemon.
  nix.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Non-interactive switches: without these, every build re-asks whether to
  # allow the extra substituters/keys that flake inputs declare in `nixConfig`.
  # trusted-users is what actually lets those settings apply; accept-flake-config
  # answers the prompt. Both mean inputs can add binary caches you did not vet -
  # acceptable here because every input is pinned in flake.lock.
  nix.settings.trusted-users = [ "root" user ];
  nix.settings.accept-flake-config = true;

  system.primaryUser = user;
  system.stateVersion = 6;

  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      ShowPathbar = true;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "Nlsv";
      FXEnableExtensionChangeWarning = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
    };
    # Tap-to-click off: require a real click on the trackpad.
    trackpad.Clicking = false;
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      ApplePressAndHoldEnabled = false;
    };
    screencapture.location = "/Users/${user}/Screenshots";
    # nix-darwin's NSGlobalDomain."com.apple.mouse.tapBehavior" only accepts 1,
    # so the "off" value goes through the raw-prefs escape hatch.
    CustomUserPreferences.NSGlobalDomain."com.apple.mouse.tapBehavior" = 0;
    CustomUserPreferences."com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
  };

  # home-manager's nixos/common.nix derives home.homeDirectory from
  # config.users.users.<name>.home, which is null on nix-darwin unless
  # declared here.
  users.users.${user}.home = "/Users/${user}";

  # Open-source tailscaled variant (not the GUI app): required for the
  # Tailscale SSH server, which mosh uses as its bootstrap. No macOS GUI
  # build (App Store or standalone) can run the SSH server.
  # Pinned to unstable: stable lags on security releases.
  services.tailscale = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
  };

  # nix-darwin manages /etc/zshrc, /etc/zprofile, /etc/zshenv.
  # (Default is already true; stated explicitly for intent.)
  programs.zsh.enable = true;

  # PATH-ordering fix vs Homebrew.
  #
  # /etc/zshenv -> set-environment puts the Nix profile dirs first, but the
  # user's ~/.zprofile then prepends/appends /opt/homebrew/bin. zsh sources
  # /etc/zshrc AFTER ~/.zprofile for a login+interactive shell, so re-asserting
  # the Nix dirs here makes Nix win. Hardcoded (not read from set-environment)
  # so this ALSO repairs nested shells that inherited
  # __NIX_DARWIN_SET_ENVIRONMENT_DONE=1 (e.g. shells spawned inside a terminal
  # app), where set-environment is skipped.
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

  # First switch: home-manager takes over ~/.zshrc and ~/.zshenv.
  # Back up pre-existing targets instead of aborting.
  home-manager.backupFileExtension = "hm-bak";

  # ------------------------------------------------------------ nix-homebrew ----
  # Adopt the pre-existing /opt/homebrew installation under Nix management.
  # The flake already imports nix-homebrew.darwinModules.nix-homebrew.
  nix-homebrew = {
    enable = true;
    user = user;
    autoMigrate = true;             # adopt existing /opt/homebrew without manual uninstall;
                                    # relinks only the tracked brew repo, keeps Cellar/Caskroom/Taps.
    mutableTaps = true;             # keep imperative `brew tap`; leaves existing Taps/ intact.
    enableZshIntegration = false;   # ~/.zprofile already puts /opt/homebrew on PATH; avoid a
                                    # second one that would re-prepend it ahead of Nix.
  };

  # --------------------------------------------------------------- homebrew ----
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;   # no `brew update` during switch
      upgrade = false;      # don't upgrade installed formulae during switch
      # Declarative brew: anything not listed here is removed on switch.
      cleanup = "uninstall";
    };

    taps = [
    ];

    brews = [
      "herdr"    # agent multiplexer, herdr.dev
      "mise"     # global CLIs (mise/config.toml) + per-project toolchains
    ];

    casks = [
      "ghostty"
      "visual-studio-code"
      "zed"
      "rectangle"
      "windows-app"   # Microsoft remote desktop client
      "balenaetcher"
      "raycast"
    ];
  };
}
