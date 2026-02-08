#!/usr/bin/env bash

if [[ "$TERM" != "xterm-ghostty" ]]; then
    exec ghostty --title=fexec -e "bash" ~/scripts/update.sh
fi

sudo nix flake update --flake /etc/nixos/
if ! sudo nixos-rebuild switch; then
    git -C /home/hagen/H4.files/nix/desktop/system/ restore flake.lock
    sudo nixos-rebuild switch
fi
echo
home-manager expire-generations "-7 days"
nix flake update --flake ~/.config/home-manager/
home-manager switch
echo
nix profile wipe-history --older-than 7d
nix profile upgrade --all
echo
flatpak update -y
echo
nvd diff /run/booted-system /run/current-system -s
echo
ls -d1v ~/.local/state/nix/profiles/home-manager-*-link | tail -n 2 | xargs nvd diff -s
echo
echo Done.
read
