#!/bin/bash


if pgrep -x spotify >/dev/null 2>&1; then
    ~/.config/hypr/scripts/hl-dispatch togglespecialworkspace music
else
    spotify-launcher & disown
    
    for _ in $(seq 1 100); do
        if hyprctl clients -j 2>/dev/null | grep -qi spotify; then
            break
        fi
        sleep 0.3
    done
    sleep 0.3
    
    if ! hyprctl monitors -j 2>/dev/null | grep -q 'special:music'; then
        ~/.config/hypr/scripts/hl-dispatch togglespecialworkspace music
    fi
fi
