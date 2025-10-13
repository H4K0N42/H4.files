#!/usr/bin/env bash

hyprlock -c ~/.config/hypr/hyprlock_off.conf &
sleep 1
hyprctl dispatch exit
loginctl kill-user $(whoami)
