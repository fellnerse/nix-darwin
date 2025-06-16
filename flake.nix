{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    # how to use stable and unstable at the same time
    # https://nixos.wiki/wiki/Flakes#Importing_packages_from_multiple_channels
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.1-1.tar.gz";
    lix-module.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, ... }: let
    systems = [ "aarch64-darwin" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    mkPkgs = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        self.overlays.unstable-packages
        self.overlays.current-lix
      ];
    };

    pkgsFor = forAllSystems mkPkgs;
  in {
    overlays = {
      unstable-packages = final: prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      };

      current-lix = final: prev: {
        lix = inputs.nixpkgs-unstable.legacyPackages.${final.system}.lix;
      };
    };

    darwinConfigurations."Sebastians-MacBook-Pro-2" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit self inputs; };
      modules = [
        ./hosts/mbp/configuration.nix
        inputs.lix-module.nixosModules.lixFromNixpkgs
        self.nixosModules.current-lix
      ];
    };

    homeConfigurations = {
      sefe = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.aarch64-darwin;
        extraSpecialArgs = { inherit self inputs; };
        modules = [ ./home-manager/home.nix ];
      };

      private = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor.aarch64-darwin;
        extraSpecialArgs = { inherit self inputs; };
        modules = [ ./home-manager/home-private.nix ];
      };
    };

    nixosModules.current-lix = {
      nixpkgs.overlays = [ self.overlays.current-lix ];
    };

    formatter = forAllSystems (system: pkgsFor.${system}.nixfmt-rfc-style);

    devShells = forAllSystems (system: {
      default = pkgsFor.${system}.mkShell {
        packages = with pkgsFor.${system}; [ git direnv ];
        shellHook = "echo 'Welcome to your development shell!'";
      };
    });
  };
}