#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <Client-Name>"
  exit 1
fi

CLIENT="$1"

# Find all lines matching client, get their IDs, pick last one
LAST_ID=$(wpctl status | grep "$CLIENT" | grep -oP '^\s*\d+' | tail -n1)

if [ -z "$LAST_ID" ]; then
  echo "No client found matching '$CLIENT'"
  exit 1
fi

# Get volume for that ID
VOLUME=$(wpctl get-volume "$LAST_ID" 2>/dev/null)

if [ -z "$VOLUME" ]; then
  echo "No volume info for client $CLIENT with ID $LAST_ID"
  exit 1
fi

NUM=$(echo "$VOLUME" | grep -oP '[0-9]+\.[0-9]+')
PERCENT=$(awk "BEGIN {printf \"%d\", $NUM * 100}")

echo "$PERCENT"
