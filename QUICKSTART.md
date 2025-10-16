# Quick Start Guide

Get your distributed Elixir application running in minutes!

## Prerequisites

- Elixir 1.18+ and Erlang/OTP 27+
- Git
- Upsun CLI (for deployment)

## Local Development

### 1. Install Dependencies

```bash
mix deps.get
```

### 2. Start the Server

```bash
mix phx.server
```

Visit http://localhost:4000

### 3. Test the API

```bash
# Hello World
curl http://localhost:4000/

# Get Counter
curl http://localhost:4000/counter

# Increment Counter
curl -X POST http://localhost:4000/counter/increment

# View Nodes
curl http://localhost:4000/nodes
```

## Testing OTP Distribution Locally

### Run Multiple Nodes

**Terminal 1:**
```bash
iex --name node1@127.0.0.1 --cookie secret -S mix phx.server
```

**Terminal 2:**
```bash
PORT=4001 iex --name node2@127.0.0.1 --cookie secret -S mix phx.server
```

**Terminal 3:**
```bash
PORT=4002 iex --name node3@127.0.0.1 --cookie secret -S mix phx.server
```

### Connect Nodes

In Terminal 2 (node2):
```elixir
Node.connect(:"node1@127.0.0.1")
```

In Terminal 3 (node3):
```elixir
Node.connect(:"node1@127.0.0.1")
```

### Verify Cluster

In any terminal:
```elixir
Node.list()  # Should show all connected nodes
```

### Test Distributed Counter

```bash
# Increment from node1
curl http://localhost:4000/counter/increment

# Check from node2 (should see same count!)
curl http://localhost:4001/counter

# Check from node3
curl http://localhost:4002/counter

# View cluster from each node
curl http://localhost:4000/nodes
curl http://localhost:4001/nodes
curl http://localhost:4002/nodes
```

## Deploy to Upsun

### 1. Install Upsun CLI

```bash
curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash
```

### 2. Login and Create Project

```bash
upsun login
upsun project:create --title "Hello Distributed Elixir"
```

### 3. Set Required Variables

```bash
# Generate Erlang cookie
upsun variable:create --level project --name ERLANG_COOKIE --value "$(mix phx.gen.secret)"

# Set hostname (replace with your actual domain)
upsun variable:create --level project --name PHX_HOST --value "your-app.upsun.app"
```

### 4. Deploy

```bash
git add .
git commit -m "Initial deployment"
git push upsun main
```

### 5. Open Your App

```bash
upsun url
```

## Deploy with Multiple Instances (OTP Distribution)

Edit `.upsun/config.yaml` and uncomment:

```yaml
workers:
  hello_distributed:
    size: S
    count: 3
```

Then deploy:

```bash
git add .upsun/config.yaml
git commit -m "Enable distributed mode with 3 instances"
git push upsun main
```

Test it:

```bash
# View nodes (should show 3 instances)
curl https://your-app.upsun.app/nodes

# Increment counter
curl -X POST https://your-app.upsun.app/counter/increment

# Counter should be shared across all instances
curl https://your-app.upsun.app/counter
```

## Project Structure

```
hello_distributed/
├── .upsun/
│   └── config.yaml          # Upsun deployment configuration
├── config/
│   ├── config.exs           # Main configuration
│   ├── dev.exs              # Development settings
│   ├── prod.exs             # Production settings
│   └── runtime.exs          # Runtime configuration (OTP setup)
├── lib/
│   ├── hello_distributed/
│   │   ├── application.ex           # OTP application
│   │   └── distributed_counter.ex   # Distributed GenServer
│   └── hello_distributed_web/
│       ├── controllers/
│       │   ├── page_controller.ex   # API endpoints
│       │   └── error_json.ex        # Error handling
│       ├── endpoint.ex              # Phoenix endpoint
│       ├── router.ex                # Routes
│       └── telemetry.ex             # Monitoring
├── mix.exs                  # Project dependencies
├── README.md               # Full documentation
├── UPSUN_MCP_GUIDE.md      # MCP integration guide
└── QUICKSTART.md           # This file!
```

## API Endpoints

| Method | Path                 | Description                    |
|--------|---------------------|--------------------------------|
| GET    | `/`                 | Hello world with node info     |
| GET    | `/counter`          | Get distributed counter value  |
| POST   | `/counter/increment`| Increment the counter          |
| GET    | `/nodes`            | List all nodes in the cluster  |

## How It Works

1. **OTP Application**: Starts a supervision tree with Phoenix and the counter GenServer
2. **Distributed Counter**: A GenServer that can communicate across nodes using Erlang distribution
3. **Node Discovery**: Nodes with the same cookie automatically discover each other
4. **State Sharing**: The counter state is accessible from any node in the cluster

## Troubleshooting

### "mix: command not found"
Install Elixir: https://elixir-lang.org/install.html

### Nodes won't connect
- Ensure all nodes use the same `--cookie` value
- Check that node names are unique
- Verify network connectivity between nodes

### Port already in use
```bash
# Use different port
PORT=4001 mix phx.server
```

### Dependencies won't compile
```bash
# Clean and retry
mix deps.clean --all
mix deps.get
mix compile
```

## Next Steps

- Read [README.md](README.md) for detailed documentation
- Read [UPSUN_MCP_GUIDE.md](UPSUN_MCP_GUIDE.md) for MCP integration
- Explore the code in `lib/hello_distributed/`
- Experiment with multiple nodes and watch state sync
- Deploy to Upsun and test real distributed deployment

## Resources

- Phoenix Framework: https://www.phoenixframework.org/
- Elixir Distribution: https://elixir-lang.org/getting-started/mix-otp/distributed-tasks.html
- Upsun Docs: https://docs.upsun.com/languages/elixir.html
- GenServer Guide: https://elixir-lang.org/getting-started/mix-otp/genserver.html

Happy distributing!
