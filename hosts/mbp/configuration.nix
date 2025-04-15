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
      options = "--delete-old";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      substituters = [
        "https://nix-community.cachix.org"
        "https://tweag-nickel.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "tweag-nickel.cachix.org-1:GIthuiK4LRgnW64ALYEoioVUQBWs0jexyoYVeLDBwRA="
      ];
    };
    optimise.automatic = true;
    registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
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
      mtr-gui
      # pkgs.openmoji-color # font with openmoji emojis
      nixpkgs-fmt
      home-manager
      yq-go
      nix-search-cli
      less
    ];
    # these shells are configured for nix
    # I think I do not need this, have a look at the bottom, how I set it up
    shells = [
      pkgs.bashInteractive
      pkgs.zsh
      #      pkgs.fish
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

    # can be found by running: `defaults find ${word}`
    defaults.CustomUserPreferences = {
      "com.apple.WindowManager" = {
        EnableTiledWindowMargins = 0;
      };
      "com.apple.dock" = {
        no-bouncing = true;
      };
      "NSGlobalDomain" = {
        "ApplePressAndHoldEnabled" = true;
        "InitialKeyRepeat" = 15;
        "KeyRepeat" = 2;
      };
    };

    # normally you would need to logout login so preferences take effect
    activationScripts.postUserActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # homebrew should be used for GUI applications
  homebrew = import ./homebrew.nix;

  users.users.sefe = {
    name = "sefe";
    home = "/Users/sefe";
    shell = pkgs.fish;
  };

  users.users.private = {
    name = "private";
    home = "/Users/private";
  };

  # https://nixos.wiki/wiki/Command_Shell
  programs = {
    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh.enable = true;
    fish.enable = true;
  };
}
