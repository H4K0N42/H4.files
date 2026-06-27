#!/usr/bin/env bash

if [[ "$TERM" != "xterm-ghostty" ]]; then
    exec ghostty --title=fexec -e "bash" ~/scripts/update.sh
fi
ghostty --title=fexec -e "bash" ~/scripts/update2.sh > /dev/null 2>&1 & disown

nh os switch -u
echo

flatpak update -y
echo
echo Done.
read
