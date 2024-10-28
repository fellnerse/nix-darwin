{
  self,
  pkgs,
  lib,
  ...
}:
{
  # The `system.stateVersion` option is not defined in your
  # nix-darwin configuration. The value is used to conditionalize
  # backwards‐incompatible changes in default settings. You should
  # usually set this once when installing nix-darwin on a new system
  # and then never change it (at least without reading all the relevant
  # entries in the changelog using `darwin-rebuild changelog`).
  system.stateVersion = 5;
  # nixpkgs.config.allowBroken = true;
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget

  environment.systemPackages = with pkgs; [
    vim
    iterm2
    nerdfonts
    mtr-gui
    asdf-vm # need to also load fish autocompletions in the fish init further down
    # pkgs.openmoji-color # font with openmoji emojis
    nixpkgs-fmt
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ self.outputs.overlays.unstable-packages ];
  };

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.fish.enable = true;

  # users.users.sefe.shell = pkgs.fish;
  # users.defaultUserShell = pkgs.fish;
  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
    pkgs.fish
  ];

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # Fonts
  fonts.packages = with pkgs; [
    recursive
    (nerdfonts.override { fonts = [ "Monaspace" ]; })
  ];

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

  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };
}
