{
  pkgs,
  lib,
  config,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };
  # the package itself is installed via brew, there is no nix package, brew is the straight forward easiest solution

  configMerge = import ../lib/config-merge.nix { inherit lib pkgs; };

  # Same litellm proxy as claude.nix/opencode.nix/zed.nix, auth via NL_CODEPILOT_API_KEY
  # (set externally by the token-acquirement project, not managed here)
  modelsConfig = {
    providers = {
      netlight = {
        baseUrl = "https://llm-proxy.edgez.live";
        api = "openai-completions";
        apiKey = "ANTHROPIC_AUTH_TOKEN";
        authHeader = true;
        auth = "apiKey";
        discovery = {
          type = "litellm";
        };
        # gpt-5.6-luna (azure/gpt-5.6-luna behind litellm, mode: chat) 500s with
        # "'async for' requires an object with __aiter__ method, got ModelResponse"
        # whenever a request carries both `tools` and `reasoning_effort` (confirmed
        # by replaying the exact request against llm-proxy.edgez.live/v1/chat/completions:
        # tools alone -> 200, reasoning_effort alone -> 200, both together -> 500 for
        # every effort value including "none"). omp always attaches reasoning_effort
        # once a model reports supports_reasoning, so every agentic (tool-using) turn
        # hit this. Disabling `reasoning` here stops omp from ever sending
        # reasoning_effort for this one model; this is a client-side workaround for a
        # litellm/Azure integration bug on the proxy side, report upstream too.
        modelOverrides = {
          "gpt-5.6-luna" = {
            reasoning = false;
          };
        };
      };
      # Claude models get their own provider using litellm's native anthropic-messages
      # endpoint (same one claude.nix points ANTHROPIC_BASE_URL at) instead of
      # openai-completions: going through the OpenAI-compat shim mangles thinking/reasoning
      # blocks for Claude models. anthropic-messages needs disableStrictTools since
      # omp always sends tool.strict, which the Anthropic tool schema rejects
      # (https://github.com/can1357/oh-my-pi/issues/826).
      "netlight-anthropic" = {
        baseUrl = "https://llm-proxy.edgez.live";
        api = "anthropic-messages";
        apiKey = "ANTHROPIC_AUTH_TOKEN";
        authHeader = true;
        auth = "apiKey";
        # top-level field, NOT nested under compat — compat.disableStrictTools
        # is not a recognized key (ArkType keeps unknown keys silently, so this
        # nested form validated fine but had no effect).
        disableStrictTools = true;
        discovery = {
          type = "litellm";
        };
      };
    };
  };

  # ~/.omp/agent/RULES.md — global rules injected into every session
  # (read-only load at startup; omp's UI never writes back to it, unlike
  # config.yml/mcp.json, so a plain overwrite is safe).
  rulesContent = ''
    Never run `find` (especially unscoped `find /`) via bash to locate a file. Use the `glob` tool instead, anchored at a known root (e.g. `.venv/lib/*/site-packages/<pkg>/**`, `node_modules/<pkg>/**`, or the repo root). This has been violated before - treat it as a hard rule, not a style preference.
  '';

  # ~/.omp/agent/config.yml — persistent settings normally written by the
  # `/settings` panel or `omp config set` (docs/settings.md).
  configConfig = {
    setupVersion = 1;
    modelRoles = {
      smol = "netlight-anthropic/claude-haiku-4-5";
      default = "netlight-anthropic/claude-sonnet-5:high";
      slow = "netlight-anthropic/claude-opus-4-8";
    };
    autolearn = {
      enabled = true;
      autoContinue = true;
    };
    providers = {
      webSearchOrder = [
        "brave"
        "perplexity"
        "gemini"
        "anthropic"
        "codex"
        "xai"
        "zai"
        "exa"
        "tinyfish"
        "jina"
        "kagi"
        "tavily"
        "firecrawl"
        "kimi"
        "parallel"
        "synthetic"
        "searxng"
        "startpage"
        "duckduckgo"
        "ecosia"
        "google"
        "mojeek"
        "public"
      ];
    };
    statusLine = {
      separator = "powerline";
    };
    terminal = {
      showProgress = true;
    };
    tui = {
      tight = true;
    };
    display = {
      showTokenUsage = true;
    };
    memory = {
      backend = "mnemopi";
    };
  };

  # ~/.omp/agent/mcp.json — MCP server registry (docs/mcp-config.md).
  mcpConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/can1357/oh-my-pi/main/packages/coding-agent/src/config/mcp-schema.json";
    mcpServers = { };
    disabledServers = [ "serena" ];
  };
in
{
  # Package installed via Homebrew tap (hosts/mbp/homebrew.nix) - not in nixpkgs
  home.file.".omp/agent/models.yml".source = yamlFormat.generate "models.yml" modelsConfig;
  home.file.".omp/agent/RULES.md".text = rulesContent;

  home.activation.ompConfigYml = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    configMerge.mergeFile {
      path = "${config.home.homeDirectory}/.omp/agent/config.yml";
      static = jsonFormat.generate "omp-config.yml" configConfig;
      format = "yaml";
    }
  );

  home.activation.ompMcpJson = lib.hm.dag.entryAfter [ "linkGeneration" ] (
    configMerge.mergeFile {
      path = "${config.home.homeDirectory}/.omp/agent/mcp.json";
      static = jsonFormat.generate "omp-mcp.json" mcpConfig;
      format = "json";
    }
  );
}
