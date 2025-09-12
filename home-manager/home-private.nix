{ pkgs, inputs, ... }:
{
  imports = [ ./common.nix ];

  home = {
    username = "private";
    homeDirectory = "/Users/private";
    stateVersion = "24.05";
    packages = with pkgs; [
      mise
    ];
  };

  # Private-specific git config
  programs.git = {
    userName = "fellnerse 💯";
    userEmail = "hey@sebastianfellner.de";
  };

  programs.zellij = {
    enable = true;
    #    enableFishIntegration = true;
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
}
