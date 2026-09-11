{
  pkgs,
  lib,
  config,
  ...
}:
let
  configMerge = import ../lib/config-merge.nix { inherit lib pkgs; };
  jsonFormat = pkgs.formats.json { };
in
{
  # Per-host opt-ins live here as options so a specific profile (e.g.
  # home.nix / home-private.nix) can add its own mcpServers/settings keys
  # without every profile inheriting them - home-manager merges attrsOf
  # option values contributed from multiple modules automatically.
  options.claude = {
    mcpServers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = { };
      description = "Entries merged into ~/.claude.json .mcpServers (declarative source of truth - replaces the whole key).";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Keys deep-merged into ~/.claude/settings.json (Claude Code owns any key not declared here).";
    };
  };

  config = {
    # Shared across every profile that imports this module (sefe, private, herdr, ...)
    claude.mcpServers.context7 = {
      type = "stdio";
      command = "npx";
      args = [
        "-y"
        "@upstash/context7-mcp"
      ];
      env = { };
    };

    claude.settings.env = {
      ANTHROPIC_BASE_URL = "https://llm-proxy.edgez.live/";
      ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-5";
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-4-5"; # 4.6 not available as of 18.6.26
      ANTHROPIC_MODEL = "sonnet";
      CLAUDE_CODE_SKIP_BEDROCK_AUTH = "true";
      CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "false";
      ENABLE_TOOL_SEARCH = "true";
      # Opt out of telemetry/error-reporting to Anthropic - both are the
      # special "any non-empty value turns it on" kind of flag.
      # https://code.claude.com/docs/en/env-vars
      DISABLE_TELEMETRY = "1";
      DISABLE_ERROR_REPORTING = "1";
    };

    home.packages = with pkgs; [
      unstable.claude-code
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

    home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      configMerge.setPath {
        path = "${config.home.homeDirectory}/.claude.json";
        jqPath = ".mcpServers";
        static = jsonFormat.generate "claude-mcp-servers.json" config.claude.mcpServers;
      }
    );

    home.activation.claudeStaticSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] (
      configMerge.mergeFile {
        path = "${config.home.homeDirectory}/.claude/settings.json";
        static = jsonFormat.generate "claude-static-settings.json" config.claude.settings;
      }
    );
  };
}
