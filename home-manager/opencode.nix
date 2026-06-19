{ pkgs, ... }:
{
  programs.opencode = {
    enable = true;
    package = pkgs.unstable.opencode;
    settings = {
      share = "disabled";
      # Use a smaller/same model for compaction (summarization when context gets full)
      small_model = "nlcodepilot/claude-latest";
      compaction = {
        auto = true;
        prune = true;
      };
      # Agent-specific config (experimental - from Gemini suggestion)
      agent = {
        compaction = {
          model = "nlcodepilot/claude-latest";
          options = {
            drop_params = true;
          };
        };
      };
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
      mcp = {
        serena = {
          type = "local";
          command = [
            "serena"
            "start-mcp-server"
            "--open-web-dashboard=false"
          ];
          enabled = true;
        };
        context7 = {
          type = "local";
          command = [
            "npx"
            "-y"
            "@upstash/context7-mcp"
          ];
          enabled = true;
        };
      };
      provider = {
        nlcodepilot = {
          name = "NL Codepilot";
          npm = "@ai-sdk/openai-compatible";
          options = {
            baseURL = "https://llm-proxy.edgez.live";
            litellmProxy = "true";
          };
          models = {
            claude-latest = {
              name = "Claude Latest";
              limit = {
                context = 200000;
                output = 64000;
              };
              cost = {
                input = 3;
                output = 15;
              };
            };
            claude-opus-4-8 = {
              name = "Claude Opus 4.8";
              limit = {
                context = 200000;
                output = 64000;
              };
              cost = {
                input = 5;
                output = 25;
              };
              options = {
                allowed_openai_params = [
                  "tool_choice"
                ];
              };
              compaction = {
                model = "nlcodepilot/claude-latest";
                options = {
                  drop_params = true;
                };
              };
            };
          };
        };
      };
    };
  };
}
