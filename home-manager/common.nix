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
    # beads # git-backed issue tracker for AI agents (provides bd completions)
    # gastown # multi-agent orchestration system (includes beads, tmux, git as dependencies, provides gt completions)
    stats # shows networking stats in status bar
    gh
    mise
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
    matchBlocks = {
      "pve.local" = {
        user = "root";
      };
    };
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
      "toml"
      "opencode"
      "pytest-language-server"
    ];

    userSettings = {
      autosave = {
        "after_delay" = {
          "milliseconds" = 500;
        };
      };
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
            "..."
          ];
        };
        Python = {
          language_servers = [
            "ty"
            "ruff"
            "pytest-language-server"
            "!basedpyright"
            "..."
          ];
          format_on_save = "on";
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
          "cmd-shift-w" = "workspace::CloseInactiveTabsAndPanes";
          "cmd-shift-t" = "terminal_panel::Toggle";
          "alt-cmd-o" = [
            "projects::OpenRecent"
            {
              "create_new_window" = true;
            }
          ];
          "cmd-?" = "agent::ToggleFocus";
          "cmd-alt-c" = [
            "task::Spawn"
            { "task_name" = "Copy Azure DevOps Permalink"; }
          ];
        };
      }
      {
        context = "!ContextEditor > (Editor && mode == full)";
        bindings = {
          "alt-." = "pane::RevealInProjectPanel";
        };
      }
    ];

    # Custom Tasks
    userTasks = [
      {
        label = "Copy Azure DevOps Permalink";
        # We use a single line command to ensure Zed/JSON parsing doesn't break
        command = "begin; set -l RAW_URL (git remote get-url origin); if string match -q 'git@ssh.dev.azure.com:v3/*' $RAW_URL; set -l STRIPPED (string replace 'git@ssh.dev.azure.com:v3/' '' $RAW_URL); set -l PARTS (string split '/' $STRIPPED); set -l ORG $PARTS[1]; set -l PROJ $PARTS[2]; set -l REPO (string replace -r '\\.git$' '' $PARTS[3]); set BASE_URL \"https://dev.azure.com/$ORG/$PROJ/_git/$REPO\"; else; set BASE_URL (string replace -r '\\.git$' '' $RAW_URL); end; set -l COMMIT (git rev-parse HEAD); set -l NEXT_ROW (math \"$ZED_ROW + 1\"); echo \"$BASE_URL?path=/$ZED_RELATIVE_FILE&version=GC$COMMIT&line=$ZED_ROW&lineEnd=$NEXT_ROW&lineStartColumn=1&lineEndColumn=1&lineStyle=plain&_a=contents\" | pbcopy; osascript -e 'display notification \"Permalink copied to clipboard\" with title \"Zed\"'; end";
        hide = "on_success";
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

  # Stats: Menu bar app that runs silently in the background
  # Launched directly via binary with ProcessType = "Interactive" to enable GUI interaction
  # This launches without showing any windows - perfect for menu bar apps
  launchd.agents.stats = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.stats}/Applications/Stats.app/Contents/MacOS/Stats" ];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  # Ghostty: Terminal app with hotkey window support
  # Must use /usr/bin/open with -g flag (background) instead of direct binary launch
  # Opens an initial window but keeps app in background for hotkey functionality
  # Direct binary launch fails on macOS; -j flag hides app too much and breaks hotkey
  launchd.agents.ghostty = {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        "-a"
        "/Applications/Ghostty.app"
      ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;
    settings = {
      share = "disabled";
      lsp = {
        pyright = {
          disabled = true;
        };
        ty = {
          command = [
            "ty"
            "server"
          ];
          extensions = [
            ".py"
            ".pyi"
          ];
        };
      };
      provider = {
        nlcodepilot = {
          name = "NL Codepilot";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://llm-proxy.edgez.live";
          };
          models = {
            claude-latest = {
              name = "Claude Latest";
              limit = {
                context = 200000;
                output = 64000;
              };
              cost = {
                input = 1.1;
                output = 5.5;
              };
            };
            claude-opus-4-5-20251101 = {
              name = "Claude Opus 4.5";
              limit = {
                context = 200000;
                output = 64000;
              };
              cost = {
                input = 5;
                output = 25;
              };
            };
          };
        };
      };
    };
  };
}
