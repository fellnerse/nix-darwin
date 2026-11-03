{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./common.nix
  ];

  # sefe-only Claude Code extras: work MCP server + the ai-tooling-marketplace
  # plugin/statusline (needs SSH access to gitlab.netlight.com, which only
  # this profile has) - not shared via claude.nix's defaults.
  claude.mcpServers.atlassian = {
    type = "http";
    url = "https://mcp.atlassian.com/v1/mcp";
  };

  claude.settings = {
    # Route through sefe's corporate LLM proxy - sefe-only, everyone else
    # (private, herdr) uses a regular Anthropic subscription directly.
    env = {
      ANTHROPIC_BASE_URL = "https://llm-proxy.edgez.live/";
      ANTHROPIC_DEFAULT_OPUS_MODEL = "claude-opus-5-5";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-5-5";
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-haiku-5-5";
      ANTHROPIC_MODEL = "sonnet";
      CLAUDE_CODE_SKIP_BEDROCK_AUTH = "true";
    };
    enabledPlugins = {
      "statusline@ai-tooling-marketplace" = true;
    };
    extraKnownMarketplaces = {
      "ai-tooling-marketplace" = {
        source = {
          source = "git";
          url = "git@gitlab.netlight.com:tech-open/ai-tooling/claude-skills.git";
        };
      };
    };
    statusLine = {
      type = "command";
      command = "${config.home.homeDirectory}/.claude/plugins/cache/ai-tooling-marketplace/statusline/1.0.0/hooks/statusline.sh";
    };
  };

  home = {
    username = "sefe";
    homeDirectory = "/Users/sefe";
    stateVersion = "26.05";
    packages = with pkgs; [
      # teams
      sops
      kubectl
      k9s
      github-copilot-cli
    ];
  };

  # Sefe-specific starship settings
  programs.starship.settings = {
    aws.disabled = true;
    gcloud.disabled = true;
    azure.disabled = true;
    docker_context.disabled = true;
    nix_shell.disabled = true;
    line_break.disabled = false;
    directory = {
      truncate_to_repo = true;
    };
    kubernetes = {
      disabled = false;
    };
  };

  # Sefe-specific git config
  programs.git.settings.user = {
    name = "sefe 💯";
    email = "sefe@netlight.com"; # Replace with actual email
  };

  # startwork8: stay-open applet that opens/closes the daily work app set.
  # Source lives in scripts/startwork8.applescript and is recompiled into a
  # local .app on every switch - deliberately NOT in iCloud Drive, since
  # Script Editor saving a bundled .app there reliably throws Error -45
  # (the File Provider sync daemon races the directory-replace write). Git
  # history is the backup now, not iCloud.
  home.activation.startwork8App =
    let
      appPath = "${config.home.homeDirectory}/Applications/startwork8.app";
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      /usr/bin/pkill -f ${lib.escapeShellArg "${appPath}/Contents/MacOS/applet"} 2>/dev/null || true
      rm -rf ${lib.escapeShellArg appPath}
      mkdir -p ${lib.escapeShellArg "${config.home.homeDirectory}/Applications"}
      /usr/bin/osacompile -s -o ${lib.escapeShellArg appPath} ${./scripts/startwork8.applescript}
    '';
  # overwrite in client projects like this:
  # shellHook = ''
  #  # Project-specific git config (overrides home-manager defaults)
  #  git config user.name "Client Developer"
  #  git config user.email "dev@client.com"
  #  ...
  #  ''
}
