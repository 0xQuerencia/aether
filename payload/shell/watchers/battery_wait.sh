#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"

PIPE="$QS_RUN_DIR/qs_battery_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null

trap 'rm -f "$PIPE"; kill $MONITOR_PID 2>/dev/null; exit 0' EXIT INT TERM


LC_ALL=C udevadm monitor --subsystem-match=power_supply 2>/dev/null > "$PIPE" &
MONITOR_PID=$!


timeout 10 grep -m 1 "change" < "$PIPE" > /dev/null
