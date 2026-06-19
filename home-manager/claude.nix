{ pkgs, lib, ... }:
let
  # Written to ~/.claude.json — replaces mcpServers entirely (declarative source of truth)
  claudeMcpServers = {
    atlassian = {
      type = "http";
      url = "https://mcp.atlassian.com/v1/mcp";
    };
    context7 = {
      type = "stdio";
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp"
      ];
      env = { };
    };
    serena = {
      type = "stdio";
      command = "serena";
      args = [
        "start-mcp-server"
        "--context=claude-code"
        "--project-from-cwd"
        "--open-web-dashboard"
        "false"
      ];
      env = { };
    };
  };
  # Written to ~/.claude/settings.json — merged (Claude Code owns the rest)
  claudeStaticSettings = {
    enabledPlugins = {
      "compound-engineering@compound-engineering-plugin" = true;
    };
    extraKnownMarketplaces = {
      "compound-engineering-plugin" = {
        source = {
          source = "github";
          repo = "EveryInc/compound-engineering-plugin";
        };
      };
    };
    env = {
      ANTHROPIC_BASE_URL = "https://llm-proxy.edgez.live/";
      ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-4-8";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-6";
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5"; # 4.6 not available as of 18.6.26
      ANTHROPIC_MODEL = "sonnet";
      CLAUDE_CODE_SKIP_BEDROCK_AUTH = "true";
      CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1";
    };
  };
in
{
  home.packages = with pkgs; [
    unstable.claude-code
    serena
    nodejs_24 # needed for context7, as it runs with npx
  ];

  # Claude Code global instructions
  home.file.".claude/CLAUDE.md".text = ''
    you can check the coverage of the current branch against main with `aurora check-coverage`
    - always use uv for running python stuff, otherwise packages are missing etc. uv is managing the environment.
    - always follow a 80/20 approach. KISS. don't do backwards compatible stuff, we are a startup and just change things.
    - never add any claude related info to git commits
    - we use conventional commit messages, but keep in mind that commitizen does not create new releases if the messages is not fix or feat (e.g. refactor does not trigger a new release)

    Always use Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.
  '';

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    f="$HOME/.claude.json"
    [ -f "$f" ] || echo '{}' > "$f"
    tmp=$(${pkgs.jq}/bin/jq --argjson s '${builtins.toJSON claudeMcpServers}' \
      '.mcpServers = $s' "$f")
    echo "$tmp" > "$f"
  '';

  home.activation.claudeStaticSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    f="$HOME/.claude/settings.json"
    [ -f "$f" ] || echo '{}' > "$f"
    tmp=$(${pkgs.jq}/bin/jq --argjson s '${builtins.toJSON claudeStaticSettings}' \
      '. * $s' "$f")
    echo "$tmp" > "$f"
  '';
}
