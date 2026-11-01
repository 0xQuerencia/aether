#!/usr/bin/env bash
# island-caffeine.sh toggle|status

STATE_DIR="$XDG_RUNTIME_DIR/quickshell/island"
PID_FILE="$STATE_DIR/caffeine_pid"
STATE_FILE="$STATE_DIR/caffeine_state"
mkdir -p "$STATE_DIR"

is_active() {
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

case "$1" in
    toggle)
        if is_active; then
            kill "$(cat "$PID_FILE")" 2>/dev/null
            rm -f "$PID_FILE"
            echo 0 > "$STATE_FILE"
        else
            systemd-inhibit --what=idle:sleep --who="Dynamic Island" \
                --why="Caffeine mode" sleep infinity &
            echo $! > "$PID_FILE"
            echo 1 > "$STATE_FILE"
        fi
        ;;
    status)
        is_active && echo 1 || echo 0
        ;;
esac
