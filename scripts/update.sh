#!/usr/bin/env bash

if [[ "$TERM" != "xterm-ghostty" ]]; then
    exec ghostty --title=update -e "bash" ~/scripts/update.sh
fi
setsid ghostty --title=update -e "bash" ~/scripts/update2.sh < /dev/null > /dev/null 2>&1 & disown

nh os switch -u
echo

flatpak update -y
echo
echo Done.
read
