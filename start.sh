#!/bin/bash
set -e

# Read the peers.json file and connect to other nodes
PEERS_FILE="/run/peers.json"

if [ -f "$PEERS_FILE" ]; then
  echo "Reading peers from $PEERS_FILE"

  # Parse the JSON and create an Elixir module to connect nodes
  cat > /tmp/connect_nodes.exs << 'ELIXIR_SCRIPT'
peers_file = "/run/peers.json"

if File.exists?(peers_file) do
  case File.read(peers_file) do
    {:ok, content} ->
      case Jason.decode(content) do
        {:ok, peers} ->
          IO.puts("Found peers: #{inspect(peers)}")

          # Get current node name
          current_node = Node.self()
          IO.puts("Current node: #{current_node}")

          # Connect to each peer
          Enum.each(peers, fn {node_name, ip_address} ->
            # Construct the full node name (e.g., hello_distributed@10.0.1.2)
            peer_node = String.to_atom("#{System.get_env("NODE_NAME", "hello_distributed")}@#{ip_address}")

            # Skip connecting to ourselves
            if peer_node != current_node do
              IO.puts("Attempting to connect to: #{peer_node}")
              case Node.connect(peer_node) do
                true -> IO.puts("Successfully connected to #{peer_node}")
                false -> IO.puts("Failed to connect to #{peer_node}")
                :ignored -> IO.puts("Connection to #{peer_node} ignored (local node not alive)")
              end
            else
              IO.puts("Skipping self: #{peer_node}")
            end
          end)

          # List all connected nodes
          IO.puts("Connected nodes: #{inspect(Node.list())}")

        {:error, reason} ->
          IO.puts("Failed to parse JSON: #{inspect(reason)}")
      end

    {:error, reason} ->
      IO.puts("Failed to read peers file: #{inspect(reason)}")
  end
else
  IO.puts("Peers file not found at #{peers_file}")
end
ELIXIR_SCRIPT

  # Start the application with node connection script
  echo "Starting Elixir node with distribution enabled"

  # Get the node name and cookie from environment
  NODE_NAME="${NODE_NAME:-hello_distributed}"
  ERLANG_COOKIE="${ERLANG_COOKIE:-change_this_to_a_secure_random_string}"

  # Get the IP address from the peers file (use the first IP that matches our hostname or a fallback)
  HOSTNAME=$(hostname)
  HOST_IP=$(cat "$PEERS_FILE" | grep -oP "\"$HOSTNAME\": \"\\K[^\"]+\"" || echo "127.0.0.1")
  HOST_IP=${HOST_IP//\"/}

  # If we couldn't find our IP, try to get it from the system
  if [ "$HOST_IP" == "127.0.0.1" ]; then
    HOST_IP=$(hostname -i | awk '{print $1}')
  fi

  echo "Starting node: ${NODE_NAME}@${HOST_IP}"
  echo "Using cookie: ${ERLANG_COOKIE}"

  # Export variables for Elixir
  export RELEASE_NODE="${NODE_NAME}@${HOST_IP}"
  export RELEASE_COOKIE="${ERLANG_COOKIE}"

  # Start with epmd (Erlang Port Mapper Daemon)
  epmd -daemon

  # Start Phoenix with distribution enabled and run the connection script after startup
  elixir --name "${NODE_NAME}@${HOST_IP}" \
    --cookie "${ERLANG_COOKIE}" \
    -e "Application.ensure_all_started(:hello_distributed); Code.eval_file(\"/tmp/connect_nodes.exs\"); " \
    -S mix phx.server
else
  echo "Peers file not found at $PEERS_FILE, starting without connecting to peers"
  mix phx.server
fi
