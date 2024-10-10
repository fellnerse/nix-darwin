{ self, pkgs, lib, ... }:
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
      
      environment.systemPackages = with pkgs;
        [ 
          vim
          iterm2
          nerdfonts
          mtr-gui
          asdf-vm # need to also load fish autocompletions in the fish init further down
          # pkgs.openmoji-color # font with openmoji emojis
          gnumake
          bun
          ffmpeg
          tesseract
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      programs.fish = {
        enable = true; # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1782971499
        # ... other things here
        interactiveShellInit = ''
          source "${pkgs.asdf-vm}/share/asdf-vm/asdf.fish"
          source "${pkgs.asdf-vm}/share/asdf-vm/completions/asdf.fish"
        '';
        # FIXME: This is needed to address bug where the $PATH is re-ordered by
        # the `path_helper` tool, prioritising Apple’s tools over the ones we’ve
        # installed with nix.
        #
        # This gist explains the issue in more detail: https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2
        # There is also an issue open for nix-darwin: https://github.com/LnL7/nix-darwin/issues/122
        loginShellInit = let
        # We should probably use `config.environment.profiles`, as described in
        # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1659465635
        # but this takes into account the new XDG paths used when the nix
        # configuration has `use-xdg-base-directories` enabled. See:
        # https://github.com/LnL7/nix-darwin/issues/947 for more information.
        profiles = [
          "/etc/profiles/per-user/$USER" # Home manager packages
          "$HOME/.nix-profile"
          "(set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)/nix/profile"
          "/run/current-system/sw"
          "/nix/var/nix/profiles/default"
        ];

        makeBinSearchPath =
          lib.concatMapStringsSep " " (path: "${path}/bin");
        in
        ''
          # Fix path that was re-ordered by Apple's path_helper
          fish_add_path --move --prepend --path ${makeBinSearchPath profiles}
          set fish_user_paths $fish_user_paths
        '';
      };
      environment.shells = [ pkgs.bashInteractive pkgs.zsh pkgs.fish ];      

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
        interval = { Weekday = 0; Hour = 0; Minute = 0; };
        options = "--delete-older-than 30d";
      };
    }