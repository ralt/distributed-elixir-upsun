#!/bin/bash
# configure_beam.sh - Calculate optimal BEAM flags from container resources

CONFIG_FILE="/run/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo ""  # Return empty, use defaults
  exit 0
fi

CPU=$(jq -r '.info.limits.cpu' "$CONFIG_FILE")
MEMORY=$(jq -r '.info.limits.memory' "$CONFIG_FILE")

# Calculate schedulers
if (( $(echo "$CPU < 0.5" | bc -l) )); then
  SCHEDULERS=1
elif (( $(echo "$CPU < 1.0" | bc -l) )); then
  SCHEDULERS=2
else
  SCHEDULERS=$(printf "%.0f" "$CPU")
fi

# Build flags
FLAGS="+S ${SCHEDULERS}:${SCHEDULERS}"

# Low CPU optimizations
if (( $(echo "$CPU < 0.5" | bc -l) )); then
  FLAGS="$FLAGS +sbwt none +sbwtdcpu none +sbwtdio none"
fi

# Low memory optimizations
if [ "$MEMORY" -lt 128 ]; then
  FLAGS="$FLAGS +MBas aoffcaobf +MBacul 0"
fi

echo "$FLAGS"
