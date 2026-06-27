#!/usr/bin/env bash

if [[ "$TERM" != "xterm-ghostty" ]]; then
    exec ghostty --title=fexec -e "bash" ~/scripts/update.sh
fi

nh os switch -u
echo

flatpak update -y
echo
echo Done.
read
