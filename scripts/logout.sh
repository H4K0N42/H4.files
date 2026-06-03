#!/usr/bin/env bash

hyprlock -c ~/.config/hypr/hyprlock_off.conf &
sleep 1
killall -SIGINT gpu-screen-recorder
niri msg action quit --skip-confirmation
sleep 1
loginctl kill-user $(whoami)
