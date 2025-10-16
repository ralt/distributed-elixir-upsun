#!/bin/bash
set -e

# Get the node name and cookie from environment
NODE_NAME="$(hostname)"
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
