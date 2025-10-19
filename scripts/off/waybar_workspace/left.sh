#!/bin/bash

# Temp file to store the last known active workspace from left side
STATE_FILE="./waybar_left_ws_state"

# Get current active workspace
active_ws=$(hyprctl activeworkspace -j | jq '.id')
left_workspaces=(1 2 3)

# Icons
icons=("󰲠" "󰲢" "󰲤")
active_icon=""
default_icon=""

# Initialize last known if not exists
[[ -f "$STATE_FILE" ]] || echo "1" > "$STATE_FILE"

# If current workspace is in 1–3, update the state file
if [[ " ${left_workspaces[*]} " == *" $active_ws "* ]]; then
    echo "$active_ws" > "$STATE_FILE"
fi

# Use the remembered left-side active if we’re on a non-left workspace
left_active_ws=$(cat "$STATE_FILE")

# Render
output=""
for i in "${!left_workspaces[@]}"; do
    ws=${left_workspaces[$i]}
    icon=${icons[$i]}

    if [[ $ws -eq $left_active_ws ]]; then
        output+="<span>$active_icon</span> "
    else
        output+="<span>$icon</span> "
    fi
done

echo "$output"
