#!/usr/bin/env bash

set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$root/payload/shell/pomodoro" "$root/payload/shell/network/sounds"
ffmpeg -y -v error -f lavfi -i 'sine=frequency=880:duration=0.45:sample_rate=48000' -af 'afade=t=out:st=0.08:d=0.37,volume=0.16' "$root/payload/shell/pomodoro/bell.ogg"
for pair in connect:740 disconnect:440 power_off:330 power_on:660 switch:550; do
    name=${pair%:*}; frequency=${pair#*:}
    ffmpeg -y -v error -f lavfi -i "sine=frequency=$frequency:duration=0.12:sample_rate=48000" -af 'afade=t=out:st=0.02:d=0.10,volume=0.08' "$root/payload/shell/network/sounds/$name.wav"
done
