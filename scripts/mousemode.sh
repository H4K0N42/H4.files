#!/usr/bin/env bash

first_line="$(maccel get param sens-mult)"

if [[ "$first_line" == "0.600000000" ]]; then
    maccel set param sens-mult 0.8
    hyprctl notify 5 3000 "rgb(00ff00)" "Mouse Mode: Speeeed"
else
    maccel set param sens-mult 0.6
    hyprctl notify 5 3000 "rgb(00ff00)" "Mouse Mode: Norm"
fi
