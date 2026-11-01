#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "music"


SEEK_FILE="$QS_RUN_MUSIC/seek_data"

# Arg mapping
command=$1
arg=$2
len_sec=$3
player_name=$4

# Fallback for player name
if [ -z "$player_name" ]; then
    player_name=$(playerctl status -f "{{playerName}}" 2>/dev/null | head -n 1)
fi
if [ -z "$player_name" ]; then exit 0; fi

case $command in
    "seek")
        
        echo "$arg $len_sec $player_name" > "$SEEK_FILE"

        lock_file="$QS_RUN_MUSIC/seek.lock"
        
        
        if [ -f "$lock_file" ]; then
            exit 0
        fi

        
        touch "$lock_file"
        
        (
            # debounce rapid updates
            sleep 0.05
            
            read -r final_arg final_len final_player < "$SEEK_FILE"
            
            # Perform the Seek Logic
            if [ -n "$final_len" ] && [ "$final_len" != "0" ]; then
                # Use AWK for math
                target_sec=$(awk -v len="$final_len" -v perc="$final_arg" 'BEGIN { printf "%.2f", (len * perc) / 100 }')
                # Execute
                playerctl -p "$final_player" position "$target_sec"
            fi
            
            
            rm "$lock_file"
        ) & 
        
        
        exit 0
        ;;
    
    "next")
        playerctl -p "$player_name" next ;;
        
    "prev")
        playerctl -p "$player_name" previous ;;
        
    "play-pause")
        playerctl -p "$player_name" play-pause ;;
        
esac
