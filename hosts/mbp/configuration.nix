{ self, pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
          pkgs.vim
          pkgs.iterm2
          pkgs.bitwarden-cli
          pkgs.nerdfonts
          pkgs.mtr-gui
          pkgs.asdf-vm
        ];

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      programs.fish.enable = true; # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1782971499
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
        onActivation.autoUpdate = true;
        # updates homebrew packages on activation,
        # can make darwin-rebuild much slower (otherwise i'd forget to do it ever though)
        casks = [
          "bitwarden"
        ];
      };

      users.users.sefe = {
        name = "sefe";
        home = "/Users/sefe";
      };
    }