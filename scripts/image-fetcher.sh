#!/bin/bash

# Target file for Eww to display
TMP_DIR="/tmp/eww/media"
mkdir -p "$TMP_DIR"
DEFAULT_ICON="./resources/placeholder.png"

while true; do
playerctl metadata --format '{{mpris:artUrl}}' --follow | while read -r url; do
    TS=$(date +%s) 
    COVER_PATH="$TMP_DIR/cover_$TS.jpg"
    rm -f "$TMP_DIR"/cover_*.jpg
    if [[ "$url" == "https://"* ]]; then
        curl -s "$url" --output "$COVER_PATH"
        echo "$COVER_PATH"
    elif [[ "$url" == "file://"* ]]; then
        echo "${url#file://}"
    else
        echo "$DEFAULT_ICON"
    fi
done
sleep 2
done
