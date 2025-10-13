#!/bin/bash


hyprctl events | while read -r line; do
    if [[ $line == window:close* ]]; then
        active_ws=$(hyprctl activeworkspace | awk '{print $3}')
        if ! hyprctl clients | grep -q "workspace: 10"; then

            if [[ "$active_ws" == "10" ]]; then
                hyprctl dispatch workspace 1
            fi
        fi
    fi
done
