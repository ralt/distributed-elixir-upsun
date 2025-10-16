#!/bin/bash
# configure_beam.sh - Calculate optimal BEAM flags from container resources

CONFIG_FILE="/run/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo ""  # Return empty, use defaults
  exit 0
fi

CPU=$(jq -r '.info.limits.cpu' "$CONFIG_FILE")
MEMORY=$(jq -r '.info.limits.memory' "$CONFIG_FILE")

# Calculate schedulers using awk instead of bc
if awk "BEGIN {exit !($CPU < 0.5)}"; then
  SCHEDULERS=1
elif awk "BEGIN {exit !($CPU < 1.0)}"; then
  SCHEDULERS=2
else
  SCHEDULERS=$(printf "%.0f" "$CPU")
fi

# Build flags
FLAGS="+S ${SCHEDULERS}:${SCHEDULERS}"

# Low CPU optimizations
if awk "BEGIN {exit !($CPU < 0.5)}"; then
  FLAGS="$FLAGS +sbwt none +sbwtdcpu none +sbwtdio none"
fi

# Low memory optimizations
if [ "$MEMORY" -lt 128 ]; then
  FLAGS="$FLAGS +MBas aoffcaobf +MBacul 0"
fi

echo "$FLAGS"
