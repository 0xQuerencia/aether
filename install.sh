#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
command -v python3 >/dev/null || { printf 'Python 3.11+ is required.\n' >&2; exit 1; }
exec python3 tools/install.py "$@"
