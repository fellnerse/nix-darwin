{ pkgs, inputs, ... }:
{
  imports = [ ./common.nix ];

  home = {
    username = "private";
    homeDirectory = "/Users/private";
    stateVersion = "24.05";
    packages = with pkgs; [
      mise
      unstable.uv
    ];
  };

  # Private-specific starship settings
  programs.starship.settings = {
    direnv.disabled = false;
  };

  # Private-specific git config
  programs.git = {
    userName = "fellnerse 💯";
    userEmail = "hey@sebastianfellner.de";
  };

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      lua-language-server
      stylua
      ripgrep
    ];
    plugins = with pkgs.vimPlugins; [ lazy-nvim ];
    extraLuaConfig = ''require("lazy").setup({ spec = { { "LazyVim/LazyVim", import = "lazyvim.plugins" } }, })'';
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
