niri msg -j pick-window | jq -r '"match app-id=\"\(.app_id)\" title=\"\(.title)\""' | wl-copy
