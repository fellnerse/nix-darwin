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

## Tailscale startup

The `sefe` Home Manager profile opens `/Applications/Tailscale.app` in the background at login through a LaunchAgent (`home-manager/home.nix`).
