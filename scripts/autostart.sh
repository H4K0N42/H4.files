#!/usr/bin/env bash

pkill -f appimage-run &

pidof waybar >/dev/null || waybar &
pidof hyprpaper >/dev/null || hyprpaper &
killall bash /home/hagen/scripts/wallpaper.sh & bash /home/hagen/scripts/wallpaper.sh &

#hyprctl setcursor theme_mycur 32 &

bluetoothctl connect 2C:BE:EB:4B:F9:90 &

pidof python3 midivol.py >/dev/null || bash /home/hagen/scripts/midivol/run.sh &

systemctl --user restart hyprpolkitagent &

clipse --kill & clipse -listen &

pidof python3 movecur.py >/dev/null || bash /home/hagen/scripts/movecur/run.sh &

appimage-run /home/hagen/Documents/OpenRGB/OpenRGB_1.0rc1.AppImage --server --profile ALL_OFF &
pidof /app/bin/Artemis.UI.Linux >/dev/null || com.artemis_rgb.Artemis --minimized &

streamcontroller -b --close-running &

noisetorch -u &
systemctl --user restart pipewire pipewire-pulse &
noisetorch -i &
bash /home/hagen/scripts/soundboard/run.sh &

pidof gpu-screen-recorder >/dev/null || gpu-screen-recorder -w DP-3 -c mp4 -k h265 -s 1920x1080 -f 30 -a "default_output|app-inverse:spotify|app-inverse:WEBRTC VoiceEngine|app-inverse:Zen" -a "app:WEBRTC VoiceEngine" -a "app:Zen" -a "default_input" -q high -r 60 -o /home/hagen/Videos/Clips &
