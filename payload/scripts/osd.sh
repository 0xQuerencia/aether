#!/usr/bin/env bash


# morphs into the slider.
# usage: osd.sh {vol-up|vol-down|vol-mute|bright-up|bright-down}

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell/island"
F="$STATE_DIR/osd.json"
mkdir -p "$STATE_DIR"
STEP=5

# Do not queue behind stalled audio.

case "$1" in
    vol-*|mic-mute) CONTROL=audio ;;
    bright-*) CONTROL=brightness ;;
    *) exit 1 ;;
esac
exec 9>"$STATE_DIR/osd-$CONTROL.lock"
flock -n 9 || exit 0

bounded() { timeout --kill-after=0.2s 1s "$@"; }
trap 'status=$?; if (( status != 0 )); then printf "Aether OSD: %s failed (status %s)\n" "$1" "$status" >&2; fi' EXIT
set -e -o pipefail

case "$1" in
    vol-up)     bounded wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ ${STEP}%+ >/dev/null 2>&1 ;;
    vol-down)   bounded wpctl set-volume @DEFAULT_AUDIO_SINK@ ${STEP}%- >/dev/null 2>&1 ;;
    vol-mute)   bounded wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null 2>&1 ;;
    mic-mute)   bounded wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle >/dev/null 2>&1 ;;
    bright-up)  bounded brightnessctl set ${STEP}%+ >/dev/null 2>&1 ;;
    bright-down) bounded brightnessctl --min-value=5 set ${STEP}%- >/dev/null 2>&1 ;;
    *) exit 1 ;;
esac

TS=$(date +%s%3N)
TMP=$(mktemp "$STATE_DIR/.osd.XXXXXX")
trap 'status=$?; rm -f "$TMP"; if (( status != 0 )); then printf "Aether OSD: %s failed (status %s)\n" "$1" "$status" >&2; fi' EXIT

if [[ "$1" == bright-* ]]; then
    VAL=$(bounded brightnessctl -m | awk -F, '{gsub(/%/,"",$4); print $4}')
    printf '{"ts":%s,"type":"brightness","value":%s,"muted":false}\n' "$TS" "${VAL:-0}" > "$TMP"
elif [[ "$1" == "mic-mute" ]]; then
    RAW=$(bounded wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
    if echo "$RAW" | grep -q MUTED; then MUTED=true; else MUTED=false; fi
    printf '{"ts":%s,"type":"mic","value":0,"muted":%s}\n' "$TS" "$MUTED" > "$TMP"
else
    RAW=$(bounded wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    VAL=$(echo "$RAW" | awk '{print int($2*100 + 0.5)}')
    if echo "$RAW" | grep -q MUTED; then MUTED=true; else MUTED=false; fi
    printf '{"ts":%s,"type":"volume","value":%s,"muted":%s}\n' "$TS" "${VAL:-0}" "$MUTED" > "$TMP"
fi

# Write the state atomically.
mv -f "$TMP" "$F"
