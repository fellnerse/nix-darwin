{ pkgs, ... }:
{
  imports = [ ./fish.nix ];
  # Common packages
  home.packages = with pkgs; [
    nix-your-shell
    shell-gpt
    unstable.claude-code
    unstable.uv
    nixd # nix language server used by zeditor
    nixfmt-rfc-style # nix formatter used by zeditor
  ];

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    settings = {
      direnv.disabled = false;
      git_commit.only_detached = false;
      time.disabled = false;
      status.disabled = false;
      sudo.disabled = false;
    };
  };

  programs.ssh = {
    enable = true;
    package = pkgs.openssh;
    enableDefaultConfig = false;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    # configs from here: https://blog.gitbutler.com/how-git-core-devs-configure-git/
    settings = {
      alias.s = "status -s";
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      init.defaultBranch = "main";
      diff.algorithm = "histogram";
      diff.colorMoved = "plain";
      diff.mnemonicPrefix = "true";
      diff.renames = "true";
      push.default = "simple";
      push.autoSetupRemote = "true";
      push.followTags = "true";
      fetch.prune = "true";
      fetch.pruneTags = "true";
      fetch.all = "true"; # why the hell not?
      help.autocorrect = "prompt";
      commit.verbose = "true";
      rerere.enabled = "true";
      rerere.autoupdate = "true";
      core.excludesfile = "~/.gitignore";
      rebase.autoSquash = "true";
      rebase.autoStash = "true";
      rebase.updateRefs = "true";
    };
  };

  programs.eza = {
    enable = true;
    icons = "always";
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "gruvbox-dark";
    };
  };

  programs.fzf.enable = true;
  programs.jq.enable = true;

  programs.autojump = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.lazygit.enable = true;

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

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;
    extensions = [
      "nix"
      "fish"
    ];

    userSettings = {
      use_system_window_tabs = true;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      base_keymap = "JetBrains";
      ui_font_size = 16;
      buffer_font_size = 15;
      theme = {
        mode = "system";
        light = "Gruvbox Light";
        dark = "Gruvbox Dark";
      };
      terminal = {
        font_family = "MonaspiceNe Nerd Font Mono";
        shell = "system";
        working_directory = "current_project_directory";
      };
      # Tell Zed to use direnv and direnv can use a flake.nix environment
      load_direnv = "shell_hook";

      # Use nixd instead of nil for Nix language server
      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
      };
    };

    userKeymaps = [
      {
        context = "Workspace";
        bindings = { };
      }
      {
        context = "Editor && vim_mode == insert";
        bindings = { };
      }
      {
        bindings = {
          "cmd-m" = "workspace::ToggleZoom";
        };
      }
    ];
  };

  programs.firefox = {
    enable = true;
  };

  programs.zellij = {
    enable = true;
    settings = {
      web_server = true;
    };
  };

}
