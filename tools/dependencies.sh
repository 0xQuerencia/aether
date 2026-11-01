#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
command -v pacman >/dev/null || { printf 'Automatic dependency installation currently supports Arch/CachyOS.\n' >&2; exit 1; }
mapfile -t packages < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$root/packages/arch.txt")
missing=(); unavailable=()
for pkg in "${packages[@]}"; do
    pacman -Q "$pkg" >/dev/null 2>&1 && continue
    if pacman -Si "$pkg" >/dev/null 2>&1; then missing+=("$pkg"); else unavailable+=("$pkg"); fi
done
printf 'Missing official packages: %s\n' "${missing[*]:-(none)}"
printf 'Unavailable in configured repositories: %s\n' "${unavailable[*]:-(none)}"
printf 'Also required: matugen and awww; package names vary by distribution/repository.\n'
if [[ ${1:-} != --apply ]]; then printf 'Plan only. Use --apply to install available missing packages.\n'; exit 0; fi
[[ $EUID -ne 0 ]] || { printf 'Run as a regular user; sudo is used only for pacman.\n' >&2; exit 1; }
if ((${#missing[@]})); then sudo pacman -S --needed "${missing[@]}"; fi
if ((${#unavailable[@]})); then printf 'Resolve unavailable packages above before starting the shell.\n' >&2; exit 1; fi
