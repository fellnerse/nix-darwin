{ pkgs, inputs, ... }:
{
  imports = [
    ./common.nix
    inputs.mac-app-util.homeManagerModules.default
  ];

  home = {
    username = "private";
    homeDirectory = "/Users/private";
    stateVersion = "24.05";
    packages = with pkgs; [
    ];
  };

  # Private-specific git config
  programs.git.settings.user = {
    name = "fellnerse 💯";
    email = "hey@sebastianfellner.de";
  };

  #  #currently broken
  #  programs.ghostty = {
  #    enable = true;
  #    enableFishIntegration = true;
  #    settings = {
  #        keybind = global:cmd+grave_accent=toggle_quick_terminal;
  #    };
  #  };

  xdg.configFile.ghostty = {
    source = pkgs.writeText "ghostty-config" ''
      keybind = global:cmd+grave_accent=toggle_quick_terminal
    '';
    target = "ghostty/config";
  };

  # Homebrew automatic background cask updates (greedy: true)
  # Runs daily at 04:00 (or immediately on wake if asleep)
  launchd.agents.brew-autoupdate = {
    enable = true;
    config = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "PATH=/opt/homebrew/bin:$PATH brew update && PATH=/opt/homebrew/bin:$PATH brew upgrade --cask --greedy"
      ];
      StartCalendarInterval = [
        {
          Hour = 4;
          Minute = 0;
        }
      ];
      StandardOutPath = "/Users/private/Library/Logs/brew-autoupdate.log";
      StandardErrorPath = "/Users/private/Library/Logs/brew-autoupdate-error.log";
    };
  };
}
