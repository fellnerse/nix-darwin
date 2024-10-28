{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    # how to use stable and unstable at the same time 
    # https://nixos.wiki/wiki/Flakes#Importing_packages_from_multiple_channels
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      mac-app-util,
      ...
    }:
    let
      system = "aarch64-darwin";
      overlay-unstable = final: prev: { unstable = nixpkgs-unstable.legacyPackages.${prev.system}; };
      forAllSystems = nixpkgs.lib.genAttrs [ system ];
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Sebastians-MacBook-Pro-2
      darwinConfigurations."Sebastians-MacBook-Pro-2" = nix-darwin.lib.darwinSystem {
        inherit system;
        # needed so we can pass self down to the other modules
        specialArgs = {
          inherit self mac-app-util;
        };
        modules = [
          # this is needed to create trampolines for applications (.app) otherwise spotlight won't find them
          mac-app-util.darwinModules.default
          # Overlays-module makes "pkgs.unstable" available in configuration.nix
          (
            { config, pkgs, ... }:
            {
              nixpkgs.overlays = [ overlay-unstable ];
            }
          )
          home-manager.darwinModules.home-manager
          ./hosts/mbp/configuration.nix
          ./hosts/mbp/home.nix
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Sebastians-MacBook-Pro-2".pkgs;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pre-commit = self.checks.${system}.pre-commit-check;
        in
        {
          default = pkgs.mkShellNoCC {
            packages = [ ] ++ pre-commit.enabledPackages;
            inherit (pre-commit) shellHook;
          };
        }
      );

      checks = forAllSystems (system: {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt-rfc-style.enable = true;
            flake-checker = {
              enable = true;
              package = inputs.nixpkgs-unstable.legacyPackages.${system}.flake-checker;
            };
            # flake-lock = {
            #   enable = true;
            #   name = "Check flake.lock";
            #   entry = "nix flake lock";
            # };
          };
        };
      });

    };
}
