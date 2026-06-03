#!/bin/sh

# Usage: ./play_sound.sh 63GB.mp3

if [ -z "$1" ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

FILE=~/Documents/Soundboard/Hagen/"$1"

VOLUME_PERCENT=80
VOLUME=$((65536 * VOLUME_PERCENT / 100))

trap '' HUP

paplay --volume="$VOLUME" --device=SoundboardSink "$FILE" &
paplay --volume="$VOLUME" --device=@DEFAULT_SINK@ "$FILE" &
