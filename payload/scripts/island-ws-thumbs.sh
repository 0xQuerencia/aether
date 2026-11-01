#!/usr/bin/env bash


THUMB_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell/island/ws_thumbs"
mkdir -p "$THUMB_DIR"


exec 9>"${XDG_RUNTIME_DIR:-/tmp}/quickshell/island/ws_thumbs.lock"
if ! flock -n 9; then
    exit 0   # another instance already holds the lock
fi
trap 'pkill -P $$ 2>/dev/null' EXIT SIGTERM SIGINT

capture() {
    local ws
    ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id' 2>/dev/null)
    [[ "$ws" =~ ^[0-9]+$ ]] || return
    [ "$ws" -ge 1 ] && [ "$ws" -le 9 ] || return


    grim -t ppm - 2>/dev/null \
        | magick - -resize 384x216^ -gravity center -extent 384x216 -quality 72 \
          "jpg:$THUMB_DIR/$ws.jpg.tmp" 2>/dev/null \
        && mv -f "$THUMB_DIR/$ws.jpg.tmp" "$THUMB_DIR/$ws.jpg" 2>/dev/null
}


sleep 0.5
capture


SOCK="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
while true; do
    socat -u "UNIX-CONNECT:$SOCK" - 2>/dev/null | while read -r line; do
        case "$line" in
            workspace\>\>*|focusedmon\>\>*)
                
                while read -t 0.05 -r _; do :; done
                sleep 0.35
                capture
                ;;
        esac
    done
    sleep 1
done
