{ pkgs, allowed-unfree-packages, mac-app-util, ... }: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit allowed-unfree-packages; };

  home-manager.sharedModules = [
    mac-app-util.homeManagerModules.default
  ];

  home-manager.users.sefe = { pkgs, ... }: {
    home.stateVersion = "24.05";

    home.packages = [
      # pkgs.teams
      pkgs.nix-your-shell
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };


    # programs.fish = {
    #   enable = true; # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1782971499
    #   # ... other things here
    #   interactiveShellInit = ''
    #     source "${pkgs.asdf-vm}/share/asdf-vm/asdf.fish"
    #     source "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.fish"
    #     complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'
    #   '';
    #   # FIXME: This is needed to address bug where the $PATH is re-ordered by
    #   # the `path_helper` tool, prioritising Apple’s tools over the ones we’ve
    #   # installed with nix.
    #   #
    #   # This gist explains the issue in more detail: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
    #   # There is also an issue open for nix-darwin: https://github.com/LnL7/nix-darwin/issues/122
    #   loginShellInit =
    #     let
    #       # We should probably use `config.environment.profiles`, as described in
    #       # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1659465635
    #       # but this takes into account the new XDG paths used when the nix
    #       # configuration has `use-xdg-base-directories` enabled. See:
    #       # https://github.com/LnL7/nix-darwin/issues/947 for more information.
    #       profiles = [
    #         "/etc/profiles/per-user/$USER" # Home manager packages
    #         "$HOME/.nix-profile"
    #         "(set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)/nix/profile"
    #         "/run/current-system/sw"
    #         "/nix/var/nix/profiles/default"
    #       ];

    #       makeBinSearchPath =
    #         lib.concatMapStringsSep " " (path: "${path}/bin");
    #     in
    #     ''
    #       # Fix path that was re-ordered by Apple's path_helper
    #       fish_add_path --move --prepend --path ${makeBinSearchPath profiles}
    #       set fish_user_paths $fish_user_paths
    #     '';
    # };



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

    xdg.configFile.iterm-integration = {
      source = ./config.cloud.fish;
      target = "fish/conf.d/config.fish";
    };

    # programs to run on startup
    # xsession.windowManager.bspwm.startupPrograms = [
    #   "iTerm2"
    # ];
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
