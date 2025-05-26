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

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      lix-module,
      nixpkgs-unstable,
      home-manager,
      mac-app-util,
      ...
    }:
    let
      systems = [ "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Sebastians-MacBook-Pro-2
      darwinConfigurations."Sebastians-MacBook-Pro-2" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        # needed so we can pass self down to the other modules
        specialArgs = {
          inherit self inputs;
        };
        modules = [
          ./hosts/mbp/configuration.nix
          lix-module.nixosModules.lixFromNixpkgs
          self.nixosModules.current-lix
        ];
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager switch --flake .#sefe -b backup'
      homeConfigurations = {
        "sefe" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = {
            inherit self inputs;
          };
          modules = [ ./home-manager/home.nix ];
        };
        "private" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          extraSpecialArgs = {
            inherit self inputs;
          };
          modules = [ ./home-manager/home-private.nix ];
        };
      };

      overlays = {
        unstable-packages = final: _prev: {
          unstable = import inputs.nixpkgs-unstable {
            system = final.system;
            config.allowUnfree = true;
          };
        };
        current-lix = final: _prev: { lix = inputs.nixpkgs-unstable.legacyPackages.${final.system}.lix; };
      };

      nixosModules.current-lix = {
        nixpkgs.overlays = [ self.overlays.current-lix ];
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.git
              pkgs.direnv
            ]; # Example packages
            shellHook = "echo 'Welcome to your development shell!'";
          };
        }
      );
    };
}
