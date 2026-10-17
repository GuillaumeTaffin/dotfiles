{
  description = "guillaume.taffin dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # Only for packages that must track upstream closely (tailscale).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs, hunk, ... }:
    let
      # host = directory under ./hosts, user = macOS account name on that machine.
      mkHost = { host, user }: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user host inputs; };
        modules = [
          ./modules/common/system.nix
          (./hosts + "/${host}/system.nix")
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit user host inputs; };
            home-manager.users.${user}.imports = [
              ./modules/common/home.nix
              (./hosts + "/${host}/home.nix")
            ];
          }
        ];
      };
    in
    {
      darwinConfigurations = {
        work = mkHost { host = "work"; user = "guillaume.taffin"; };
        perso = mkHost { host = "perso"; user = "guillaumetaffin"; };
      };
    };
}
