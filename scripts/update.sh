#!/usr/bin/env bash
if zenity --question --text="Update system?"; then
    ghostty --title=fexec -e "sudo nix flake update --flake /etc/nixos/;echo;nix flake update --flake ~/.config/home-manager/;echo;sudo nixos-rebuild switch --upgrade;echo;home-manager switch;echo;nix profile upgrade --all;echo;read"
    # if zenity --question --text="Optimize NixOS?"; then
    # ghostty --title=fexec -e "bash ~/scripts/nixos-opt.sh;echo;read"
    # fi
fi


# if zenity --question --text="Update system?"; then
#     ghostty --title=fexec -e "sudo nix-channel --update;echo;nix-channel --update;echo;nix flake update --flake ~/.config/home-manager/;echo;sudo nixos-rebuild switch --upgrade;echo;home-manager switch;echo;nix profile upgrade --all;echo;read"
#     if zenity --question --text="Optimize NixOS?"; then
#     ghostty --title=fexec -e "bash ~/scripts/nixos-opt.sh;echo;read"
#     fi
# fi
