{ pkgs, ... }:
let
  yamlFormat = pkgs.formats.yaml { };
  # the package itself is installed via brew, there is no nix package, brew is the straight forward easiest solution

  # Same litellm proxy as claude.nix/opencode.nix/zed.nix, auth via NL_CODEPILOT_API_KEY
  # (set externally by the token-acquirement project, not managed here)
  netlightModels = [
    {
      id = "claude-latest";
      name = "Claude Latest";
      contextWindow = 200000;
      maxTokens = 64000;
    }
    {
      id = "claude-opus-4-8";
      name = "Claude Opus 4.8";
      contextWindow = 200000;
      maxTokens = 64000;
    }
    {
      id = "claude-sonnet-4-6";
      name = "Claude Sonnet 4.6";
      contextWindow = 200000;
      maxTokens = 64000;
    }
    {
      id = "claude-haiku-4-5";
      name = "Claude Haiku 4.5";
      contextWindow = 200000;
      maxTokens = 64000;
    }
    {
      id = "gpt-5";
      name = "GPT-5";
      contextWindow = 400000;
      maxTokens = 128000;
    }
    {
      id = "gpt-5.1";
      name = "GPT-5.1";
      contextWindow = 400000;
      maxTokens = 128000;
    }
    {
      id = "gpt-5.6-luna";
      name = "GPT-5.6 Luna";
      contextWindow = 1100000;
      maxTokens = 128000;
    }
    {
      id = "gpt-5.6-terra";
      name = "GPT-5.6 Terra";
      contextWindow = 1100000;
      maxTokens = 128000;
    }
    {
      id = "gpt-5.6-sol";
      name = "GPT-5.6 Sol";
      contextWindow = 1100000;
      maxTokens = 128000;
    }
  ];

  modelsConfig = {
    providers = {
      netlight = {
        baseUrl = "https://llm-proxy.edgez.live";
        api = "openai-completions";
        apiKey = "ANTHROPIC_AUTH_TOKEN";
        authHeader = true;
        auth = "apiKey";
        models = netlightModels;
        discovery = {
          type = "litellm";
        };
      };
    };
  };
in
{
  # Package installed via Homebrew tap (hosts/mbp/homebrew.nix) - not in nixpkgs
  home.file.".omp/agent/models.yml".source = yamlFormat.generate "models.yml" modelsConfig;
}
