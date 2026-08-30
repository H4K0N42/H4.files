#!/usr/bin/env bash
cd /mnt/nfs/Soundboard/Hagen
~/scripts/soundboard/soundboard.sh "$(fzf -i --bind 'change:top' --no-mouse)"
