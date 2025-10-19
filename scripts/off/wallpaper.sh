#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/wallpapers/"

MONITORS=("DP-2" "DP-3")

ALL_WALLPAPERS=($(find "$WALLPAPER_DIR" -type f))

USED_WALLPAPERS=()

get_random_wallpaper() {
    local candidates=()
    for wp in "${ALL_WALLPAPERS[@]}"; do
        if [[ ! " ${USED_WALLPAPERS[*]} " =~ " $wp " ]]; then
            candidates+=("$wp")
        fi
    done

    if [ ${#candidates[@]} -eq 0 ]; then
        USED_WALLPAPERS=()
        candidates=("${ALL_WALLPAPERS[@]}")
    fi

    local choice="${candidates[RANDOM % ${#candidates[@]}]}"
    USED_WALLPAPERS+=("$choice")
    echo "$choice"
}

for MON in "${MONITORS[@]}"; do
    WP=$(get_random_wallpaper)
    if [ -z "$WP" ]; then
        echo "Warning: no wallpaper found for monitor $MON"
        continue
    fi
    echo "Setting wallpaper for $MON: $WP"
    hyprctl hyprpaper reload "$MON,$WP"
done

sleep 600
bash /home/hagen/scripts/wallpaper.sh &
kill $$
