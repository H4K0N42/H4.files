#!/usr/bin/env bash

nh home switch -u

nix profile wipe-history --older-than 7d
nix profile upgrade --all

echo
echo Done.
read
