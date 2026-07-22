{ pkgs, ... }:
let
  yamlFormat = pkgs.formats.yaml { };
  # the package itself is installed via brew, there is no nix package, brew is the straight forward easiest solution

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
      };
      # Claude models get their own provider using litellm's native anthropic-messages
      # endpoint (same one claude.nix points ANTHROPIC_BASE_URL at) instead of
      # openai-completions: going through the OpenAI-compat shim mangles thinking/reasoning
      # blocks for Claude models. anthropic-messages needs compat.disableStrictTools since
      # omp always sends tool.strict, which the Anthropic tool schema rejects
      # (https://github.com/can1357/oh-my-pi/issues/826).
      "netlight-anthropic" = {
        baseUrl = "https://llm-proxy.edgez.live";
        api = "anthropic-messages";
        apiKey = "ANTHROPIC_AUTH_TOKEN";
        authHeader = true;
        auth = "apiKey";
        compat = {
          disableStrictTools = true;
        };
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
