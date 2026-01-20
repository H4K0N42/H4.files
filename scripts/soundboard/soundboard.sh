#!/bin/sh

# Usage: ./play_sound.sh 63GB.mp3

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILE=~/Documents/Soundboard/Hagen/"$1"

trap '' HUP

paplay --device=SoundboardSink "$FILE" &
paplay --device=@DEFAULT_SINK@ "$FILE" &
