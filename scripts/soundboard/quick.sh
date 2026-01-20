#!/usr/bin/env bash
cd /mnt/nfs/Soundboard/Hagen
hyprctl dispatch focuswindow title:Soundboard
~/scripts/soundboard/soundboard.sh "$(fzf -i --bind 'change:top' --no-mouse)"
