{
  pkgs,
  inputs,
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
      pkgs.sops
      pkgs.kubectl
      pkgs.unstable.claude-code
      pkgs.shell-gpt
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
    # configs form here: https://blog.gitbutler.com/how-git-core-devs-configure-git/
    extraConfig = {
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      init.defaultBranch = "main";
      diff.algorithm = "histogram";
      diff.colorMoved = "plain";
      diff.mnemonicPrefix = "true";
      diff.renames = "true";
      push.default = "simple";
      push.autoSetupRemote = "true";
      push.followTags = "true";
      fetch.prune = "true";
      fetch.pruneTags = "true";
      fetch.all = "true"; # why the hell not?
      help.autocorrect = "prompt";
      commit.verbose = "true";
      rerere.enabled = "true";
      rerere.autoupdate = "true";
      core.excludesfile = "~/.gitignore";
      rebase.autoSquash = "true";
      rebase.autoStash = "true";
      rebase.updateRefs = "true";
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

  programs.k9s = {
    enable = true;
    # was not able to get it to work with command kubectl, that does not support pipes
    # the plugins location can be found with k9s info
    # logs about plugin failure can be found in the logs (also in k9s info)
    plugin = {
      plugins = {
        jqlogs = {
          shortCut = "Ctrl-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [
            "pod"
          ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl logs -f --tail=20 "$NAME" -n "$NAMESPACE" --context "$CONTEXT" \
                          | jq -SR '. | try (fromjson| (.record.time.repr) +" " + (.record.level.name) +" ["+ (.record.extra.plant_id) +"|" +(.record.extra.correlation_id) +"] "+ (.record.message ) )' ''
          ];
        };
        # deployment view plugin
        jqlogsd = {
          shortCut = "Ctrl-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "deployment" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl logs -f --tail=20 "deployment/$NAME" -n "$NAMESPACE" --context "$CONTEXT" \
                | jq -SR '. | try (fromjson | (.record.time.repr) +" " + (.record.level.name) + " [" + (.record.extra.plant_id) + "|" + (.record.extra.correlation_id) + "] " + (.record.message)) catch .'
            ''
          ];
        };
        # service view plugin
        jqlogss = {
          shortCut = "Ctrl-L";
          confirm = false;
          description = "Logs (jq)";
          scopes = [ "service" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              kubectl logs -f --tail=20 "service/$NAME" -n "$NAMESPACE" --context "$CONTEXT" \
                | jq -SR '. | try (fromjson | (.record.time.repr) +" " + (.record.level.name) + " [" + (.record.extra.plant_id) + "|" + (.record.extra.correlation_id) + "] " + (.record.message)) catch .'
            ''
          ];
        };
      };
    };
  };

  programs.fzf.enable = true;
  programs.jq.enable = true;

  programs.autojump = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.wezterm = {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };

  programs.lazygit.enable = true;
  programs.uv.enable = true;
  programs.neovim.enable = true;
  programs.fd.enable = true;
  programs.ripgrep.enable = true;

  # add my custom stuff to fish config
  xdg.configFile.iterm-integration = {
    source = ./config.cloud.fish;
    target = "fish/conf.d/config.fish";
  };
}
