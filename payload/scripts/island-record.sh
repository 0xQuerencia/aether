#!/usr/bin/env bash

if [[ "$1" == status ]]; then
    "$HOME/.local/bin/aether-studio" status | python3 -c 'import json,sys;print(1 if json.load(sys.stdin).get("status")=="recording" else 0)'
else
    exec "$HOME/.local/bin/aether-studio" "$@"
fi
