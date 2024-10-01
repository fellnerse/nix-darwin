{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    # how to use stable and unstable at the same time 
    # https://discourse.nixos.org/t/mixing-stable-and-unstable-packages-on-flake-based-nixos-system/50351/4
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nixpkgs-unstable, home-manager, ... }:
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Sebastians-MacBook-Pro-2
    darwinConfigurations."Sebastians-MacBook-Pro-2" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      # needed so we can pass self down to the other modules
      specialArgs = { inherit self inputs; };
      modules = [ 
        home-manager.darwinModules.home-manager
        ./hosts/mbp/configuration.nix
        ./hosts/mbp/home.nix
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Sebastians-MacBook-Pro-2".pkgs;
  };
}
