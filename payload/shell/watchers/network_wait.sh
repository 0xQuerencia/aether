#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"

PIPE="$QS_RUN_DIR/qs_network_wait_$$.fifo"
mkfifo "$PIPE" 2>/dev/null


trap 'rm -f "$PIPE"; kill $MONITOR_PID 2>/dev/null; exit 0' EXIT INT TERM


LC_ALL=C nmcli monitor 2>/dev/null > "$PIPE" &
MONITOR_PID=$!


grep -m 1 -iwE "connected|disconnected|enabled|disabled|activated|deactivated|available|unavailable" < "$PIPE" > /dev/null
