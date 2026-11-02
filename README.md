# nix-darwin configuration

## Claude Code MCP Servers

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

## Tailscale

`services.tailscale` in `hosts/mbp/configuration.nix` runs the CLI-only `tailscaled` as a system LaunchDaemon. It uses macOS `utun`, not a Tailscale system extension, and has no GUI. Manage it with `sudo tailscale up` and `sudo tailscale status`; nix-darwin configures the `ts.net` MagicDNS resolver.

First run `mise run user` to remove the old login launcher. Then quit and remove Tailscale.app, empty Trash, and reboot. After reboot, run `mise run system` to install the daemon, then `sudo tailscale up` to authenticate.
