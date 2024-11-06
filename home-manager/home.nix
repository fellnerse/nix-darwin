{ pkgs, inputs, ... }:
{
  home = {
    username = "sefe";
    homeDirectory = "/Users/sefe";
    stateVersion = "24.05";
    packages = [
      # pkgs.teams
      pkgs.nix-your-shell
    ];
  };

  programs.home-manager.enable = true;
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

  # add my custom stuff to fish config
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
}
