{ inputs, pkgs, ... }:
{
  # Open-source tailscaled variant (not the GUI app): required for the
  # Tailscale SSH server, which mosh uses as its bootstrap. No macOS GUI
  # build (App Store or standalone) can run the SSH server.
  # Pinned to unstable: stable lags on security releases.
  services.tailscale = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tailscale;
  };

  homebrew = {
    # Declarative brew: anything not listed (here or in common) is removed on switch.
    onActivation.cleanup = "uninstall";

    taps = [
      { name = "rjyo/moshi"; trusted = true; }
    ];

    brews = [
      # start_service registers the launchd agent on switch; it then auto-starts
      # at every login without any manual `brew services start`.
      { name = "moshi-hook"; start_service = true; restart_service = "changed"; }
      "herdr"    # agent multiplexer, herdr.dev
      # Rootless container runtime. Brew brings the vfkit/gvproxy helpers that
      # `podman machine` needs; bootstrap the VM once with `podman-up`.
      "podman"
      "pandoc"
      # JVM build tools stay on brew; SDKMAN owns the JDKs themselves.
      "maven"
      "gradle"
      "kotlin"
    ];

    casks = [
      "raycast"
      "slack"
      "notion"
      "moonlight"  # game streaming client
    ];
  };
}
