{
  pkgs,
  inputs,
  lib,
  ...
}:
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
      direnv.disabled = true;
      status.disabled = false;
      sudo.disabled = false;
      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
      docker_context.disabled = true;
      nix_shell.disabled = true;
      line_break.disabled = false;
      directory = {
        truncate_to_repo = true;
      };
    };
  };

  programs.git = {
    enable = true;
    delta.enable = true;
    aliases = {
      s = "status -s";
    };
  };

  programs.eza = {
    enable = true;
    icons = "always";
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
    };
  };

  # this seems to work for loading, but the generated file is in the wrong format...it somehow introduces a new line where it should not
  programs.k9s = {
    enable = true;
    plugin = {
      plugins = {
        jqlogs = {
          shortCut = "Shift-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [
            "pod"
            "containers"
            "logs"
          ];
          command = "bash";
          background = false;
          args = [
            "-c"
            "kubectl logs -f --tail=20 $NAME -n $NAMESPACE --context $CONTEXT | jq -SR '. | try (fromjson|.text) catch .'"
          ];
        };
      };
    };
  };

  programs.fzf.enable = true;
  programs.jq.enable = true;

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
        Program = "/Applications/iTerm.app/Contents/MacOS/iTerm2";
        RunAtLoad = true;
      };
    };
  };
}
