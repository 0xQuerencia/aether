#!/usr/bin/env bash
# island-screenshot.sh <region|full|window>
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TS=$(date +"%Y-%m-%d_%H-%M-%S")
FILE="$SAVE_DIR/screenshot-$TS.png"


shot_preview() {
    python3 - "$1" "$HOME/.config/hypr/rice-prefs.json" "${XDG_RUNTIME_DIR:-/tmp}/quickshell/island/shot.json" <<'PY'
import json, os, sys, time
path, prefs, out = sys.argv[1:4]
try:
    if not json.load(open(prefs)).get("shotPreview", True):
        sys.exit(1)
except (OSError, ValueError):
    pass
os.makedirs(os.path.dirname(out), exist_ok=True)
tmp = out + ".tmp"
with open(tmp, "w") as f:
    json.dump({"path": path, "ts": time.time()}, f)
os.replace(tmp, out)
PY
}


case "$1" in
    region)
        grim -g "$(slurp -d)" "$FILE" && wl-copy < "$FILE" && shot_preview "$FILE" &
        ;;
    full)
        grim "$FILE" && wl-copy < "$FILE" && shot_preview "$FILE" &
        ;;
    window)
        GEOM=$(hyprctl -j activewindow 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        grim -g "$GEOM" "$FILE" && wl-copy < "$FILE" && shot_preview "$FILE" &
        ;;
esac
