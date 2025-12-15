#!/usr/bin/env bash

first_line="$(maccel get mode | head -n 1)"

if [[ "$first_line" == "Natural (w/ Gain)" ]]; then
    maccel set mode no-accel
    hyprctl notify 5 3000 "rgb(00ff00)" "Mouse Mode: Noaccel"
else
    maccel set mode natural
    hyprctl notify 5 3000 "rgb(00ff00)" "Mouse Mode: Natural"
fi
