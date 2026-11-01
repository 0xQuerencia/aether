#!/usr/bin/env bash


# Usage:


STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell/island/ambient"
mkdir -p "$STATE_DIR"
VOL_FILE="$STATE_DIR/volume"
[ -f "$VOL_FILE" ] || echo 50 > "$VOL_FILE"

SOUNDS="rain ocean wind fire"

lavfi_for() {
    case "$1" in
        rain)  echo "anoisesrc=color=pink:amplitude=0.6,highpass=f=400,lowpass=f=6000" ;;
        ocean) echo "anoisesrc=color=brown:amplitude=0.9,lowpass=f=500,tremolo=f=0.1:d=0.7" ;;
        wind)  echo "anoisesrc=color=brown:amplitude=0.8,lowpass=f=800,tremolo=f=0.25:d=0.6" ;;
        fire)  echo "anoisesrc=color=brown:amplitude=0.85,lowpass=f=1100,tremolo=f=9:d=0.6,tremolo=f=0.5:d=0.4" ;;
        *) return 1 ;;
    esac
}

is_on() {
    local pid_file="$STATE_DIR/$1.pid"
    [ -f "$pid_file" ] || return 1
    local pid; pid=$(cat "$pid_file" 2>/dev/null)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

start_sound() {
    local s="$1" graph; graph=$(lavfi_for "$s") || return 1
    local vol; vol=$(cat "$VOL_FILE")
    local sock="$STATE_DIR/$s.sock"
    rm -f "$sock"
    setsid mpv --no-video --no-terminal --loop=inf --volume="$vol" \
        --input-ipc-server="$sock" \
        "av://lavfi:$graph" >/dev/null 2>&1 &
    echo $! > "$STATE_DIR/$s.pid"
}

stop_sound() {
    local s="$1"
    local pid_file="$STATE_DIR/$s.pid" sock="$STATE_DIR/$s.sock"
    if [ -f "$pid_file" ]; then
        local pid; pid=$(cat "$pid_file" 2>/dev/null)
        [ -n "$pid" ] && kill "$pid" 2>/dev/null
    fi
    rm -f "$pid_file" "$sock"
}

case "$1" in
    toggle)
        s="$2"
        lavfi_for "$s" >/dev/null || exit 1
        if is_on "$s"; then stop_sound "$s"; else start_sound "$s"; fi
        ;;
    volume)
        v="$2"
        [[ "$v" =~ ^[0-9]+$ ]] || exit 1
        [ "$v" -gt 100 ] && v=100
        echo "$v" > "$VOL_FILE"
        
        for s in $SOUNDS; do
            if is_on "$s"; then
                printf '{"command":["set_property","volume",%s]}\n' "$v" \
                    | socat - "$STATE_DIR/$s.sock" >/dev/null 2>&1
            fi
        done
        ;;
    stop-all)
        for s in $SOUNDS; do stop_sound "$s"; done
        ;;
    status|"")
        vol=$(cat "$VOL_FILE")
        out="{\"volume\":$vol,\"active\":{"
        first=1
        for s in $SOUNDS; do
            if is_on "$s"; then st=true; else st=false; fi
            [ $first -eq 1 ] && first=0 || out+=","
            out+="\"$s\":$st"
        done
        out+="}}"
        echo "$out"
        ;;
esac
