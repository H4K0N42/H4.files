#!/usr/bin/env bash

gpu-screen-recorder -w DP-1 -c mp4 -k av1 -s 2560x1440 -f 60 \
  -a 'default_output|default_input' \
  -a 'app-inverse:Chromium|app-inverse:WEBRTC VoiceEngine|app-inverse:Zen|app-inverse:soundboard_loopback' \
  -a 'app:WEBRTC VoiceEngine' \
  -a 'default_input' \
  -q ultra -ab 256 -r 180 -o /home/hagen/Videos/Clips &

pid=$!

trap "kill -SIGINT $pid" SIGTERM SIGINT

wait $pid
