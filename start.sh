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

  echo "Starting node: ${RELEASE_NODE}"
  echo "Using cookie: ${RELEASE_COOKIE}"

  # Start with epmd (Erlang Port Mapper Daemon)
  epmd -daemon

  # Start Phoenix with distribution enabled
  elixir --name "${RELEASE_NODE}" \
    --cookie "${RELEASE_COOKIE}" \
    -S mix phx.server
else
  echo "Not enough peers found, starting without distribution"
  mix phx.server
fi
