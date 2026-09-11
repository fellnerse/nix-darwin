{
  pkgs,
  inputs,
  config,
  ...
}:
{
  imports = [
    ./common.nix
    inputs.mac-app-util.homeManagerModules.default
  ];

  # sefe-only Claude Code extras: work MCP server + the ai-tooling-marketplace
  # plugin/statusline (needs SSH access to gitlab.netlight.com, which only
  # this profile has) - not shared via claude.nix's defaults.
  claude.mcpServers.atlassian = {
    type = "http";
    url = "https://mcp.atlassian.com/v1/mcp";
  };

  claude.settings = {
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
    stateVersion = "24.05";
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
  # overwrite in client projects like this:
  # shellHook = ''
  #  # Project-specific git config (overrides home-manager defaults)
  #  git config user.name "Client Developer"
  #  git config user.email "dev@client.com"
  #  ...
  #  ''
}
