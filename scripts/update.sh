#!/usr/bin/env bash

if [[ "$TERM" != "xterm-ghostty" ]]; then
    exec ghostty --title=fexec -e "bash ~/scripts/update.sh"
fi

if ! sudo nixos-rebuild switch --upgrade; then
    git -C /home/hagen/H4.files/nix/desktop/system/ restore flake.lock
    sudo nixos-rebuild switch
fi
echo
nix flake update --flake ~/.config/home-manager/
home-manager switch
echo
nix profile upgrade --all
echo
echo Done.
read
