{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
          pkgs.vim
          pkgs.iterm2
          pkgs.bitwarden-cli
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      programs.fish.enable = true; # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1782971499
      environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];      

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";


      homebrew = {
        enable = true;
        onActivation.autoUpdate = true;
        # updates homebrew packages on activation,
        # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
        casks = [
          "bitwarden"
        ];
      };

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      users.users.sefe = {
        name = "sefe";
        home = "/Users/sefe";
      };

      home-manager.users.sefe = { pkgs, ... }: {

        home.stateVersion = "24.05";

        programs.tmux = { # my tmux configuration, for example
          enable = true;
          keyMode = "vi";
          clock24 = true;
          historyLimit = 10000;
          plugins = with pkgs.tmuxPlugins; [
            vim-tmux-navigator
            gruvbox
          ];
          extraConfig = ''
            new-session -s main
            bind-key -n C-a send-prefix
          '';
        };
      };
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Sebastians-MacBook-Pro-2
    darwinConfigurations."Sebastians-MacBook-Pro-2" = nix-darwin.lib.darwinSystem {
      modules = [ 
        home-manager.darwinModules.home-manager
        configuration 
      ];
      system = "aarch64-darwin";
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Sebastians-MacBook-Pro-2".pkgs;
  };
}
