# nix-darwin configuration

## OpenCode Configuration

### Claude Opus 4.6 with Tool Use

When using Claude Opus 4.6 in OpenCode with MCP servers (Serena, Context7), you need to explicitly allow the `tool_choice` parameter in the model configuration. This tells litellm that `tool_choice` is allowed and should be passed through to Bedrock.

The configuration is in `home-manager/common.nix`:
```nix
claude-opus-4-6 = {
  name = "Claude Opus 4.6";
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
};
```

Without this configuration, you'll get: `bedrock does not support parameters: ['tool_choice']`

## Claude Code MCP Servers

### Serena

[Serena](https://github.com/oraios/serena) provides code-aware tools for semantic code search, refactoring, and project understanding. Installed via home-manager.

**Global configuration (recommended):**
```bash
claude mcp add --scope user serena -- serena start-mcp-server --context=claude-code --project-from-cwd --open-web-dashboard false```

**Per-project configuration:**
```bash
claude mcp add serena -- serena start-mcp-server --context claude-code --project "$(pwd) --open-web-dashboard false"
```

Options:
- `--context claude-code` disables tools that duplicate Claude Code's built-in capabilities
- `--project-from-cwd` auto-detects project from current directory
- `--open-web-dashboard false` disables the web dashboard

### Context7

[Context7](https://github.com/upstash/context7) fetches up-to-date, version-specific documentation directly into your prompt.

**Add to Claude Code:**
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
```

**Usage:** Add "use context7" to your prompt, e.g.: "Create a basic FastAPI app with CORS middleware. use context7"

Optional: Get a free API key at [context7.com/dashboard](https://context7.com/dashboard) for higher rate limits, then:
```bash
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

## Troubleshooting

### mac-app-util trampolines: "open: command not found"

When using `mac-app-util` for trampoline apps (so Nix-installed apps work with Spotlight/Dock), you may get `sh: open: command not found` when launching apps.

**Cause:** The launchd PATH doesn't include `/usr/bin` where the `open` command lives.

**Fix (persistent, requires reboot):**
```bash
sudo launchctl config user path "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin"
```

**Fix (current session only):**
```bash
launchctl setenv PATH "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin"
killall Finder  # Restart Finder to pick up new PATH
```

### Icons showing as AppleScript icon

If trampoline apps show the generic AppleScript icon instead of the app icon, clear the icon cache:
```bash
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock
killall Finder
touch ~/Applications/Home\ Manager\ Trampolines/*.app
```

May require logout/login or reboot to fully take effect.
