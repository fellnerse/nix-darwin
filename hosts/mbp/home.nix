{ pkgs,allowed-unfree-packages,mac-app-util, ... }: {
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
home-manager.extraSpecialArgs = {inherit allowed-unfree-packages;};

home-manager.sharedModules = [
  mac-app-util.homeManagerModules.default
];

home-manager.users.sefe = { pkgs, ... }: {
        home.stateVersion = "24.05";

        home.packages = [
          # pkgs.teams
        ];

        programs.direnv = {
          enable = true;
          nix-direnv.enable = true;
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
    };};
      };
}