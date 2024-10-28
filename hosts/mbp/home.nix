{
  pkgs,
  allowed-unfree-packages,
  mac-app-util,
  ...
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {
    inherit allowed-unfree-packages;
  };

  home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];

  home-manager.users.sefe =
    { pkgs, ... }:
    {
      home.stateVersion = "24.05";

      home.packages = [
        # pkgs.teams
        pkgs.nix-your-shell
      ];

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          nix-your-shell fish | source
        '';
        plugins = [
          {
            name = "fish-completion-sync";
            src = pkgs.fetchFromGitHub {
              owner = "pfgray";
              repo = "fish-completion-sync";
              rev = "f75ed04e98b3b39af1d3ce6256ca5232305565d8";
              sha256 = "0q3i0vgrfqzbihmnxghbfa11f3449zj6rkys4vpncdmzb18lqsy2";
            };
          }
        ];
      };
      programs.starship = {
        enable = true;
        settings = {
          git_commit.only_detached = false;
          time.disabled = false;
          direnv.disabled = false;
          status.disabled = false;
          sudo.disabled = false;
        };
      };

      # add my custom stuff to fish confif
      xdg.configFile.iterm-integration = {
        source = ./config.cloud.fish;
        target = "fish/conf.d/config.fish";
      };

      # programs to run on startup
      launchd.agents = {
        iterm2 = {
          enable = true;
          config = {
            Program = "/run/current-system/sw/bin/iterm2";
            RunAtLoad = true;
          };
        };
      };
    };
}
