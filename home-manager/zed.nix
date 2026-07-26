{ ... }:
{
  programs.zed-editor = {
    enable = true;
    # Installed via Homebrew cask (hosts/mbp/homebrew.nix) instead of nixpkgs:
    # zed-editor on aarch64-darwin is a large Rust build that Hydra frequently
    # fails/cancels, so nix flake update regularly lands on an uncached
    # revision and forces a slow local build. home-manager still manages
    # settings/keymaps/tasks/extensions below regardless of package = null.
    package = null;
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
            "pytest-language-server" # I think I need that one, so the fixtures of pytest are resolved correctly
            "!basedpyright"
            "!pyright"
            "..."
          ];
          format_on_save = "on";
          code_actions_on_format = {
            "source.organizeImports.ruff" = true;
          };
          formatter = {
            language_server = {
              name = "ruff";
            };
          };
        };
      };

      # this is for zeditor native stuff
      # other stuff can use these definitions here
      # Auth works via `NL_CODEPILOT_API_KEY` which is set via token-acquirement project
      language_models = {
        openai_compatible = {
          NL-Codepilot = {
            api_url = "https://llm-proxy.edgez.live";
            available_models = [
              {
                name = "claude-latest";
                display_name = "NL - Claude - latest";
                max_tokens = 2000000;
              }
              {
                name = "claude-opus-4-8";
                display_name = "NL - Claude - opus";
                max_tokens = 2000000;
              }
              {
                name = "claude-sonnet-4-6";
                display_name = "NL - Claude - sonnet";
                max_tokens = 2000000;
              }
              {
                name = "claude-haiku-4-5";
                display_name = "NL - Claude - haiku";
                max_tokens = 2000000;
              }
              {
                name = "gpt-5";
                display_name = "NL - GPT-5";
                max_tokens = 4000000;
              }
              {
                name = "gpt-5.1";
                display_name = "NL - GPT-5.1";
                max_tokens = 4000000;
              }
            ];
          };
        };
      };
      # this is the setting for the zed native agent, here we reference the one from above, with the claude-latest default
      # I'm not sure where the auth tokens comes from, but this seems to be currently out of budget, where as the claude code integration still works
      # ah this is set via NL_CODEPILOT_API_KEY, which was different from ANTHROPIC_AUTH_TOKEN
      agent = {
        default_model = {
          provider = "NL-Codepilot";
          model = "claude-sonnet-4-6";
        };
        model_parameters = [ ];
      };
      # and for some reason the edit predictions in the editor need additional settings
      # auth works via ZED_OPEN_AI_COMPATIBLE_EDIT_PREDICTION_API_KEY
      # Not sure why, but it seems not working atm. probably the auth header is not correctly set: https://zed.dev/docs/ai/edit-prediction#self-hosted-openai-compatible-servers
      edit_predictions = {
        provider = "open_ai_compatible_api";
        open_ai_compatible_api = {
          api_url = "https://llm-proxy.edgez.live/v1/completions";
          model = "claude-haiku-4-5";
          prompt_format = "infer";
          max_output_tokens = 64;
        };
      };
      feature_flags = {
        tabular-data-preview = "on";
        notebooks = "on";
      };
      agent_servers = {
        omp = {
          type = "custom";
          command = "omp";
          args = [
            "acp"
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
          "cmd-shift-p" = "git::PullRebase";
          "cmd-shift-m" = "workspace::CloseAllDocks";
          "cmd-g" = "git_graph::Open";
        };
      }
      {
        context = "!ContextEditor > (Editor && mode == full)";
        bindings = {
          "alt-." = "pane::RevealInProjectPanel";
        };
      }
      {
        context = "!Terminal"; # usually it is bound to Workspace, but I want to be able to use cmd p in claude code
        bindings = {
          "cmd-p" = "file_finder::Toggle";
        };
      }
      {
        # allow the usage of ctrl-p in claude code for model selection
        context = "Workspace";
        bindings = {
          "cmd-p" = null;
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
}
