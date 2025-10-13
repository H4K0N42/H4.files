#!/bin/bash

cd /home/hagen/scripts/dc_mute
nix-shell --run "python3 dc_mute.py $1"
