# Hello Distributed - Elixir OTP Distribution Demo

A demonstration Phoenix HTTP server showcasing OTP distribution capabilities, ready to deploy on Upsun.

## Features

- **Hello World Endpoint**: Simple HTTP endpoint returning JSON
- **Distributed Counter**: A GenServer-based counter that works across nodes
- **Node Information**: View connected nodes in your cluster
- **OTP Distribution**: Full support for Erlang distribution

## API Endpoints

- `GET /` - Hello world endpoint with node information
- `GET /counter` - Get the current counter value
- `POST /counter/increment` - Increment the counter
- `GET /nodes` - View all connected nodes in the cluster

## Local Development

### Prerequisites

- Elixir 1.18 or later
- Erlang/OTP 27 or later

### Setup

```bash
# Install dependencies
mix deps.get

# Run the server
mix phx.server
```

The server will start on `http://localhost:4000`

### Testing OTP Distribution Locally

You can test distribution by running multiple nodes locally:

```bash
# Terminal 1 - Start first node
iex --name node1@127.0.0.1 --cookie secret -S mix phx.server

# Terminal 2 - Start second node on different port
PORT=4001 iex --name node2@127.0.0.1 --cookie secret -S mix phx.server

# In Terminal 2, connect to node1
Node.connect(:"node1@127.0.0.1")

# Now both nodes can see each other
Node.list()
```

## Deploying to Upsun

### Prerequisites

- Upsun account
- Upsun CLI installed

### Configuration

The project includes `.upsun/config.yaml` with:

- Elixir 1.18 runtime
- Production environment configuration
- OTP distribution enabled via `ENABLE_DISTRIBUTION` variable
- Secure Erlang cookie for node authentication

### Important Environment Variables

Before deploying, set these variables in Upsun:

```bash
# Generate a secure Erlang cookie
upsun variable:create --level project --name ERLANG_COOKIE --value "$(mix phx.gen.secret)"

# Set your hostname
upsun variable:create --level project --name PHX_HOST --value "your-app.upsun.app"
```

### Deploy

```bash
# Push to Upsun
git add .
git commit -m "Initial commit"
upsun push
```

## How OTP Distribution Works

This application demonstrates OTP distribution through a distributed counter:

1. **Distributed Counter GenServer** (`lib/hello_distributed/distributed_counter.ex`):
   - Uses global registration with `{:global, __MODULE__}` to ensure only one counter process exists across the entire cluster
   - When nodes connect, only the first node to start successfully registers the counter globally
   - Other nodes attempting to start the counter receive `:ignore` and gracefully skip registration
   - All nodes can access the counter by calling `{:global, __MODULE__}` - Erlang automatically routes to the correct node
   - Maintains a single source of truth for the counter value across all instances

2. **Node Discovery**:
   - `Node.self()` - Current node name
   - `Node.list()` - All connected nodes
   - Nodes automatically discover each other when configured with the same cookie
   - On Upsun, uses `/run/peers.json` to automatically discover and connect to peer nodes

3. **Configuration** (`config/runtime.exs`):
   - Sets up node name and cookie at runtime
   - Enables longnames for distributed communication
   - Uses environment variables for production settings
   - Reads `/run/peers.json` to connect to other application instances

## Testing Distribution on Upsun

To test distribution with multiple instances:

1. Uncomment the `workers` section in `.upsun/config.yaml`
2. Deploy the changes
3. Hit the `/nodes` endpoint to see all instances
4. Use `/counter` endpoints to see shared state across instances

## Architecture

```
HelloDistributed.Application
├── HelloDistributedWeb.Telemetry
├── Phoenix.PubSub
├── HelloDistributedWeb.Endpoint
└── HelloDistributed.DistributedCounter (GenServer)
```

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir OTP Distribution](https://elixir-lang.org/getting-started/mix-otp/distributed-tasks.html)
- [Upsun Elixir Documentation](https://docs.upsun.com/languages/elixir.html)
- [Erlang Distribution Protocol](https://www.erlang.org/doc/reference_manual/distributed.html)

---

Built with [Claude](https://claude.ai)
