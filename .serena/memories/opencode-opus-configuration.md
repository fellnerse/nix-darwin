# OpenCode Claude Opus 4.6 Configuration

## Issue
When using Claude Opus 4.6 in OpenCode with MCP servers (Serena, Context7), requests fail with:
```
litellm.UnsupportedParamsError: bedrock does not support parameters: ['tool_choice'], 
for model=anthropic.claude-opus-4-6-v1:0
```

This occurs because OpenCode sends `tool_choice` parameter when MCP servers are configured, but Bedrock's Opus model requires explicit allowance of this parameter.

## Solution
Add `allowed_openai_params = ["tool_choice"]` to the Opus model configuration in `home-manager/common.nix`:

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

## Solution Attempts & Findings

### Attempt 1: `allowed_openai_params = ["tool_choice"]` 
- ✅ Works for initial requests
- ❌ Fails during compression with: "Bedrock doesn't support tool calling without `tools=` param"

### Attempt 2: `drop_params = true`
- ✅ Theoretically should strip `tool_choice`
- ❌ Still fails - `drop_params` at model/provider level not being honored by proxy

### Attempt 3: Provider-level `drop_params = true`
- ❌ Settings not being passed through to litellm proxy

## Root Cause Analysis
**This is a backend litellm proxy configuration issue, NOT an OpenCode config issue**

Evidence:
- Claude Code works with Opus + tools through the same proxy
- OpenCode fails on first request, not just compression
- Both use the same proxy endpoint (`https://llm-proxy.edgez.live`)
- Claude Latest works fine in OpenCode
- The error explicitly says: "set `litellm_settings: drop_params: true`" (server-side config, not client-side)

## Action Required
Contact litellm proxy admins:
1. Claude Code works with Opus but OpenCode doesn't
2. OpenCode uses `@ai-sdk/openai-compatible` SDK
3. Error: `bedrock does not support parameters: ['tool_choice']` on first request
4. Need model-specific litellm config for `claude-opus-4-6` to handle `tool_choice`
5. Claude Latest works fine - check what's different about Opus configuration
