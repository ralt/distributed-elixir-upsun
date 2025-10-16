# Upsun MCP Integration Guide

This guide explains how to use the Upsun Model Context Protocol (MCP) server with this project.

## What is Upsun MCP?

Upsun provides an MCP server at `https://mcp.upsun.com/mcp` that allows AI assistants to interact with your Upsun infrastructure. The MCP uses HTTP POST for client-to-server messages with optional Server-Sent Events for streaming.

## Setting Up MCP in Claude Desktop

To use the Upsun MCP with Claude Desktop, add this to your Claude Desktop configuration:

### Configuration File Location

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

### Configuration Example

```json
{
  "mcpServers": {
    "upsun": {
      "url": "https://mcp.upsun.com/mcp",
      "transport": {
        "type": "http",
        "headers": {
          "Authorization": "Bearer YOUR_UPSUN_API_TOKEN"
        }
      }
    }
  }
}
```

## Getting Your Upsun API Token

1. Log in to Upsun console: https://console.upsun.com
2. Go to Account Settings → API Tokens
3. Create a new API token with appropriate permissions
4. Copy the token and add it to your Claude Desktop config

## Available MCP Capabilities

Once configured, you can ask Claude to:

- Deploy applications to Upsun
- Check deployment status
- View application logs
- Manage environment variables
- Scale applications
- Monitor resource usage
- Manage domains and routes

## Example MCP Commands via Claude

After setting up the MCP, you can interact with Upsun through natural language:

```
"Deploy this application to Upsun"
"What's the status of my deployments?"
"Show me the logs for the production environment"
"Scale my application to 3 instances"
```

## Deploying This Project

### Step 1: Initialize Upsun Project

```bash
# Install Upsun CLI
curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash

# Login to Upsun
upsun login

# Create a new project
upsun project:create --title "Hello Distributed Elixir"
```

### Step 2: Set Environment Variables

```bash
# Generate and set Erlang cookie for distribution
upsun variable:create \
  --level project \
  --name ERLANG_COOKIE \
  --value "$(mix phx.gen.secret)"

# Set Phoenix host (replace with your actual domain)
upsun variable:create \
  --level project \
  --name PHX_HOST \
  --value "your-app.upsun.app"
```

### Step 3: Deploy

```bash
# Add remote
upsun project:set-remote

# Deploy
git add .
git commit -m "Initial deployment"
git push upsun main
```

### Step 4: Test OTP Distribution (Multiple Instances)

To test OTP distribution with multiple instances:

1. Edit `.upsun/config.yaml` and uncomment the `workers` section:

```yaml
workers:
  hello_distributed:
    size: S
    count: 3  # Run 3 instances
```

2. Deploy the changes:

```bash
git add .upsun/config.yaml
git commit -m "Enable multiple instances for distribution"
git push upsun main
```

3. Test the distributed counter across instances:

```bash
# Get your app URL
upsun url

# Test the nodes endpoint
curl https://your-app.upsun.app/nodes

# Increment counter multiple times
curl -X POST https://your-app.upsun.app/counter/increment
curl -X POST https://your-app.upsun.app/counter/increment

# Check counter value (should be consistent across all nodes)
curl https://your-app.upsun.app/counter
```

## MCP-Assisted Deployment

With the Upsun MCP configured in Claude Desktop, you can simply say:

```
"Deploy the hello_distributed Elixir app to Upsun with 3 instances for testing OTP distribution"
```

Claude will use the MCP to handle the deployment automatically!

## Troubleshooting

### MCP Connection Issues

- Verify your API token is valid and not expired
- Check the MCP URL is correct: `https://mcp.upsun.com/mcp`
- Ensure headers are properly formatted in the config

### OTP Distribution Issues

- Verify `ERLANG_COOKIE` is set to the same value across all instances
- Check that `ENABLE_DISTRIBUTION` is set to `true`
- Ensure nodes can communicate (firewall rules, network configuration)

### Application Not Starting

- Check logs: `upsun log`
- Verify all environment variables are set
- Ensure dependencies are installed: check build logs

## Resources

- [Upsun MCP Announcement](https://devcenter.upsun.com/posts/upsun-mcp-announcement/)
- [Deploy MCP Servers on Upsun](https://devcenter.upsun.com/posts/deploy-mcp-servers-on-upsun/)
- [Upsun Elixir Documentation](https://docs.upsun.com/languages/elixir.html)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
