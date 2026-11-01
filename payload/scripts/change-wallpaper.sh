#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 IMAGE [scheme-tonal-spot|scheme-neutral|scheme-content]" >&2
    exit 2
fi
exec python3 "$HOME/.config/hypr/scripts/aether-theme.py" wallpaper "$@"
