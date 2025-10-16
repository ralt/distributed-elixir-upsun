#!/bin/bash
set -e

# Get the node name and cookie from environment
NODE_NAME="${NODE_NAME:-hello_distributed}"
ERLANG_COOKIE="${ERLANG_COOKIE:-change_this_to_a_secure_random_string}"

# Check if we should enable distributed mode
PEERS_FILE="/run/peers.json"

if [ -f "$PEERS_FILE" ]; then
  echo "Peers file found, starting with distribution enabled"

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

  # Start Phoenix with distribution enabled
  elixir --name "${NODE_NAME}@${HOST_IP}" \
    --cookie "${ERLANG_COOKIE}" \
    -S mix phx.server
else
  echo "Peers file not found at $PEERS_FILE, starting without distribution"
  mix phx.server
fi
