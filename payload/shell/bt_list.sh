#!/usr/bin/env bash

CONNECTED=$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}')

bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
    [ -z "$mac" ] && continue
    is_connected="false"
    echo "$CONNECTED" | grep -qF "$mac" && is_connected="true"
    # get icon type
    icon=$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Icon/{print $2}' | tr -d ' ')
    [ -z "$icon" ] && icon="bluetooth"
    # escape name
    name=$(echo "$name" | sed 's/"/\\"/g')
    printf '{"mac":"%s","name":"%s","icon":"%s","connected":%s}\n' "$mac" "$name" "$icon" "$is_connected"
done | python3 -c "
import sys, json
lines = [l.strip() for l in sys.stdin if l.strip()]
out = []
for l in lines:
    try: out.append(json.loads(l))
    except: pass
print(json.dumps(out))
"
