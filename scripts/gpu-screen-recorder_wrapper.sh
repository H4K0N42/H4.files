#!/usr/bin/env sh
trap 'kill -INT "$pid"' TERM
gpu-screen-recorder -w DP-3 -c mp4 -k h265 -s 2560x1440 -f 30 -a 'default_output|app-inverse:Chromium|app-inverse:WEBRTC VoiceEngine|app-inverse:Zen' -a 'app:WEBRTC VoiceEngine'  -a 'app:Zen' -a 'default_input' -q high -r 180 -o /home/hagen/Videos/Clips &
pid=$!
wait "$pid"
