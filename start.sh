#!/bin/bash
set -e

# Configure BEAM dynamically based on container resources
if [ -f "./configure_beam.sh" ]; then
  export ERL_FLAGS=$(./configure_beam.sh)
  if [ -n "$ERL_FLAGS" ]; then
    echo "BEAM configured with: ERL_FLAGS='${ERL_FLAGS}'"
  fi
fi

# Extract hostname from PLATFORM_ROUTES for Phoenix
if [ -n "$PLATFORM_ROUTES" ]; then
  export PHX_HOST=$(echo "$PLATFORM_ROUTES" | base64 --decode | jq -r 'to_entries[] | select(.value.primary==true) | .key | split("://")[1] | split("/")[0]')
  if [ -n "$PHX_HOST" ]; then
    echo "Phoenix host configured: PHX_HOST='${PHX_HOST}'"
  fi
fi

# Get the node name and cookie from environment
export NODE_NAME="$(hostname -s)"
HOST_IP="$(hostname -i)"
export RELEASE_COOKIE="${ERLANG_COOKIE:-change_this_to_a_secure_random_string}"
export RELEASE_NODE="${NODE_NAME}@${HOST_IP}"

if (( "$(cat /run/peers.json | jq length)" > 1 )); then
  echo "More than one peer found, starting with distribution enabled"

if [ -f "$PEERS_FILE" ]; then
  echo "Peers file found, starting with distribution enabled"

  # Get current node's IP
  HOSTNAME=$(hostname)
  HOST_IP=$(jq -r --arg host "$HOSTNAME" '.[$host]' "$PEERS_FILE")

  if [ -z "$HOST_IP" ] || [ "$HOST_IP" == "null" ]; then
    HOST_IP=$(hostname -i | awk '{print $1}')
  fi

  # Build list of peer nodes for sync_nodes_optional (exclude self)
  PEER_NODES=$(jq -r --arg node "$NODE_NAME" --arg host "$HOSTNAME" \
    'to_entries[] | select(.key != $host) | "\($node)@" + .value' \
    "$PEERS_FILE" | sed "s/^/'/;s/$/'/" | paste -sd "," -)

  echo "Starting node: ${NODE_NAME}@${HOST_IP}"
  echo "Peer nodes for auto-connect: ${PEER_NODES}"
  echo "Using cookie: ${ERLANG_COOKIE}"

  # Export variables for Elixir
  export RELEASE_NODE="${NODE_NAME}@${HOST_IP}"
  export RELEASE_COOKIE="${ERLANG_COOKIE}"

  # Start with epmd (Erlang Port Mapper Daemon)
  epmd -daemon

  # Start with automatic peer connection using sync_nodes_optional
  if [ -n "$PEER_NODES" ]; then
    elixir --name "${NODE_NAME}@${HOST_IP}" \
      --cookie "${ERLANG_COOKIE}" \
      --erl "-kernel sync_nodes_optional [${PEER_NODES}]" \
      --erl "-kernel sync_nodes_timeout 5000" \
      -S mix phx.server
  else
    # No peers, just start normally with distribution
    elixir --name "${NODE_NAME}@${HOST_IP}" \
      --cookie "${ERLANG_COOKIE}" \
      -S mix phx.server
  fi
else
  echo "Not enough peers found, starting without distribution"
  mix phx.server
fi
