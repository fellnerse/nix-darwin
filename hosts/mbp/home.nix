{ pkgs, ... }: {
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;

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
}