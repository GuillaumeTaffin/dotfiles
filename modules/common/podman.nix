{ config, pkgs, ... }:
let
  # Podman keeps a stable socket symlink pointing at the active machine, so
  # DOCKER_HOST can be static instead of shelling out to `podman machine inspect`
  # at every shell start.
  socket = "${config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock";
in
{
  # podman itself comes from Homebrew (hosts/*/system.nix): the brew formula
  # ships the vfkit/gvproxy helpers `podman machine` needs on darwin, nixpkgs
  # does not wire them up.
  home.packages = with pkgs; [
    docker-compose   # compose v2; `podman compose` shells out to it

    # A real `docker` executable rather than a zsh alias: scripts run
    # non-interactively (`command -v docker` in a Justfile recipe, CI, direnv)
    # never see aliases.
    (writeShellScriptBin "docker" ''
      exec podman "$@"
    '')
  ];

  programs.zsh.initContent = ''
    # --- podman (rootless VM, docker-compatible socket) ---
    [ -S "${socket}" ] && export DOCKER_HOST="unix://${socket}"
    # `podman compose` must pick docker-compose, never podman-compose.
    export PODMAN_COMPOSE_PROVIDER=docker-compose

    # One-shot VM bootstrap. Rootless is the darwin default; --rootful=false
    # is stated anyway so a machine created elsewhere gets fixed too.
    podman-up() {
      podman machine inspect >/dev/null 2>&1 || podman machine init || return
      podman machine set --rootful=false >/dev/null 2>&1
      podman machine start 2>/dev/null || true
      podman machine ls
    }
  '';
}
