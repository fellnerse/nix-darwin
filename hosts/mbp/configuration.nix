{
  self,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  services.nix-daemon.enable = true;

  nix = {
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://tweag-nickel.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA="
      ];
    };
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ self.outputs.overlays.unstable-packages ];
    # The platform the configuration will be used on.
    hostPlatform = "aarch64-darwin";
  };

  environment = {
    systemPackages = with pkgs; [
      vim
      iterm2 # todo install with homebrew
      nerdfonts
      mtr-gui
      asdf-vm # need to also load fish autocompletions in the fish init further down
      # pkgs.openmoji-color # font with openmoji emojis
      nixpkgs-fmt
    ];
    # these shells are configured for nix
    shells = [
      pkgs.bashInteractive
      pkgs.zsh
      pkgs.fish
    ];
  };

  fonts.packages = with pkgs; [
    recursive
    (nerdfonts.override { fonts = [ "Monaspace" ]; })
  ];

  # check `darwin-rebuild changelog`
  system = {
    stateVersion = 5;
    configurationRevision = self.rev or self.dirtyRev or null;
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # homebrew should be used for GUI applications
  homebrew = {
    enable = true;
    # updates homebrew packages on activation,
    # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
    onActivation.autoUpdate = true;
    casks = [
      # "bitwarden" the cask version does not support fingerprint auth enymore
      "signal"
      "arc"
    ];
    masApps = {
      "Bitwarden" = 1352778147;
    };
  };

  users.users.sefe = {
    name = "sefe";
    home = "/Users/sefe";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    # this is needed to create trampolines for applications (.app) otherwise spotlight won't find them
    sharedModules = [ inputs.mac-app-util.homeManagerModules.default ];
    users.sefe = import ./home.nix;
    extraSpecialArgs = {
      inherit inputs;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.fish.enable = true;

}
