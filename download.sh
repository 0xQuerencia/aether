#!/usr/bin/env bash
# Usage: bash download.sh OWNER/REPOSITORY [REF] [installer options...]
set -euo pipefail
repo=${1:-}; ref=${2:-main}
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || { printf 'Usage: %s OWNER/REPO [REF] [--apply --wallpapers]\n' "$0" >&2; exit 2; }
[[ "$ref" =~ ^[A-Za-z0-9_./-]+$ && "$ref" != -* ]] || { printf 'Invalid Git ref\n' >&2; exit 2; }
shift; if (($#)); then shift; fi
command -v git >/dev/null || { printf 'Install git first.\n' >&2; exit 1; }
base=${XDG_DATA_HOME:-$HOME/.local/share}/aether-installer
mkdir -p "$base"
checkout=$(mktemp -d "$base/download-XXXXXXXX")
git clone --filter=blob:none --no-checkout "https://github.com/$repo.git" "$checkout"
git -C "$checkout" checkout --detach "$ref"
printf 'Downloaded commit: '; git -C "$checkout" rev-parse HEAD
printf 'Source checkout retained at: %s\n' "$checkout"
exec bash "$checkout/install.sh" "$@"
